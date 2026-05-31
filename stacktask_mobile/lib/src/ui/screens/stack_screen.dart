import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
import 'package:stacktask_mobile/src/ui/widgets/add_task_modal.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_stack_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/empty_state_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/fab_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/header_widget.dart';

class StackScreen extends StatefulWidget {
  final StackViewModel viewModel;

  const StackScreen({super.key, required this.viewModel});

  @override
  State<StackScreen> createState() => _StackScreenState();
}

class _StackScreenState extends State<StackScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChange);
    widget.viewModel.loadCards();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  void _onViewModelChange() {
    if (mounted) setState(() {});
  }

  void _openAddTaskModal() {
    widget.viewModel.openModal();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black54,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return AddTaskModal(
              onSubmit: ({
                required title,
                required tag,
                description = '',
                timeEstimate,
                priority = 1,
              }) {
                widget.viewModel.addCard(
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
      widget.viewModel.closeModal();
    });
  }

  void _handleCardTap(int index) {
    if (widget.viewModel.peekedIndex == index) {
      widget.viewModel.clearPeek();
    } else {
      widget.viewModel.peek(index);
    }
  }

  void _handleSwipeLeft() {
    widget.viewModel.dismissCard(SwipeDirection.left);
  }

  void _handleSwipeRight() {
    widget.viewModel.dismissCard(SwipeDirection.right);
  }

  void _handleSwipeDown() {
    widget.viewModel.cycleFrontToEnd();
  }

  void _handleMoveCard(int fromIndex, int toIndex) {
    widget.viewModel.moveCardTo(fromIndex, toIndex);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

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
                        : CardStackWidget(
                            cards: vm.cards,
                            peekedIndex: vm.peekedIndex,
                            onCardTap: _handleCardTap,
                            onSwipeLeft: _handleSwipeLeft,
                            onSwipeRight: _handleSwipeRight,
                            onFrontSwipeDown: _handleSwipeDown,
                            onMoveCard: _handleMoveCard,
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
        onTap: _openAddTaskModal,
      ),
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