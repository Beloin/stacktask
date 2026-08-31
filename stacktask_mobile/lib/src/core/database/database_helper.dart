import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:stacktask_mobile/src/core/database/migrations/migrations_barrel.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';

class DatabaseHelper {
  static const _dbName = 'stacktasks.db';
  static const _dbVersion = 3;

  static const tasksTable = 'tasks';
  static const changesTable = 'task_changes';
  static const groupsTable = 'task_groups';

  static const List<Migration> _migrations = [
    V2AddIsDoneToTasks(),
    V3AddTaskGroups(),
  ];

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<Database> openForTesting({
    required String path,
    required DatabaseFactory factory,
  }) {
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $groupsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.insert(groupsTable, {
      'id': TaskGroup.defaultId,
      'name': TaskGroup.defaultName,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.execute('''
      CREATE TABLE $tasksTable (
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
      CREATE TABLE $changesTable (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        change_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (final migration in _migrations) {
      if (oldVersion < migration.version) {
        await migration.up(db);
      }
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
