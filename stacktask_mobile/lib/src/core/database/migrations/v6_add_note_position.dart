import 'package:sqflite/sqflite.dart';

import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/database/migrations/migration.dart';

class V6AddNotePosition extends Migration {
  const V6AddNotePosition();

  @override
  int get version => 6;

  @override
  String get description => 'Add position column to notes for reordering';

  @override
  Future<void> up(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(${DatabaseHelper.notesTable})',
    );
    final hasPosition = columns.any((row) => row['name'] == 'position');
    if (hasPosition) return;

    await db.execute(
      'ALTER TABLE ${DatabaseHelper.notesTable} '
      'ADD COLUMN position INTEGER NOT NULL DEFAULT 0',
    );

    final rows = await db.query(
      DatabaseHelper.notesTable,
      orderBy: 'created_at DESC',
    );
    for (int i = 0; i < rows.length; i++) {
      await db.update(
        DatabaseHelper.notesTable,
        {'position': i},
        where: 'id = ?',
        whereArgs: [rows[i]['id']],
      );
    }
  }
}
