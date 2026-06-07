import '../database/database_helper.dart';
import '../models/note.dart';

class NoteService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Note>> getAllNotes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) return getAllNotes();
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getNotesByTag(String tag) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<String>> getAllTags() async {
    final notes = await getAllNotes();
    final tagSet = <String>{};
    for (final note in notes) {
      tagSet.addAll(note.tags);
    }
    final sorted = tagSet.toList()..sort();
    return sorted;
  }

  Future<List<Note>> getPinnedNotes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'is_pinned = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNoteById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<Note> createNote(Note note) async {
    final db = await _dbHelper.database;
    final id = await db.insert(DatabaseHelper.tableNotes, note.toMap());
    return note.copyWith(id: id);
  }

  Future<void> updateNote(Note note) async {
    final db = await _dbHelper.database;
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await db.update(
      DatabaseHelper.tableNotes,
      updatedNote.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableNotes, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> togglePin(Note note) async {
    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  Future<int> getNoteCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${DatabaseHelper.tableNotes}');
    return result.first['count'] as int;
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableNotes);
  }
}
