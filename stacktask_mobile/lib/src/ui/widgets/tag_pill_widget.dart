import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/models/task_tag.dart';

class TagPillWidget extends StatelessWidget {
  final TaskTag tag;

  const TagPillWidget({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: tag.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: tag.color,
        ),
      ),
    );
  }
}