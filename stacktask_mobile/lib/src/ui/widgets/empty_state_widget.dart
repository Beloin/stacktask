import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎉',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            'All done!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0x80FFFFFF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new task',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0x4DFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}