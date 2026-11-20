import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/models/note.dart';

void main() {
  group('Note', () {
    final now = DateTime(2025, 1, 15, 10, 30);
    final note = Note(
      id: 'n-1',
      title: 'Meeting notes',
      description: 'Discuss launch',
      groupId: 'g-1',
      createdAt: now,
    );

    test('stores all fields', () {
      expect(note.id, 'n-1');
      expect(note.title, 'Meeting notes');
      expect(note.description, 'Discuss launch');
      expect(note.groupId, 'g-1');
      expect(note.createdAt, now);
      expect(note.position, 0);
    });

    test('description defaults to empty string', () {
      final empty = Note(
        id: 'n-2',
        title: 'No description',
        groupId: 'g-1',
        createdAt: now,
      );
      expect(empty.description, '');
    });

    test('copyWith preserves unspecified fields', () {
      final updated = note.copyWith(title: 'Updated', description: 'New');
      expect(updated.id, note.id);
      expect(updated.title, 'Updated');
      expect(updated.description, 'New');
      expect(updated.groupId, note.groupId);
      expect(updated.createdAt, note.createdAt);
    });

    test('toMap uses group_id and created_at keys', () {
      final map = note.toMap();
      expect(map['id'], 'n-1');
      expect(map['title'], 'Meeting notes');
      expect(map['description'], 'Discuss launch');
      expect(map['group_id'], 'g-1');
      expect(map['created_at'], now.toIso8601String());
      expect(map['position'], 0);
    });

    test('toMap and fromMap round-trip', () {
      final map = note.toMap();
      final restored = Note.fromMap(map);
      expect(restored, note);
    });

    test('fromMap defaults null description to empty string', () {
      final restored = Note.fromMap({
        'id': 'n-3',
        'title': 'No description',
        'description': null,
        'group_id': 'g-1',
        'created_at': now.toIso8601String(),
      });
      expect(restored.description, '');
    });

    test('equality works for identical notes', () {
      final same = Note(
        id: 'n-1',
        title: 'Meeting notes',
        description: 'Discuss launch',
        groupId: 'g-1',
        createdAt: now,
      );
      expect(note, equals(same));
    });

    test('inequality when fields differ', () {
      final other = note.copyWith(title: 'Other');
      expect(note, isNot(equals(other)));
    });

    test('hashCode is consistent with equality', () {
      final same = Note(
        id: 'n-1',
        title: 'Meeting notes',
        description: 'Discuss launch',
        groupId: 'g-1',
        createdAt: now,
      );
      expect(note.hashCode, same.hashCode);
    });

    test('toString contains id, title, and groupId', () {
      expect(note.toString(), contains('n-1'));
      expect(note.toString(), contains('Meeting notes'));
      expect(note.toString(), contains('g-1'));
    });
  });
}
