import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';

class HeaderWidget extends StatelessWidget {
  final String groupName;
  final int taskCount;

  const HeaderWidget({
    super.key,
    required this.groupName,
    required this.taskCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STACKTASKS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 2.5,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  groupName,
                  style: Theme.of(context).textTheme.headlineLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$taskCount',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'task${taskCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
