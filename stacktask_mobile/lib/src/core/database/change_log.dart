class ChangeLog {
  const ChangeLog({
    required this.id,
    required this.taskId,
    required this.changeType,
    required this.payload,
    required this.timestamp,
  });

  final String id;
  final String? taskId;
  final ChangeType changeType;
  final String payload;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'change_type': changeType.name,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChangeLog.fromMap(Map<String, dynamic> map) {
    return ChangeLog(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      changeType: ChangeType.values.firstWhere(
        (e) => e.name == map['change_type'],
        orElse: () => ChangeType.insert,
      ),
      payload: map['payload'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

enum ChangeType { insert, delete, reorder, update }