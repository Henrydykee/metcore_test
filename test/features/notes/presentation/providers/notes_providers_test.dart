// Unit tests only – logic/functions, no UI.

import 'package:filed_notes/features/notes/domain/entities/note.dart';
import 'package:filed_notes/features/notes/domain/enums/sync_status.dart';
import 'package:filed_notes/features/notes/domain/repositories/notes_repository.dart';
import 'package:filed_notes/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'notes_providers_test.mocks.dart';

@GenerateMocks([NotesRepository])
void main() {
  group('Notes Providers', () {
    late MockNotesRepository mockRepository;
    late ProviderContainer container;

    final testNotes = [
      Note(
        id: '1',
        title: 'Note 1',
        body: 'Body 1',
        tags: ['work'],
        updatedAt: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        syncStatus: SyncStatus.synced,
      ),
      Note(
        id: '2',
        title: 'Note 2',
        body: 'Body 2',
        tags: ['personal'],
        updatedAt: DateTime(2024, 1, 2),
        createdAt: DateTime(2024, 1, 2),
        syncStatus: SyncStatus.synced,
      ),
    ];

    setUp(() {
      mockRepository = MockNotesRepository();
      container = ProviderContainer(
        overrides: [
          notesRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('notesListProvider', () {
      test('should return list of notes', () async {
        // Arrange
        when(mockRepository.getNotes()).thenAnswer((_) async => testNotes);

        // Act
        final result = await container.read(notesListProvider.future);

        // Assert
        expect(result, testNotes);
        verify(mockRepository.getNotes()).called(1);
      });

      test('should handle empty list', () async {
        // Arrange
        when(mockRepository.getNotes()).thenAnswer((_) async => []);

        // Act
        final result = await container.read(notesListProvider.future);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('noteByIdProvider', () {
      test('should return note by id', () async {
        // Arrange
        final note = testNotes.first;
        when(mockRepository.getNoteById('1'))
            .thenAnswer((_) async => note);

        // Act
        final result = await container
            .read(noteByIdProvider('1').future);

        // Assert
        expect(result, note);
        verify(mockRepository.getNoteById('1')).called(1);
      });

      test('should return null when note not found', () async {
        // Arrange
        when(mockRepository.getNoteById('999'))
            .thenAnswer((_) async => null);

        // Act
        final result = await container
            .read(noteByIdProvider('999').future);

        // Assert
        expect(result, isNull);
      });
    });

    group('searchQueryProvider', () {
      test('should initialize with empty string', () {
        final query = container.read(searchQueryProvider);

        expect(query, '');
      });

      test('should update search query', () {
        container.read(searchQueryProvider.notifier).state = 'test';

        final query = container.read(searchQueryProvider);
        expect(query, 'test');
      });
    });

    group('filterTagProvider', () {
      test('should initialize with empty string', () {
        final tag = container.read(filterTagProvider);

        expect(tag, '');
      });

      test('should update filter tag', () {
        container.read(filterTagProvider.notifier).state = 'work';

        final tag = container.read(filterTagProvider);
        expect(tag, 'work');
      });
    });

    group('filteredNotesProvider', () {
      test('should filter by tag when tag is provided', () async {
        // Arrange
        final filteredNotes = [testNotes.first];
        container.read(filterTagProvider.notifier).state = 'work';
        when(mockRepository.filterByTag('work'))
            .thenAnswer((_) async => filteredNotes);

        // Act
        final result = await container.read(filteredNotesProvider.future);

        // Assert
        expect(result, filteredNotes);
        verify(mockRepository.filterByTag('work')).called(1);
        verifyNever(mockRepository.searchByTitle(any));
      });

      test('should search by title when tag is empty', () async {
        // Arrange
        container.read(searchQueryProvider.notifier).state = 'Note';
        container.read(filterTagProvider.notifier).state = '';
        when(mockRepository.searchByTitle('Note'))
            .thenAnswer((_) async => testNotes);

        // Act
        final result = await container.read(filteredNotesProvider.future);

        // Assert
        expect(result, testNotes);
        verify(mockRepository.searchByTitle('Note')).called(1);
        verifyNever(mockRepository.filterByTag(any));
      });

      test('should prioritize tag filter over search', () async {
        // Arrange
        container.read(searchQueryProvider.notifier).state = 'Note';
        container.read(filterTagProvider.notifier).state = 'work';
        when(mockRepository.filterByTag('work'))
            .thenAnswer((_) async => [testNotes.first]);

        // Act
        final result = await container.read(filteredNotesProvider.future);

        // Assert
        expect(result.length, 1);
        verify(mockRepository.filterByTag('work')).called(1);
        verifyNever(mockRepository.searchByTitle(any));
      });
    });

    group('allTagsProvider', () {
      test('should return unique sorted tags', () async {
        // Arrange
        final notesWithTags = [
          testNotes.first.copyWith(tags: ['work', 'urgent']),
          testNotes.last.copyWith(tags: ['personal', 'work']),
        ];
        when(mockRepository.getNotes())
            .thenAnswer((_) async => notesWithTags);

        // Act
        final result = await container.read(allTagsProvider.future);

        // Assert
        expect(result, ['personal', 'urgent', 'work']);
        expect(result.length, 3);
      });

      test('should return empty list when no tags exist', () async {
        // Arrange
        final notesWithoutTags = testNotes.map((n) => n.copyWith(tags: [])).toList();
        when(mockRepository.getNotes())
            .thenAnswer((_) async => notesWithoutTags);

        // Act
        final result = await container.read(allTagsProvider.future);

        // Assert
        expect(result, isEmpty);
      });

      test('should handle duplicate tags', () async {
        // Arrange
        final notes = [
          testNotes.first.copyWith(tags: ['work', 'work']),
          testNotes.last.copyWith(tags: ['work']),
        ];
        when(mockRepository.getNotes())
            .thenAnswer((_) async => notes);

        // Act
        final result = await container.read(allTagsProvider.future);

        // Assert
        expect(result, ['work']);
        expect(result.length, 1);
      });
    });
  });
}
