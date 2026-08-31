import 'package:sqflite/sqflite.dart';

import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/database/migrations/migration.dart';

class V2AddIsDoneToTasks extends Migration {
  const V2AddIsDoneToTasks();

  @override
  int get version => 2;

  @override
  String get description => 'Add is_done column to tasks';

  @override
  Future<void> up(Database db) async {
    await db.execute(
      'ALTER TABLE ${DatabaseHelper.tasksTable} '
      'ADD COLUMN is_done INTEGER NOT NULL DEFAULT 0',
    );
  }
}
