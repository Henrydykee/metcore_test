import '../../domain/entities/note.dart';
import '../../domain/enums/sync_status.dart';

class NoteDto {
  NoteDto({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NoteDto.fromJson(Map<String, dynamic> json) {
    return NoteDto(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Note toEntity() {
    return Note(
      id: id,
      title: title,
      body: body,
      tags: List.from(tags),
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
    );
  }

  factory NoteDto.fromEntity(Note note) {
    return NoteDto(
      id: note.id,
      title: note.title,
      body: note.body,
      tags: List.from(note.tags),
      createdAt: note.createdAt ?? note.updatedAt,
      updatedAt: note.updatedAt,
    );
  }

  Map<String, dynamic> toCreateRequest() {
    return {
      'title': title,
      'body': body,
      'tags': tags,
    };
  }

  Map<String, dynamic> toUpdateRequest() {
    return {
      'title': title,
      'body': body,
      'tags': tags,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
