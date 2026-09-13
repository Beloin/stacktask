import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper migration v2 -> v3', () {
    test('adds task_groups, inserts Default, backfills group_id', () async {
      final path = '${inMemoryDatabasePath}_v2';
      final v2 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE ${DatabaseHelper.tasksTable} (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                tag TEXT NOT NULL,
                time_estimate TEXT,
                priority INTEGER NOT NULL DEFAULT 1,
                is_done INTEGER NOT NULL DEFAULT 0,
                position INTEGER NOT NULL,
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
          },
        ),
      );

      await v2.insert(DatabaseHelper.tasksTable, {
        'id': 'm-1',
        'title': 'Legacy task A',
        'description': '',
        'tag': 'dev',
        'time_estimate': null,
        'priority': 1,
        'is_done': 0,
        'position': 0,
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await v2.insert(DatabaseHelper.tasksTable, {
        'id': 'm-2',
        'title': 'Legacy task B',
        'description': '',
        'tag': 'bug',
        'time_estimate': null,
        'priority': 2,
        'is_done': 0,
        'position': 1,
        'created_at': DateTime(2025, 1, 2).toIso8601String(),
      });
      await v2.close();

      final helper = DatabaseHelper.instance;
      final upgraded = await helper.openForTesting(
        path: path,
        factory: databaseFactoryFfi,
      );

      final groups = await upgraded.query(DatabaseHelper.groupsTable);
      expect(groups.length, 1);
      expect(groups.first['id'], TaskGroup.defaultId);
      expect(groups.first['name'], TaskGroup.defaultName);

      final tasks = await upgraded.query(DatabaseHelper.tasksTable);
      expect(tasks.length, 2);
      for (final row in tasks) {
        expect(row['group_id'], TaskGroup.defaultId);
      }

      final columns = await upgraded.rawQuery('PRAGMA table_info(tasks)');
      final colNames = columns.map((c) => c['name'] as String).toList();
      expect(colNames, contains('group_id'));

      final notNull = columns.firstWhere((c) => c['name'] == 'group_id');
      expect(notNull['notnull'], 1);

      await upgraded.close();
      await databaseFactoryFfi.deleteDatabase(path);
    });

    test('migration is idempotent when re-run on a v3 DB', () async {
      final path = '${inMemoryDatabasePath}_v3';
      final v3 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, _) async {
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
                is_done INTEGER NOT NULL DEFAULT 0,
                position INTEGER NOT NULL,
                group_id TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      await v3.close();

      final helper = DatabaseHelper.instance;
      final reopened = await helper.openForTesting(
        path: path,
        factory: databaseFactoryFfi,
      );

      final groups = await reopened.query(DatabaseHelper.groupsTable);
      expect(groups.length, 1);
      expect(groups.first['id'], TaskGroup.defaultId);

      await reopened.close();
      await databaseFactoryFfi.deleteDatabase(path);
    });
  });

  group('DatabaseHelper migration v3 -> v4', () {
    test('converts is_done to status and preserves data', () async {
      final path = '${inMemoryDatabasePath}_v3_to_v4';
      final v3 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, _) async {
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
                is_done INTEGER NOT NULL DEFAULT 0,
                position INTEGER NOT NULL,
                group_id TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      await v3.insert(DatabaseHelper.tasksTable, {
        'id': 't-1',
        'title': 'Active task',
        'description': '',
        'tag': 'dev',
        'time_estimate': null,
        'priority': 1,
        'is_done': 0,
        'position': 0,
        'group_id': TaskGroup.defaultId,
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await v3.insert(DatabaseHelper.tasksTable, {
        'id': 't-2',
        'title': 'Done task',
        'description': '',
        'tag': 'bug',
        'time_estimate': null,
        'priority': 2,
        'is_done': 1,
        'position': 1,
        'group_id': TaskGroup.defaultId,
        'created_at': DateTime(2025, 1, 2).toIso8601String(),
      });
      await v3.close();

      final helper = DatabaseHelper.instance;
      final upgraded = await helper.openForTesting(
        path: path,
        factory: databaseFactoryFfi,
      );

      final columns = await upgraded.rawQuery('PRAGMA table_info(tasks)');
      final colNames = columns.map((c) => c['name'] as String).toList();
      expect(colNames, contains('status'));
      expect(colNames, isNot(contains('is_done')));

      final tasks = await upgraded.query(DatabaseHelper.tasksTable);
      expect(tasks.length, 2);
      final byId = {for (final row in tasks) row['id'] as String: row};
      expect(byId['t-1']!['status'], 'doing');
      expect(byId['t-2']!['status'], 'done');
      expect(byId['t-2']!['title'], 'Done task');
      expect(byId['t-2']!['priority'], 2);
      expect(byId['t-2']!['group_id'], TaskGroup.defaultId);

      await upgraded.close();
      await databaseFactoryFfi.deleteDatabase(path);
    });

    test('preserves status data when reopening a v4 DB', () async {
      final path = '${inMemoryDatabasePath}_v4';
      final helper = DatabaseHelper.instance;
      final db = await helper.openForTesting(
        path: path,
        factory: databaseFactoryFfi,
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseHelper.groupsTable} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL
        )
      ''');
      await db.insert(DatabaseHelper.groupsTable, {
        'id': TaskGroup.defaultId,
        'name': TaskGroup.defaultName,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseHelper.tasksTable} (
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
      await db.insert(DatabaseHelper.tasksTable, {
        'id': 'v4-1',
        'title': 'V4 task',
        'description': '',
        'tag': 'dev',
        'time_estimate': null,
        'priority': 1,
        'status': 'ignored',
        'position': 0,
        'group_id': TaskGroup.defaultId,
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      await db.close();

      final reopened = await helper.openForTesting(
        path: path,
        factory: databaseFactoryFfi,
      );
      final tasks = await reopened.query(DatabaseHelper.tasksTable);
      expect(tasks.length, 1);
      expect(tasks.first['status'], 'ignored');

      await reopened.close();
      await databaseFactoryFfi.deleteDatabase(path);
    });
  });
}
