import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/models/note.dart';
import 'package:stacktask_mobile/src/core/result/result_barrel.dart';

class NoteRepository {
  final Database _db;
  final Uuid _uuid;

  NoteRepository({required Database database, Uuid? uuid})
      : _db = database,
        _uuid = uuid ?? const Uuid();

  AsyncResult<List<Note>, ErrorCode> loadNotes(String groupId) async {
    try {
      final maps = await _db.query(
        DatabaseHelper.notesTable,
        where: 'group_id = ?',
        whereArgs: [groupId],
        orderBy: 'position ASC',
      );
      return Success(maps.map((m) => Note.fromMap(m)).toList());
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to load notes: $e'));
    }
  }

  AsyncResult<Note, ErrorCode> addNote({
    required String groupId,
    required String title,
    String description = '',
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return Failure(ErrorCode.fromString(message: 'Note title cannot be empty'));
    }
    try {
      await _db.rawUpdate(
        'UPDATE ${DatabaseHelper.notesTable} '
        'SET position = position + 1 WHERE group_id = ?',
        [groupId],
      );
      final note = Note(
        id: _uuid.v4(),
        title: trimmed,
        description: description.trim(),
        groupId: groupId,
        createdAt: DateTime.now(),
        position: 0,
      );
      await _db.insert(DatabaseHelper.notesTable, note.toMap());
      return Success(note);
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to add note: $e'));
    }
  }

  AsyncResult<void, ErrorCode> updateNote(Note note) async {
    try {
      final updated = await _db.update(
        DatabaseHelper.notesTable,
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
      if (updated == 0) {
        return Failure(ErrorCode.fromString(message: 'Note not found'));
      }
      return const Success(null);
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to update note: $e'));
    }
  }

  AsyncResult<void, ErrorCode> deleteNote(String id) async {
    try {
      await _db.delete(
        DatabaseHelper.notesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Success(null);
    } catch (e) {
      return Failure(ErrorCode.fromString(message: 'Failed to delete note: $e'));
    }
  }

  AsyncResult<void, ErrorCode> deleteNotesByGroup(String groupId) async {
    try {
      await _db.delete(
        DatabaseHelper.notesTable,
        where: 'group_id = ?',
        whereArgs: [groupId],
      );
      return const Success(null);
    } catch (e) {
      return Failure(
        ErrorCode.fromString(message: 'Failed to delete notes: $e'),
      );
    }
  }

  AsyncResult<void, ErrorCode> syncNotePositions(List<Note> notes) async {
    try {
      final batch = _db.batch();
      for (int i = 0; i < notes.length; i++) {
        batch.update(
          DatabaseHelper.notesTable,
          {'position': i},
          where: 'id = ?',
          whereArgs: [notes[i].id],
        );
      }
      await batch.commit(noResult: true);
      return const Success(null);
    } catch (e) {
      return Failure(
        ErrorCode.fromString(message: 'Failed to reorder notes: $e'),
      );
    }
  }
}
