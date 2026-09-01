import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_tag.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_scroll_picker.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_stack_controller.dart';
import 'package:stacktask_mobile/src/ui/widgets/tag_pill_widget.dart';

class CardStackWidget2 extends StatefulWidget {
  final List<TaskCard> cards;
  final ValueChanged<int>? onCardTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onFrontSwipeDown;
  final void Function(int fromIndex, int toIndex)? onMoveCard;

  const CardStackWidget2({
    super.key,
    required this.cards,
    this.onCardTap,
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
  static const double _swipeAffordanceReach = 120.0;
  static const double _defaultCardHeight = 320.0;
  static const double _liftFraction = 0.15;

  late final CardStackController _controller;

  final GlobalKey _frontMeasureKey = GlobalKey();
  double _cardHeight = _defaultCardHeight;
  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller = CardStackController(
      onCardTap: widget.onCardTap,
      onSwipeLeft: widget.onSwipeLeft,
      onSwipeRight: widget.onSwipeRight,
      onFrontSwipeDown: widget.onFrontSwipeDown,
      onMoveCard: widget.onMoveCard,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        _screenHeight = constraints.maxHeight;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _measureCard());

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _controller.clearDetailedView(),
                child: _buildCardsLayer(constraints),
              ),
            ),
            Positioned(
              top: constraints.maxHeight / 6,
              bottom: constraints.maxHeight / 6,
              right: 0,
              width: 40,
              child: CardScrollPicker(
                cardCount: widget.cards.length,
                onIndexChanged: (index) {
                  if (index == null) {
                    _controller.clearDetailedView();
                  } else {
                    _controller.setDetailedView(index);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _measureCard() {
    final render = _frontMeasureKey.currentContext?.findRenderObject();
    if (render is RenderBox && render.hasSize) {
      final h = render.size.height;
      if (h > 0 && (h - _cardHeight).abs() > 0.5) {
        setState(() => _cardHeight = h);
      }
    }
  }

  Widget _buildCardsLayer(BoxConstraints constraints) {
    final totalCards = widget.cards.length;
    final cardWidth = constraints.maxWidth * 0.88;
    final cardLeft = (constraints.maxWidth - cardWidth) / 2;
    final frontCardTop =
        constraints.maxHeight - _bottomPadding - _cardHeight;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (int i = totalCards - 1; i >= 0; i--)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            top: frontCardTop - i * _cardSpacing,
            left: cardLeft,
            child: SizedBox(
              width: cardWidth,
              child: _buildCard(
                widget.cards[i],
                i,
                constraints.maxWidth,
              ),
            ),
          ),
      ],
    );
  }

  double _opacityFor(int index, int? detailedIndex) {
    if (detailedIndex == null) return 1.0;
    if (index == detailedIndex) return 1.0;
    if (index == detailedIndex + 1) return 1.0;
    return 0.35;
  }

  Widget _buildCard(TaskCard card, int index, double areaWidth) {
    final isFront = index == 0;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isDetailed = _controller.isDetailedView(index);
        final isExpanded = isFront || isDetailed;
        final liftY =
            isDetailed && !isFront ? _screenHeight * _liftFraction : 0.0;
        final isSelected = _controller.isSelected(index);
        final isBypassed = _controller.isBypassed(index);
        final selectedHasOffset =
            isSelected && _controller.selectedOffset != Offset.zero;
        final opacity = isBypassed
            ? 0.4
            : _opacityFor(index, _controller.detailedViewIndex);
        final dragX = _controller.frontDragX;
        final isDraggingHorizontally =
            _controller.isFrontDragging && dragX.abs() > 4;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _controller.tapCard(index),
          onHorizontalDragStart: isFront && !isDetailed
              ? (_) => _controller.onFrontDragStart()
              : null,
          onHorizontalDragUpdate: isFront && !isDetailed
              ? (d) => _controller.onFrontDragUpdate(d.delta)
              : null,
          onHorizontalDragEnd: isFront && !isDetailed
              ? (d) => _handleFrontDragEnd(d)
              : null,
          onVerticalDragStart: isFront && !isDetailed
              ? (_) => _controller.onFrontDragStart()
              : null,
          onVerticalDragUpdate: isFront && !isDetailed
              ? (d) => _controller.onFrontDragUpdate(d.delta)
              : null,
          onVerticalDragEnd: isFront && !isDetailed
              ? (d) => _handleFrontDragEnd(d)
              : null,
          onLongPressStart: isDetailed
              ? null
              : (_) => _controller.select(index),
          onLongPressMoveUpdate: isDetailed
              ? null
              : (d) => _controller.onSelectedDragUpdate(d.offsetFromOrigin),
          onLongPressEnd:
              isDetailed ? null : (_) => _controller.onSelectedDragEnd(),
          child: SizedBox(
            width: areaWidth,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (isFront)
                  _buildSwipeAffordance(
                    isLeft: true,
                    isDragging: isDraggingHorizontally,
                    dragX: dragX,
                  ),
                TweenAnimationBuilder<Offset>(
                  tween: Tween<Offset>(
                    begin: Offset.zero,
                    end: Offset(0, -liftY),
                  ),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedLift, child) {
                    return Transform.translate(
                      offset: animatedLift,
                      child: child,
                    );
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Transform.translate(
                      offset: isSelected
                          ? _controller.selectedOffset
                          : Offset.zero,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: opacity,
                        child: isFront
                            ? _buildSwipeableFront(card, isSelected,
                                selectedHasOffset, isDetailed)
                            : _buildCardShell(
                                card,
                                showSelectionBorder: selectedHasOffset,
                                detailedOutline: isDetailed,
                                expanded: isExpanded,
                              ),
                      ),
                    ),
                  ),
                ),
                if (isFront)
                  _buildSwipeAffordance(
                    isLeft: false,
                    isDragging: isDraggingHorizontally,
                    dragX: dragX,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeableFront(
    TaskCard card,
    bool isSelected,
    bool selectedHasOffset,
    bool isDetailed,
  ) {
    final target = _controller.isSwipingOut
        ? _controller.swipeOutTarget
        : _controller.frontOffset;

    return TweenAnimationBuilder<Offset>(
      key: ValueKey(card.id),
      tween: Tween<Offset>(begin: target, end: target),
      duration: _controller.isSwipingOut
          ? CardStackController.swipeOutDuration
          : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, animatedOffset, child) {
        return Opacity(
          opacity: _controller.isSwipingOut ? 0.0 : 1.0,
          child: Transform.translate(
            offset: isSelected ? Offset.zero : animatedOffset,
            child: child,
          ),
        );
      },
      child: _buildCardShell(
        card,
        showSelectionBorder: selectedHasOffset,
        detailedOutline: isDetailed,
        key: _frontMeasureKey,
        expanded: true,
      ),
    );
  }

  Widget _buildSwipeAffordance({
    required bool isLeft,
    required bool isDragging,
    required double dragX,
  }) {
    if (!isDragging) return const SizedBox.shrink();
    final isThisDirection = isLeft ? dragX < 0 : dragX > 0;
    if (!isThisDirection) return const SizedBox.shrink();

    final distance = dragX.abs();
    final progress = (distance / _swipeAffordanceReach).clamp(0.0, 1.0);
    final color = isLeft ? AppColors.danger : AppColors.success;
    final label = isLeft ? 'Delete' : 'Done';
    final alignment = isLeft ? Alignment.centerLeft : Alignment.centerRight;
    final iconData = isLeft ? Icons.delete_outline : Icons.check_circle_outline;
    final iconHorizontalPadding = isLeft ? 32.0 : 0.0;
    final labelHorizontalPadding = isLeft ? 0.0 : 32.0;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: progress,
          child: Stack(
            alignment: alignment,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 60,
                      spreadRadius: 18,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: iconHorizontalPadding,
                  right: 32 - iconHorizontalPadding,
                ),
                child: Icon(
                  iconData,
                  size: 56,
                  color: color.withValues(alpha: 0.95),
                ),
              ),
              Positioned(
                bottom: 56,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: labelHorizontalPadding,
                    right: 32 - labelHorizontalPadding,
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFrontDragEnd(DragEndDetails details) {
    final result =
        _controller.onFrontDragEnd(details.velocity.pixelsPerSecond);
    if (result == FrontDragResult.none) return;

    final direction = switch (result) {
      FrontDragResult.swipeLeft => SwipeOutDirection.left,
      FrontDragResult.swipeRight => SwipeOutDirection.right,
      FrontDragResult.swipeDown => SwipeOutDirection.down,
      FrontDragResult.none => SwipeOutDirection.none,
    };

    _controller.beginSwipeOut(direction);

    Future.delayed(CardStackController.swipeOutDuration, () {
      if (!mounted) return;
      _controller.completeSwipeOut();
      switch (direction) {
        case SwipeOutDirection.left:
          _controller.onSwipeLeft?.call();
        case SwipeOutDirection.right:
          _controller.onSwipeRight?.call();
        case SwipeOutDirection.down:
          _controller.onFrontSwipeDown?.call();
        case SwipeOutDirection.none:
          break;
      }
    });
  }

  Widget _buildCardShell(
    TaskCard card, {
    bool showSelectionBorder = false,
    bool detailedOutline = false,
    bool expanded = false,
    Key? key,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: showSelectionBorder
            ? Border.all(
                color: AppColors.accent.withValues(alpha: 0.6),
                width: 2,
              )
            : detailedOutline
                ? Border.all(
                    color: AppColors.success.withValues(alpha: 0.95),
                    width: 3,
                  )
                : null,
        boxShadow: [
          if (detailedOutline)
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.35),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildCardBody(card, expanded: expanded),
    );
  }

  Widget _buildCardBody(TaskCard card, {required bool expanded}) {
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
            maxLines: expanded ? null : 2,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (expanded && card.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              card.description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
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
