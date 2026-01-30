import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_theme.dart';
import '../providers/notes_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/note_list_tile.dart';
import 'create_edit_note_screen.dart';
import 'note_detail_screen.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(filteredNotesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filterTag = ref.watch(filterTagProvider);
    final allTagsAsync = ref.watch(allTagsProvider);
    final allTags = allTagsAsync.valueOrNull ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Filed Notes'),
        actions: [
          if (filterTag.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              onPressed: () => ref.read(filterTagProvider.notifier).state = '',
              tooltip: 'Clear tag filter',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search notes…',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
              ),
            ),
            if (allTags.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allTags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final t = allTags[i];
                    final selected = filterTag == t;
                    return FilterChip(
                      label: Text(t),
                      selected: selected,
                      onSelected: (_) {
                        ref.read(filterTagProvider.notifier).state =
                            selected ? '' : t;
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return EmptyState(
                      message: searchQuery.isNotEmpty || filterTag.isNotEmpty
                          ? 'No notes match your search or filter.'
                          : 'No notes yet.\nCreate one to get started.',
                      actionLabel: searchQuery.isEmpty && filterTag.isEmpty
                          ? 'Create note'
                          : null,
                      onAction: searchQuery.isEmpty && filterTag.isEmpty
                          ? () => _openCreate(context)
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(filteredNotesProvider);
                    },
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: notes.length,
                      itemBuilder: (context, i) {
                        final note = notes[i];
                        return NoteListTile(
                          note: note,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  NoteDetailScreen(noteId: note.id),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const LoadingState(message: 'Loading notes…'),
                error: (e, st) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(filteredNotesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New note'),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreateEditNoteScreen(),
      ),
    );
  }
}
