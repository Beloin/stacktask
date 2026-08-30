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
    // Each card slot is _cardSpacing pixels apart vertically.
    // Dragging up (negative Y) past -_cardSpacing moves the card up by 1 slot.
    // Dragging down (positive Y) past _cardSpacing moves the card down by 1 slot.
    const cardSpacing = 40.0;
    final steps = (-_selectedDragY / cardSpacing).floor();
    if (steps == 0) return from;
    final target = from + steps;
    if (target < 0) return 0;
    return target;
  }

  void onSelectedDragEnd() {
    if (_selectedIndex == null) return;
    _selectedDragX = 0;
    _selectedDragY = 0;
    _selectedIndex = null;
    _bypassedIndex = null;
    notifyListeners();
  }

  bool _isFrontDragging = false;
  bool get isFrontDragging => _isFrontDragging;

  void onFrontDragStart() {
    if (_isSwipingOut) return;
    _isFrontDragging = true;
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
    if (_isSwipingOut) {
      _isFrontDragging = false;
      return FrontDragResult.none;
    }

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

    _isFrontDragging = false;
    _frontDragX = 0;
    _frontDragY = 0;
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

  void reset() {
    _frontDragX = 0;
    _frontDragY = 0;
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
  swipeDown,
}

enum SwipeOutDirection {
  none,
  left,
  right,
  down,
}