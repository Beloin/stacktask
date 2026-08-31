import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';

void main() {
  group('TaskGroup', () {
    final now = DateTime(2025, 1, 15, 10, 30);
    final group = TaskGroup(
      id: 'g-1',
      name: 'Work',
      createdAt: now,
    );

    test('stores all fields', () {
      expect(group.id, 'g-1');
      expect(group.name, 'Work');
      expect(group.createdAt, now);
    });

    test('copyWith preserves unspecified fields', () {
      final renamed = group.copyWith(name: 'Personal');
      expect(renamed.id, group.id);
      expect(renamed.name, 'Personal');
      expect(renamed.createdAt, group.createdAt);
    });

    test('toMap and fromMap round-trip', () {
      final map = group.toMap();
      final restored = TaskGroup.fromMap(map);
      expect(restored.id, group.id);
      expect(restored.name, group.name);
      expect(restored.createdAt, group.createdAt);
    });

    test('equality works for identical groups', () {
      final same = TaskGroup(
        id: 'g-1',
        name: 'Work',
        createdAt: now,
      );
      expect(group, equals(same));
    });

    test('inequality when fields differ', () {
      final other = group.copyWith(name: 'Other');
      expect(group, isNot(equals(other)));
    });

    test('hashCode is consistent with equality', () {
      final same = TaskGroup(
        id: 'g-1',
        name: 'Work',
        createdAt: now,
      );
      expect(group.hashCode, same.hashCode);
    });

    test('toString contains id and name', () {
      expect(group.toString(), contains('g-1'));
      expect(group.toString(), contains('Work'));
    });

    test('defaultId and defaultName are stable', () {
      expect(TaskGroup.defaultId, '00000000-0000-0000-0000-000000000001');
      expect(TaskGroup.defaultName, 'Default');
    });
  });
}
