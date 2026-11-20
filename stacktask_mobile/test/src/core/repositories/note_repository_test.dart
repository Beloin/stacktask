import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/note.dart';
import 'package:stacktask_mobile/src/core/models/task_group.dart';
import 'package:stacktask_mobile/src/core/repositories/note_repository.dart';
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

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NoteRepository', () {
    late Database db;
    late NoteRepository repository;

    setUp(() async {
      db = await _createTestDatabase();
      repository = NoteRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    Note makeNote(
      String id,
      String groupId,
      DateTime createdAt, {
      int position = 0,
    }) {
      return Note(
        id: id,
        title: 'Note $id',
        description: 'Description $id',
        groupId: groupId,
        createdAt: createdAt,
        position: position,
      );
    }

    Future<void> insertNote(Note note) async {
      await db.insert(DatabaseHelper.notesTable, note.toMap());
    }

    test('loadNotes filters by group and orders by position', () async {
      await insertNote(
        makeNote('n-1', TaskGroup.defaultId, DateTime(2025, 1, 1), position: 0),
      );
      await insertNote(
        makeNote('n-2', 'g-2', DateTime(2025, 1, 2), position: 0),
      );
      await insertNote(
        makeNote('n-3', TaskGroup.defaultId, DateTime(2025, 1, 3), position: 1),
      );

      final result = await repository.loadNotes(TaskGroup.defaultId);
      expect(result, isA<Success>());
      result.when(
        success: (notes) {
          expect(notes.length, 2);
          expect(notes.first.id, 'n-1');
          expect(notes.last.id, 'n-3');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('addNote inserts a new note and trims title', () async {
      final result = await repository.addNote(
        groupId: TaskGroup.defaultId,
        title: '  Groceries  ',
        description: '  Milk and eggs  ',
      );
      expect(result, isA<Success>());
      result.when(
        success: (note) {
          expect(note.title, 'Groceries');
          expect(note.description, 'Milk and eggs');
          expect(note.groupId, TaskGroup.defaultId);
          expect(note.position, 0);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('addNote rejects empty titles', () async {
      final result = await repository.addNote(
        groupId: TaskGroup.defaultId,
        title: '   ',
      );
      expect(result, isA<Failure>());
      result.when(
        success: (_) => fail('Should not succeed'),
        failure: (error) => expect(error.message, contains('title')),
      );
    });

    test('addNote puts the new note at position 0 and shifts existing', () async {
      await insertNote(
        makeNote('n-1', TaskGroup.defaultId, DateTime(2025, 1, 1), position: 0),
      );
      final added = await repository.addNote(
        groupId: TaskGroup.defaultId,
        title: 'New top',
      );
      added.when(
        success: (note) => expect(note.position, 0),
        failure: (error) => fail('Should not fail: $error'),
      );

      final load = await repository.loadNotes(TaskGroup.defaultId);
      load.when(
        success: (notes) {
          expect(notes.length, 2);
          expect(notes.first.title, 'New top');
          expect(notes.last.id, 'n-1');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('syncNotePositions renumbers notes to the given order', () async {
      await insertNote(
        makeNote('n-1', TaskGroup.defaultId, DateTime(2025, 1, 1), position: 0),
      );
      await insertNote(
        makeNote('n-2', TaskGroup.defaultId, DateTime(2025, 1, 2), position: 1),
      );
      await insertNote(
        makeNote('n-3', TaskGroup.defaultId, DateTime(2025, 1, 3), position: 2),
      );

      final reordered = [
        makeNote('n-3', TaskGroup.defaultId, DateTime(2025, 1, 3)),
        makeNote('n-1', TaskGroup.defaultId, DateTime(2025, 1, 1)),
        makeNote('n-2', TaskGroup.defaultId, DateTime(2025, 1, 2)),
      ];
      final result = await repository.syncNotePositions(reordered);
      expect(result, isA<Success>());

      final load = await repository.loadNotes(TaskGroup.defaultId);
      load.when(
        success: (notes) {
          expect(notes.map((n) => n.id).toList(), ['n-3', 'n-1', 'n-2']);
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('updateNote updates an existing note', () async {
      await insertNote(
        makeNote('n-1', TaskGroup.defaultId, DateTime(2025, 1, 1)),
      );
      final result = await repository.updateNote(
        makeNote('n-1', TaskGroup.defaultId, DateTime(2025, 1, 1))
            .copyWith(title: 'Updated', description: 'Changed'),
      );
      expect(result, isA<Success>());

      final load = await repository.loadNotes(TaskGroup.defaultId);
      load.when(
        success: (notes) {
          expect(notes.length, 1);
          expect(notes.first.title, 'Updated');
          expect(notes.first.description, 'Changed');
        },
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('updateNote returns failure when note not found', () async {
      final result = await repository.updateNote(
        makeNote('missing', TaskGroup.defaultId, DateTime(2025, 1, 1)),
      );
      expect(result, isA<Failure>());
      result.when(
        success: (_) => fail('Should not succeed'),
        failure: (error) => expect(error.message, contains('not found')),
      );
    });

    test('deleteNote removes the note', () async {
      await insertNote(
        makeNote('n-1', TaskGroup.defaultId, DateTime(2025, 1, 1)),
      );
      final result = await repository.deleteNote('n-1');
      expect(result, isA<Success>());

      final load = await repository.loadNotes(TaskGroup.defaultId);
      load.when(
        success: (notes) => expect(notes, isEmpty),
        failure: (error) => fail('Should not fail: $error'),
      );
    });

    test('deleteNotesByGroup removes only that group', () async {
      await insertNote(
        makeNote('n-1', TaskGroup.defaultId, DateTime(2025, 1, 1)),
      );
      await insertNote(makeNote('n-2', 'g-2', DateTime(2025, 1, 2)));
      await insertNote(makeNote('n-3', 'g-2', DateTime(2025, 1, 3)));

      final result = await repository.deleteNotesByGroup('g-2');
      expect(result, isA<Success>());

      final remaining = await repository.loadNotes(TaskGroup.defaultId);
      remaining.when(
        success: (notes) {
          expect(notes.length, 1);
          expect(notes.first.id, 'n-1');
        },
        failure: (error) => fail('Should not fail: $error'),
      );

      final deleted = await repository.loadNotes('g-2');
      deleted.when(
        success: (notes) => expect(notes, isEmpty),
        failure: (error) => fail('Should not fail: $error'),
      );
    });
  });
}
