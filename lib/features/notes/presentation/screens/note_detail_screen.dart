import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/note.dart';
import '../../domain/enums/sync_status.dart';
import '../providers/notes_providers.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import 'create_edit_note_screen.dart';

class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          if (noteAsync.valueOrNull != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                final note = noteAsync.valueOrNull!;
                if (v == 'edit') _openEdit(context, note);
                if (v == 'delete') _confirmDelete(context, ref, noteId);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: noteAsync.when(
        data: (note) {
          if (note == null) {
            return const ErrorState(
              message: 'Note not found.',
            );
          }
          return _NoteContent(note: note);
        },
        loading: () => const LoadingState(message: 'Loading note...'),
        error: (e, st) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(noteByIdProvider(noteId)),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateEditNoteScreen(note: note),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'This note will be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(notesRepositoryProvider).deleteNote(id);
    ref.invalidate(notesListProvider);
    ref.invalidate(filteredNotesProvider);
    ref.invalidate(noteByIdProvider(id));
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _NoteContent extends StatelessWidget {
  const _NoteContent({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SyncStatusChip(status: note.syncStatus),
              const SizedBox(width: 12),
              Text(
                DateFormat.yMMMd().add_Hm().format(note.updatedAt),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            note.title.isEmpty ? '(No title)' : note.title,
            style: theme.textTheme.headlineSmall,
          ),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: note.tags
                  .map((t) => Chip(label: Text(t)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            note.body.isEmpty ? '(No body)' : note.body,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case SyncStatus.synced:
        color = Colors.green;
        label = 'Synced';
        break;
      case SyncStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case SyncStatus.failed:
        color = Colors.red;
        label = 'Failed';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}
