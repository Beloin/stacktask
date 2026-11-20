import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/repositories/group_repository.dart';
import 'package:stacktask_mobile/src/core/repositories/note_repository.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/services/stack_service.dart';
import 'package:stacktask_mobile/src/core/services/task_group_service.dart';
import 'package:stacktask_mobile/src/core/state/main_state.dart';
import 'package:stacktask_mobile/src/core/state/state_service.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
import 'package:stacktask_mobile/src/ui/widgets/notes_drawer.dart';

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
  await db.execute('''
    CREATE TABLE IF NOT EXISTS ${DatabaseHelper.notesTable} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      group_id TEXT NOT NULL,
      position INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
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
  final noteRepository = NoteRepository(database: db);
  final vm = StackViewModel(
    repository: repository,
    groupRepository: groupRepository,
    noteRepository: noteRepository,
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
      home: Scaffold(body: NotesDrawer()),
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NotesDrawer', () {
    late StackViewModel viewModel;
    late Database db;

    setUp(() async {
      db = await _createTestDatabase();
      viewModel = await _createViewModel(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders header and New Note action', (tester) async {
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('NOTES'), findsOneWidget);
      expect(find.text('New Note'), findsOneWidget);
    });

    testWidgets('shows notes for the selected group', (tester) async {
      await tester.runAsync(() async {
        await viewModel.addNote(title: 'Standup', description: 'Team sync');
      });
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Standup'), findsOneWidget);
      expect(find.text('Team sync'), findsOneWidget);
    });

    testWidgets('tapping New Note opens the editor sheet', (tester) async {
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Note'));
      await tester.pumpAndSettle();

      expect(find.text('Add Note'), findsOneWidget);
    });

    testWidgets('tapping a note opens the detail sheet', (tester) async {
      await tester.runAsync(() async {
        await viewModel.addNote(title: 'Standup', description: 'Team sync');
      });
      await tester.pumpWidget(_wrapDrawer(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Standup'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
