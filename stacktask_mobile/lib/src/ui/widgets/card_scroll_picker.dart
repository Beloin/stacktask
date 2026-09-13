import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';

class CardScrollPicker extends StatefulWidget {
  final int cardCount;
  final ValueChanged<int?> onIndexChanged;
  final bool inverted;

  const CardScrollPicker({
    super.key,
    required this.cardCount,
    required this.onIndexChanged,
    this.inverted = false,
  });

  @override
  State<CardScrollPicker> createState() => _CardScrollPickerState();
}

class _CardScrollPickerState extends State<CardScrollPicker> {
  static const double _restSize = 14.0;
  static const double _activeSize = 30.0;

  bool _active = false;
  double _ballY = 0;

  int _indexForY(double localY, double trackHeight) {
    if (widget.cardCount <= 1) return 0;
    final boxHeight = trackHeight / widget.cardCount;
    final box = (localY / boxHeight).floor();
    final rawIndex = widget.inverted ? box : widget.cardCount - 1 - box;
    return rawIndex.clamp(0, widget.cardCount - 1);
  }

  void _emit(double localY, double trackHeight) {
    final idx = _indexForY(localY, trackHeight);
    widget.onIndexChanged(idx);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cardCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            setState(() {
              _active = true;
              _ballY = e.localPosition.dy;
            });
            _emit(e.localPosition.dy, trackHeight);
          },
          onPointerMove: (e) {
            if (!_active) return;
            setState(() => _ballY = e.localPosition.dy);
            _emit(e.localPosition.dy, trackHeight);
          },
          onPointerUp: (_) {
            setState(() => _active = false);
            widget.onIndexChanged(null);
          },
          onPointerCancel: (_) {
            setState(() => _active = false);
            widget.onIndexChanged(null);
          },
          child: SizedBox.expand(
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: _active
                      ? const Duration(milliseconds: 60)
                      : const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  top: _active
                      ? (_ballY - _activeSize / 2)
                          .clamp(0.0, trackHeight - _activeSize)
                      : widget.inverted
                          ? 60
                          : trackHeight - _restSize - 60,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: _active ? _activeSize : _restSize,
                    height: _active ? _activeSize : _restSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _active
                          ? AppColors.success.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.35),
                      border: Border.all(
                        color: _active
                            ? AppColors.success
                            : Colors.white.withValues(alpha: 0.6),
                        width: _active ? 2 : 1,
                      ),
                      boxShadow: _active
                          ? [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
