import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';

class FabWidget extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const FabWidget({
    super.key,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 500),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 2500),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accentLight,
                  width: 2,
                ),
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, Color(0xFF7C6CF0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onTap,
              icon: AnimatedRotation(
                duration: const Duration(milliseconds: 400),
                turns: isOpen ? 0.125 : 0,
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}