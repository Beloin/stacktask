import 'package:flutter/material.dart';

enum TaskTag {
  design(label: 'Design', emoji: '🎨', colorValue: 0xFF6C5CE7),
  dev(label: 'Dev', emoji: '💻', colorValue: 0xFF0984E3),
  research(label: 'Research', emoji: '🔬', colorValue: 0xFF00B894),
  review(label: 'Review', emoji: '👀', colorValue: 0xFFFDCB6E),
  bug(label: 'Bug', emoji: '🐛', colorValue: 0xFFD63031),
  writing(label: 'Writing', emoji: '✏️', colorValue: 0xFFE17055);

  const TaskTag({
    required this.label,
    required this.emoji,
    required this.colorValue,
  });

  final String label;
  final String emoji;
  final int colorValue;

  Color get color => Color(colorValue);

  Color get backgroundColor => Color(colorValue).withValues(alpha: 0.12);

  String get displayName => '$emoji $label';

  static TaskTag fromName(String name) {
    return TaskTag.values.firstWhere(
      (tag) => tag.name == name,
      orElse: () => TaskTag.dev,
    );
  }
}