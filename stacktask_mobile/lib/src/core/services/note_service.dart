import 'package:stacktask_mobile/src/core/models/note.dart';

class NoteService {
  final List<Note> _notes = [];

  List<Note> get all => List.unmodifiable(_notes);

  int get count => _notes.length;

  bool get isEmpty => _notes.isEmpty;

  Note? byId(String id) {
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  void replaceAll(List<Note> notes) {
    _notes
      ..clear()
      ..addAll(notes);
  }

  void add(Note note) {
    _notes.insert(0, note);
  }

  void update(Note note) {
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i < 0) return;
    _notes[i] = note;
  }

  void moveTo(int from, int to) {
    if (from < 0 || from >= _notes.length) return;
    if (to < 0 || to >= _notes.length) return;
    final note = _notes.removeAt(from);
    _notes.insert(to, note);
  }

  void remove(String id) {
    _notes.removeWhere((n) => n.id == id);
  }

  void clear() {
    _notes.clear();
  }
}
