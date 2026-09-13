import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/models/task_status.dart';
import 'package:stacktask_mobile/src/core/repositories/group_repository.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/services/stack_service.dart';
import 'package:stacktask_mobile/src/core/services/task_group_service.dart';
import 'package:stacktask_mobile/src/core/state/main_state.dart';
import 'package:stacktask_mobile/src/core/state/state_service.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
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

  group('StackViewModel', () {
    late StackViewModel viewModel;
    late Database db;
    late StateService stateService;
    late StackRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      stateService = StateService(prefs);
      stateService.register<MainState>(MainState.fromJson);

      db = await _createTestDatabase();
      repository = StackRepository(database: db);
      final groupRepository = GroupRepository(
        database: db,
        stackRepository: repository,
      );
      viewModel = StackViewModel(
        repository: repository,
        groupRepository: groupRepository,
        stateService: stateService,
        service: StackService(),
        groupService: TaskGroupService(),
      );
      await viewModel.bootstrap();
    });

    tearDown(() async {
      await db.close();
    });

    test('starts empty after bootstrap (no tasks, one default group)', () {
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.count, 0);
      expect(viewModel.frontCard, isNull);
      expect(viewModel.isModalOpen, isFalse);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.groups.length, 1);
      expect(viewModel.groups.first.id, TaskGroup.defaultId);
      expect(viewModel.selectedGroupId, TaskGroup.defaultId);
      expect(viewModel.selectedGroupName, TaskGroup.defaultName);
    });

    test('addCard adds card to front and notifies listeners', () async {
      bool notified = false;
      viewModel.addListener(() => notified = true);
      await viewModel.addCard(title: 'Test task', tag: 'dev');
      expect(viewModel.count, 1);
      expect(viewModel.frontCard?.title, 'Test task');
      expect(viewModel.frontCard?.groupId, TaskGroup.defaultId);
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

    test('markCardAsDone removes card from active stack and marks it done',
        () async {
      await viewModel.addCard(title: 'To complete', tag: 'dev');
      expect(viewModel.count, 1);
      expect(viewModel.cards[0].status, TaskStatus.doing);
      final cardId = viewModel.cards[0].id;
      await viewModel.markCardAsDone(0);
      expect(viewModel.count, 0);
      expect(viewModel.doneCount, 1);

      final archived = await repository.searchArchivedCards(
        status: TaskStatus.done,
      );
      archived.when(
        success: (cards) {
          expect(cards.length, 1);
          expect(cards.first.id, cardId);
          expect(cards.first.status, TaskStatus.done);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('ignoreCardAt removes card from stack and marks it ignored',
        () async {
      await viewModel.addCard(title: 'To ignore', tag: 'dev');
      expect(viewModel.count, 1);
      final cardId = viewModel.cards[0].id;
      await viewModel.ignoreCardAt(0);
      expect(viewModel.count, 0);
      expect(viewModel.ignoredCount, 1);

      final archived = await repository.searchArchivedCards(
        status: TaskStatus.ignored,
      );
      archived.when(
        success: (cards) {
          expect(cards.length, 1);
          expect(cards.first.id, cardId);
          expect(cards.first.status, TaskStatus.ignored);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('removeCardAt removes card at given index', () async {
      await viewModel.addCard(title: 'A', tag: 'dev');
      await viewModel.addCard(title: 'B', tag: 'dev');
      await viewModel.addCard(title: 'C', tag: 'dev');
      await viewModel.removeCardAt(1);
      expect(viewModel.count, 2);
    });

    test('markCardAsDone on invalid index is a no-op', () async {
      await viewModel.addCard(title: 'X', tag: 'dev');
      await viewModel.markCardAsDone(99);
      expect(viewModel.count, 1);
      await viewModel.markCardAsDone(-1);
      expect(viewModel.count, 1);
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

    test('updateCard changes fields in place and keeps id', () async {
      await viewModel.addCard(
        title: 'Original',
        tag: 'dev',
        description: 'old',
        priority: 1,
      );
      final originalId = viewModel.cards[0].id;
      final originalCreatedAt = viewModel.cards[0].createdAt;
      await viewModel.updateCard(
        id: originalId,
        title: 'Edited',
        tag: 'review',
        description: 'new',
        priority: 4,
      );
      expect(viewModel.cards[0].title, 'Edited');
      expect(viewModel.cards[0].tag, 'review');
      expect(viewModel.cards[0].description, 'new');
      expect(viewModel.cards[0].priority, 4);
      expect(viewModel.cards[0].id, originalId);
      expect(viewModel.cards[0].createdAt, originalCreatedAt);
    });

    test('updateCard with unknown id is a no-op', () async {
      await viewModel.addCard(title: 'X', tag: 'dev');
      await viewModel.updateCard(
        id: 'does-not-exist',
        title: 'whatever',
        tag: 'dev',
      );
      expect(viewModel.cards[0].title, 'X');
    });

    group('moveCardToGroup', () {
      test('moves a card to another group and removes it from active stack',
          () async {
        await viewModel.addCard(title: 'Movable', tag: 'dev');
        await viewModel.addGroup('Work');
        final targetId = viewModel.selectedGroupId!;
        expect(viewModel.selectedGroupName, 'Work');
        expect(viewModel.count, 0);

        await viewModel.selectGroup(TaskGroup.defaultId);
        expect(viewModel.count, 1);
        final cardId = viewModel.cards.first.id;
        final defaultCountBefore =
            viewModel.groupTaskCounts[TaskGroup.defaultId];

        final moved = await viewModel.moveCardToGroup(cardId, targetId);
        expect(moved, isTrue);
        expect(viewModel.cards.any((c) => c.id == cardId), isFalse);
        expect(viewModel.groupTaskCounts[TaskGroup.defaultId],
            defaultCountBefore! - 1);
        expect(viewModel.groupTaskCounts[targetId], 1);
      });

      test('keeps card visible when moving out of inactive group', () async {
        await viewModel.addCard(title: 'Stay', tag: 'dev');
        await viewModel.addGroup('Work');
        final targetId = viewModel.selectedGroupId!;
        await viewModel.selectGroup(TaskGroup.defaultId);
        final cardId = viewModel.cards.first.id;

        final moved = await viewModel.moveCardToGroup(cardId, targetId);
        expect(moved, isTrue);
        expect(viewModel.cards.any((c) => c.id == cardId), isFalse);
      });

      test('returns false when card is not in the active stack', () async {
        await viewModel.addGroup('Work');
        await viewModel.selectGroup(TaskGroup.defaultId);
        final moved = await viewModel.moveCardToGroup('missing-id', 'any');
        expect(moved, isFalse);
      });

      test('returns false when target is the current group', () async {
        await viewModel.addCard(title: 'X', tag: 'dev');
        final cardId = viewModel.cards.first.id;
        final moved =
            await viewModel.moveCardToGroup(cardId, TaskGroup.defaultId);
        expect(moved, isFalse);
        expect(viewModel.count, 1);
      });
    });

    group('groups', () {
      test('addGroup creates a new group and selects it', () async {
        await viewModel.addGroup('Work');
        expect(viewModel.groups.length, 2);
        expect(viewModel.selectedGroupId, isNot(TaskGroup.defaultId));
        expect(viewModel.selectedGroupName, 'Work');
      });

      test('addGroup surfaces unique-name failures', () async {
        await viewModel.addGroup('Work');
        viewModel.clearError();
        await viewModel.addGroup('Work');
        expect(viewModel.hasError, isTrue);
        expect(viewModel.lastError?.message, contains('Work'));
      });

      test('selectGroup switches the visible stack', () async {
        await viewModel.addCard(title: 'Default task', tag: 'dev');
        await viewModel.addGroup('Work');
        await viewModel.addCard(title: 'Work task', tag: 'dev');
        expect(viewModel.count, 1);
        expect(viewModel.frontCard?.title, 'Work task');

        await viewModel.selectGroup(TaskGroup.defaultId);
        expect(viewModel.count, 1);
        expect(viewModel.frontCard?.title, 'Default task');
      });

      test('renameGroup updates the service name', () async {
        await viewModel.addGroup('Work');
        final id = viewModel.selectedGroupId!;
        await viewModel.renameGroup(id, 'Personal');
        expect(viewModel.selectedGroupName, 'Personal');
      });

      test('renameGroup refuses to rename Default', () async {
        viewModel.clearError();
        await viewModel.renameGroup(TaskGroup.defaultId, 'Renamed');
        expect(viewModel.hasError, isTrue);
        expect(viewModel.selectedGroupName, TaskGroup.defaultName);
      });

      test('deleteGroupCascade removes group and its tasks', () async {
        await viewModel.addGroup('Work');
        final id = viewModel.selectedGroupId!;
        await viewModel.addCard(title: 'Work task', tag: 'dev');
        expect(viewModel.count, 1);

        final removed = await viewModel.deleteGroupCascade(id);
        expect(removed, 1);
        expect(viewModel.groups.any((g) => g.id == id), isFalse);
        expect(viewModel.selectedGroupId, TaskGroup.defaultId);
      });

      test('deleteGroupCascade refuses to delete Default', () async {
        viewModel.clearError();
        final removed = await viewModel.deleteGroupCascade(TaskGroup.defaultId);
        expect(removed, isNull);
        expect(viewModel.hasError, isTrue);
        expect(viewModel.groups.any((g) => g.id == TaskGroup.defaultId), isTrue);
      });

      test('groupTaskCounts reflects current counts', () async {
        await viewModel.addCard(title: 'A', tag: 'dev');
        await viewModel.addCard(title: 'B', tag: 'dev');
        expect(viewModel.groupTaskCounts[TaskGroup.defaultId], 2);
        await viewModel.addGroup('Work');
        await viewModel.addCard(title: 'W1', tag: 'dev');
        expect(viewModel.groupTaskCounts[TaskGroup.defaultId], 2);
        expect(viewModel.groupTaskCounts[viewModel.selectedGroupId!], 1);
      });
    });

    group('persistence', () {
      test('restores selected group on relaunch via initialSelectedGroupId',
          () async {
        await viewModel.addGroup('Work');
        final workId = viewModel.selectedGroupId!;
        expect(viewModel.selectedGroupName, 'Work');

        // Simulate relaunch: new VM with the restored initialSelectedGroupId.
        final repository2 = StackRepository(database: db);
        final groupRepository2 = GroupRepository(
          database: db,
          stackRepository: repository2,
        );
        final vm2 = StackViewModel(
          repository: repository2,
          groupRepository: groupRepository2,
          stateService: stateService,
          initialSelectedGroupId: stateService.get<MainState>()?.group,
        );
        await vm2.bootstrap();
        expect(vm2.selectedGroupId, workId);
        expect(vm2.selectedGroupName, 'Work');
      });
    });

    group('archive mode', () {
      test('openArchive loads newest cards first', () async {
        await viewModel.addCard(title: 'Old card', tag: 'dev');
        final oldId = viewModel.cards[0].id;
        await viewModel.markCardAsDone(0);
        await viewModel.addCard(title: 'New card', tag: 'dev');
        final newId = viewModel.cards[0].id;
        await viewModel.markCardAsDone(0);

        await viewModel.openArchive(TaskStatus.done);
        expect(viewModel.isArchiveMode, isTrue);
        expect(viewModel.archiveStatus, TaskStatus.done);
        expect(viewModel.selectedGroupName, 'DONE');
        expect(viewModel.archivedCards.length, 2);
        expect(viewModel.archivedCards.first.id, newId);
        expect(viewModel.archivedCards.last.id, oldId);
      });

      test('openArchive limits to 8 cards', () async {
        for (int i = 0; i < 12; i++) {
          await viewModel.addCard(title: 'Task $i', tag: 'dev');
          await viewModel.markCardAsDone(0);
        }
        await viewModel.openArchive(TaskStatus.done);
        expect(viewModel.archivedCards.length, 8);
        expect(viewModel.archivedCards.first.title, 'Task 11');
      });

      test('selectGroup exits archive mode', () async {
        await viewModel.addCard(title: 'X', tag: 'dev');
        await viewModel.markCardAsDone(0);
        await viewModel.openArchive(TaskStatus.done);
        expect(viewModel.isArchiveMode, isTrue);

        await viewModel.selectGroup(TaskGroup.defaultId);
        expect(viewModel.isArchiveMode, isFalse);
        expect(viewModel.archiveStatus, isNull);
        expect(viewModel.archivedCards, isEmpty);
        expect(viewModel.selectedGroupName, TaskGroup.defaultName);
      });

      test('updateArchiveSearch filters after debounce', () async {
        await viewModel.addCard(
          title: 'Alpha task',
          tag: 'dev',
          description: 'about taxes',
        );
        await viewModel.markCardAsDone(0);
        await viewModel.addCard(
          title: 'Beta task',
          tag: 'dev',
          description: 'about meetings',
        );
        await viewModel.markCardAsDone(0);
        await viewModel.openArchive(TaskStatus.done);
        expect(viewModel.archivedCards.length, 2);

        await viewModel.updateArchiveSearch('Alpha');
        await Future<void>.delayed(
          StackViewModel.searchDebounce + const Duration(milliseconds: 50),
        );
        expect(viewModel.archivedCards.length, 1);
        expect(viewModel.archivedCards.first.title, 'Alpha task');

        await viewModel.updateArchiveSearch('taxes');
        await Future<void>.delayed(
          StackViewModel.searchDebounce + const Duration(milliseconds: 50),
        );
        expect(viewModel.archivedCards.length, 1);
        expect(viewModel.archivedCards.first.title, 'Alpha task');
      });

      test('updateArchiveSearch coalesces rapid keystrokes', () async {
        await viewModel.addCard(title: 'Alpha task', tag: 'dev');
        await viewModel.markCardAsDone(0);
        await viewModel.openArchive(TaskStatus.done);
        expect(viewModel.archivedCards.length, 1);

        bool notified = false;
        viewModel.addListener(() => notified = true);
        await viewModel.updateArchiveSearch('A');
        await viewModel.updateArchiveSearch('Al');
        await viewModel.updateArchiveSearch('Alp');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(notified, isFalse);

        await Future<void>.delayed(
          StackViewModel.searchDebounce + const Duration(milliseconds: 50),
        );
        expect(notified, isTrue);
        expect(viewModel.archivedCards.length, 1);
      });

      test('closeArchive returns to the selected group stack', () async {
        await viewModel.addCard(title: 'Active', tag: 'dev');
        await viewModel.addCard(title: 'Done one', tag: 'dev');
        final doneId = viewModel.cards[0].id;
        await viewModel.markCardAsDone(0);
        expect(viewModel.count, 1);

        await viewModel.openArchive(TaskStatus.done);
        await viewModel.closeArchive();
        expect(viewModel.isArchiveMode, isFalse);
        expect(viewModel.count, 1);
        expect(viewModel.frontCard?.title, 'Active');
        expect(viewModel.doneCount, 1);
        expect(doneId, isNotEmpty);
      });

      test('selectedGroupName reflects ignored archive', () async {
        await viewModel.addCard(title: 'Skip me', tag: 'dev');
        await viewModel.ignoreCardAt(0);
        await viewModel.openArchive(TaskStatus.ignored);
        expect(viewModel.selectedGroupName, 'IGNORED');
        expect(viewModel.archivedCards.length, 1);
      });

      test('loadCards loads only doing cards for the group', () async {
        await viewModel.addCard(title: 'Stays', tag: 'dev');
        await viewModel.addCard(title: 'Completes', tag: 'dev');
        await viewModel.markCardAsDone(0);
        await viewModel.loadCards();
        expect(viewModel.count, 1);
        expect(viewModel.frontCard?.title, 'Stays');
      });
    });
  });
}
