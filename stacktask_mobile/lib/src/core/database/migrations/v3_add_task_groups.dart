import 'package:sqflite/sqflite.dart';

import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/database/migrations/migration.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';

class V3AddTaskGroups extends Migration {
  const V3AddTaskGroups();

  @override
  int get version => 3;

  @override
  String get description => 'Add task_groups table and group_id to tasks';

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseHelper.groupsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.insert(
      DatabaseHelper.groupsTable,
      {
        'id': TaskGroup.defaultId,
        'name': TaskGroup.defaultName,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    final tasksColumns = await db.rawQuery(
      'PRAGMA table_info(${DatabaseHelper.tasksTable})',
    );
    final hasGroupId = tasksColumns.any((row) => row['name'] == 'group_id');

    if (!hasGroupId) {
      await db.execute(
        'ALTER TABLE ${DatabaseHelper.tasksTable} ADD COLUMN group_id TEXT',
      );
      await db.update(
        DatabaseHelper.tasksTable,
        {'group_id': TaskGroup.defaultId},
        where: 'group_id IS NULL',
      );
    }

    await db.execute('''
      CREATE TABLE ${DatabaseHelper.tasksTable}_new (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        tag TEXT NOT NULL,
        time_estimate TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        is_done INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL,
        group_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      INSERT INTO ${DatabaseHelper.tasksTable}_new
        (id, title, description, tag, time_estimate, priority, is_done, position, group_id, created_at)
      SELECT
        id, title, description, tag, time_estimate, priority, is_done, position,
        COALESCE(group_id, '${TaskGroup.defaultId}'),
        created_at
      FROM ${DatabaseHelper.tasksTable}
    ''');

    await db.execute('DROP TABLE ${DatabaseHelper.tasksTable}');
    await db.execute(
      'ALTER TABLE ${DatabaseHelper.tasksTable}_new '
      'RENAME TO ${DatabaseHelper.tasksTable}',
    );
  }
}
