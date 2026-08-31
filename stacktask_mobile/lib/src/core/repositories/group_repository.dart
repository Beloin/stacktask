import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/result/result_barrel.dart';

class GroupRepository {
  final Database _db;
  final Uuid _uuid;
  final StackRepository _stackRepository;

  GroupRepository({
    required Database database,
    required StackRepository stackRepository,
    Uuid? uuid,
  })  : _db = database,
        _stackRepository = stackRepository,
        _uuid = uuid ?? const Uuid();

  AsyncResult<List<TaskGroup>, ErrorCode> loadGroups() async {
    try {
      final maps = await _db.query(
        DatabaseHelper.groupsTable,
        orderBy: 'created_at ASC',
      );
      return Success(maps.map((m) => TaskGroup.fromMap(m)).toList());
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to load groups: $e'));
    }
  }

  AsyncResult<Map<String, int>, ErrorCode> taskCountByGroup() async {
    try {
      final rows = await _db.rawQuery(
        'SELECT g.id AS group_id, COUNT(t.id) AS c '
        'FROM ${DatabaseHelper.groupsTable} g '
        'LEFT JOIN ${DatabaseHelper.tasksTable} t ON t.group_id = g.id '
        'GROUP BY g.id',
      );
      final counts = <String, int>{};
      for (final row in rows) {
        final id = row['group_id'] as String?;
        if (id != null) {
          counts[id] = (row['c'] as int?) ?? 0;
        }
      }
      return Success(counts);
    } catch (e) {
      return Failure(
        ErrorCode.fromString(message: 'Failed to count tasks by group: $e'),
      );
    }
  }

  AsyncResult<TaskGroup, ErrorCode> addGroup(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Failure(ErrorCode.fromString(message: 'Group name cannot be empty'));
    }
    try {
      final group = TaskGroup(
        id: _uuid.v4(),
        name: trimmed,
        createdAt: DateTime.now(),
      );
      await _db.insert(
        DatabaseHelper.groupsTable,
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return Success(group);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return Failure(
          ErrorCode.fromString(message: 'A group named "$trimmed" already exists'),
        );
      }
      return Failure(ErrorCode.fromString(message: 'Failed to add group: $e'));
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to add group: $e'));
    }
  }

  AsyncResult<void, ErrorCode> renameGroup(String id, String name) async {
    if (id == TaskGroup.defaultId) {
      return Failure(ErrorCode.fromString(message: 'Default group cannot be renamed'));
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Failure(ErrorCode.fromString(message: 'Group name cannot be empty'));
    }
    try {
      final updated = await _db.update(
        DatabaseHelper.groupsTable,
        {'name': trimmed},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated == 0) {
        return Failure(ErrorCode.fromString(message: 'Group not found'));
      }
      return const Success(null);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return Failure(
          ErrorCode.fromString(message: 'A group named "$trimmed" already exists'),
        );
      }
      return Failure(ErrorCode.fromString(message: 'Failed to rename group: $e'));
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to rename group: $e'));
    }
  }

  AsyncResult<int, ErrorCode> deleteGroupCascade(String id) async {
    if (id == TaskGroup.defaultId) {
      return Failure(ErrorCode.fromString(message: 'Default group cannot be deleted'));
    }
    try {
      final groups = await _db.query(
        DatabaseHelper.groupsTable,
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (groups.isEmpty) {
        return Failure(ErrorCode.fromString(message: 'Group not found'));
      }

      final deleted = await _stackRepository.deleteCardsByGroup(id);
      int removedCards = 0;
      switch (deleted) {
        case Success(:final value):
          removedCards = value.length;
        case Failure(:final error):
          return Failure(error);
      }

      await _db.delete(
        DatabaseHelper.groupsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      return Success(removedCards);
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to delete group: $e'));
    }
  }
}
