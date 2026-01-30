// Unit tests only – logic/functions, no UI.

import 'package:filed_notes/features/notes/data/models/note_dto.dart';
import 'package:filed_notes/features/notes/domain/entities/note.dart';
import 'package:filed_notes/features/notes/domain/enums/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';



void main() {
  group('NoteDto', () {
    final testDto = NoteDto(
      id: 'test-id',
      title: 'Test Note',
      body: 'Test body',
      tags: ['tag1', 'tag2'],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    group('fromJson', () {
      test('should create NoteDto from valid JSON', () {
        final json = {
          'id': 'test-id',
          'title': 'Test Note',
          'body': 'Test body',
          'tags': ['tag1', 'tag2'],
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final dto = NoteDto.fromJson(json);

        expect(dto.id, 'test-id');
        expect(dto.title, 'Test Note');
        expect(dto.body, 'Test body');
        expect(dto.tags, ['tag1', 'tag2']);
        expect(dto.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
        expect(dto.updatedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
      });

      test('should handle empty tags', () {
        final json = {
          'id': 'id',
          'title': 'Title',
          'body': 'Body',
          'tags': [],
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        };

        final dto = NoteDto.fromJson(json);

        expect(dto.tags, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert NoteDto to JSON', () {
        final json = testDto.toJson();

        expect(json['id'], 'test-id');
        expect(json['title'], 'Test Note');
        expect(json['body'], 'Test body');
        expect(json['tags'], ['tag1', 'tag2']);
        expect(json['createdAt'], testDto.createdAt.toIso8601String());
        expect(json['updatedAt'], testDto.updatedAt.toIso8601String());
      });

      test('should serialize dates in ISO8601 format', () {
        final json = testDto.toJson();

        expect(json['createdAt'], isA<String>());
        expect(json['updatedAt'], isA<String>());
        expect(() => DateTime.parse(json['createdAt'] as String),
            returnsNormally);
        expect(() => DateTime.parse(json['updatedAt'] as String),
            returnsNormally);
      });
    });

    group('toEntity', () {
      test('should convert NoteDto to Note entity', () {
        final entity = testDto.toEntity();

        expect(entity.id, testDto.id);
        expect(entity.title, testDto.title);
        expect(entity.body, testDto.body);
        expect(entity.tags, testDto.tags);
        expect(entity.createdAt, testDto.createdAt);
        expect(entity.updatedAt, testDto.updatedAt);
        expect(entity.syncStatus, SyncStatus.synced);
      });

      test('should create new list for tags', () {
        final entity = testDto.toEntity();
        entity.tags.add('new-tag');

        expect(testDto.tags.length, 2);
        expect(entity.tags.length, 3);
      });
    });

    group('fromEntity', () {
      test('should create NoteDto from Note entity', () {
        final note = Note(
          id: 'note-id',
          title: 'Note Title',
          body: 'Note Body',
          tags: ['work'],
          updatedAt: DateTime(2024, 1, 2),
          createdAt: DateTime(2024, 1, 1),
          syncStatus: SyncStatus.pending,
        );

        final dto = NoteDto.fromEntity(note);

        expect(dto.id, note.id);
        expect(dto.title, note.title);
        expect(dto.body, note.body);
        expect(dto.tags, note.tags);
        expect(dto.updatedAt, note.updatedAt);
        expect(dto.createdAt, note.createdAt ?? note.updatedAt);
      });

      test('should use updatedAt as createdAt when createdAt is null', () {
        final note = Note(
          id: 'id',
          title: 'Title',
          body: 'Body',
          tags: [],
          updatedAt: DateTime(2024, 1, 2),
          syncStatus: SyncStatus.pending,
        );

        final dto = NoteDto.fromEntity(note);

        expect(dto.createdAt, note.updatedAt);
      });

      test('should create new list for tags', () {
        final note = Note(
          id: 'id',
          title: 'Title',
          body: 'Body',
          tags: ['tag1'],
          updatedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          syncStatus: SyncStatus.synced,
        );

        final dto = NoteDto.fromEntity(note);
        dto.tags.add('tag2');

        expect(note.tags.length, 1);
        expect(dto.tags.length, 2);
      });
    });

    group('toCreateRequest', () {
      test('should create request body without id and timestamps', () {
        final request = testDto.toCreateRequest();

        expect(request.containsKey('id'), isFalse);
        expect(request.containsKey('createdAt'), isFalse);
        expect(request.containsKey('updatedAt'), isFalse);
        expect(request['title'], testDto.title);
        expect(request['body'], testDto.body);
        expect(request['tags'], testDto.tags);
      });

      test('should include only title, body, and tags', () {
        final request = testDto.toCreateRequest();

        expect(request.keys.length, 3);
        expect(request.keys, containsAll(['title', 'body', 'tags']));
      });
    });

    group('toUpdateRequest', () {
      test('should create update request without id and createdAt', () {
        final request = testDto.toUpdateRequest();

        expect(request.containsKey('id'), isFalse);
        expect(request.containsKey('createdAt'), isFalse);
        expect(request.containsKey('updatedAt'), isTrue);
        expect(request['title'], testDto.title);
        expect(request['body'], testDto.body);
        expect(request['tags'], testDto.tags);
      });

      test('should include updatedAt timestamp', () {
        final request = testDto.toUpdateRequest();

        expect(request['updatedAt'], testDto.updatedAt.toIso8601String());
      });
    });
  });
}
