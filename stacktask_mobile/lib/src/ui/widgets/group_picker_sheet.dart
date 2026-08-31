import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';

class GroupPickerSheet extends StatelessWidget {
  final List<TaskGroup> groups;
  final String currentGroupId;
  final ValueChanged<String> onSelected;

  const GroupPickerSheet({
    super.key,
    required this.groups,
    required this.currentGroupId,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required List<TaskGroup> groups,
    required String currentGroupId,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.modalBackground,
      builder: (_) => GroupPickerSheet(
        groups: groups,
        currentGroupId: currentGroupId,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moveable = groups
        .where((g) => g.id != currentGroupId)
        .toList(growable: false);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Move to group',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          if (moveable.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Text(
                'No other groups available. Create one from the menu.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: moveable.length,
                itemBuilder: (context, i) {
                  final group = moveable[i];
                  return ListTile(
                    leading: const Icon(
                      Icons.folder_outlined,
                      color: AppColors.accentLight,
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelected(group.id);
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
