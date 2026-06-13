import 'dart:ui';

import 'package:flutter/foundation.dart';

class CardStackController extends ChangeNotifier {
  static const double swipeThreshold = 120.0;
  static const double swipeDownThreshold = 100.0;
  static const double swipeVelocityThreshold = 500.0;
  static const double swipeOutDistance = 600.0;
  static const Duration swipeOutDuration = Duration(milliseconds: 400);

  double _frontDragX = 0;
  double _frontDragY = 0;
  double get frontDragX => _frontDragX;
  double get frontDragY => _frontDragY;
  Offset get frontOffset => Offset(_frontDragX, _frontDragY);

  bool _isSwipingOut = false;
  SwipeOutDirection _swipeOutDirection = SwipeOutDirection.none;
  bool get isSwipingOut => _isSwipingOut;
  SwipeOutDirection get swipeOutDirection => _swipeOutDirection;

  Offset get swipeOutTarget {
    switch (_swipeOutDirection) {
      case SwipeOutDirection.left:
        return const Offset(-swipeOutDistance, 0);
      case SwipeOutDirection.right:
        return const Offset(swipeOutDistance, 0);
      case SwipeOutDirection.down:
        return const Offset(0, swipeOutDistance);
      case SwipeOutDirection.none:
        return Offset.zero;
    }
  }

  void onFrontDragStart() {
    if (_isSwipingOut) return;
    _frontDragX = 0;
    _frontDragY = 0;
    notifyListeners();
  }

  void onFrontDragUpdate(Offset delta) {
    if (_isSwipingOut) return;
    _frontDragX += delta.dx;
    _frontDragY += delta.dy;
    notifyListeners();
  }

  FrontDragResult onFrontDragEnd(Offset velocity) {
    if (_isSwipingOut) return FrontDragResult.none;

    final fastHorizontalSwipe = velocity.dx.abs() > swipeVelocityThreshold;
    final fastVerticalSwipe = velocity.dy > swipeVelocityThreshold;

    FrontDragResult result = FrontDragResult.none;

    if (_frontDragX.abs() > swipeThreshold ||
        (fastHorizontalSwipe && _frontDragX.abs() > 40)) {
      result = _frontDragX > 0
          ? FrontDragResult.swipeRight
          : FrontDragResult.swipeLeft;
    } else if (_frontDragY > swipeDownThreshold ||
        (fastVerticalSwipe && _frontDragY > 40)) {
      result = FrontDragResult.swipeDown;
    }

    _frontDragX = 0;
    _frontDragY = 0;
    notifyListeners();
    return result;
  }

  /// Begin the swipe-out animation. The card flies off-screen in the given
  /// direction; the widget should call [completeSwipeOut] after the animation
  /// finishes to actually dismiss/cycle the card via the ViewModel callback.
  void beginSwipeOut(SwipeOutDirection direction) {
    _isSwipingOut = true;
    _swipeOutDirection = direction;
    notifyListeners();
  }

  /// Called by the widget when the animation completes. Resets swipe-out state
  /// and returns the original swipe direction so the caller knows which
  /// ViewModel action to fire.
  SwipeOutDirection completeSwipeOut() {
    final dir = _swipeOutDirection;
    _isSwipingOut = false;
    _swipeOutDirection = SwipeOutDirection.none;
    notifyListeners();
    return dir;
  }

  void reset() {
    _frontDragX = 0;
    _frontDragY = 0;
    _isSwipingOut = false;
    _swipeOutDirection = SwipeOutDirection.none;
    notifyListeners();
  }
}

enum FrontDragResult {
  none,
  swipeLeft,
  swipeRight,
  swipeDown,
}

enum SwipeOutDirection {
  none,
  left,
  right,
  down,
}