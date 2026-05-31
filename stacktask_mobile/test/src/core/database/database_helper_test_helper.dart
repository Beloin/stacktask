import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';

Future<Database> createTestDatabase() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.execute('''
    CREATE TABLE IF NOT EXISTS ${DatabaseHelper.tasksTable} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      tag TEXT NOT NULL,
      time_estimate TEXT,
      priority INTEGER NOT NULL DEFAULT 1,
      position INTEGER NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS ${DatabaseHelper.changesTable} (
      id TEXT PRIMARY KEY,
      task_id TEXT,
      change_type TEXT NOT NULL,
      payload TEXT NOT NULL,
      timestamp TEXT NOT NULL
    )
  ''');
  return db;
}