import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_stack_controller.dart';

void main() {
  group('CardStackController callbacks', () {
    test('tapCard invokes onCardTap with the index', () {
      int? tapped;
      final controller = CardStackController(onCardTap: (i) => tapped = i);
      controller.tapCard(3);
      expect(tapped, 3);
    });

    test('tapCard invokes onCardTap for any index', () {
      final tapped = <int>[];
      final controller = CardStackController(onCardTap: tapped.add);
      controller.tapCard(0);
      controller.tapCard(2);
      expect(tapped, [0, 2]);
    });

    test('onSwipeLeft receives the front index', () {
      int? swiped;
      final controller = CardStackController(onSwipeLeft: (i) => swiped = i);
      controller.onFrontDragStart(3);
      controller.onSwipeLeft?.call(controller.frontIndex!);
      expect(swiped, 3);
    });

    test('onSwipeRight receives the front index', () {
      int? swiped;
      final controller = CardStackController(onSwipeRight: (i) => swiped = i);
      controller.onFrontDragStart(1);
      controller.onSwipeRight?.call(controller.frontIndex!);
      expect(swiped, 1);
    });

    test('onSelectedDragEnd invokes onMoveCard when index changes', () {
      final moves = <List<int>>[];
      final controller =
          CardStackController(onMoveCard: (f, t) => moves.add([f, t]));
      controller.select(2);
      controller.onSelectedDragUpdate(const Offset(0, 80));
      controller.onSelectedDragEnd();
      expect(moves, [
        [2, 0],
      ]);
    });

    test('onSelectedDragEnd does not fire onMoveCard when index unchanged',
        () {
      var called = false;
      final controller =
          CardStackController(onMoveCard: (f, t) => called = true);
      controller.select(1);
      controller.onSelectedDragEnd();
      expect(called, isFalse);
    });

    test('onSelectedDragEnd does not fire onMoveCard when nothing selected',
        () {
      var called = false;
      final controller =
          CardStackController(onMoveCard: (f, t) => called = true);
      controller.onSelectedDragEnd();
      expect(called, isFalse);
    });
  });

  group('CardStackController gestures', () {
    test('onFrontDragStart/Update track offset', () {
      final controller = CardStackController();
      controller.onFrontDragStart(0);
      expect(controller.isFrontDragging, isTrue);
      expect(controller.frontIndex, 0);
      controller.onFrontDragUpdate(const Offset(10, 5));
      controller.onFrontDragUpdate(const Offset(20, 5));
      expect(controller.frontDragX, 30);
    });

    test('onFrontDragEnd returns swipeLeft for far left drag', () {
      final controller = CardStackController();
      controller.onFrontDragStart(0);
      controller.onFrontDragUpdate(const Offset(-200, 0));
      final result = controller.onFrontDragEnd(Offset.zero);
      expect(result, FrontDragResult.swipeLeft);
      expect(controller.frontIndex, 0);
    });

    test('onFrontDragEnd returns swipeRight for far right drag', () {
      final controller = CardStackController();
      controller.onFrontDragStart(0);
      controller.onFrontDragUpdate(const Offset(200, 0));
      final result = controller.onFrontDragEnd(Offset.zero);
      expect(result, FrontDragResult.swipeRight);
      expect(controller.frontIndex, 0);
    });

    test('onFrontDragEnd returns none for vertical drag', () {
      final controller = CardStackController();
      controller.onFrontDragStart(0);
      controller.onFrontDragUpdate(const Offset(0, 150));
      final result = controller.onFrontDragEnd(Offset.zero);
      expect(result, FrontDragResult.none);
    });

    test('onFrontDragEnd returns none for small drag', () {
      final controller = CardStackController();
      controller.onFrontDragStart(0);
      controller.onFrontDragUpdate(const Offset(10, 10));
      final result = controller.onFrontDragEnd(Offset.zero);
      expect(result, FrontDragResult.none);
    });

    test('onFrontDragEnd returns none while swiping out', () {
      final controller = CardStackController();
      controller.beginSwipeOut(SwipeOutDirection.left);
      final result = controller.onFrontDragEnd(Offset.zero);
      expect(result, FrontDragResult.none);
    });

    test('beginSwipeOut/completeSwipeOut cycle state', () {
      final controller = CardStackController();
      controller.beginSwipeOut(SwipeOutDirection.right);
      expect(controller.isSwipingOut, isTrue);
      expect(controller.swipeOutTarget, const Offset(600, 0));
      final dir = controller.completeSwipeOut();
      expect(dir, SwipeOutDirection.right);
      expect(controller.isSwipingOut, isFalse);
    });

    test('swipeOutTarget maps directions', () {
      final controller = CardStackController();
      controller.beginSwipeOut(SwipeOutDirection.left);
      expect(controller.swipeOutTarget, const Offset(-600, 0));
      controller.beginSwipeOut(SwipeOutDirection.right);
      expect(controller.swipeOutTarget, const Offset(600, 0));
    });

    test('select sets selected and bypassed index', () {
      final controller = CardStackController();
      controller.select(2);
      expect(controller.selectedIndex, 2);
      expect(controller.bypassedIndex, 2);
      expect(controller.isSelected(2), isTrue);
    });

    test('isBypassed reflects range between selected and bypassed', () {
      final controller = CardStackController();
      controller.select(1);
      controller.onSelectedDragUpdate(const Offset(0, 80));
      expect(controller.bypassedIndex, 0);
      expect(controller.isBypassed(0), isTrue);
      expect(controller.isBypassed(1), isTrue);
      expect(controller.isBypassed(2), isFalse);
    });

    test('reset clears all state', () {
      final controller = CardStackController();
      controller.onFrontDragStart(0);
      controller.onFrontDragUpdate(const Offset(50, 50));
      controller.select(1);
      controller.beginSwipeOut(SwipeOutDirection.left);
      controller.reset();
      expect(controller.frontIndex, isNull);
      expect(controller.frontDragX, 0);
      expect(controller.isFrontDragging, isFalse);
      expect(controller.isSwipingOut, isFalse);
      expect(controller.selectedIndex, isNull);
    });
  });
}
