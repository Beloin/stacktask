import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_tag.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_stack_controller.dart';
import 'package:stacktask_mobile/src/ui/widgets/tag_pill_widget.dart';

class CardStackWidget2 extends StatefulWidget {
  final List<TaskCard> cards;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onFrontSwipeDown;
  final void Function(int fromIndex, int toIndex)? onMoveCard;

  const CardStackWidget2({
    super.key,
    required this.cards,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onFrontSwipeDown,
    this.onMoveCard,
  });

  @override
  State<CardStackWidget2> createState() => _CardStackWidget2State();
}

class _CardStackWidget2State extends State<CardStackWidget2> {
  static const double _cardSpacing = 40.0;
  static const double _bottomPadding = 80.0;

  final CardStackController _controller = CardStackController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    final totalCards = widget.cards.length;
    final controller = _controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.88;
        final cardLeft = (constraints.maxWidth - cardWidth) / 2;
        final stackHeight = _bottomPadding + (totalCards * _cardSpacing) + 320;

        return SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = totalCards - 1; i >= 0; i--)
                Positioned(
                  bottom: _bottomPadding + i * _cardSpacing,
                  left: cardLeft,
                  child: SizedBox(
                    width: cardWidth,
                    child: i == 0
                        ? _buildFrontCard(widget.cards[0], controller)
                        : _buildBackgroundCard(widget.cards[i], i, controller),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrontCard(TaskCard card, CardStackController controller) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final target = controller.isSwipingOut
            ? controller.swipeOutTarget
            : controller.frontOffset;
        final isSelected = controller.isSelected(0);
        final isBypassed = controller.isBypassed(0);
        final selectedHasOffset =
            isSelected && controller.selectedOffset != Offset.zero;
        final opacity = isBypassed ? 0.4 : 1.0;

        return GestureDetector(
          onHorizontalDragStart: (_) => controller.onFrontDragStart(),
          onHorizontalDragUpdate: (d) => controller.onFrontDragUpdate(d.delta),
          onHorizontalDragEnd: (d) => _handleFrontDragEnd(d, controller),
          onVerticalDragStart: (_) => controller.onFrontDragStart(),
          onVerticalDragUpdate: (d) => controller.onFrontDragUpdate(d.delta),
          onVerticalDragEnd: (d) => _handleFrontDragEnd(d, controller),
          onLongPressStart: (_) => controller.select(0),
          onLongPressMoveUpdate: (d) =>
              controller.onSelectedDragUpdate(d.offsetFromOrigin),
          onLongPressEnd: (_) => _handleSelectedDragEnd(controller),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(begin: target, end: target),
            duration: controller.isSwipingOut
                ? CardStackController.swipeOutDuration
                : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, animatedOffset, child) {
              return Opacity(
                opacity: controller.isSwipingOut
                    ? 0.0
                    : isSelected
                    ? 1.0
                    : opacity,
                child: Transform.translate(
                  offset: isSelected
                      ? controller.selectedOffset
                      : animatedOffset,
                  child: Transform.scale(
                    scale: isSelected ? 1.05 : 1.0,
                    child: child,
                  ),
                ),
              );
            },
            child: _buildCardShell(
              card,
              showSelectionBorder: selectedHasOffset,
            ),
          ),
        );
      },
    );
  }

  void _handleFrontDragEnd(
    DragEndDetails details,
    CardStackController controller,
  ) {
    final result = controller.onFrontDragEnd(details.velocity.pixelsPerSecond);
    if (result == FrontDragResult.none) return;

    final direction = switch (result) {
      FrontDragResult.swipeLeft => SwipeOutDirection.left,
      FrontDragResult.swipeRight => SwipeOutDirection.right,
      FrontDragResult.swipeDown => SwipeOutDirection.down,
      FrontDragResult.none => SwipeOutDirection.none,
    };

    controller.beginSwipeOut(direction);

    Future.delayed(CardStackController.swipeOutDuration, () {
      if (!mounted) return;
      controller.completeSwipeOut();
      switch (direction) {
        case SwipeOutDirection.left:
          widget.onSwipeLeft?.call();
        case SwipeOutDirection.right:
          widget.onSwipeRight?.call();
        case SwipeOutDirection.down:
          widget.onFrontSwipeDown?.call();
        case SwipeOutDirection.none:
          break;
      }
    });
  }

  void _handleSelectedDragEnd(CardStackController controller) {
    final from = controller.selectedIndex;
    final to = controller.bypassedIndex;
    controller.onSelectedDragEnd();
    if (from != null && to != null && from != to) {
      widget.onMoveCard?.call(from, to);
    }
  }

  Widget _buildBackgroundCard(
    TaskCard card,
    int index,
    CardStackController controller,
  ) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isSelected = controller.isSelected(index);
        final isBypassed = controller.isBypassed(index);
        final selectedHasOffset =
            isSelected && controller.selectedOffset != Offset.zero;
        final opacity = isBypassed ? 0.4 : 1.0;

        return GestureDetector(
          onLongPressStart: (_) => controller.select(index),
          onLongPressMoveUpdate: (d) =>
              controller.onSelectedDragUpdate(d.offsetFromOrigin),
          onLongPressEnd: (_) => _handleSelectedDragEnd(controller),
          child: AnimatedScale(
            scale: isSelected ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Transform.translate(
              offset: isSelected ? controller.selectedOffset : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: opacity,
                child: _buildCardShell(
                  card,
                  showSelectionBorder: selectedHasOffset,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardShell(TaskCard card, {bool showSelectionBorder = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: showSelectionBorder
            ? Border.all(
                color: AppColors.accent.withValues(alpha: 0.6),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildCardBody(card),
    );
  }

  Widget _buildCardBody(TaskCard card) {
    final tag = TaskTag.fromName(card.tag);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TagPillWidget(tag: tag),
          const SizedBox(height: 14),
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (card.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              card.description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                card.timeEstimate ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              ...List.generate(4, (index) {
                final isActive = index < card.priority;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: isActive ? 8 : 6,
                    height: isActive ? 8 : 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent
                          : AppColors.textSecondary.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
