import 'package:sqflite/sqflite.dart';

import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/database/migrations/migration.dart';

class V4AddStatusToTasks extends Migration {
  const V4AddStatusToTasks();

  @override
  int get version => 4;

  @override
  String get description => 'Replace is_done with a status column on tasks';

  @override
  Future<void> up(Database db) async {
    final tasksColumns = await db.rawQuery(
      'PRAGMA table_info(${DatabaseHelper.tasksTable})',
    );
    final hasStatus = tasksColumns.any((row) => row['name'] == 'status');

    if (!hasStatus) {
      await db.execute('''
        CREATE TABLE ${DatabaseHelper.tasksTable}_new (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          tag TEXT NOT NULL,
          time_estimate TEXT,
          priority INTEGER NOT NULL DEFAULT 1,
          status TEXT NOT NULL DEFAULT 'doing',
          position INTEGER NOT NULL,
          group_id TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        INSERT INTO ${DatabaseHelper.tasksTable}_new
          (id, title, description, tag, time_estimate, priority, status, position, group_id, created_at)
        SELECT
          id, title, description, tag, time_estimate, priority,
          CASE WHEN is_done = 1 THEN 'done' ELSE 'doing' END,
          position, group_id, created_at
        FROM ${DatabaseHelper.tasksTable}
      ''');

      await db.execute('DROP TABLE ${DatabaseHelper.tasksTable}');
      await db.execute(
        'ALTER TABLE ${DatabaseHelper.tasksTable}_new '
        'RENAME TO ${DatabaseHelper.tasksTable}',
      );
    }
  }
}