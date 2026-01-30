import '../entities/note.dart';

abstract class NotesRepository {
  Future<List<Note>> getNotes();
  Future<Note?> getNoteById(String id);
  Future<Note> createNote({required String title, required String body, List<String> tags = const []});
  Future<Note> updateNote(Note note);
  Future<void> deleteNote(String id);
  Future<List<Note>> searchByTitle(String query);
  Future<List<Note>> filterByTag(String tag);
}
