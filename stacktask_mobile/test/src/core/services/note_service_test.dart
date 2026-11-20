import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/models/note.dart';
import 'package:stacktask_mobile/src/core/services/note_service.dart';

void main() {
  group('NoteService', () {
    late NoteService service;

    Note makeNote(String id, {String title = 'Note'}) {
      return Note(
        id: id,
        title: title,
        groupId: 'g-1',
        createdAt: DateTime(2025, 1, 1),
      );
    }

    setUp(() {
      service = NoteService();
    });

    test('starts empty', () {
      expect(service.count, 0);
      expect(service.isEmpty, isTrue);
      expect(service.all, isEmpty);
    });

    test('add inserts at index 0 (newest first)', () {
      service.add(makeNote('1', title: 'First'));
      service.add(makeNote('2', title: 'Second'));
      expect(service.count, 2);
      expect(service.all.first.id, '2');
      expect(service.all.last.id, '1');
    });

    test('all is unmodifiable', () {
      service.add(makeNote('1'));
      expect(() => service.all.add(makeNote('2')), throwsUnsupportedError);
    });

    test('byId returns the matching note', () {
      service.add(makeNote('1', title: 'First'));
      expect(service.byId('1')?.title, 'First');
      expect(service.byId('missing'), isNull);
    });

    test('replaceAll replaces the entire list', () {
      service.add(makeNote('1'));
      service.replaceAll([makeNote('2'), makeNote('3')]);
      expect(service.count, 2);
      expect(service.byId('1'), isNull);
      expect(service.byId('2'), isNotNull);
      expect(service.byId('3'), isNotNull);
    });

    test('update replaces note with the same id', () {
      service.add(makeNote('1', title: 'Before'));
      service.update(makeNote('1', title: 'After'));
      expect(service.byId('1')?.title, 'After');
    });

    test('update ignores unknown id', () {
      service.add(makeNote('1'));
      service.update(makeNote('missing', title: 'Ghost'));
      expect(service.count, 1);
      expect(service.byId('1')?.title, 'Note');
    });

    test('moveTo reorders notes', () {
      service.add(makeNote('1', title: 'First'));
      service.add(makeNote('2', title: 'Second'));
      service.add(makeNote('3', title: 'Third'));
      service.moveTo(0, 2);
      expect(service.all.map((n) => n.id).toList(), ['2', '1', '3']);
    });

    test('remove deletes note by id', () {
      service.add(makeNote('1'));
      service.add(makeNote('2'));
      service.remove('1');
      expect(service.count, 1);
      expect(service.byId('1'), isNull);
      expect(service.byId('2'), isNotNull);
    });

    test('clear empties the list', () {
      service.add(makeNote('1'));
      service.add(makeNote('2'));
      service.clear();
      expect(service.count, 0);
      expect(service.isEmpty, isTrue);
    });
  });
}
