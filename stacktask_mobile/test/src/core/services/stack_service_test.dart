import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/services/stack_service.dart';

void main() {
  group('StackService', () {
    late StackService service;

    TaskCard makeCard(String id, {String title = 'Test', String tag = 'dev'}) {
      return TaskCard(
        id: id,
        title: title,
        tag: tag,
        createdAt: DateTime(2025, 1, 1),
      );
    }

    setUp(() {
      service = StackService();
    });

    test('starts empty', () {
      expect(service.count, 0);
      expect(service.isEmpty, isTrue);
      expect(service.peek, isNull);
    });

    group('push', () {
      test('adds card to front (index 0)', () {
        final card1 = makeCard('1');
        final card2 = makeCard('2');
        service.push(card1);
        service.push(card2);
        expect(service.peek, card2);
        expect(service.all[1], card1);
      });

      test('discards oldest card when exceeding maxCards', () {
        for (int i = 0; i < StackService.maxCards + 1; i++) {
          service.push(makeCard('card-$i'));
        }
        expect(service.count, StackService.maxCards);
        expect(service.all.last.id, 'card-1');
      });
    });

    group('pop', () {
      test('removes and returns front card', () {
        final card = makeCard('1');
        service.push(card);
        final popped = service.pop();
        expect(popped, card);
        expect(service.count, 0);
      });

      test('returns null when empty', () {
        expect(service.pop(), isNull);
      });
    });

    group('removeAt', () {
      test('removes card at given index', () {
        service.push(makeCard('1'));
        service.push(makeCard('2'));
        service.push(makeCard('3'));
        service.removeAt(1);
        expect(service.count, 2);
        expect(service.all[0].id, '3');
        expect(service.all[1].id, '1');
      });

      test('does nothing for out of bounds index', () {
        service.push(makeCard('1'));
        service.removeAt(5);
        expect(service.count, 1);
        service.removeAt(-1);
        expect(service.count, 1);
      });
    });

    group('promoteToFront', () {
      test('moves card at index to front', () {
        service.push(makeCard('1'));
        service.push(makeCard('2'));
        service.push(makeCard('3'));
        service.promoteToFront(2);
        expect(service.all[0].id, '1');
        expect(service.all[1].id, '3');
        expect(service.all[2].id, '2');
      });

      test('does nothing if index is 0', () {
        service.push(makeCard('1'));
        service.push(makeCard('2'));
        service.promoteToFront(0);
        expect(service.all[0].id, '2');
      });

      test('does nothing for out of bounds index', () {
        service.push(makeCard('1'));
        service.promoteToFront(5);
        expect(service.all[0].id, '1');
      });
    });

    group('cycleFrontToEnd', () {
      test('moves front card to end', () {
        service.push(makeCard('1'));
        service.push(makeCard('2'));
        service.push(makeCard('3'));
        service.cycleFrontToEnd();
        expect(service.all[0].id, '2');
        expect(service.all[1].id, '1');
        expect(service.all[2].id, '3');
      });

      test('does nothing with 1 or fewer cards', () {
        service.push(makeCard('1'));
        service.cycleFrontToEnd();
        expect(service.count, 1);
      });
    });

    group('moveCardTo', () {
      test('moves card from one position to another', () {
        service.push(makeCard('1'));
        service.push(makeCard('2'));
        service.push(makeCard('3'));
        service.moveCardTo(0, 2);
        expect(service.all[0].id, '2');
        expect(service.all[2].id, '3');
      });

      test('moves card to front', () {
        service.push(makeCard('1'));
        service.push(makeCard('2'));
        service.push(makeCard('3'));
        service.moveCardTo(2, 0);
        expect(service.all[0].id, '1');
      });

      test('does nothing for out of bounds indices', () {
        service.push(makeCard('1'));
        service.moveCardTo(0, 5);
        expect(service.all[0].id, '1');
        service.moveCardTo(-1, 0);
        expect(service.all[0].id, '1');
      });
    });

    test('all returns unmodifiable list', () {
      service.push(makeCard('1'));
      expect(() => service.all.add(makeCard('2')), throwsUnsupportedError);
    });
  });
}