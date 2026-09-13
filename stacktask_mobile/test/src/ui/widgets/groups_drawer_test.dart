import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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
import 'package:stacktask_mobile/src/ui/widgets/groups_drawer.dart';

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

Future<StackViewModel> _createViewModel(Database db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final stateService = StateService(prefs);
  stateService.register<MainState>(MainState.fromJson);
  final repository = StackRepository(database: db);
  final groupRepository = GroupRepository(
    database: db,
    stackRepository: repository,
  );
  final vm = StackViewModel(
    repository: repository,
    groupRepository: groupRepository,
    stateService: stateService,
    service: StackService(),
    groupService: TaskGroupService(),
  );
  await vm.bootstrap();
  return vm;
}

Widget _wrapDrawer(StackViewModel vm) {
  return ChangeNotifierProvider.value(
    value: vm,
    child: const MaterialApp(
      home: Scaffold(body: GroupsDrawer()),
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GroupsDrawer', () {
    late StackViewModel viewModel;
    late Database db;

    setUp(() async {
      db = await _createTestDatabase();
      viewModel = await _createViewModel(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders group rows and fixed status buttons', (tester) async {
      await tester.runAsync(() async {
        await viewModel.addGroup('Work');
      });
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
      expect(find.text('IGNORED'), findsOneWidget);
      expect(find.text('New Group'), findsOneWidget);
    });

    testWidgets('tapping DONE enters the done archive', (tester) async {
      await tester.runAsync(() async {
        await viewModel.addCard(title: 'Card 1', tag: 'dev');
        await viewModel.markCardAsDone(0);
        await viewModel.addCard(title: 'Card 2', tag: 'dev');
        await viewModel.ignoreCardAt(0);
      });
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DONE'));
      await tester.pump();

      expect(viewModel.isArchiveMode, isTrue);
      expect(viewModel.archiveStatus, TaskStatus.done);
    });

    testWidgets('tapping IGNORED enters the ignored archive', (tester) async {
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(find.text('IGNORED'));
      await tester.pump();

      expect(viewModel.isArchiveMode, isTrue);
      expect(viewModel.archiveStatus, TaskStatus.ignored);
    });

    testWidgets('tapping a group exits archive mode', (tester) async {
      await tester.runAsync(() async {
        await viewModel.addCard(title: 'Card 1', tag: 'dev');
        await viewModel.markCardAsDone(0);
        await viewModel.openArchive(TaskStatus.done);
      });
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Default'));
      await tester.pump();

      expect(viewModel.isArchiveMode, isFalse);
      expect(viewModel.selectedGroupId, TaskGroup.defaultId);
    });

    testWidgets('status buttons show counts', (tester) async {
      await tester.runAsync(() async {
        await viewModel.addCard(title: 'One', tag: 'dev');
        await viewModel.markCardAsDone(0);
        await viewModel.addCard(title: 'Two', tag: 'dev');
        await viewModel.ignoreCardAt(0);
      });
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      final doneButton = find.ancestor(
        of: find.text('DONE'),
        matching: find.byType(InkWell),
      );
      expect(
        find.descendant(of: doneButton, matching: find.text('1')),
        findsOneWidget,
      );

      final ignoredButton = find.ancestor(
        of: find.text('IGNORED'),
        matching: find.byType(InkWell),
      );
      expect(
        find.descendant(of: ignoredButton, matching: find.text('1')),
        findsOneWidget,
      );
    });
  });
}