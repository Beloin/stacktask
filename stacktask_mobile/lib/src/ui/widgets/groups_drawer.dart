import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/models/task_status.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
import 'package:stacktask_mobile/src/ui/widgets/delete_group_confirmation_dialog.dart';
import 'package:stacktask_mobile/src/ui/widgets/group_actions_sheet.dart';
import 'package:stacktask_mobile/src/ui/widgets/group_tab_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/new_group_sheet.dart';

class GroupsDrawer extends StatelessWidget {
  const GroupsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background1,
      child: SafeArea(
        child: Consumer<StackViewModel>(
          builder: (context, vm, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text(
                    'GROUPS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 2.5,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: vm.groups.length,
                    itemBuilder: (context, i) {
                      final group = vm.groups[i];
                      final count = vm.groupTaskCounts[group.id] ?? 0;
                      return _DrawerGroupRow(
                        group: group,
                        taskCount: count,
                        isActive:
                            !vm.isArchiveMode && group.id == vm.selectedGroupId,
                        onTap: () {
                          vm.selectGroup(group.id);
                          Navigator.of(context).pop();
                        },
                        onLongPress: () => _showActions(context, vm, group),
                      );
                    },
                  ),
                ),
                _StatusGroupsRow(
                  doneCount: vm.doneCount,
                  ignoredCount: vm.ignoredCount,
                  activeStatus: vm.isArchiveMode ? vm.archiveStatus : null,
                  onSelected: (status) {
                    vm.openArchive(status);
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(height: 1, color: Colors.white12),
                InkWell(
                  onTap: () => _showNewGroup(context, vm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: AppColors.accentLight),
                        SizedBox(width: 12),
                        Text(
                          'New Group',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showActions(
    BuildContext context,
    StackViewModel vm,
    TaskGroup group,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.modalBackground,
      builder: (_) => GroupActionsSheet(
        canDelete: group.id != TaskGroup.defaultId,
        onRename: (name) => vm.renameGroup(group.id, name),
        onDelete: () async {
          final confirmed = await DeleteGroupConfirmationDialog.show(
            context,
            groupName: group.name,
            taskCount: vm.groupTaskCounts[group.id] ?? 0,
          );
          if (!confirmed) return;
          await vm.deleteGroupCascade(group.id);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showNewGroup(BuildContext context, StackViewModel vm) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.modalBackground,
      builder: (modalContext) => ChangeNotifierProvider.value(
        value: vm,
        child: NewGroupSheet(
          errorMessage: vm.hasError ? vm.lastError?.message : null,
          onSubmit: (name) {
            vm.clearError();
            vm.addGroup(name);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _StatusGroupsRow extends StatelessWidget {
  static const double _rowHeight = 56.0;
  static const double _rowSpacing = 10.0;
  static const double _edgePadding = 12.0;

  final int doneCount;
  final int ignoredCount;
  final TaskStatus? activeStatus;
  final ValueChanged<TaskStatus> onSelected;

  const _StatusGroupsRow({
    required this.doneCount,
    required this.ignoredCount,
    required this.activeStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _edgePadding,
        _rowSpacing,
        _edgePadding,
        _rowSpacing,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusGroupButton(
              label: 'DONE',
              count: doneCount,
              color: AppColors.doneGreen,
              activeColor: AppColors.doneGreenLight,
              isActive: activeStatus == TaskStatus.done,
              onTap: () => onSelected(TaskStatus.done),
            ),
          ),
          const SizedBox(width: _rowSpacing),
          Expanded(
            child: _StatusGroupButton(
              label: 'IGNORED',
              count: ignoredCount,
              color: AppColors.ignoredRed,
              activeColor: AppColors.ignoredRedLight,
              isActive: activeStatus == TaskStatus.ignored,
              onTap: () => onSelected(TaskStatus.ignored),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGroupButton extends StatelessWidget {
  static const double _buttonHeight = _StatusGroupsRow._rowHeight;

  final String label;
  final int count;
  final Color color;
  final Color activeColor;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusGroupButton({
    required this.label,
    required this.count,
    required this.color,
    required this.activeColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isActive ? color : color.withValues(alpha: 0.55);
    final borderColor =
        isActive ? Border.all(color: activeColor, width: 2) : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: borderColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerGroupRow extends StatelessWidget {
  final TaskGroup group;
  final int taskCount;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DrawerGroupRow({
    required this.group,
    required this.taskCount,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: GroupTabWidget(
        name: group.name,
        taskCount: taskCount,
        isActive: isActive,
        onTap: onTap,
      ),
    );
  }
}