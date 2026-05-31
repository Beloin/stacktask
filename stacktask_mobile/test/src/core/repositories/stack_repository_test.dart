import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/change_log.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/result/result_barrel.dart';

Future<Database> _createTestDatabase() async {
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

      final loadResult = await repository.loadCards();
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
      final result = await repository.loadCards();
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

      final loadResult = await repository.loadCards();
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

      final loadResult = await repository.loadCards();
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

      final loadResult = await repository.loadCards();
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
  });
}

extension ResultWhen<S, E> on Result<S, E> {
  T when<T>({
    required T Function(S value) success,
    required T Function(E error) failure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      Failure(:final error) => failure(error),
    };
  }
}