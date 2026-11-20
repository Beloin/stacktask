class Note {
  const Note({
    required this.id,
    required this.title,
    this.description = '',
    required this.groupId,
    required this.createdAt,
    this.position = 0,
  });

  final String id;
  final String title;
  final String description;
  final String groupId;
  final DateTime createdAt;
  final int position;

  Note copyWith({
    String? id,
    String? title,
    String? description,
    String? groupId,
    DateTime? createdAt,
    int? position,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
      'position': position,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      groupId: map['group_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      position: (map['position'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          groupId == other.groupId &&
          createdAt == other.createdAt &&
          position == other.position;

  @override
  int get hashCode =>
      Object.hash(id, title, description, groupId, createdAt, position);

  @override
  String toString() =>
      'Note(id: $id, title: $title, groupId: $groupId, position: $position)';
}
