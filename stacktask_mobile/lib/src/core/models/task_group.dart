class TaskGroup {
  const TaskGroup({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  static const String defaultId = '00000000-0000-0000-0000-000000000001';
  static const String defaultName = 'Default';

  final String id;
  final String name;
  final DateTime createdAt;

  TaskGroup copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return TaskGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskGroup.fromMap(Map<String, dynamic> map) {
    return TaskGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskGroup &&
          id == other.id &&
          name == other.name &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, name, createdAt);

  @override
  String toString() => 'TaskGroup(id: $id, name: $name)';
}
