import '../enums/sync_status.dart';

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.updatedAt,
    required this.syncStatus,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? createdAt;

  Note copyWith({
    String? id,
    String? title,
    String? body,
    List<String>? tags,
    DateTime? updatedAt,
    DateTime? createdAt,
    SyncStatus? syncStatus,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
