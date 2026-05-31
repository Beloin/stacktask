import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/database/change_log.dart';

void main() {
  group('ChangeLog', () {
    final now = DateTime(2025, 6, 15, 12, 0);

    test('stores all fields correctly', () {
      final log = ChangeLog(
        id: 'cl-1',
        taskId: 'task-1',
        changeType: ChangeType.insert,
        payload: '{"title":"Test"}',
        timestamp: now,
      );
      expect(log.id, 'cl-1');
      expect(log.taskId, 'task-1');
      expect(log.changeType, ChangeType.insert);
      expect(log.payload, '{"title":"Test"}');
      expect(log.timestamp, now);
    });

    test('toMap and fromMap round-trip', () {
      final log = ChangeLog(
        id: 'cl-2',
        taskId: 'task-2',
        changeType: ChangeType.reorder,
        payload: '{"from":1,"to":0}',
        timestamp: now,
      );
      final map = log.toMap();
      final restored = ChangeLog.fromMap(map);
      expect(restored.id, log.id);
      expect(restored.taskId, log.taskId);
      expect(restored.changeType, log.changeType);
      expect(restored.payload, log.payload);
    });

    test('handles null taskId', () {
      final log = ChangeLog(
        id: 'cl-3',
        taskId: null,
        changeType: ChangeType.delete,
        payload: '{}',
        timestamp: now,
      );
      final map = log.toMap();
      final restored = ChangeLog.fromMap(map);
      expect(restored.taskId, isNull);
    });

    test('all ChangeType values exist', () {
      expect(ChangeType.values, containsAll([
        ChangeType.insert,
        ChangeType.delete,
        ChangeType.reorder,
        ChangeType.update,
      ]));
    });

    test('fromMap falls back to insert for unknown change type', () {
      final map = {
        'id': 'cl-4',
        'task_id': null,
        'change_type': 'unknown_type',
        'payload': '{}',
        'timestamp': now.toIso8601String(),
      };
      final restored = ChangeLog.fromMap(map);
      expect(restored.changeType, ChangeType.insert);
    });
  });
}