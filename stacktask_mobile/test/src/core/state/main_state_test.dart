import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/state/main_state.dart';

void main() {
  group('MainState', () {
    test('toJson serializes group', () {
      const state = MainState(group: 'g-1');
      expect(state.toJson(), {'group': 'g-1'});
    });

    test('toJson serializes null group', () {
      const state = MainState();
      expect(state.toJson(), {'group': null});
    });

    test('fromJson reads group', () {
      final state = MainState.fromJson({'group': 'g-2'});
      expect(state.group, 'g-2');
    });

    test('fromJson handles missing group', () {
      final state = MainState.fromJson({});
      expect(state.group, isNull);
    });

    test('round-trips through json', () {
      const original = MainState(group: 'g-3');
      final restored = MainState.fromJson(original.toJson());
      expect(restored, original);
    });

    test('equality compares group', () {
      const a = MainState(group: 'x');
      const b = MainState(group: 'x');
      const c = MainState(group: 'y');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = MainState(group: 'x');
      const b = MainState(group: 'x');
      expect(a.hashCode, b.hashCode);
    });
  });
}
