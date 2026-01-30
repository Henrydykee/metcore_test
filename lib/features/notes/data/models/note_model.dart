import '../../domain/entities/note.dart';
import '../../domain/enums/sync_status.dart';

class NoteModel {
  NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.updatedAt,
    required this.syncStatus,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime updatedAt;
  final String syncStatus;
  final DateTime? createdAt;

  static NoteModel fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      body: note.body,
      tags: List.from(note.tags),
      updatedAt: note.updatedAt,
      createdAt: note.createdAt,
      syncStatus: note.syncStatus.name,
    );
  }

  Note toEntity() {
    return Note(
      id: id,
      title: title,
      body: body,
      tags: List.from(tags),
      updatedAt: updatedAt,
      createdAt: createdAt,
      syncStatus: SyncStatus.values.byName(syncStatus),
    );
  }
}
