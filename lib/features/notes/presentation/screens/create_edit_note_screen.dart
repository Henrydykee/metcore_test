import 'package:filed_notes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';

class CreateEditNoteScreen extends ConsumerStatefulWidget {
  const CreateEditNoteScreen({super.key, this.note});

  final Note? note;

  @override
  ConsumerState<CreateEditNoteScreen> createState() =>
      _CreateEditNoteScreenState();
}

class _CreateEditNoteScreenState extends ConsumerState<CreateEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagsController;

  bool _isSaving = false;
  String? _saveError;

  static const int _maxTitleLength = 100;
  static const int _maxBodyLength = 50000;
  static const int _maxTags = 10;
  static const int _maxTagLength = 30;

  @override
  void initState() {
    super.initState();
    final n = widget.note;

    _titleController = TextEditingController(text: n?.title ?? '');
    _bodyController = TextEditingController(text: n?.body ?? '');
    _tagsController = TextEditingController(
      text: n?.tags.isEmpty ?? true ? '' : n!.tags.join(', '),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[\s,]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';
    final body = _bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      return 'Enter a title or some content';
    }

    if (title.length > _maxTitleLength) {
      return 'Title must be at most $_maxTitleLength characters';
    }

    return null;
  }

  String? _validateBody(String? value) {
    final body = value?.trim() ?? '';
    final title = _titleController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      return 'Enter a title or some content';
    }

    if (body.length > _maxBodyLength) {
      return 'Body must be at most $_maxBodyLength characters';
    }

    return null;
  }

  String? _validateTags(String? value) {
    final tags = _parseTags(value ?? '');

    if (tags.length > _maxTags) {
      return 'At most $_maxTags tags allowed';
    }

    final seen = <String>{};

    for (final tag in tags) {
      if (tag.length > _maxTagLength) {
        return 'Each tag must be at most $_maxTagLength characters';
      }

      final lower = tag.toLowerCase();
      if (!seen.add(lower)) {
        return 'Duplicate tags are not allowed';
      }
    }

    return null;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _saveError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(notesRepositoryProvider);

      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      final tags = _parseTags(_tagsController.text);

      if (widget.note != null) {
        await repo.updateNote(
          widget.note!.copyWith(
            title: title.isEmpty ? 'Untitled' : title,
            body: body,
            tags: tags,
          ),
        );
      } else {
        await repo.createNote(
          title: title.isEmpty ? 'Untitled' : title,
          body: body,
          tags: tags,
        );
      }

      ref.invalidate(notesListProvider);
      ref.invalidate(filteredNotesProvider);
      ref.invalidate(allTagsProvider);

      if (widget.note != null) {
        ref.invalidate(noteByIdProvider(widget.note!.id));
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveError = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.note != null ? 'Edit note' : 'New note'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isSaving && _saveError == null
          ? const LoadingState(message: 'Saving…')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_saveError != null) ...[
                      ErrorState(
                        message: _saveError!,
                        onRetry: () {
                          setState(() => _saveError = null);
                          _save();
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Note title',
                      ),
                      validator: _validateTitle,
                      maxLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        hintText: 'Write your note…',
                        alignLabelWithHint: true,
                      ),
                      validator: _validateBody,
                      maxLines: 12,
                      textCapitalization: TextCapitalization.sentences,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'work, personal, ideas',
                        prefixIcon: Icon(
                          Icons.label_outline_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      validator: _validateTags,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
