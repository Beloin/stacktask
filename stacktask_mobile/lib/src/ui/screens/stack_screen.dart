import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Consumer<StackViewModel>(
      builder: (context, vm, _) {
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
                  Column(
                    children: [
                      HeaderWidget(taskCount: vm.count),
                      Expanded(
                        child: vm.isEmpty
                            ? const EmptyStateWidget()
                            : CardStackWidget2(
                                cards: vm.cards,
                                peekedIndex: vm.peekedIndex,
                                onCardTap: (index) {
                                  if (vm.peekedIndex == index) {
                                    vm.clearPeek();
                                  } else {
                                    vm.peek(index);
                                  }
                                },
                                onSwipeLeft: () =>
                                    vm.dismissCard(SwipeDirection.left),
                                onSwipeRight: () =>
                                    vm.dismissCard(SwipeDirection.right),
                                onFrontSwipeDown: () => vm.cycleFrontToEnd(),
                                onMoveCard: (from, to) =>
                                    vm.moveCardTo(from, to),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FabWidget(
            isOpen: vm.isModalOpen,
            onTap: () => _openAddTaskModal(context, vm),
          ),
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
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.black54),
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
    ).whenComplete(() {
      vm.closeModal();
    });
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

