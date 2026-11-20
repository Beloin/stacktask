import 'package:sqflite/sqflite.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/database/migrations/migration.dart';

class V5AddNotes extends Migration {
  const V5AddNotes();
  @override
  int get version => 5;
  @override
  String get description => 'Add notes table';
  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseHelper.notesTable} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        group_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
