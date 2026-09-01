import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_scroll_picker.dart';

void main() {
  Future<void> pumpPicker(
    WidgetTester tester, {
    required int cardCount,
    required ValueChanged<int?> onIndexChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 40,
              height: 300,
              child: CardScrollPicker(
                cardCount: cardCount,
                onIndexChanged: onIndexChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Rect rect(WidgetTester tester) =>
      tester.getRect(find.byType(CardScrollPicker));

  testWidgets('maps bottom box to index 0', (tester) async {
    final emitted = <int?>[];
    await pumpPicker(tester, cardCount: 3, onIndexChanged: emitted.add);

    final r = rect(tester);
    await tester.tapAt(Offset(r.center.dx, r.bottom - 10));
    await tester.pump();

    expect(emitted.first, 0);
  });

  testWidgets('maps top box to last index', (tester) async {
    final emitted = <int?>[];
    await pumpPicker(tester, cardCount: 3, onIndexChanged: emitted.add);

    final r = rect(tester);
    await tester.tapAt(Offset(r.center.dx, r.top + 10));
    await tester.pump();

    expect(emitted.first, 2);
  });

  testWidgets('maps middle box to middle index', (tester) async {
    final emitted = <int?>[];
    await pumpPicker(tester, cardCount: 3, onIndexChanged: emitted.add);

    final r = rect(tester);
    await tester.tapAt(Offset(r.center.dx, r.center.dy));
    await tester.pump();

    expect(emitted.first, 1);
  });

  testWidgets('emits null on release', (tester) async {
    final emitted = <int?>[];
    await pumpPicker(tester, cardCount: 3, onIndexChanged: emitted.add);

    final r = rect(tester);
    final gesture = await tester.startGesture(r.center);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(emitted.last, isNull);
  });

  testWidgets('emits index on drag move', (tester) async {
    final emitted = <int?>[];
    await pumpPicker(tester, cardCount: 4, onIndexChanged: emitted.add);

    final r = rect(tester);
    final gesture = await tester.startGesture(Offset(r.center.dx, r.bottom - 10));
    await tester.pump();
    await gesture.moveTo(Offset(r.center.dx, r.top + 10));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(emitted, contains(3));
  });

  testWidgets('renders nothing for zero cards', (tester) async {
    await pumpPicker(tester, cardCount: 0, onIndexChanged: (_) {});
    expect(find.byType(CardScrollPicker), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
  });
}
