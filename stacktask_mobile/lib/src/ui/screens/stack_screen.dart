import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
import 'package:stacktask_mobile/src/ui/widgets/add_task_modal.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_stack_widget2.dart';
import 'package:stacktask_mobile/src/ui/widgets/empty_state_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/fab_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/header_widget.dart';

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
    final repository = StackRepository(database: db);
    final vm = StackViewModel(repository: repository);
    await vm.loadCards();
    return vm;
  }
}

class _StackScreenBody extends StatelessWidget {
  const _StackScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            HeaderWidget(taskCount: vm.count),
            Expanded(
              child: vm.isEmpty
                  ? const EmptyStateWidget()
                  : CardStackWidget2(
                      cards: vm.cards,
                      onSwipeLeft: () => vm.dismissCard(SwipeDirection.left),
                      onSwipeRight: () => vm.dismissCard(SwipeDirection.right),
                      onFrontSwipeDown: () => vm.cycleFrontToEnd(),
                      onMoveCard: (from, to) => vm.moveCardTo(from, to),
                    ),
            ),
          ],
        );
      },
    );
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => GestureDetector(
        onTap: () => Navigator.of(modalContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black54,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return AddTaskModal(
                onSubmit:
                    ({
                      required title,
                      required tag,
                      description = '',
                      timeEstimate,
                      priority = 1,
                    }) {
                      vm.addCard(
                        title: title,
                        tag: tag,
                        description: description,
                        timeEstimate: timeEstimate,
                        priority: priority,
                      );
                    },
              );
            },
          ),
        ),
      ),
    ).whenComplete(() {
      vm.closeModal();
    });
  }
}
