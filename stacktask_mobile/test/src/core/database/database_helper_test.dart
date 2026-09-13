import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper tables', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE ${DatabaseHelper.groupsTable} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL
        )
      ''');
      await db.insert(DatabaseHelper.groupsTable, {
        'id': TaskGroup.defaultId,
        'name': TaskGroup.defaultName,
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.execute('''
        CREATE TABLE ${DatabaseHelper.tasksTable} (
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
        CREATE TABLE ${DatabaseHelper.changesTable} (
          id TEXT PRIMARY KEY,
          task_id TEXT,
          change_type TEXT NOT NULL,
          payload TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    });

    tearDown(() async {
      await db.close();
    });

    test('tasks table has correct columns', () async {
      final result = await db.rawQuery('PRAGMA table_info(tasks)');
      final columnNames = result.map((row) => row['name'] as String).toList();
      expect(columnNames, containsAll([
        'id', 'title', 'description', 'tag',
        'time_estimate', 'priority', 'status', 'position',
        'group_id', 'created_at',
      ]));
    });

    test('task_changes table has correct columns', () async {
      final result = await db.rawQuery('PRAGMA table_info(task_changes)');
      final columnNames = result.map((row) => row['name'] as String).toList();
      expect(columnNames, containsAll([
        'id', 'task_id', 'change_type', 'payload', 'timestamp',
      ]));
    });

    test('task_groups table has correct columns', () async {
      final result = await db.rawQuery('PRAGMA table_info(task_groups)');
      final columnNames = result.map((row) => row['name'] as String).toList();
      expect(columnNames, containsAll([
        'id', 'name', 'created_at',
      ]));
    });

    test('task_groups.name is unique', () async {
      await db.insert(DatabaseHelper.groupsTable, {
        'id': 'g-2',
        'name': 'Work',
        'created_at': DateTime.now().toIso8601String(),
      });
      expect(
        () => db.insert(DatabaseHelper.groupsTable, {
          'id': 'g-3',
          'name': 'Work',
          'created_at': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('can insert and read a task', () async {
      await db.insert(DatabaseHelper.tasksTable, {
        'id': 'test-1',
        'title': 'Test task',
        'description': 'A test',
        'tag': 'dev',
        'time_estimate': '2h',
        'priority': 2,
        'position': 0,
        'group_id': TaskGroup.defaultId,
        'created_at': DateTime.now().toIso8601String(),
      });
      final results = await db.query(
        DatabaseHelper.tasksTable,
        where: 'id = ?',
        whereArgs: ['test-1'],
      );
      expect(results.length, 1);
      expect(results.first['title'], 'Test task');
    });

    test('can insert and read a change log', () async {
      await db.insert(DatabaseHelper.changesTable, {
        'id': 'change-1',
        'task_id': 'test-1',
        'change_type': 'insert',
        'payload': '{"title":"Test"}',
        'timestamp': DateTime.now().toIso8601String(),
      });
      final results = await db.query(
        DatabaseHelper.changesTable,
        where: 'id = ?',
        whereArgs: ['change-1'],
      );
      expect(results.length, 1);
      expect(results.first['change_type'], 'insert');
    });
  });
}
