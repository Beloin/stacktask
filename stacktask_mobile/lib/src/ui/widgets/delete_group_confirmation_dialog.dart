import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';

class DeleteGroupConfirmationDialog extends StatelessWidget {
  final String groupName;
  final int taskCount;

  const DeleteGroupConfirmationDialog({
    super.key,
    required this.groupName,
    required this.taskCount,
  });

  static Future<bool> show(
    BuildContext context, {
    required String groupName,
    required int taskCount,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteGroupConfirmationDialog(
        groupName: groupName,
        taskCount: taskCount,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final taskWord = taskCount == 1 ? 'task' : 'tasks';
    return AlertDialog(
      backgroundColor: AppColors.modalBackground,
      title: const Text(
        'Delete group?',
        style: TextStyle(color: Colors.white),
      ),
      content: Text(
        'Delete "$groupName"? This will also delete $taskCount $taskWord. '
        'This cannot be undone.',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
