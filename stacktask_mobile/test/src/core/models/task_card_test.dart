import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';

void main() {
  group('TaskCard', () {
    final now = DateTime(2025, 1, 15, 10, 30);
    final card = TaskCard(
      id: 'test-id-1',
      title: 'Fix login bug',
      tag: 'bug',
      description: 'Users cannot log in on iOS',
      timeEstimate: '2h',
      priority: 2,
      createdAt: now,
    );

    test('stores all fields correctly', () {
      expect(card.id, 'test-id-1');
      expect(card.title, 'Fix login bug');
      expect(card.tag, 'bug');
      expect(card.description, 'Users cannot log in on iOS');
      expect(card.timeEstimate, '2h');
      expect(card.priority, 2);
      expect(card.createdAt, now);
    });

    test('defaults optional fields', () {
      final minimal = TaskCard(
        id: 'id-2',
        title: 'Minimal',
        tag: 'dev',
        createdAt: now,
      );
      expect(minimal.description, '');
      expect(minimal.timeEstimate, isNull);
      expect(minimal.priority, 1);
    });

    test('copyWith returns new instance with updated fields', () {
      final updated = card.copyWith(title: 'Fix signup bug', priority: 3);
      expect(updated.id, card.id);
      expect(updated.title, 'Fix signup bug');
      expect(updated.priority, 3);
      expect(updated.tag, card.tag);
      expect(updated.description, card.description);
    });

    test('copyWith preserves unmodified fields', () {
      final copied = card.copyWith();
      expect(copied.id, card.id);
      expect(copied.title, card.title);
      expect(copied.priority, card.priority);
    });

    test('toMap and fromMap round-trip', () {
      final map = card.toMap();
      final restored = TaskCard.fromMap(map);
      expect(restored.id, card.id);
      expect(restored.title, card.title);
      expect(restored.tag, card.tag);
      expect(restored.description, card.description);
      expect(restored.timeEstimate, card.timeEstimate);
      expect(restored.priority, card.priority);
    });

    test('equality works for identical cards', () {
      final same = TaskCard(
        id: 'test-id-1',
        title: 'Fix login bug',
        tag: 'bug',
        createdAt: now,
      );
      expect(card, equals(same));
    });

    test('inequality for different cards', () {
      final different = card.copyWith(title: 'Different title');
      expect(card, isNot(equals(different)));
    });

    test('hashCode is consistent with equality', () {
      final same = TaskCard(
        id: 'test-id-1',
        title: 'Fix login bug',
        tag: 'bug',
        createdAt: now,
      );
      expect(card.hashCode, same.hashCode);
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'id': 'id-3',
        'title': 'Test',
        'tag': 'dev',
        'description': null,
        'time_estimate': null,
        'priority': null,
        'created_at': now.toIso8601String(),
      };
      final restored = TaskCard.fromMap(map);
      expect(restored.description, '');
      expect(restored.timeEstimate, isNull);
      expect(restored.priority, 1);
    });

    test('toString contains id and title', () {
      final str = card.toString();
      expect(str, contains('test-id-1'));
      expect(str, contains('Fix login bug'));
    });
  });
}