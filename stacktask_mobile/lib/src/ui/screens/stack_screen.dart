import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/repositories/group_repository.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
import 'package:stacktask_mobile/src/ui/screens/add_task_screen.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_stack_widget2.dart';
import 'package:stacktask_mobile/src/ui/widgets/delete_group_confirmation_dialog.dart';
import 'package:stacktask_mobile/src/ui/widgets/empty_state_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/fab_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/group_actions_sheet.dart';
import 'package:stacktask_mobile/src/ui/widgets/group_picker_sheet.dart';
import 'package:stacktask_mobile/src/ui/widgets/group_tab_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/header_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/new_group_sheet.dart';
import 'package:stacktask_mobile/src/ui/widgets/task_detail_modal.dart';

class StackScreen extends StatelessWidget {
  const StackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StackViewModel>(
      future: _createViewModel(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ChangeNotifierProvider.value(
          value: snapshot.data!,
          child: const _StackScreenBody(),
        );
      },
    );
  }

  Future<StackViewModel> _createViewModel() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    final stackRepository = StackRepository(database: db);
    final groupRepository = GroupRepository(
      database: db,
      stackRepository: stackRepository,
    );
    final vm = StackViewModel(
      repository: stackRepository,
      groupRepository: groupRepository,
    );
    await vm.bootstrap();
    return vm;
  }
}

class _StackScreenBody extends StatelessWidget {
  const _StackScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _GroupsDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background1,
              AppColors.background2,
              AppColors.background3,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      _buildAmbientOrb(
                        alignment: Alignment.topLeft,
                        color: AppColors.accent,
                        size: 200,
                      ),
                      _buildAmbientOrb(
                        alignment: Alignment.bottomRight,
                        color: AppColors.tagPillPink,
                        size: 180,
                      ),
                      _buildAmbientOrb(
                        alignment: Alignment.bottomLeft,
                        color: AppColors.tagPillTeal,
                        size: 160,
                      ),
                    ],
                  ),
                ),
              ),
              const _CardArea(),
              const Align(
                alignment: Alignment(-1.0, -0.5),
                child: Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: _DrawerHandle(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const _FabArea(),
    );
  }

  Widget _buildAmbientOrb({
    required AlignmentGeometry alignment,
    required Color color,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _CardArea extends StatelessWidget {
  const _CardArea();

  @override
  Widget build(BuildContext context) {
    return Consumer<StackViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            HeaderWidget(
              groupName: vm.selectedGroupName,
              taskCount: vm.count,
            ),
            Expanded(
              child: vm.isEmpty
                  ? const EmptyStateWidget()
                  : CardStackWidget2(
                      cards: vm.cards,
                      onCardTap: (i) => _openTaskDetailModal(context, vm, i),
                      onSwipeLeft: () => vm.removeCardAt(0),
                      onSwipeRight: () => vm.markCardAsDone(0),
                      onFrontSwipeDown: () => vm.cycleFrontToEnd(),
                      onMoveCard: (from, to) => vm.moveCardTo(from, to),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _openTaskDetailModal(
    BuildContext context,
    StackViewModel vm,
    int index,
  ) {
    final card = vm.cards[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => ChangeNotifierProvider.value(
        value: vm,
        child: _TaskDetailSheet(
          card: card,
          cardIndex: index,
        ),
      ),
    );
  }
}

class _TaskDetailSheet extends StatelessWidget {
  final TaskCard card;
  final int cardIndex;

  const _TaskDetailSheet({required this.card, required this.cardIndex});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black54,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return TaskDetailModal(
              card: card,
              onDismiss: () => Navigator.of(context).pop(),
              onDelete: () {
                Navigator.of(context).pop();
                context.read<StackViewModel>().removeCardAt(cardIndex);
              },
              onEdit: () {
                Navigator.of(context).pop();
                _openEditTaskModal(context, cardIndex);
              },
              onMove: () {
                final vm = context.read<StackViewModel>();
                GroupPickerSheet.show(
                  context,
                  groups: vm.groups,
                  currentGroupId: card.groupId,
                  onSelected: (groupId) async {
                    final moved = await vm.moveCardToGroup(card.id, groupId);
                    if (moved && context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openEditTaskModal(BuildContext context, int index) {
    final vm = context.read<StackViewModel>();
    final currentCard = vm.cards[index];
    vm.openModal();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AddTaskScreen(vm: vm, editing: currentCard),
          ),
        )
        .whenComplete(() {
          vm.closeModal();
        });
  }
}

class _FabArea extends StatelessWidget {
  const _FabArea();

  @override
  Widget build(BuildContext context) {
    return Consumer<StackViewModel>(
      builder: (context, vm, _) {
        return FabWidget(
          isOpen: vm.isModalOpen,
          onTap: () => _openAddTaskModal(context, vm),
        );
      },
    );
  }

  void _openAddTaskModal(BuildContext context, StackViewModel vm) {
    vm.openModal();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AddTaskScreen(vm: vm),
          ),
        )
        .whenComplete(() {
          vm.closeModal();
        });
  }
}

class _GroupsDrawer extends StatelessWidget {
  const _GroupsDrawer();

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
                        isActive: group.id == vm.selectedGroupId,
                        onTap: () {
                          vm.selectGroup(group.id);
                          Navigator.of(context).pop();
                        },
                        onLongPress: () => _showActions(context, vm, group),
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),
                InkWell(
                  onTap: () => _showNewGroup(context, vm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: const [
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

class _DrawerHandle extends StatelessWidget {
  const _DrawerHandle();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Scaffold.of(context).openDrawer(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.menu_rounded,
            color: AppColors.textWhite,
            size: 22,
          ),
        ),
      ),
    );
  }
}
