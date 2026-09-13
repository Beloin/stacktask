import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_status.dart';
import 'package:stacktask_mobile/src/core/repositories/group_repository.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/state/main_state.dart';
import 'package:stacktask_mobile/src/core/state/state_service.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
import 'package:stacktask_mobile/src/ui/screens/add_task_screen.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_stack_widget2.dart';
import 'package:stacktask_mobile/src/ui/widgets/empty_state_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/fab_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/group_picker_sheet.dart';
import 'package:stacktask_mobile/src/ui/widgets/groups_drawer.dart';
import 'package:stacktask_mobile/src/ui/widgets/header_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/task_detail_modal.dart';

class StackScreen extends StatelessWidget {
  final StateService stateService;

  const StackScreen({super.key, required this.stateService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StackViewModel>(
      future: _createViewModel(stateService),
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

  Future<StackViewModel> _createViewModel(StateService stateService) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    final stackRepository = StackRepository(database: db);
    final groupRepository = GroupRepository(
      database: db,
      stackRepository: stackRepository,
    );
    final initialGroupId = stateService.get<MainState>()?.group;
    final vm = StackViewModel(
      repository: stackRepository,
      groupRepository: groupRepository,
      stateService: stateService,
      initialSelectedGroupId: initialGroupId,
    );
    await vm.bootstrap();
    return vm;
  }
}

class _StackScreenBody extends StatelessWidget {
  const _StackScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<StackViewModel>(
      builder: (context, vm, _) {
        final isArchive = vm.isArchiveMode;
        final isDone = vm.archiveStatus == TaskStatus.done;
        final colors = isArchive
            ? (isDone
                ? const [
                    AppColors.doneBackground1,
                    AppColors.doneBackground2,
                    AppColors.doneBackground3,
                  ]
                : const [
                    AppColors.ignoredBackground1,
                    AppColors.ignoredBackground2,
                    AppColors.ignoredBackground3,
                  ])
            : const [
                AppColors.background1,
                AppColors.background2,
                AppColors.background3,
              ];

        return Scaffold(
          resizeToAvoidBottomInset: false,
          drawer: const GroupsDrawer(),
          floatingActionButton:
              isArchive ? const SizedBox.shrink() : const _FabArea(),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _buildAmbientOrbs(isArchive: isArchive),
                    ),
                  ),
                  _CardArea(isArchive: isArchive),
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
        );
      },
    );
  }

  Widget _buildAmbientOrbs({required bool isArchive}) {
    return Stack(
      children: [
        _buildAmbientOrb(
          alignment: Alignment.topLeft,
          color: AppColors.accent,
          size: 200,
          opacity: isArchive ? 0.04 : 0.12,
        ),
        _buildAmbientOrb(
          alignment: Alignment.bottomRight,
          color: AppColors.tagPillPink,
          size: 180,
          opacity: isArchive ? 0.04 : 0.12,
        ),
        _buildAmbientOrb(
          alignment: Alignment.bottomLeft,
          color: AppColors.tagPillTeal,
          size: 160,
          opacity: isArchive ? 0.04 : 0.12,
        ),
      ],
    );
  }

  Widget _buildAmbientOrb({
    required Alignment alignment,
    required Color color,
    required double size,
    required double opacity,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _CardArea extends StatelessWidget {
  final bool isArchive;

  const _CardArea({required this.isArchive});

  @override
  Widget build(BuildContext context) {
    return Consumer<StackViewModel>(
      builder: (context, vm, _) {
        final cards = isArchive ? vm.archivedCards : vm.cards;
        return Column(
          children: [
            HeaderWidget(
              groupName: vm.selectedGroupName,
              taskCount: isArchive
                  ? (vm.archiveStatus == TaskStatus.done
                      ? vm.doneCount
                      : vm.ignoredCount)
                  : vm.count,
            ),
            if (isArchive)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: _ArchiveSearchField(
                  onChanged: vm.updateArchiveSearch,
                ),
              ),
            Expanded(
              child: cards.isEmpty
                  ? const EmptyStateWidget()
                  : isArchive
                      ? CardStackWidget2(
                          cards: cards,
                          readOnly: true,
                          inverted: true,
                          showDescriptionOnFirstCard: false,
                          onCardTap: (i) =>
                              _openArchiveDetailModal(context, vm, i),
                        )
                      : CardStackWidget2(
                          cards: cards,
                          onCardTap: (i) => _openTaskDetailModal(context, vm, i),
                          onSwipeLeft: () => vm.ignoreCardAt(0),
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

  void _openArchiveDetailModal(
    BuildContext context,
    StackViewModel vm,
    int index,
  ) {
    final card = vm.archivedCards[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => ChangeNotifierProvider.value(
        value: vm,
        child: _TaskDetailSheet(
          card: card,
          cardIndex: index,
          readOnly: true,
        ),
      ),
    );
  }
}

class _ArchiveSearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const _ArchiveSearchField({required this.onChanged});

  @override
  State<_ArchiveSearchField> createState() => _ArchiveSearchFieldState();
}

class _ArchiveSearchFieldState extends State<_ArchiveSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: const TextStyle(
        color: AppColors.textWhite,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Search cards',
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 15,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.accentLight.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _TaskDetailSheet extends StatelessWidget {
  final TaskCard card;
  final int cardIndex;
  final bool readOnly;

  const _TaskDetailSheet({
    required this.card,
    required this.cardIndex,
    this.readOnly = false,
  });

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
              onDelete: readOnly
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.read<StackViewModel>().removeCardAt(cardIndex);
                    },
              onEdit: readOnly
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _openEditTaskModal(context, cardIndex);
                    },
              onMove: readOnly
                  ? null
                  : () {
                      final vm = context.read<StackViewModel>();
                      GroupPickerSheet.show(
                        context,
                        groups: vm.groups,
                        currentGroupId: card.groupId,
                        onSelected: (groupId) async {
                          final moved =
                              await vm.moveCardToGroup(card.id, groupId);
                          if (moved && context.mounted) {
                            Navigator.of(context).pop();
                          }
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