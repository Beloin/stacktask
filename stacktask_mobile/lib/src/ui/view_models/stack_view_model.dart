import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/result/result_barrel.dart';
import 'package:stacktask_mobile/src/core/services/stack_service.dart';

enum SwipeDirection { left, right, down }

class StackViewModel extends ChangeNotifier {
  final StackService _service;
  final StackRepository _repository;
  final Uuid _uuid;

  bool _isModalOpen = false;
  bool _isLoading = false;
  ErrorCode? _lastError;

  StackViewModel({
    required StackRepository repository,
    StackService? service,
    Uuid? uuid,
  })  : _service = service ?? StackService(),
        _repository = repository,
        _uuid = uuid ?? const Uuid();

  List<TaskCard> get cards => _service.all;
  int get count => _service.count;
  bool get isEmpty => _service.isEmpty;
  TaskCard? get frontCard => _service.peek;
  bool get isModalOpen => _isModalOpen;
  bool get isLoading => _isLoading;
  ErrorCode? get lastError => _lastError;
  bool get hasError => _lastError != null;

  int get maxCards => StackService.maxCards;

  TaskCard? cardAt(int index) => _service.cardAt(index);

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> loadCards() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final result = await _repository.loadCards();
    switch (result) {
      case Success(:final value):
        _service.clear();
        for (final card in value.reversed) {
          _service.push(card);
        }
        _isLoading = false;
        notifyListeners();
      case Failure(:final error):
        _lastError = error;
        _isLoading = false;
        notifyListeners();
    }
  }

  Future<void> addCard({
    required String title,
    required String tag,
    String description = '',
    String? timeEstimate,
    int priority = 1,
  }) async {
    final card = TaskCard(
      id: _uuid.v4(),
      title: title,
      tag: tag,
      description: description,
      timeEstimate: timeEstimate,
      priority: priority,
      createdAt: DateTime.now(),
    );
    _service.push(card);
    notifyListeners();

    final saveResult = await _repository.saveCard(card, 0);
    switch (saveResult) {
      case Success():
        final syncResult = await _repository.syncPositions(_service.all);
        if (syncResult case Failure(:final error)) {
          _lastError = error;
          notifyListeners();
        }
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
    }
  }

  Future<void> dismissCard(SwipeDirection direction) async {
    final card = _service.pop();
    if (card == null) return;
    notifyListeners();

    final deleteResult = await _repository.deleteCard(card.id);
    switch (deleteResult) {
      case Success():
        final syncResult = await _repository.syncPositions(_service.all);
        if (syncResult case Failure(:final error)) {
          _lastError = error;
          notifyListeners();
        }
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
    }
  }

  Future<void> removeCardAt(int index) async {
    final card = _service.cardAt(index);
    if (card == null) return;
    _service.removeAt(index);
    notifyListeners();

    final deleteResult = await _repository.deleteCard(card.id);
    switch (deleteResult) {
      case Success():
        final syncResult = await _repository.syncPositions(_service.all);
        if (syncResult case Failure(:final error)) {
          _lastError = error;
          notifyListeners();
        }
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
    }
  }

  Future<void> promoteToFront(int index) async {
    _service.promoteToFront(index);
    notifyListeners();

    final result = await _repository.syncPositions(_service.all);
    if (result case Failure(:final error)) {
      _lastError = error;
      notifyListeners();
    }
  }

  Future<void> moveCardTo(int fromIndex, int toIndex) async {
    _service.moveCardTo(fromIndex, toIndex);
    notifyListeners();

    final result = await _repository.syncPositions(_service.all);
    if (result case Failure(:final error)) {
      _lastError = error;
      notifyListeners();
    }
  }

  Future<void> updateCard({
    required String id,
    required String title,
    required String tag,
    String description = '',
    String? timeEstimate,
    int priority = 1,
  }) async {
    if (id.isEmpty) return;
    final index = _service.all.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final existing = _service.all[index];
    final updated = existing.copyWith(
      title: title,
      tag: tag,
      description: description,
      timeEstimate: timeEstimate,
      priority: priority,
    );
    final result = await _repository.updateCard(updated);
    switch (result) {
      case Success():
        _service.replaceAt(index, updated);
        notifyListeners();
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
    }
  }

  Future<void> markCardAsDone(int index) async {
    if (index < 0 || index >= _service.count) return;
    final card = _service.cardAt(index);
    if (card == null) return;
    final updated = card.copyWith(isDone: true);
    final result = await _repository.updateCard(updated);
    switch (result) {
      case Success():
        _service.removeAt(index);
        notifyListeners();
        final syncResult = await _repository.syncPositions(_service.all);
        if (syncResult case Failure(:final error)) {
          _lastError = error;
          notifyListeners();
        }
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
    }
  }

  Future<void> cycleFrontToEnd() async {
    _service.cycleFrontToEnd();
    notifyListeners();

    final result = await _repository.syncPositions(_service.all);
    if (result case Failure(:final error)) {
      _lastError = error;
      notifyListeners();
    }
  }

  void openModal() {
    _isModalOpen = true;
    notifyListeners();
  }

  void closeModal() {
    _isModalOpen = false;
    notifyListeners();
  }
}