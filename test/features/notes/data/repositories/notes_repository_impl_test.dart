// Unit tests only – logic/functions, no UI.

import 'package:filed_notes/core/data/database/db_exceptions.dart';
import 'package:filed_notes/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:filed_notes/features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:filed_notes/features/notes/data/models/note_dto.dart';
import 'package:filed_notes/features/notes/data/models/note_model.dart';
import 'package:filed_notes/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:filed_notes/features/notes/domain/entities/note.dart';
import 'package:filed_notes/features/notes/domain/enums/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'notes_repository_impl_test.mocks.dart';

@GenerateMocks([NotesLocalDatasource, NotesRemoteDatasource])
void main() {
  late NotesRepositoryImpl repository;
  late MockNotesLocalDatasource mockLocal;
  late MockNotesRemoteDatasource mockRemote;

  setUp(() {
    mockLocal = MockNotesLocalDatasource();
    mockRemote = MockNotesRemoteDatasource();
    repository = NotesRepositoryImpl(mockLocal, mockRemote);
  });

  group('NotesRepositoryImpl', () {
    final testNote = Note(
      id: 'test-id',
      title: 'Test Note',
      body: 'Test body',
      tags: ['test'],
      updatedAt: DateTime(2024, 1, 1),
      createdAt: DateTime(2024, 1, 1),
      syncStatus: SyncStatus.synced,
    );

    final testNoteModel = NoteModel.fromEntity(testNote);
    final testNoteDto = NoteDto.fromEntity(testNote);

    group('getNotes', () {
      test('should return notes from local when remote succeeds', () async {
        // Arrange - getNotes called twice: push pending + fetch merge
        when(mockRemote.getNotes())
            .thenAnswer((_) async => [testNoteDto]);
        when(mockLocal.getAll()).thenReturn([testNoteModel]);

        // Act
        final result = await repository.getNotes();

        // Assert
        expect(result, isA<List<Note>>());
        expect(result.length, 1);
        expect(result.first.id, testNote.id);
        verify(mockRemote.getNotes()).called(greaterThanOrEqualTo(1));
        verify(mockLocal.putAll(any)).called(1);
        verify(mockLocal.getAll()).called(greaterThanOrEqualTo(1));
      });

      test('should return local notes when remote fails', () async {
        // Arrange - push and fetch both fail; fall back to local
        when(mockRemote.getNotes())
            .thenThrow(NetworkFailure('Network error'));
        when(mockLocal.getAll()).thenReturn([testNoteModel]);

        // Act
        final result = await repository.getNotes();

        // Assert
        expect(result, isA<List<Note>>());
        expect(result.length, 1);
        expect(result.first.id, testNote.id);
        verify(mockLocal.getAll()).called(greaterThanOrEqualTo(1));
        verifyNever(mockLocal.putAll(any));
      });

      test('should return empty list when no notes exist', () async {
        // Arrange
        when(mockRemote.getNotes()).thenAnswer((_) async => []);
        when(mockLocal.getAll()).thenReturn([]);

        // Act
        final result = await repository.getNotes();

        // Assert
        expect(result, isEmpty);
      });

      test('should push pending notes to server before fetching on launch', () async {
        // Arrange: local has a pending note (created offline)
        final pendingNote = Note(
          id: 'client-uuid-pending',
          title: 'Offline Note',
          body: 'Created while offline',
          tags: ['test'],
          updatedAt: DateTime(2024, 1, 2),
          createdAt: DateTime(2024, 1, 2),
          syncStatus: SyncStatus.pending,
        );
        final pendingModel = NoteModel.fromEntity(pendingNote);
        final syncedDto = NoteDto(
          id: 'server-uuid-synced',
          title: 'Offline Note',
          body: 'Created while offline',
          tags: ['test'],
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        );
        final syncedModel = NoteModel.fromEntity(syncedDto.toEntity());
        when(mockRemote.getNotes())
            .thenAnswer((_) async => [syncedDto]);
        when(mockRemote.createNote(any)).thenAnswer((_) async => syncedDto);
        // First getAll: pending for push; later getAll: synced after merge
        var getAllCallCount = 0;
        when(mockLocal.getAll()).thenAnswer((_) {
          getAllCallCount++;
          if (getAllCallCount <= 2) return [pendingModel];
          return [syncedModel];
        });

        // Act
        final result = await repository.getNotes();

        // Assert: pending was pushed (POST), then we got synced version back
        expect(result.length, 1);
        expect(result.first.id, 'server-uuid-synced');
        verify(mockRemote.createNote(any)).called(1);
      });
    });

    group('getNoteById', () {
      test('should return note from remote when available', () async {
        // Arrange
        when(mockRemote.getNoteById(testNote.id))
            .thenAnswer((_) async => testNoteDto);
        when(mockLocal.getById(testNote.id)).thenReturn(testNoteModel);

        // Act
        final result = await repository.getNoteById(testNote.id);

        // Assert
        expect(result, isNotNull);
        expect(result?.id, testNote.id);
        verify(mockRemote.getNoteById(testNote.id)).called(1);
        verify(mockLocal.put(any)).called(1);
      });

      test('should return note from local when remote fails', () async {
        // Arrange
        when(mockRemote.getNoteById(testNote.id))
            .thenThrow(NetworkFailure('Network error'));
        when(mockLocal.getById(testNote.id)).thenReturn(testNoteModel);

        // Act
        final result = await repository.getNoteById(testNote.id);

        // Assert
        expect(result, isNotNull);
        expect(result?.id, testNote.id);
        verify(mockRemote.getNoteById(testNote.id)).called(1);
        verify(mockLocal.getById(testNote.id)).called(1);
      });

      test('should return null when note does not exist', () async {
        // Arrange
        when(mockRemote.getNoteById('non-existent'))
            .thenThrow(NetworkFailure('Not found'));
        when(mockLocal.getById('non-existent')).thenReturn(null);

        // Act
        final result = await repository.getNoteById('non-existent');

        // Assert
        expect(result, isNull);
      });
    });

    group('createNote', () {
      test('should create note locally and sync to remote', () async {
        // Arrange: server returns the created note (same title/body/tags we sent)
        final now = DateTime.now().toUtc();
        final syncedDto = NoteDto(
          id: testNote.id,
          title: 'New Note',
          body: 'New body',
          tags: ['new'],
          createdAt: now,
          updatedAt: now,
        );
        when(mockRemote.createNote(any))
            .thenAnswer((_) async => syncedDto);

        // Act
        final result = await repository.createNote(
          title: 'New Note',
          body: 'New body',
          tags: ['new'],
        );

        // Assert
        expect(result, isA<Note>());
        expect(result.title, 'New Note');
        expect(result.body, 'New body');
        expect(result.syncStatus, SyncStatus.synced);
        verify(mockLocal.put(any)).called(2); // Once for pending, once for synced
        verify(mockRemote.createNote(any)).called(1);
      });

      test('should create note locally when remote fails', () async {
        // Arrange
        when(mockRemote.createNote(any))
            .thenThrow(NetworkFailure('Network error'));

        // Act
        final result = await repository.createNote(
          title: 'New Note',
          body: 'New body',
        );

        // Assert
        expect(result, isA<Note>());
        expect(result.title, 'New Note');
        expect(result.syncStatus, SyncStatus.pending);
        verify(mockLocal.put(any)).called(1);
        verify(mockRemote.createNote(any)).called(1);
      });
    });

    group('updateNote', () {
      test('should update note locally and sync to remote', () async {
        // Arrange
        final updatedDto = NoteDto(
          id: testNote.id,
          title: 'Updated Title',
          body: testNote.body,
          tags: testNote.tags,
          createdAt: testNote.createdAt!,
          updatedAt: DateTime.now(),
        );
        when(mockRemote.updateNote(any))
            .thenAnswer((_) async => updatedDto);

        // Act
        final result = await repository.updateNote(
          testNote.copyWith(title: 'Updated Title'),
        );

        // Assert
        expect(result, isA<Note>());
        expect(result.title, 'Updated Title');
        expect(result.syncStatus, SyncStatus.synced);
        verify(mockLocal.put(any)).called(2);
        verify(mockRemote.updateNote(any)).called(1);
      });

      test('should update note locally when remote fails', () async {
        // Arrange
        when(mockRemote.updateNote(any))
            .thenThrow(NetworkFailure('Network error'));

        // Act
        final result = await repository.updateNote(
          testNote.copyWith(title: 'Updated Title'),
        );

        // Assert
        expect(result, isA<Note>());
        expect(result.title, 'Updated Title');
        expect(result.syncStatus, SyncStatus.pending);
        verify(mockLocal.put(any)).called(1);
        verify(mockRemote.updateNote(any)).called(1);
      });
    });

    group('deleteNote', () {
      test('should delete note locally and from remote', () async {
        // Arrange
        when(mockRemote.deleteNote(testNote.id))
            .thenAnswer((_) async => Future.value());

        // Act
        await repository.deleteNote(testNote.id);

        // Assert
        verify(mockLocal.delete(testNote.id)).called(1);
        verify(mockRemote.deleteNote(testNote.id)).called(1);
      });

      test('should delete note locally when remote fails', () async {
        // Arrange
        when(mockRemote.deleteNote(testNote.id))
            .thenThrow(NetworkFailure('Network error'));

        // Act
        await repository.deleteNote(testNote.id);

        // Assert
        verify(mockLocal.delete(testNote.id)).called(1);
        verify(mockRemote.deleteNote(testNote.id)).called(1);
      });
    });

    group('searchByTitle', () {
      test('should return filtered notes by title', () async {
        // Arrange
        final note1 = testNote.copyWith(id: '1', title: 'Flutter Guide');
        final note2 = testNote.copyWith(id: '2', title: 'Dart Tutorial');
        final note3 = testNote.copyWith(id: '3', title: 'Flutter Tips');

        when(mockRemote.getNotes())
            .thenAnswer((_) async => [testNoteDto]);
        when(mockLocal.getAll()).thenReturn([
          NoteModel.fromEntity(note1),
          NoteModel.fromEntity(note2),
          NoteModel.fromEntity(note3),
        ]);

        // Act
        final result = await repository.searchByTitle('Flutter');

        // Assert
        expect(result.length, 2);
        expect(result.every((n) => n.title.contains('Flutter')), isTrue);
      });

      test('should return all notes when query is empty', () async {
        // Arrange
        when(mockRemote.getNotes()).thenAnswer((_) async => []);
        when(mockLocal.getAll()).thenReturn([testNoteModel]);

        // Act
        final result = await repository.searchByTitle('');

        // Assert
        expect(result.length, 1);
      });
    });

    group('filterByTag', () {
      test('should return notes filtered by tag', () async {
        // Arrange
        final note1 = testNote.copyWith(id: '1', tags: ['work', 'urgent']);
        final note2 = testNote.copyWith(id: '2', tags: ['personal']);
        final note3 = testNote.copyWith(id: '3', tags: ['work']);

        when(mockRemote.getNotes())
            .thenAnswer((_) async => [testNoteDto]);
        when(mockLocal.getAll()).thenReturn([
          NoteModel.fromEntity(note1),
          NoteModel.fromEntity(note2),
          NoteModel.fromEntity(note3),
        ]);

        // Act
        final result = await repository.filterByTag('work');

        // Assert
        expect(result.length, 2);
        expect(result.every((n) => n.tags.contains('work')), isTrue);
      });

      test('should return all notes when tag is empty', () async {
        // Arrange
        when(mockRemote.getNotes()).thenAnswer((_) async => []);
        when(mockLocal.getAll()).thenReturn([testNoteModel]);

        // Act
        final result = await repository.filterByTag('');

        // Assert
        expect(result.length, 1);
      });
    });

    group('repository without remote', () {
      test('should work with only local datasource', () async {
        // Arrange
        final localOnlyRepo = NotesRepositoryImpl(mockLocal, null);
        when(mockLocal.getAll()).thenReturn([testNoteModel]);

        // Act
        final result = await localOnlyRepo.getNotes();

        // Assert
        expect(result.length, 1);
        verify(mockLocal.getAll()).called(1);
        verifyNever(mockRemote.getNotes());
      });
    });
  });
}
