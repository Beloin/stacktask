import 'package:stacktask_mobile/src/core/models/task_group.dart';

class TaskGroupService {
  final List<TaskGroup> _groups = [];

  List<TaskGroup> get all => List.unmodifiable(_groups);

  int get count => _groups.length;

  bool get isEmpty => _groups.isEmpty;

  TaskGroup? byId(String id) {
    for (final g in _groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  void replaceAll(List<TaskGroup> groups) {
    _groups
      ..clear()
      ..addAll(groups);
  }

  void add(TaskGroup group) {
    _groups.add(group);
  }

  void rename(String id, String name) {
    final i = _groups.indexWhere((g) => g.id == id);
    if (i < 0) return;
    _groups[i] = _groups[i].copyWith(name: name);
  }

  void remove(String id) {
    _groups.removeWhere((g) => g.id == id);
  }

  void clear() {
    _groups.clear();
  }
}
