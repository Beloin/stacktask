import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/repositories/group_repository.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/result/result_barrel.dart';
import 'package:stacktask_mobile/src/core/services/stack_service.dart';
import 'package:stacktask_mobile/src/core/services/task_group_service.dart';

enum SwipeDirection { left, right, down }

class StackViewModel extends ChangeNotifier {
  final StackService _service;
  final StackRepository _repository;
  final TaskGroupService _groupService;
  final GroupRepository _groupRepository;
  final Uuid _uuid;

  bool _isModalOpen = false;
  bool _isLoading = false;
  ErrorCode? _lastError;

  String? _selectedGroupId;
  Map<String, int> _groupTaskCounts = const {};

  StackViewModel({
    required StackRepository repository,
    required GroupRepository groupRepository,
    StackService? service,
    TaskGroupService? groupService,
    Uuid? uuid,
    String? initialSelectedGroupId,
  })  : _service = service ?? StackService(),
        _repository = repository,
        _groupRepository = groupRepository,
        _groupService = groupService ?? TaskGroupService(),
        _uuid = uuid ?? const Uuid(),
        _selectedGroupId = initialSelectedGroupId;

  List<TaskCard> get cards => _service.all;
  int get count => _service.count;
  bool get isEmpty => _service.isEmpty;
  TaskCard? get frontCard => _service.peek;
  bool get isModalOpen => _isModalOpen;
  bool get isLoading => _isLoading;
  ErrorCode? get lastError => _lastError;
  bool get hasError => _lastError != null;

  List<TaskGroup> get groups => _groupService.all;
  int get groupCount => _groupService.count;
  Map<String, int> get groupTaskCounts => _groupTaskCounts;
  String? get selectedGroupId => _selectedGroupId;

  String get selectedGroupName {
    final id = _selectedGroupId;
    if (id == null) return '';
    return _groupService.byId(id)?.name ?? '';
  }

  TaskGroup? selectedGroup() {
    final id = _selectedGroupId;
    if (id == null) return null;
    return _groupService.byId(id);
  }

  int get maxCards => StackService.maxCards;

  TaskCard? cardAt(int index) => _service.cardAt(index);

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> loadGroups() async {
    final result = await _groupRepository.loadGroups();
    switch (result) {
      case Success(:final value):
        _groupService.replaceAll(value);
        if (_selectedGroupId == null ||
            _groupService.byId(_selectedGroupId!) == null) {
          _selectedGroupId = value.isNotEmpty ? value.first.id : null;
        }
        await _refreshGroupCounts();
        notifyListeners();
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
    }
  }

  Future<void> _refreshGroupCounts() async {
    final result = await _groupRepository.taskCountByGroup();
    if (result case Success(:final value)) {
      _groupTaskCounts = value;
    }
  }

  Future<void> loadCards() async {
    final groupId = _selectedGroupId;
    if (groupId == null) {
      _service.clear();
      notifyListeners();
      return;
    }
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final result = await _repository.loadCards(groupId);
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

  Future<void> bootstrap() async {
    await loadGroups();
    await loadCards();
  }

  Future<void> selectGroup(String groupId) async {
    if (_selectedGroupId == groupId) return;
    _selectedGroupId = groupId;
    notifyListeners();
    await loadCards();
  }

  Future<void> addGroup(String name) async {
    final result = await _groupRepository.addGroup(name);
    switch (result) {
      case Success(:final value):
        _groupService.add(value);
        _selectedGroupId = value.id;
        await _refreshGroupCounts();
        notifyListeners();
        await loadCards();
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
    }
  }

  Future<void> renameGroup(String id, String name) async {
    final result = await _groupRepository.renameGroup(id, name);
    switch (result) {
      case Success():
        _groupService.rename(id, name.trim());
        notifyListeners();
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
    }
  }

  Future<int?> deleteGroupCascade(String id) async {
    final wasSelected = _selectedGroupId == id;
    final result = await _groupRepository.deleteGroupCascade(id);
    switch (result) {
      case Success(:final value):
        _groupService.remove(id);
        _groupTaskCounts = {..._groupTaskCounts}..remove(id);
        if (wasSelected) {
          final fallback = _groupService.all.isNotEmpty
              ? _groupService.all.first.id
              : TaskGroup.defaultId;
          _selectedGroupId = fallback;
        }
        await _refreshGroupCounts();
        notifyListeners();
        if (wasSelected) {
          await loadCards();
        }
        return value;
      case Failure(:final error):
        _lastError = error;
        notifyListeners();
        return null;
    }
  }

  Future<void> addCard({
    required String title,
    required String tag,
    String description = '',
    String? timeEstimate,
    int priority = 1,
  }) async {
    final groupId = _selectedGroupId ?? TaskGroup.defaultId;
    final card = TaskCard(
      id: _uuid.v4(),
      title: title,
      tag: tag,
      description: description,
      timeEstimate: timeEstimate,
      priority: priority,
      createdAt: DateTime.now(),
      groupId: groupId,
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
        } else {
          await _refreshGroupCounts();
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
        } else {
          await _refreshGroupCounts();
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
        } else {
          await _refreshGroupCounts();
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

  Future<bool> moveCardToGroup(String cardId, String newGroupId) async {
    final index = _service.all.indexWhere((c) => c.id == cardId);
    if (index < 0) return false;
    final existing = _service.all[index];
    if (existing.groupId == newGroupId) return false;

    final wasActiveGroup = existing.groupId == _selectedGroupId;
    final moved = existing.copyWith(groupId: newGroupId);
    _service.replaceAt(index, moved);

    final result = await _repository.moveCardToGroup(cardId, newGroupId);
    switch (result) {
      case Success():
        if (wasActiveGroup) {
          _service.removeAt(index);
        }
        await _refreshGroupCounts();
        notifyListeners();
        return true;
      case Failure(:final error):
        _service.replaceAt(index, existing);
        _lastError = error;
        notifyListeners();
        return false;
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
        } else {
          await _refreshGroupCounts();
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
