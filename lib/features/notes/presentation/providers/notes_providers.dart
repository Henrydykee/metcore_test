import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  throw UnimplementedError(
    'NotesRepository must be overridden in main with notesRepositoryProvider',
  );
});

final notesListProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.getNotes();
});

final noteByIdProvider =
    FutureProvider.family<Note?, String>((ref, id) async {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.getNoteById(id);
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final filterTagProvider = StateProvider<String>((ref) => '');

final filteredNotesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(notesRepositoryProvider);
  final search = ref.watch(searchQueryProvider);
  final tag = ref.watch(filterTagProvider);
  if (tag.isNotEmpty) {
    return repo.filterByTag(tag);
  }
  return repo.searchByTitle(search);
});

final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(notesRepositoryProvider);
  final notes = await repo.getNotes();
  final tags = <String>{};
  for (final n in notes) {
    tags.addAll(n.tags);
  }
  return tags.toList()..sort();
});
