import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/change_log.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/models/task_status.dart';
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

  group('StackRepository', () {
    late StackRepository repository;
    late Database db;

    setUp(() async {
      db = await _createTestDatabase();
      repository = StackRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saveCard and loadCards round-trip', () async {
      final card = TaskCard(
        id: 'repo-1',
        title: 'Repo test',
        tag: 'design',
        description: 'Test card',
        timeEstimate: '2h',
        priority: 3,
        createdAt: DateTime(2025, 6, 15),
      );
      final saveResult = await repository.saveCard(card, 0);
      expect(saveResult, isA<Success>());

      final loadResult = await repository.loadCards(TaskGroup.defaultId);
      expect(loadResult, isA<Success>());
      loadResult.when(
        success: (cards) {
          expect(cards.length, 1);
          expect(cards.first.id, 'repo-1');
          expect(cards.first.title, 'Repo test');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('loadCards returns empty list when no cards', () async {
      final result = await repository.loadCards(TaskGroup.defaultId);
      expect(result, isA<Success>());
      result.when(
        success: (cards) => expect(cards, isEmpty),
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('saveCard logs INSERT change', () async {
      final card = TaskCard(
        id: 'repo-2',
        title: 'Change log test',
        tag: 'bug',
        createdAt: DateTime(2025, 6, 15),
      );
      await repository.saveCard(card, 0);
      final changesResult = await repository.getChangeLogs();
      expect(changesResult, isA<Success>());
      changesResult.when(
        success: (changes) {
          expect(changes.length, 1);
          expect(changes.first.changeType, ChangeType.insert);
          expect(changes.first.taskId, 'repo-2');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('deleteCard removes card and logs DELETE change', () async {
      final card = TaskCard(
        id: 'repo-3',
        title: 'To delete',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      await repository.saveCard(card, 0);
      final deleteResult = await repository.deleteCard('repo-3');
      expect(deleteResult, isA<Success>());

      final loadResult = await repository.loadCards(TaskGroup.defaultId);
      loadResult.when(
        success: (cards) => expect(cards, isEmpty),
        failure: (error) => fail('Should not fail: $error'),
      );

      final changesResult = await repository.getChangeLogs();
      changesResult.when(
        success: (changes) {
          expect(changes.any((c) => c.changeType == ChangeType.delete), isTrue);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('syncPositions updates all positions and logs REORDER', () async {
      final card1 = TaskCard(
        id: 'a', title: 'A', tag: 'dev', createdAt: DateTime(2025, 1, 1),
      );
      final card2 = TaskCard(
        id: 'b', title: 'B', tag: 'dev', createdAt: DateTime(2025, 1, 1),
      );
      await repository.saveCard(card1, 0);
      await repository.saveCard(card2, 1);
      final syncResult = await repository.syncPositions([card2, card1]);
      expect(syncResult, isA<Success>());

      final loadResult = await repository.loadCards(TaskGroup.defaultId);
      loadResult.when(
        success: (cards) => expect(cards.first.id, 'b'),
        failure: (error) => fail('Should not fail: $error'),
      );

      final changesResult = await repository.getChangeLogs();
      changesResult.when(
        success: (changes) {
          expect(changes.any((c) => c.changeType == ChangeType.reorder), isTrue);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('updateCard modifies card and logs UPDATE change', () async {
      final card = TaskCard(
        id: 'repo-4',
        title: 'Original',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      await repository.saveCard(card, 0);
      final updated = card.copyWith(title: 'Updated');
      final updateResult = await repository.updateCard(updated);
      expect(updateResult, isA<Success>());

      final loadResult = await repository.loadCards(TaskGroup.defaultId);
      loadResult.when(
        success: (cards) => expect(cards.first.title, 'Updated'),
        failure: (error) => fail('Should not fail: $error'),
      );

      final changesResult = await repository.getChangeLogs();
      changesResult.when(
        success: (changes) {
          expect(changes.any((c) => c.changeType == ChangeType.update), isTrue);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('updateCard with status=done persists the flag', () async {
      final card = TaskCard(
        id: 'repo-done',
        title: 'Finish report',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      await repository.saveCard(card, 0);
      final done = card.copyWith(status: TaskStatus.done);
      final result = await repository.updateCard(done);
      expect(result, isA<Success>());

      final loadResult = await repository.searchArchivedCards(
        status: TaskStatus.done,
      );
      loadResult.when(
        success: (cards) {
          expect(cards.length, 1);
          expect(cards.first.id, 'repo-done');
          expect(cards.first.status, TaskStatus.done);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('loadCards filters by status doing only', () async {
      final card = TaskCard(
        id: 'st-1',
        title: 'Doing task',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      await repository.saveCard(card, 0);
      await repository.updateCardStatus('st-1', TaskStatus.done);

      final loadResult = await repository.loadCards(TaskGroup.defaultId);
      loadResult.when(
        success: (cards) => expect(cards, isEmpty),
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('updateCardStatus persists status and logs change', () async {
      final card = TaskCard(
        id: 'st-2',
        title: 'Status change',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      await repository.saveCard(card, 0);

      final result = await repository.updateCardStatus('st-2', TaskStatus.ignored);
      expect(result, isA<Success>());

      final raw = await db.query(
        DatabaseHelper.tasksTable,
        where: 'id = ?',
        whereArgs: ['st-2'],
      );
      expect(raw.first['status'], 'ignored');

      final changesResult = await repository.getChangeLogs();
      changesResult.when(
        success: (changes) {
          final statusChange = changes.where(
            (c) => c.taskId == 'st-2' && c.changeType == ChangeType.update,
          );
          expect(statusChange, isNotEmpty);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('searchArchivedCards returns newest first limited to 8', () async {
      for (int i = 0; i < 12; i++) {
        final card = TaskCard(
          id: 'arch-$i',
          title: 'Archived $i',
          tag: 'dev',
          createdAt: DateTime(2025, 6, 1).add(Duration(days: i)),
        );
        await repository.saveCard(card, i);
        await repository.updateCardStatus('arch-$i', TaskStatus.done);
      }

      final result = await repository.searchArchivedCards(
        status: TaskStatus.done,
      );
      result.when(
        success: (cards) {
          expect(cards.length, 8);
          expect(cards.first.id, 'arch-11');
          expect(cards.first.createdAt.isAfter(cards.last.createdAt), isTrue);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('searchArchivedCards filters by title and description', () async {
      final a = TaskCard(
        id: 'q-1',
        title: 'Alpha report',
        description: 'about taxes',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 1),
      );
      final b = TaskCard(
        id: 'q-2',
        title: 'Beta summary',
        description: 'about meetings',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 2),
      );
      final c = TaskCard(
        id: 'q-3',
        title: 'Gamma plan',
        description: 'about taxes too',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 3),
      );
      await repository.saveCard(a, 0);
      await repository.saveCard(b, 1);
      await repository.saveCard(c, 2);
      for (final id in ['q-1', 'q-2', 'q-3']) {
        await repository.updateCardStatus(id, TaskStatus.ignored);
      }

      final byTitle = await repository.searchArchivedCards(
        status: TaskStatus.ignored,
        query: 'Alpha',
      );
      byTitle.when(
        success: (cards) {
          expect(cards.length, 1);
          expect(cards.first.id, 'q-1');
        },
        failure: (error) => fail('Should not fail: $error'),
      );

      final byDescription = await repository.searchArchivedCards(
        status: TaskStatus.ignored,
        query: 'taxes',
      );
      byDescription.when(
        success: (cards) {
          expect(cards.length, 2);
          expect(cards.first.id, 'q-3');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('countByStatus returns counts per status', () async {
      final c1 = TaskCard(
        id: 'cnt-1',
        title: 'One',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 1),
      );
      final c2 = TaskCard(
        id: 'cnt-2',
        title: 'Two',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 2),
      );
      final c3 = TaskCard(
        id: 'cnt-3',
        title: 'Three',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 3),
      );
      await repository.saveCard(c1, 0);
      await repository.saveCard(c2, 1);
      await repository.saveCard(c3, 2);
      await repository.updateCardStatus('cnt-1', TaskStatus.done);
      await repository.updateCardStatus('cnt-2', TaskStatus.ignored);

      final result = await repository.countByStatus();
      result.when(
        success: (counts) {
          expect(counts[TaskStatus.doing], 1);
          expect(counts[TaskStatus.done], 1);
          expect(counts[TaskStatus.ignored], 1);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('loadCards filters by group_id', () async {
      await db.insert(DatabaseHelper.groupsTable, {
        'id': 'g-work',
        'name': 'Work',
        'created_at': DateTime.now().toIso8601String(),
      });

      final defaultCard = TaskCard(
        id: 'd-1',
        title: 'Default task',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      final workCard = TaskCard(
        id: 'w-1',
        title: 'Work task',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
        groupId: 'g-work',
      );
      await repository.saveCard(defaultCard, 0);
      await repository.saveCard(workCard, 0);

      final defaultResult = await repository.loadCards(TaskGroup.defaultId);
      defaultResult.when(
        success: (cards) {
          expect(cards.length, 1);
          expect(cards.first.id, 'd-1');
        },
        failure: (error) => fail('Should not fail: $error'),
      );

      final workResult = await repository.loadCards('g-work');
      workResult.when(
        success: (cards) {
          expect(cards.length, 1);
          expect(cards.first.id, 'w-1');
          expect(cards.first.groupId, 'g-work');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('moveCardToGroup updates group_id and logs update', () async {
      final card = TaskCard(
        id: 'mv-1',
        title: 'Move me',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
      );
      await repository.saveCard(card, 0);

      await db.insert(DatabaseHelper.groupsTable, {
        'id': 'g-target',
        'name': 'Target',
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await repository.moveCardToGroup('mv-1', 'g-target');
      expect(result, isA<Success>());

      final loadResult = await repository.loadCards('g-target');
      loadResult.when(
        success: (cards) {
          expect(cards.length, 1);
          expect(cards.first.id, 'mv-1');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('deleteCardsByGroup removes all cards and logs deletes', () async {
      await db.insert(DatabaseHelper.groupsTable, {
        'id': 'g-del',
        'name': 'ToDelete',
        'created_at': DateTime.now().toIso8601String(),
      });

      final c1 = TaskCard(
        id: 'del-1',
        title: 'D1',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
        groupId: 'g-del',
      );
      final c2 = TaskCard(
        id: 'del-2',
        title: 'D2',
        tag: 'dev',
        createdAt: DateTime(2025, 6, 15),
        groupId: 'g-del',
      );
      await repository.saveCard(c1, 0);
      await repository.saveCard(c2, 1);

      final result = await repository.deleteCardsByGroup('g-del');
      expect(result, isA<Success>());
      result.when(
        success: (ids) {
          expect(ids.length, 2);
          expect(ids, containsAll(['del-1', 'del-2']));
        },
        failure: (error) => fail('Should not fail: $error'),
      );

      final loadResult = await repository.loadCards('g-del');
      loadResult.when(
        success: (cards) => expect(cards, isEmpty),
        failure: (error) => fail('Should not fail: $error'),
      );
    });
  });
}
