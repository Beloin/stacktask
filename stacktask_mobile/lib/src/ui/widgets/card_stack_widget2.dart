import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_tag.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/widgets/tag_pill_widget.dart';

class CardStackWidget2 extends StatelessWidget {
  final List<TaskCard> cards;
  final int? peekedIndex;
  final ValueChanged<int> onCardTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onFrontSwipeDown;
  final void Function(int fromIndex, int toIndex)? onMoveCard;

  const CardStackWidget2({
    super.key,
    required this.cards,
    this.peekedIndex,
    required this.onCardTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onFrontSwipeDown,
    this.onMoveCard,
  });

  static const double _cardSpacing = 40.0;
  static const double _bottomPadding = 80.0;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final totalCards = cards.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.88;
        final cardLeft = (constraints.maxWidth - cardWidth) / 2;
        final stackHeight =
            _bottomPadding + (totalCards * _cardSpacing) + 320;

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
                    child: GestureDetector(
                      onTap: () => onCardTap(i),
                      child: _buildCard(cards[i]),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(TaskCard card) {
    final tag = TaskTag.fromName(card.tag);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 8),
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
            ],
          ),
        ],
      ),
    );
  }
}
