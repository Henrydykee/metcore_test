import 'package:hive_flutter/hive_flutter.dart';

import '../models/note_model.dart';

const String _notesBoxName = 'notes';

class NotesLocalDatasource {
  NotesLocalDatasource(this._box);

  final Box<NoteModel> _box;

  static Future<Box<NoteModel>> openBox() async {
    if (!Hive.isBoxOpen(_notesBoxName)) {
      return Hive.openBox<NoteModel>(_notesBoxName);
    }
    return Hive.box<NoteModel>(_notesBoxName);
  }

  List<NoteModel> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  NoteModel? getById(String id) {
    try {
      return _box.values.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> put(NoteModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> putAll(Iterable<NoteModel> models) async {
    await _box.putAll({for (var m in models) m.id: m});
  }
}
