import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/models/task_status.dart';
import 'package:stacktask_mobile/src/core/repositories/group_repository.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/result/result_barrel.dart';
import '../../test_helpers.dart';

Future<Database> _createTestDatabase() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
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

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GroupRepository', () {
    late Database db;
    late GroupRepository repository;

    setUp(() async {
      db = await _createTestDatabase();
      final stackRepository = StackRepository(database: db);
      repository = GroupRepository(
        database: db,
        stackRepository: stackRepository,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('loadGroups returns the Default group on a fresh DB', () async {
      final result = await repository.loadGroups();
      expect(result, isA<Success>());
      result.when(
        success: (groups) {
          expect(groups.length, 1);
          expect(groups.first.id, TaskGroup.defaultId);
          expect(groups.first.name, TaskGroup.defaultName);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('addGroup inserts a new group', () async {
      final result = await repository.addGroup('Work');
      expect(result, isA<Success>());
      result.when(
        success: (group) {
          expect(group.name, 'Work');
          expect(group.id, isNot(TaskGroup.defaultId));
        },
        failure: (error) => fail('Should not fail: $error'),
      );

      final load = await repository.loadGroups();
      load.when(
        success: (groups) => expect(groups.length, 2),
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('addGroup rejects empty names', () async {
      final result = await repository.addGroup('   ');
      expect(result, isA<Failure>());
    });

    test('addGroup rejects duplicate names', () async {
      await repository.addGroup('Work');
      final result = await repository.addGroup('Work');
      expect(result, isA<Failure>());
      result.when(
        success: (_) => fail('Should not succeed'),
        failure: (error) => expect(error.message, contains('Work')),
      );
    });

    test('renameGroup updates the name', () async {
      final addResult = await repository.addGroup('Work');
      String id = '';
      addResult.when(
        success: (group) => id = group.id,
        failure: (error) => fail('Should not fail: $error'),
      );

      final renameResult = await repository.renameGroup(id, 'Personal');
      expect(renameResult, isA<Success>());

      final loadResult = await repository.loadGroups();
      loadResult.when(
        success: (groups) {
          final renamed = groups.firstWhere((g) => g.id == id);
          expect(renamed.name, 'Personal');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('renameGroup refuses to rename Default', () async {
      final result = await repository.renameGroup(TaskGroup.defaultId, 'X');
      expect(result, isA<Failure>());
    });

    test('renameGroup rejects empty names', () async {
      final addResult = await repository.addGroup('Work');
      String id = '';
      addResult.when(
        success: (group) => id = group.id,
        failure: (error) => fail('Should not fail: $error'),
      );
      final result = await repository.renameGroup(id, '   ');
      expect(result, isA<Failure>());
    });

    test('renameGroup rejects duplicate names', () async {
      final a = await repository.addGroup('A');
      final b = await repository.addGroup('B');
      String idB = '';
      b.when(
        success: (group) => idB = group.id,
        failure: (error) => fail('Should not fail: $error'),
      );
      final result = await repository.renameGroup(idB, 'A');
      expect(result, isA<Failure>());
      a.when(
        success: (_) {},
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('taskCountByGroup returns map keyed by group_id', () async {
      final addResult = await repository.addGroup('Work');
      String workId = '';
      addResult.when(
        success: (group) => workId = group.id,
        failure: (error) => fail('Should not fail: $error'),
      );

      final stackRepository = StackRepository(database: db);
      await stackRepository.saveCard(
        TaskCard(
          id: 'd-1',
          title: 'D1',
          tag: 'dev',
          createdAt: DateTime(2025, 6, 15),
        ),
        0,
      );
      await stackRepository.saveCard(
        TaskCard(
          id: 'w-1',
          title: 'W1',
          tag: 'dev',
          createdAt: DateTime(2025, 6, 15),
          groupId: workId,
        ),
        0,
      );

      final result = await repository.taskCountByGroup();
      expect(result, isA<Success>());
      result.when(
        success: (counts) {
          expect(counts[TaskGroup.defaultId], 1);
          expect(counts[workId], 1);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('taskCountByGroup counts only doing cards', () async {
      final stackRepository = StackRepository(database: db);
      final doing = TaskCard(
        id: 'dc-1',
        title: 'Active',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      final done = TaskCard(
        id: 'dc-2',
        title: 'Finished',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      final ignored = TaskCard(
        id: 'dc-3',
        title: 'Ignored',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      await stackRepository.saveCard(doing, 0);
      await stackRepository.saveCard(done, 1);
      await stackRepository.saveCard(ignored, 2);
      await stackRepository.updateCardStatus('dc-2', TaskStatus.done);
      await stackRepository.updateCardStatus('dc-3', TaskStatus.ignored);

      final result = await repository.taskCountByGroup();
      expect(result, isA<Success>());
      result.when(
        success: (counts) => expect(counts[TaskGroup.defaultId], 1),
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('deleteGroupCascade deletes group and all its tasks', () async {
      final addResult = await repository.addGroup('Work');
      String workId = '';
      addResult.when(
        success: (group) => workId = group.id,
        failure: (error) => fail('Should not fail: $error'),
      );

      final stackRepository = StackRepository(database: db);
      await stackRepository.saveCard(
        TaskCard(
          id: 'w-1',
          title: 'W1',
          tag: 'dev',
          createdAt: DateTime(2025, 6, 15),
          groupId: workId,
        ),
        0,
      );
      await stackRepository.saveCard(
        TaskCard(
          id: 'w-2',
          title: 'W2',
          tag: 'dev',
          createdAt: DateTime(2025, 6, 15),
          groupId: workId,
        ),
        1,
      );
      await stackRepository.saveCard(
        TaskCard(
          id: 'd-1',
          title: 'D1',
          tag: 'dev',
          createdAt: DateTime(2025, 6, 15),
        ),
        0,
      );

      final result = await repository.deleteGroupCascade(workId);
      expect(result, isA<Success>());
      result.when(
        success: (removed) => expect(removed, 2),
        failure: (error) => fail('Should not fail: $error'),
      );

      final groupsResult = await repository.loadGroups();
      groupsResult.when(
        success: (groups) => expect(
          groups.any((g) => g.id == workId),
          isFalse,
        ),
        failure: (error) => fail('Should not fail: $error'),
      );

      final workCards = await stackRepository.loadCards(workId);
      workCards.when(
        success: (cards) => expect(cards, isEmpty),
        failure: (error) => fail('Should not fail: $error'),
      );

      final defaultCards = await stackRepository.loadCards(TaskGroup.defaultId);
      defaultCards.when(
        success: (cards) => expect(cards.length, 1),
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('deleteGroupCascade leaves no orphan change-log rows for the deleted tasks',
        () async {
      final addResult = await repository.addGroup('Work');
      String workId = '';
      addResult.when(
        success: (group) => workId = group.id,
        failure: (error) => fail('Should not fail: $error'),
      );

      final stackRepository = StackRepository(database: db);
      await stackRepository.saveCard(
        TaskCard(
          id: 'w-1',
          title: 'W1',
          tag: 'dev',
          createdAt: DateTime(2025, 6, 15),
          groupId: workId,
        ),
        0,
      );

      final beforeChanges = await stackRepository.getChangeLogs();
      beforeChanges.when(
        success: (changes) => expect(
          changes.where((c) => c.taskId == 'w-1').isNotEmpty,
          isTrue,
        ),
        failure: (error) => fail('Should not fail: $error'),
      );

      await repository.deleteGroupCascade(workId);

      final afterChanges = await stackRepository.getChangeLogs();
      afterChanges.when(
        success: (changes) => expect(
          changes.where((c) => c.taskId == 'w-1').isEmpty,
          isTrue,
        ),
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('deleteGroupCascade refuses to delete Default', () async {
      final result = await repository.deleteGroupCascade(TaskGroup.defaultId);
      expect(result, isA<Failure>());
    });

    test('deleteGroupCascade returns failure for unknown id', () async {
      final result = await repository.deleteGroupCascade('does-not-exist');
      expect(result, isA<Failure>());
    });
  });
}
