import 'package:uuid/uuid.dart';

import '../../../../core/data/database/db_exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/note.dart';
import '../../domain/enums/sync_status.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_local_datasource.dart';
import '../datasources/notes_remote_datasource.dart';
import '../models/note_dto.dart';
import '../models/note_model.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._local, this._remote);

  final NotesLocalDatasource _local;
  final NotesRemoteDatasource? _remote;

  @override
  Future<List<Note>> getNotes() async {
    if (_remote != null) {
      // 1. Push any pending notes to server first (on launch / refresh)
      await _pushPendingNotes();

      // 2. Fetch from remote and sync to local
      try {
        final remoteNotes = await _remote!.getNotes();
        // Sync remote notes to local storage
        final models = remoteNotes.map((dto) {
          final entity = dto.toEntity();
          return NoteModel.fromEntity(entity);
        }).toList();
        await _local.putAll(models);
        // Remove orphaned local pending notes that duplicate synced remote notes
        // (e.g. client-created note later synced with different server id)
        final remoteIds = {for (var m in models) m.id};
        final localList = _local.getAll();
        for (final local in localList) {
          if (local.syncStatus == SyncStatus.pending.name &&
              !remoteIds.contains(local.id)) {
            final isDuplicate = models.any((r) =>
                r.title == local.title &&
                r.body == local.body &&
                _tagsEqual(r.tags, local.tags));
            if (isDuplicate) {
              await _local.delete(local.id);
            }
          }
        }
      } on NetworkFailure catch (e) {
        logger.e('Failed to fetch notes from remote: ${e.message}');
        // Continue with local data
      }
    }

    // Return local data (either synced from remote or existing local data)
    final list = _local.getAll();
    return list.map((m) => m.toEntity()).toList();
  }

  bool _tagsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = Set.from(a);
    return b.every((t) => sa.contains(t));
  }

  /// Pushes local pending notes to the server. Called on getNotes (launch/refresh).
  Future<void> _pushPendingNotes() async {
    if (_remote == null) return;

    List<String> serverIds;
    try {
      final remoteNotes = await _remote!.getNotes();
      serverIds = remoteNotes.map((d) => d.id).toList();
    } on NetworkFailure catch (e) {
      logger.e('Failed to fetch server state for push: ${e.message}');
      return;
    }

    final pending = _local.getAll().where((m) => m.syncStatus == SyncStatus.pending.name).toList();
    for (final local in pending) {
      final entity = local.toEntity();
      final dto = NoteDto.fromEntity(entity);

      try {
        if (serverIds.contains(local.id)) {
          // Note exists on server → PATCH (update)
          final remoteNote = await _remote!.updateNote(dto);
          final synced = NoteModel.fromEntity(remoteNote.toEntity());
          await _local.put(synced);
        } else {
          // Note not on server → POST (create)
          final remoteNote = await _remote!.createNote(dto);
          final syncedEntity = remoteNote.toEntity();
          await _local.put(NoteModel.fromEntity(syncedEntity));
          if (syncedEntity.id != local.id) {
            await _local.delete(local.id);
          }
        }
      } on NetworkFailure catch (e) {
        logger.e('Failed to push pending note ${local.id}: ${e.message}');
        // Keep pending; will retry on next getNotes
      }
    }
  }

  @override
  Future<Note?> getNoteById(String id) async {
    // Try remote first
    if (_remote != null) {
      try {
        final dto = await _remote!.getNoteById(id);
        final entity = dto.toEntity();
        // Update local cache
        await _local.put(NoteModel.fromEntity(entity));
        return entity;
      } on NetworkFailure catch (e) {
        logger.e('Failed to fetch note from remote: ${e.message}');
        // Fallback to local
      }
    }

    // Fallback to local
    final model = _local.getById(id);
    return model?.toEntity();
  }

  @override
  Future<Note> createNote({
    required String title,
    required String body,
    List<String> tags = const [],
  }) async {
    final id = _newId();
    final now = DateTime.now().toUtc();
    
    // Create locally first with pending status
    final note = Note(
      id: id,
      title: title,
      body: body,
      tags: List.from(tags),
      updatedAt: now,
      createdAt: now,
      syncStatus: SyncStatus.pending,
    );
    await _local.put(NoteModel.fromEntity(note));

    // Try to sync to remote
    if (_remote != null) {
      try {
        final dto = NoteDto.fromEntity(note);
        final remoteNote = await _remote!.createNote(dto);
        // Update local with synced data (server assigns its own id)
        final syncedEntity = remoteNote.toEntity();
        await _local.put(NoteModel.fromEntity(syncedEntity));
        // Remove the original local entry; server id differs from client id
        if (syncedEntity.id != note.id) {
          await _local.delete(note.id);
        }
        return syncedEntity;
      } on NetworkFailure catch (e) {
        logger.e('Failed to create note on remote: ${e.message}');
        // Keep local note with pending status
      }
    }

    return note;
  }

  @override
  Future<Note> updateNote(Note note) async {
    final updated = note.copyWith(
      updatedAt: DateTime.now().toUtc(),
      syncStatus: SyncStatus.pending,
    );
    
    // Update locally first
    await _local.put(NoteModel.fromEntity(updated));

    // Try to sync to remote
    if (_remote != null) {
      try {
        final dto = NoteDto.fromEntity(updated);
        final remoteNote = await _remote!.updateNote(dto);
        // Update local with synced data
        final syncedEntity = remoteNote.toEntity();
        await _local.put(NoteModel.fromEntity(syncedEntity));
        return syncedEntity;
      } on NetworkFailure catch (e) {
        logger.e('Failed to update note on remote: ${e.message}');
        // Keep local note with pending status
      }
    }

    return updated;
  }

  @override
  Future<void> deleteNote(String id) async {
    // Delete locally first
    await _local.delete(id);

    // Try to delete from remote
    if (_remote != null) {
      try {
        await _remote!.deleteNote(id);
      } on NetworkFailure catch (e) {
        logger.e('Failed to delete note on remote: ${e.message}');
        // Note is deleted locally, but will remain on server
        // Could implement a queue for retry logic later
      }
    }
  }

  @override
  Future<List<Note>> searchByTitle(String query) async {
    final all = await getNotes();
    if (query.trim().isEmpty) return all;
    final lower = query.trim().toLowerCase();
    return all.where((n) => n.title.toLowerCase().contains(lower)).toList();
  }

  @override
  Future<List<Note>> filterByTag(String tag) async {
    final all = await getNotes();
    if (tag.trim().isEmpty) return all;
    final lower = tag.trim().toLowerCase();
    return all.where((n) => n.tags.any((t) => t.toLowerCase() == lower)).toList();
  }

  static final _uuid = Uuid();

  String _newId() => _uuid.v4();
}
