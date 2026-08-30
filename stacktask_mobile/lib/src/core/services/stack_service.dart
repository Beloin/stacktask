import 'package:stacktask_mobile/src/core/models/task_card.dart';

class StackService {
  static const int maxCards = 15;

  final List<TaskCard> _cards = [];

  List<TaskCard> get all => List.unmodifiable(_cards);

  int get count => _cards.length;

  bool get isEmpty => _cards.isEmpty;

  TaskCard? get peek => _cards.isNotEmpty ? _cards.first : null;

  TaskCard? cardAt(int index) {
    if (index >= 0 && index < _cards.length) return _cards[index];
    return null;
  }

  void push(TaskCard card) {
    if (_cards.length >= maxCards) {
      _cards.removeLast();
    }
    _cards.insert(0, card);
  }

  TaskCard? pop() {
    if (_cards.isEmpty) return null;
    return _cards.removeAt(0);
  }

  void removeAt(int index) {
    if (index >= 0 && index < _cards.length) {
      _cards.removeAt(index);
    }
  }

  void replaceAt(int index, TaskCard card) {
    if (index >= 0 && index < _cards.length) {
      _cards[index] = card;
    }
  }

  void promoteToFront(int index) {
    if (index <= 0 || index >= _cards.length) return;
    final card = _cards.removeAt(index);
    _cards.insert(0, card);
  }

  void cycleFrontToEnd() {
    if (_cards.length <= 1) return;
    final card = _cards.removeAt(0);
    _cards.add(card);
  }

  void clear() {
    _cards.clear();
  }

  void moveCardTo(int from, int to) {
    if (from < 0 || from >= _cards.length) return;
    if (to < 0 || to >= _cards.length) return;
    final card = _cards.removeAt(from);
    _cards.insert(to, card);
  }
}