import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';

class FabStack extends StatefulWidget {
  final VoidCallback onAddTap;
  final VoidCallback onNotesTap;

  const FabStack({
    super.key,
    required this.onAddTap,
    required this.onNotesTap,
  });

  @override
  State<FabStack> createState() => _FabStackState();
}

class _FabStackState extends State<FabStack> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  void _run(VoidCallback action) {
    setState(() => _open = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          _buildMini(
            label: 'Add task',
            icon: Icons.add,
            color: AppColors.accent,
            openBottom: 76,
            onTap: () => _run(widget.onAddTap),
          ),
          _buildMini(
            label: 'Notes',
            icon: Icons.sticky_note_2_outlined,
            color: AppColors.success,
            openBottom: 132,
            onTap: () => _run(widget.onNotesTap),
          ),
          _CircleButton(
            icon: Icons.add,
            color: AppColors.accent,
            onTap: _toggle,
            size: 56,
            rotateTurns: _open ? 0.125 : 0,
          ),
        ],
      ),
    );
  }

  Widget _buildMini({
    required String label,
    required IconData icon,
    required Color color,
    required double openBottom,
    required VoidCallback onTap,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      right: 0,
      bottom: _open ? openBottom : 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _open ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !_open,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _CircleButton(icon: icon, color: color, onTap: onTap, size: 44),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final double rotateTurns;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 44,
    this.rotateTurns = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: rotateTurns,
            child: Icon(icon, color: Colors.white, size: size * 0.44),
          ),
        ),
      ),
    );
  }
}
