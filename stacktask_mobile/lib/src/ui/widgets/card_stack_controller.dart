import 'dart:ui';

import 'package:flutter/foundation.dart';

class CardStackController extends ChangeNotifier {
  CardStackController({
    this.onCardTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onMoveCard,
  });

  static const double swipeThreshold = 120.0;
  static const double swipeVelocityThreshold = 500.0;
  static const double swipeOutDistance = 600.0;
  static const Duration swipeOutDuration = Duration(milliseconds: 400);

  ValueChanged<int>? onCardTap;
  ValueChanged<int>? onSwipeLeft;
  ValueChanged<int>? onSwipeRight;
  void Function(int from, int to)? onMoveCard;

  void updateCallbacks({
    ValueChanged<int>? onCardTap,
    ValueChanged<int>? onSwipeLeft,
    ValueChanged<int>? onSwipeRight,
    void Function(int from, int to)? onMoveCard,
  }) {
    this.onCardTap = onCardTap;
    this.onSwipeLeft = onSwipeLeft;
    this.onSwipeRight = onSwipeRight;
    this.onMoveCard = onMoveCard;
  }

  int? _frontIndex;
  int? get frontIndex => _frontIndex;

  double _frontDragX = 0;
  double get frontDragX => _frontDragX;
  Offset get frontOffset => Offset(_frontDragX, 0);

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
      case SwipeOutDirection.none:
        return Offset.zero;
    }
  }

  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;
  bool isSelected(int index) => _selectedIndex == index;

  int? _bypassedIndex;
  int? get bypassedIndex => _bypassedIndex;
  bool isBypassed(int index) {
    if (_selectedIndex == null || _bypassedIndex == null) return false;
    if (_bypassedIndex == _selectedIndex) return false;
    final lo = _selectedIndex! < _bypassedIndex!
        ? _selectedIndex!
        : _bypassedIndex!;
    final hi = _selectedIndex! < _bypassedIndex!
        ? _bypassedIndex!
        : _selectedIndex!;
    return index >= lo && index <= hi;
  }

  double _selectedDragX = 0;
  double _selectedDragY = 0;
  double get selectedDragX => _selectedDragX;
  double get selectedDragY => _selectedDragY;
  Offset get selectedOffset => Offset(_selectedDragX, _selectedDragY);

  void select(int index) {
    if (_isSwipingOut) return;
    _selectedIndex = index;
    _bypassedIndex = index;
    _selectedDragX = 0;
    _selectedDragY = 0;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIndex == null) return;
    _selectedIndex = null;
    _bypassedIndex = null;
    _selectedDragX = 0;
    _selectedDragY = 0;
    notifyListeners();
  }

  void onSelectedDragStart() {
    if (_selectedIndex == null) return;
    _selectedDragX = 0;
    _selectedDragY = 0;
    notifyListeners();
  }

  void onSelectedDragUpdate(Offset offsetFromOrigin) {
    if (_selectedIndex == null) return;
    _selectedDragX = offsetFromOrigin.dx;
    _selectedDragY = offsetFromOrigin.dy;
    _bypassedIndex = _calcBypassedIndex();
    notifyListeners();
  }

  int? _calcBypassedIndex() {
    if (_selectedIndex == null) return _selectedIndex;
    final from = _selectedIndex!;
    const cardSpacing = 40.0;
    final steps = (-_selectedDragY / cardSpacing).floor();
    if (steps == 0) return from;
    final target = from + steps;
    if (target < 0) return 0;
    return target;
  }

  void onSelectedDragEnd() {
    if (_selectedIndex == null) return;
    final from = _selectedIndex;
    final to = _bypassedIndex;
    _selectedDragX = 0;
    _selectedDragY = 0;
    _selectedIndex = null;
    _bypassedIndex = null;
    notifyListeners();
    if (from != null && to != null && from != to) {
      onMoveCard?.call(from, to);
    }
  }

  bool _isFrontDragging = false;
  bool get isFrontDragging => _isFrontDragging;

  void onFrontDragStart(int index) {
    if (_isSwipingOut) return;
    _frontIndex = index;
    _isFrontDragging = true;
    _frontDragX = 0;
    notifyListeners();
  }

  void onFrontDragUpdate(Offset delta) {
    if (_isSwipingOut) return;
    _frontDragX += delta.dx;
    notifyListeners();
  }

  FrontDragResult onFrontDragEnd(Offset velocity) {
    if (_isSwipingOut) {
      _isFrontDragging = false;
      return FrontDragResult.none;
    }

    final fastHorizontalSwipe = velocity.dx.abs() > swipeVelocityThreshold;

    FrontDragResult result = FrontDragResult.none;

    if (_frontDragX.abs() > swipeThreshold ||
        (fastHorizontalSwipe && _frontDragX.abs() > 40)) {
      result = _frontDragX > 0
          ? FrontDragResult.swipeRight
          : FrontDragResult.swipeLeft;
    }

    _isFrontDragging = false;
    _frontDragX = 0;
    notifyListeners();
    return result;
  }

  void beginSwipeOut(SwipeOutDirection direction) {
    _isSwipingOut = true;
    _swipeOutDirection = direction;
    notifyListeners();
  }

  SwipeOutDirection completeSwipeOut() {
    final dir = _swipeOutDirection;
    _isSwipingOut = false;
    _swipeOutDirection = SwipeOutDirection.none;
    notifyListeners();
    return dir;
  }

  void tapCard(int index) {
    onCardTap?.call(index);
  }

  void reset() {
    _frontIndex = null;
    _frontDragX = 0;
    _isFrontDragging = false;
    _isSwipingOut = false;
    _swipeOutDirection = SwipeOutDirection.none;
    _selectedIndex = null;
    _bypassedIndex = null;
    _selectedDragX = 0;
    _selectedDragY = 0;
    notifyListeners();
  }
}

enum FrontDragResult {
  none,
  swipeLeft,
  swipeRight,
}

enum SwipeOutDirection {
  none,
  left,
  right,
}
