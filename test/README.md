# Unit tests – logic only, no UI

This project uses **unit tests only**. We test functions and logic, not UI (widgets, screens, or layout).

## Tests

| Test file | What it tests |
|-----------|----------------|
| `note_dto_test.dart` | NoteDto JSON, toEntity/fromEntity |
| `notes_repository_impl_test.dart` | Repository CRUD and offline fallback |
| `notes_providers_test.dart` | Riverpod providers (notes, search, filter, tags) |

## Run tests

```bash
flutter test
```

To run a single file:

```bash
flutter test test/features/notes/data/repositories/notes_repository_impl_test.dart
```
