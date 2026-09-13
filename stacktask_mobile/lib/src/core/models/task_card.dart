import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/models/task_status.dart';

class TaskCard {
  const TaskCard({
    required this.id,
    required this.title,
    required this.tag,
    this.description = '',
    this.timeEstimate,
    this.priority = 1,
    this.status = TaskStatus.doing,
    required this.createdAt,
    this.groupId = TaskGroup.defaultId,
  });

  final String id;
  final String title;
  final String tag;
  final String description;
  final String? timeEstimate;
  final int priority;
  final TaskStatus status;
  final DateTime createdAt;
  final String groupId;

  TaskCard copyWith({
    String? id,
    String? title,
    String? tag,
    String? description,
    String? timeEstimate,
    int? priority,
    TaskStatus? status,
    DateTime? createdAt,
    String? groupId,
  }) {
    return TaskCard(
      id: id ?? this.id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
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
      'status': status.name,
      'group_id': groupId,
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
      status: TaskStatus.fromName(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      groupId: (map['group_id'] as String?) ?? TaskGroup.defaultId,
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
          status == other.status &&
          groupId == other.groupId;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        tag,
        description,
        timeEstimate,
        priority,
        status,
        groupId,
      );

  @override
  String toString() =>
      'TaskCard(id: $id, title: $title, tag: $tag, status: ${status.name}, groupId: $groupId)';
}