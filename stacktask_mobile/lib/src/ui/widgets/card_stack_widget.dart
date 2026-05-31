import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_tag.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/widgets/tag_pill_widget.dart';

class CardStackWidget extends StatefulWidget {
  final List<TaskCard> cards;
  final int? peekedIndex;
  final ValueChanged<int> onCardTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onFrontSwipeDown;
  final void Function(int fromIndex, int toIndex)? onMoveCard;

  const CardStackWidget({
    super.key,
    required this.cards,
    this.peekedIndex,
    required this.onCardTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onFrontSwipeDown,
    this.onMoveCard,
  });

  @override
  State<CardStackWidget> createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends State<CardStackWidget>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  double _dragY = 0;
  double _dragRotation = 0;
  bool _isDragging = false;
  bool _isSwipingOut = false;
  Timer? _debounceTimer;
  int _swipedCardIndex = -1;

  static const double _swipeThreshold = 120.0;
  static const double _swipeDownThreshold = 100.0;
  static const double _cardSpacing = 40.0;
  static const double _peekLift = 60.0;
  static const double _bottomPadding = 80.0;
  static const Duration _swipeOutDuration = Duration(milliseconds: 400);

  void _debouncedTap(int index) {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {});
    widget.onCardTap(index);
  }

  void _onFrontDragStart(DragStartDetails details) {
    if (widget.cards.isEmpty || _isSwipingOut) return;
    setState(() {
      _isDragging = true;
      _swipedCardIndex = 0;
      _dragX = 0;
      _dragY = 0;
      _dragRotation = 0;
    });
  }

  void _onPeekedDragStart(DragStartDetails details, int index) {
    if (_isSwipingOut) return;
    setState(() {
      _isDragging = true;
      _swipedCardIndex = index;
      _dragX = 0;
      _dragY = 0;
      _dragRotation = 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
      _dragRotation = _dragX * 0.06;
    });
  }

  void _onFrontDragEnd(DragEndDetails details) {
    if (!_isDragging || _isSwipingOut) return;
    _isDragging = false;
    _swipedCardIndex = -1;

    final velocity = details.velocity.pixelsPerSecond;
    final fastSwipe = velocity.dx.abs() > 500;

    if (_dragX.abs() > _swipeThreshold || (fastSwipe && _dragX.abs() > 40)) {
      _animateSwipeOut(() {
        if (_dragX > 0) {
          widget.onSwipeRight?.call();
        } else {
          widget.onSwipeLeft?.call();
        }
      });
    } else if (_dragY > _swipeDownThreshold ||
        (velocity.dy > 500 && _dragY > 40)) {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _dragRotation = 0;
      });
      widget.onFrontSwipeDown?.call();
    } else {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _dragRotation = 0;
      });
    }
  }

  void _onPeekedDragEnd(DragEndDetails details, int fromIndex) {
    if (!_isDragging || _isSwipingOut) return;
    _isDragging = false;
    _swipedCardIndex = -1;

    final velocity = details.velocity.pixelsPerSecond;

    if (_dragY > _swipeDownThreshold ||
        (velocity.dy > 500 && _dragY > 40)) {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _dragRotation = 0;
      });
      widget.onMoveCard?.call(fromIndex, 0);
    } else {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _dragRotation = 0;
      });
    }
  }

  void _animateSwipeOut(VoidCallback onDone) {
    setState(() {
      _isSwipingOut = true;
    });
    Future.delayed(_swipeOutDuration, () {
      if (mounted) {
        onDone();
        setState(() {
          _isSwipingOut = false;
          _dragX = 0;
          _dragY = 0;
          _dragRotation = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    final visibleCount = widget.cards.length > 4 ? 4 : widget.cards.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.88;
        final stackHeight =
            _bottomPadding + (visibleCount * _cardSpacing) + 280 + _peekLift;

        final visibleCards = <Widget>[];

        for (int i = visibleCount - 1; i >= 0; i--) {
          final isFront = i == 0;
          final isPeeked = i == widget.peekedIndex;

          final double baseBottom =
              _bottomPadding + (i * _cardSpacing) + (isPeeked ? _peekLift : 0);
          final double scale =
              isPeeked ? 1.0 : (1.0 - (i * 0.05)).clamp(0.8, 1.0);
          final double opacity =
              isPeeked ? 1.0 : (1.0 - (i * 0.12)).clamp(0.5, 1.0);

          final card = widget.cards[i];

          if (isFront && _isSwipingOut) {
            visibleCards.add(
              Positioned(
                bottom: baseBottom,
                left: _dragX > 0
                    ? constraints.maxWidth + 200
                    : -200 - cardWidth,
                child: Opacity(
                  opacity: 0,
                  child: SizedBox(
                    width: cardWidth,
                    child: TaskCardWidget(
                      card: card,
                      isFront: true,
                      isPeeked: false,
                    ),
                  ),
                ),
              ),
            );
          } else if (isFront) {
            visibleCards.add(
              Positioned(
                bottom: baseBottom,
                left: (constraints.maxWidth - cardWidth) / 2,
                child: GestureDetector(
                  onHorizontalDragStart: _onFrontDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onFrontDragEnd,
                  onVerticalDragStart: _onFrontDragStart,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onFrontDragEnd,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: (1.0 - (_dragX.abs() / 500)).clamp(0.3, 1.0),
                    child: Transform.translate(
                      offset: Offset(_dragX, _dragY),
                      child: Transform.rotate(
                        angle: _dragRotation * 0.017,
                        child: SizedBox(
                          width: cardWidth,
                          child: TaskCardWidget(
                            card: card,
                            isFront: true,
                            isPeeked: false,
                            isElevated: _isDragging,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else if (isPeeked) {
            final bool isPeekedDragging =
                _isDragging && _swipedCardIndex == i;
            visibleCards.add(
              Positioned(
                bottom:
                    baseBottom + (isPeekedDragging ? _dragY : 0),
                left: (constraints.maxWidth - cardWidth) / 2 +
                    (isPeekedDragging ? _dragX : 0),
                child: GestureDetector(
                  onVerticalDragStart: (details) =>
                      _onPeekedDragStart(details, i),
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: (details) =>
                      _onPeekedDragEnd(details, i),
                  onTap: () => _debouncedTap(i),
                  child: SizedBox(
                    width: cardWidth,
                    child: TaskCardWidget(
                      card: card,
                      isFront: false,
                      isPeeked: true,
                      isElevated: isPeekedDragging,
                    ),
                  ),
                ),
              ),
            );
          } else {
            visibleCards.add(
              Positioned(
                bottom: baseBottom,
                left: (constraints.maxWidth - cardWidth * scale) / 2,
                child: GestureDetector(
                  onTap: () => _debouncedTap(i),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: SizedBox(
                        width: cardWidth,
                        child: TaskCardWidget(
                          card: card,
                          isFront: false,
                          isPeeked: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: visibleCards,
          ),
        );
      },
    );
  }
}

class TaskCardWidget extends StatelessWidget {
  final TaskCard card;
  final bool isFront;
  final bool isPeeked;
  final bool isElevated;
  final VoidCallback? onTap;

  const TaskCardWidget({
    super.key,
    required this.card,
    this.isFront = false,
    this.isPeeked = false,
    this.isElevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tag = TaskTag.fromName(card.tag);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: isElevated ? 0.35 : (isPeeked ? 0.25 : 0.18)),
              blurRadius: isElevated ? 60 : (isPeeked ? 40 : 32),
              offset:
                  Offset(0, isElevated ? 20 : (isPeeked ? 16 : 8)),
            ),
            if (isElevated)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 0),
              ),
            if (isPeeked && !isElevated)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 0),
              ),
          ],
        ),
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
                Icon(Icons.schedule,
                    size: 14, color: AppColors.textSecondary),
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
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 10 : 8,
                      height: isActive ? 10 : 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textSecondary
                                .withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}