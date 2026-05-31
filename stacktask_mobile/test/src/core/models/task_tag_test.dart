import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/models/task_tag.dart';

void main() {
  group('TaskTag', () {
    test('has exactly 6 values', () {
      expect(TaskTag.values.length, 6);
    });

    test('each tag has required properties', () {
      for (final tag in TaskTag.values) {
        expect(tag.label, isNotEmpty);
        expect(tag.emoji, isNotEmpty);
        expect(tag.colorValue, isNonZero);
        expect(tag.color, isNotNull);
        expect(tag.backgroundColor, isNotNull);
      }
    });

    test('displayName combines emoji and label', () {
      expect(TaskTag.design.displayName, '🎨 Design');
      expect(TaskTag.dev.displayName, '💻 Dev');
      expect(TaskTag.bug.displayName, '🐛 Bug');
    });

    test('backgroundColor has low alpha', () {
      for (final tag in TaskTag.values) {
        final bg = tag.backgroundColor;
        expect(bg.a, lessThan(0.2));
      }
    });

    test('fromName returns correct tag', () {
      expect(TaskTag.fromName('design'), TaskTag.design);
      expect(TaskTag.fromName('dev'), TaskTag.dev);
      expect(TaskTag.fromName('research'), TaskTag.research);
      expect(TaskTag.fromName('review'), TaskTag.review);
      expect(TaskTag.fromName('bug'), TaskTag.bug);
      expect(TaskTag.fromName('writing'), TaskTag.writing);
    });

    test('fromName returns dev for unknown name', () {
      expect(TaskTag.fromName('unknown'), TaskTag.dev);
    });

    test('color matches colorValue', () {
      expect(TaskTag.design.color.toARGB32(), TaskTag.design.colorValue);
    });
  });
}