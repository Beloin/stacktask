import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:stacktask_mobile/src/core/database/change_log.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_status.dart';
import 'package:stacktask_mobile/src/core/result/result_barrel.dart';

class StackRepository {
  final Database _db;
  final Uuid _uuid;

  StackRepository({required Database database, Uuid? uuid})
      : _db = database,
        _uuid = uuid ?? const Uuid();

  static Future<StackRepository> create({DatabaseHelper? dbHelper}) async {
    final helper = dbHelper ?? DatabaseHelper.instance;
    final db = await helper.database;
    return StackRepository(database: db);
  }

  AsyncResult<List<TaskCard>, ErrorCode> loadCards(String groupId) async {
    try {
      final maps = await _db.query(
        DatabaseHelper.tasksTable,
        where: 'group_id = ? AND status = ?',
        whereArgs: [groupId, TaskStatus.doing.name],
        orderBy: 'position ASC',
      );
      return Success(maps.map((m) => TaskCard.fromMap(m)).toList());
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to load cards: $e'));
    }
  }

  AsyncResult<void, ErrorCode> updateCardStatus(
    String cardId,
    TaskStatus status,
  ) async {
    try {
      await _db.update(
        DatabaseHelper.tasksTable,
        {'status': status.name},
        where: 'id = ?',
        whereArgs: [cardId],
      );
      await _logChange(
        changeType: ChangeType.update,
        taskId: cardId,
        payload: {'status': status.name},
      );
      return const Success(null);
    } catch (e) {
      return Failure(
        ErrorCode.fromString(message: 'Failed to update card status: $e'),
      );
    }
  }

  AsyncResult<List<TaskCard>, ErrorCode> searchArchivedCards({
    required TaskStatus status,
    String query = '',
    int limit = 8,
  }) async {
    try {
      final pattern = '%${query.trim()}%';
      final maps = await _db.query(
        DatabaseHelper.tasksTable,
        where: 'status = ? AND (title LIKE ? OR description LIKE ?)',
        whereArgs: [status.name, pattern, pattern],
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return Success(maps.map((m) => TaskCard.fromMap(m)).toList());
    } catch (e) {
      return Failure(
        ErrorCode.fromString(message: 'Failed to search archived cards: $e'),
      );
    }
  }

  AsyncResult<Map<TaskStatus, int>, ErrorCode> countByStatus() async {
    try {
      final rows = await _db.rawQuery(
        'SELECT status, COUNT(*) AS c FROM ${DatabaseHelper.tasksTable} '
        'GROUP BY status',
      );
      final counts = <TaskStatus, int>{};
      for (final row in rows) {
        final status = TaskStatus.fromName(row['status'] as String?);
        counts[status] = (row['c'] as int?) ?? 0;
      }
      return Success(counts);
    } catch (e) {
      return Failure(
        ErrorCode.fromString(message: 'Failed to count cards by status: $e'),
      );
    }
  }

  AsyncResult<void, ErrorCode> saveCard(TaskCard card, int position) async {
    try {
      final map = card.toMap();
      map['position'] = position;
      await _db.insert(
        DatabaseHelper.tasksTable,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _logChange(
        changeType: ChangeType.insert,
        taskId: card.id,
        payload: map,
      );
      return const Success(null);
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to save card: $e'));
    }
  }

  AsyncResult<void, ErrorCode> deleteCard(String cardId) async {
    try {
      await _db.delete(
        DatabaseHelper.tasksTable,
        where: 'id = ?',
        whereArgs: [cardId],
      );
      await _logChange(
        changeType: ChangeType.delete,
        taskId: cardId,
        payload: {'id': cardId},
      );
      return const Success(null);
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to delete card: $e'));
    }
  }

  AsyncResult<List<String>, ErrorCode> deleteCardsByGroup(String groupId) async {
    try {
      final cards = await _db.query(
        DatabaseHelper.tasksTable,
        columns: ['id'],
        where: 'group_id = ?',
        whereArgs: [groupId],
      );
      final ids = cards.map((c) => c['id'] as String).toList();
      if (ids.isEmpty) return const Success(<String>[]);

      await _db.delete(
        DatabaseHelper.tasksTable,
        where: 'group_id = ?',
        whereArgs: [groupId],
      );

      final placeholders = List.filled(ids.length, '?').join(',');
      await _db.delete(
        DatabaseHelper.changesTable,
        where: 'task_id IN ($placeholders)',
        whereArgs: ids,
      );
      return Success(ids);
    } catch (e) {
      return Failure(
        ErrorCode.fromString(message: 'Failed to delete group cards: $e'),
      );
    }
  }

  AsyncResult<void, ErrorCode> syncPositions(List<TaskCard> cards) async {
    try {
      final batch = _db.batch();
      for (int i = 0; i < cards.length; i++) {
        batch.update(
          DatabaseHelper.tasksTable,
          {'position': i},
          where: 'id = ?',
          whereArgs: [cards[i].id],
        );
      }
      await batch.commit(noResult: true);
      await _logChange(
        changeType: ChangeType.reorder,
        taskId: null,
        payload: {'order': cards.map((c) => c.id).toList()},
      );
      return const Success(null);
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to sync positions: $e'));
    }
  }

  AsyncResult<void, ErrorCode> updateCard(TaskCard card) async {
    try {
      final map = card.toMap();
      map['position'] = (await _getPositionForCard(card.id)) ?? 0;
      await _db.update(
        DatabaseHelper.tasksTable,
        map,
        where: 'id = ?',
        whereArgs: [card.id],
      );
      await _logChange(
        changeType: ChangeType.update,
        taskId: card.id,
        payload: map,
      );
      return const Success(null);
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to update card: $e'));
    }
  }

  AsyncResult<void, ErrorCode> moveCardToGroup(
    String cardId,
    String newGroupId,
  ) async {
    try {
      await _db.update(
        DatabaseHelper.tasksTable,
        {'group_id': newGroupId},
        where: 'id = ?',
        whereArgs: [cardId],
      );
      await _logChange(
        changeType: ChangeType.update,
        taskId: cardId,
        payload: {'group_id': newGroupId},
      );
      return const Success(null);
    } catch (e) {
      return Failure(
        ErrorCode.fromString(message: 'Failed to move card to group: $e'),
      );
    }
  }

  AsyncResult<List<ChangeLog>, ErrorCode> getChangeLogs() async {
    try {
      final maps = await _db.query(
        DatabaseHelper.changesTable,
        orderBy: 'timestamp ASC',
      );
      return Success(maps.map((m) => ChangeLog.fromMap(m)).toList());
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to get change logs: $e'));
    }
  }

  Future<int?> _getPositionForCard(String cardId) async {
    final results = await _db.query(
      DatabaseHelper.tasksTable,
      columns: ['position'],
      where: 'id = ?',
      whereArgs: [cardId],
    );
    if (results.isEmpty) return null;
    return results.first['position'] as int;
  }

  Future<void> _logChange({
    required ChangeType changeType,
    required String? taskId,
    required Map<String, dynamic> payload,
  }) async {
    final change = ChangeLog(
      id: _uuid.v4(),
      taskId: taskId,
      changeType: changeType,
      payload: jsonEncode(payload),
      timestamp: DateTime.now(),
    );
    await _db.insert(DatabaseHelper.changesTable, change.toMap());
  }
}
