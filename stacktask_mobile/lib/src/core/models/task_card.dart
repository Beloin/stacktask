class TaskCard {
  const TaskCard({
    required this.id,
    required this.title,
    required this.tag,
    this.description = '',
    this.timeEstimate,
    this.priority = 1,
    this.isDone = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String tag;
  final String description;
  final String? timeEstimate;
  final int priority;
  final bool isDone;
  final DateTime createdAt;

  TaskCard copyWith({
    String? id,
    String? title,
    String? tag,
    String? description,
    String? timeEstimate,
    int? priority,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return TaskCard(
      id: id ?? this.id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tag': tag,
      'time_estimate': timeEstimate,
      'priority': priority,
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskCard.fromMap(Map<String, dynamic> map) {
    return TaskCard(
      id: map['id'] as String,
      title: map['title'] as String,
      tag: map['tag'] as String,
      description: (map['description'] as String?) ?? '',
      timeEstimate: map['time_estimate'] as String?,
      priority: (map['priority'] as int?) ?? 1,
      isDone: ((map['is_done'] as int?) ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCard &&
          id == other.id &&
          title == other.title &&
          tag == other.tag &&
          description == other.description &&
          timeEstimate == other.timeEstimate &&
          priority == other.priority &&
          isDone == other.isDone;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        tag,
        description,
        timeEstimate,
        priority,
        isDone,
      );

  @override
  String toString() =>
      'TaskCard(id: $id, title: $title, tag: $tag, isDone: $isDone)';
}
