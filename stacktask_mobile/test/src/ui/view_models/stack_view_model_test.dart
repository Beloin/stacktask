import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/services/stack_service.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';

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

  group('StackViewModel', () {
    late StackViewModel viewModel;

    setUp(() async {
      final db = await _createTestDatabase();
      final repository = StackRepository(database: db);
      viewModel = StackViewModel(
        repository: repository,
        service: StackService(),
      );
    });

    test('starts empty', () {
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.count, 0);
      expect(viewModel.frontCard, isNull);
      expect(viewModel.isModalOpen, isFalse);
      expect(viewModel.hasError, isFalse);
    });

    test('addCard adds card to front and notifies listeners', () async {
      bool notified = false;
      viewModel.addListener(() => notified = true);
      await viewModel.addCard(title: 'Test task', tag: 'dev');
      expect(viewModel.count, 1);
      expect(viewModel.frontCard?.title, 'Test task');
      expect(notified, isTrue);
    });

    test('addCard generates unique id', () async {
      await viewModel.addCard(title: 'Task 1', tag: 'dev');
      await viewModel.addCard(title: 'Task 2', tag: 'bug');
      expect(viewModel.cards[0].id, isNot(equals(viewModel.cards[1].id)));
    });

    test('cards beyond maxCards discard oldest', () async {
      for (int i = 0; i < StackService.maxCards + 2; i++) {
        await viewModel.addCard(title: 'Task $i', tag: 'dev');
      }
      expect(viewModel.count, StackService.maxCards);
    });

    test('dismissCard removes front card', () async {
      await viewModel.addCard(title: 'First', tag: 'dev');
      await viewModel.addCard(title: 'Second', tag: 'bug');
      await viewModel.dismissCard(SwipeDirection.left);
      expect(viewModel.count, 1);
      expect(viewModel.frontCard?.title, 'First');
    });

    test('dismissCard on empty stack does nothing', () async {
      await viewModel.dismissCard(SwipeDirection.right);
      expect(viewModel.count, 0);
    });

    test('removeCardAt removes card at given index', () async {
      await viewModel.addCard(title: 'A', tag: 'dev');
      await viewModel.addCard(title: 'B', tag: 'dev');
      await viewModel.addCard(title: 'C', tag: 'dev');
      await viewModel.removeCardAt(1);
      expect(viewModel.count, 2);
    });

    test('promoteToFront moves card to front', () async {
      await viewModel.addCard(title: 'A', tag: 'dev');
      await viewModel.addCard(title: 'B', tag: 'dev');
      await viewModel.addCard(title: 'C', tag: 'dev');
      await viewModel.promoteToFront(2);
      expect(viewModel.frontCard?.title, 'A');
    });

    test('cycleFrontToEnd moves front card to end', () async {
      await viewModel.addCard(title: 'A', tag: 'dev');
      await viewModel.addCard(title: 'B', tag: 'dev');
      await viewModel.addCard(title: 'C', tag: 'dev');
      final frontTitle = viewModel.frontCard?.title;
      await viewModel.cycleFrontToEnd();
      expect(viewModel.cards.last.title, frontTitle);
      expect(viewModel.count, 3);
    });

    test('openModal and closeModal toggle state', () {
      expect(viewModel.isModalOpen, isFalse);
      viewModel.openModal();
      expect(viewModel.isModalOpen, isTrue);
      viewModel.closeModal();
      expect(viewModel.isModalOpen, isFalse);
    });

    test('clearError resets lastError', () async {
      viewModel.clearError();
      expect(viewModel.hasError, isFalse);
      expect(viewModel.lastError, isNull);
    });

    test('moveCardTo reorders cards', () async {
      await viewModel.addCard(title: 'A', tag: 'dev');
      await viewModel.addCard(title: 'B', tag: 'dev');
      await viewModel.addCard(title: 'C', tag: 'dev');
      await viewModel.moveCardTo(2, 0);
      expect(viewModel.cards[0].title, 'A');
    });
  });
}