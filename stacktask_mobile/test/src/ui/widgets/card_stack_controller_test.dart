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

    test('tapCard invokes onCardTap for any index when no detailed view', () {
      final tapped = <int>[];
      final controller = CardStackController(onCardTap: tapped.add);
      controller.tapCard(0);
      controller.tapCard(2);
      expect(tapped, [0, 2]);
    });

    test('tapCard only fires for the detailed card when in detailed view', () {
      final tapped = <int>[];
      final controller = CardStackController(onCardTap: tapped.add);
      controller.setDetailedView(1);
      controller.tapCard(0);
      controller.tapCard(1);
      controller.tapCard(2);
      expect(tapped, [1]);
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

  group('CardStackController detailed view', () {
    test('starts without detailed view', () {
      final controller = CardStackController();
      expect(controller.hasDetailedView, isFalse);
      expect(controller.detailedViewIndex, isNull);
    });

    test('setDetailedView sets and notifies', () {
      final controller = CardStackController();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setDetailedView(2);
      expect(controller.detailedViewIndex, 2);
      expect(controller.hasDetailedView, isTrue);
      expect(controller.isDetailedView(2), isTrue);
      expect(controller.isDetailedView(1), isFalse);
      expect(notified, isTrue);
    });

    test('setDetailedView with same index does not notify', () {
      final controller = CardStackController();
      controller.setDetailedView(1);
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setDetailedView(1);
      expect(notified, isFalse);
    });

    test('clearDetailedView resets state', () {
      final controller = CardStackController();
      controller.setDetailedView(1);
      controller.clearDetailedView();
      expect(controller.hasDetailedView, isFalse);
      expect(controller.detailedViewIndex, isNull);
    });

    test('select is blocked while in detailed view', () {
      final controller = CardStackController();
      controller.setDetailedView(1);
      controller.select(0);
      expect(controller.selectedIndex, isNull);
    });

    test('onFrontDragStart is blocked while in detailed view', () {
      final controller = CardStackController();
      controller.setDetailedView(1);
      controller.onFrontDragStart();
      expect(controller.isFrontDragging, isFalse);
    });
  });

  group('CardStackController gestures', () {
    test('onFrontDragStart/Update track offset', () {
      final controller = CardStackController();
      controller.onFrontDragStart();
      expect(controller.isFrontDragging, isTrue);
      controller.onFrontDragUpdate(const Offset(10, 5));
      controller.onFrontDragUpdate(const Offset(20, 5));
      expect(controller.frontDragX, 30);
      expect(controller.frontDragY, 10);
    });

    test('onFrontDragEnd returns swipeLeft for far left drag', () {
      final controller = CardStackController();
      controller.onFrontDragStart();
      controller.onFrontDragUpdate(const Offset(-200, 0));
      final result = controller.onFrontDragEnd(Offset.zero);
      expect(result, FrontDragResult.swipeLeft);
    });

    test('onFrontDragEnd returns swipeRight for far right drag', () {
      final controller = CardStackController();
      controller.onFrontDragStart();
      controller.onFrontDragUpdate(const Offset(200, 0));
      final result = controller.onFrontDragEnd(Offset.zero);
      expect(result, FrontDragResult.swipeRight);
    });

    test('onFrontDragEnd returns swipeDown for far down drag', () {
      final controller = CardStackController();
      controller.onFrontDragStart();
      controller.onFrontDragUpdate(const Offset(0, 150));
      final result = controller.onFrontDragEnd(Offset.zero);
      expect(result, FrontDragResult.swipeDown);
    });

    test('onFrontDragEnd returns none for small drag', () {
      final controller = CardStackController();
      controller.onFrontDragStart();
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
      controller.beginSwipeOut(SwipeOutDirection.down);
      expect(controller.swipeOutTarget, const Offset(0, 600));
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
      controller.onFrontDragStart();
      controller.onFrontDragUpdate(const Offset(50, 50));
      controller.select(1);
      controller.setDetailedView(2);
      controller.beginSwipeOut(SwipeOutDirection.left);
      controller.reset();
      expect(controller.frontDragX, 0);
      expect(controller.frontDragY, 0);
      expect(controller.isFrontDragging, isFalse);
      expect(controller.isSwipingOut, isFalse);
      expect(controller.selectedIndex, isNull);
      expect(controller.detailedViewIndex, isNull);
    });
  });
}
