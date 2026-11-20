import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_tag.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/widgets/card_stack_controller.dart';
import 'package:stacktask_mobile/src/ui/widgets/tag_pill_widget.dart';

class CardStackWidget2 extends StatefulWidget {
  final List<TaskCard> cards;
  final ValueChanged<int>? onCardTap;
  final ValueChanged<int>? onSwipeLeft;
  final ValueChanged<int>? onSwipeRight;
  final void Function(int from, int to)? onMoveCard;
  final bool readOnly;

  const CardStackWidget2({
    super.key,
    required this.cards,
    this.onCardTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onMoveCard,
    this.readOnly = false,
  });

  @override
  State<CardStackWidget2> createState() => _CardStackWidget2State();
}

class _CardStackWidget2State extends State<CardStackWidget2>
    with SingleTickerProviderStateMixin {
  static const double _cardSpacing = 40.0;
  static const double _bottomPadding = 80.0;
  static const double _expandedHeight = 160.0;
  static const double _collapsedHeight = 112.0;
  static const double _swipeAffordanceReach = 120.0;
  static const double _topFadeFraction = 0.10;
  static const double _focusShrink = 0.85;
  static const double _focusDarken = 0.75;
  static const double _scrollLiftFraction = 0.08;

  late final CardStackController _controller;
  late final AnimationController _flingController;
  double _scrollOffset = 0;

  double get _maxScroll {
    final n = widget.cards.length;
    if (n <= 1) return 0;
    return (n - 1) * _cardSpacing;
  }

  bool get _atRest => _scrollOffset <= 0.5;

  int _activeIndexFor(double offset) {
    final n = widget.cards.length;
    if (n == 0) return 0;
    return (offset / _cardSpacing).round().clamp(0, n - 1);
  }

  double _heightFor(TaskCard card, double progress) {
    if (card.description.isEmpty) return _collapsedHeight;
    return _collapsedHeight + (_expandedHeight - _collapsedHeight) * progress;
  }

  @override
  void initState() {
    super.initState();
    _controller = CardStackController(
      onCardTap: widget.onCardTap,
      onSwipeLeft: widget.onSwipeLeft,
      onSwipeRight: widget.onSwipeRight,
      onMoveCard: widget.onMoveCard,
    );
    _flingController = AnimationController.unbounded(vsync: this)
      ..addListener(_onFlingTick);
  }

  @override
  void didUpdateWidget(covariant CardStackWidget2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.updateCallbacks(
      onCardTap: widget.onCardTap,
      onSwipeLeft: widget.onSwipeLeft,
      onSwipeRight: widget.onSwipeRight,
      onMoveCard: widget.onMoveCard,
    );
    if (widget.cards.length != oldWidget.cards.length) {
      final maxScroll = _maxScroll;
      if (_scrollOffset > maxScroll) _scrollOffset = maxScroll;
      if (_scrollOffset < 0) _scrollOffset = 0;
    }
  }

  @override
  void dispose() {
    _flingController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFlingTick() {
    final maxScroll = _maxScroll;
    final next = _flingController.value.clamp(0.0, maxScroll);
    if ((next - _scrollOffset).abs() < 0.01) return;
    setState(() => _scrollOffset = next);
  }

  void _fling(double velocity) {
    final maxScroll = _maxScroll;
    if (maxScroll <= 0) {
      _snapToNearestSlot();
      return;
    }
    _flingController.stop();
    _flingController.value = _scrollOffset.clamp(0.0, maxScroll);
    final simulation = ClampingScrollSimulation(
      position: _scrollOffset,
      velocity: velocity,
    );
    _flingController.animateWith(simulation).then((_) {
      if (!mounted) return;
      _snapToNearestSlot();
    });
  }

  void _snapToNearestSlot() {
    if (!mounted) return;
    final maxScroll = _maxScroll;
    if (maxScroll <= 0) return;
    final target = (_scrollOffset / _cardSpacing).round() * _cardSpacing;
    final clamped = target.clamp(0.0, maxScroll);
    _flingController.stop();
    _flingController.value = _scrollOffset;
    _flingController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToRest() {
    final maxScroll = _maxScroll;
    _flingController.stop();
    _flingController.value = _scrollOffset.clamp(0.0, maxScroll);
    _flingController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final n = widget.cards.length;
        final maxScroll = _maxScroll;
        final activeIndex = _activeIndexFor(_scrollOffset);
        final areaWidth = constraints.maxWidth;
        final topFadeBand = constraints.maxHeight * _topFadeFraction;
        final isSelecting = _controller.selectedIndex != null;
        final atRest = _atRest;
        final activeCard = widget.cards[activeIndex];
        final activeCardHeight = _heightFor(activeCard, 1.0);
        final scrollProgress = (_scrollOffset / _cardSpacing).clamp(0.0, 1.0);
        final lift =
            constraints.maxHeight * _scrollLiftFraction * scrollProgress;
        final frontCardTop =
            constraints.maxHeight - _bottomPadding - activeCardHeight - lift;

        final cards = <Widget>[
          for (int i = 0; i < activeIndex; i++)
            _buildPositionedCard(
              index: i,
              activeIndex: activeIndex,
              frontCardTop: frontCardTop,
              areaWidth: areaWidth,
              topFadeBand: topFadeBand,
              atRest: atRest,
            ),
          for (int i = n - 1; i > activeIndex; i--)
            _buildPositionedCard(
              index: i,
              activeIndex: activeIndex,
              frontCardTop: frontCardTop,
              areaWidth: areaWidth,
              topFadeBand: topFadeBand,
              atRest: atRest,
            ),
          _buildPositionedCard(
            index: activeIndex,
            activeIndex: activeIndex,
            frontCardTop: frontCardTop,
            areaWidth: areaWidth,
            topFadeBand: topFadeBand,
            atRest: atRest,
          ),
        ];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart:
              isSelecting ? null : (_) => _flingController.stop(),
          onVerticalDragUpdate: isSelecting
              ? null
              : (d) {
                  _scrollOffset =
                      (_scrollOffset + d.delta.dy).clamp(0.0, maxScroll);
                  setState(() {});
                },
          onVerticalDragEnd: isSelecting
              ? null
              : (d) => _fling(d.velocity.pixelsPerSecond.dy),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...cards,
              _buildMatte(constraints.maxHeight),
              _buildBackButton(atRest),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatte(double height) {
    return Positioned(
      top: height - _bottomPadding,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(bool atRest) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: atRest,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: atRest ? 0.0 : 1.0,
          child: Center(
            child: Material(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _goToRest,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: AppColors.textWhite,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Back to stack',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionedCard({
    required int index,
    required int activeIndex,
    required double frontCardTop,
    required double areaWidth,
    required double topFadeBand,
    required bool atRest,
  }) {
    final card = widget.cards[index];
    final isActive = index == activeIndex;
    final progress = (1.0 - (index - activeIndex).abs()).clamp(0.0, 1.0);
    final height = _heightFor(card, progress);
    final fullWidth = areaWidth * 0.88;
    final left = (areaWidth - fullWidth) / 2;
    final top = frontCardTop - (index - activeIndex) * _cardSpacing;
    final opacity = _topOpacityFor(top, topFadeBand);
    final darken = (!isActive && !atRest) ? _focusDarken : 1.0;
    final focusScale = (!isActive && !atRest) ? _focusShrink : 1.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      top: top,
      left: left,
      width: fullWidth,
      height: height,
      child: _buildCard(
        card,
        index,
        progress: progress,
        opacity: opacity * darken,
        isActive: isActive,
        focusScale: focusScale,
      ),
    );
  }

  double _topOpacityFor(double top, double band) {
    if (band <= 0) return 1.0;
    if (top <= 0) return 0.0;
    if (top >= band) return 1.0;
    return top / band;
  }

  Widget _buildCard(
    TaskCard card,
    int index, {
    required double progress,
    required double opacity,
    required bool isActive,
    required double focusScale,
  }) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isSelected = _controller.isSelected(index);
        final isBypassed = _controller.isBypassed(index);
        final finalOpacity = isBypassed ? 0.4 : opacity;
        final dragX = _controller.frontDragX;
        final isDraggingHorizontally =
            _controller.isFrontDragging && dragX.abs() > 4;
        final showSelectionBorder =
            isSelected && _controller.selectedOffset != Offset.zero;

        final content = isActive
            ? _buildActiveCardContent(
                card: card,
                isSelected: isSelected,
                progress: progress,
                showSelectionBorder: showSelectionBorder,
              )
            : _buildCardShell(
                card,
                progress: progress,
                showSelectionBorder: showSelectionBorder,
              );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _controller.tapCard(index),
          onHorizontalDragStart: isActive && !widget.readOnly
              ? (_) => _controller.onFrontDragStart(index)
              : null,
          onHorizontalDragUpdate: isActive && !widget.readOnly
              ? (d) => _controller.onFrontDragUpdate(d.delta)
              : null,
          onHorizontalDragEnd: isActive && !widget.readOnly
              ? _handleFrontDragEnd
              : null,
          onLongPressStart:
              widget.readOnly ? null : (_) => _controller.select(index),
          onLongPressMoveUpdate: widget.readOnly
              ? null
              : (d) => _controller.onSelectedDragUpdate(d.offsetFromOrigin),
          onLongPressEnd:
              widget.readOnly ? null : (_) => _controller.onSelectedDragEnd(),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (isActive)
                _buildSwipeAffordance(
                  isLeft: true,
                  isDragging: isDraggingHorizontally,
                  dragX: dragX,
                ),
              AnimatedScale(
                scale: isSelected ? 1.05 : focusScale,
                duration: const Duration(milliseconds: 200),
                child: Transform.translate(
                  offset: isSelected
                      ? _controller.selectedOffset
                      : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: finalOpacity,
                    child: content,
                  ),
                ),
              ),
              if (isActive)
                _buildSwipeAffordance(
                  isLeft: false,
                  isDragging: isDraggingHorizontally,
                  dragX: dragX,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveCardContent({
    required TaskCard card,
    required bool isSelected,
    required double progress,
    required bool showSelectionBorder,
  }) {
    final target = _controller.isSwipingOut
        ? _controller.swipeOutTarget
        : _controller.frontOffset;

    return TweenAnimationBuilder<Offset>(
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
        progress: progress,
        showSelectionBorder: showSelectionBorder,
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
    final label = isLeft ? 'Ignore' : 'Done';
    final alignment = isLeft ? Alignment.centerLeft : Alignment.centerRight;
    final iconData = isLeft
        ? Icons.visibility_off_outlined
        : Icons.check_circle_outline;
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
      FrontDragResult.none => SwipeOutDirection.none,
    };

    _controller.beginSwipeOut(direction);

    Future.delayed(CardStackController.swipeOutDuration, () {
      if (!mounted) return;
      _controller.completeSwipeOut();
      switch (direction) {
        case SwipeOutDirection.left:
          _controller.onSwipeLeft?.call(_controller.frontIndex!);
        case SwipeOutDirection.right:
          _controller.onSwipeRight?.call(_controller.frontIndex!);
        case SwipeOutDirection.none:
          break;
      }
    });
  }

  Widget _buildCardShell(
    TaskCard card, {
    required double progress,
    bool showSelectionBorder = false,
  }) {
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
      clipBehavior: Clip.antiAlias,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: _buildCardBody(card, progress: progress),
      ),
    );
  }

  Widget _buildCardBody(TaskCard card, {required double progress}) {
    final tag = TaskTag.fromName(card.tag);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TagPillWidget(tag: tag),
          const SizedBox(height: 8),
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (card.description.isNotEmpty)
            _buildDescription(card.description, progress),
          const SizedBox(height: 8),
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

  Widget _buildDescription(String text, double progress) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        heightFactor: progress,
        child: Opacity(
          opacity: progress,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
