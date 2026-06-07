class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final List<String> tags;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.tags = const [],
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String? ?? '';
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isPinned: (map['is_pinned'] as int) == 1,
      tags: tagsStr.isEmpty ? [] : tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned ? 1 : 0,
      'tags': tags.join(','),
    };
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() => 'Note(id: $id, title: $title, isPinned: $isPinned, tags: $tags)';
}
