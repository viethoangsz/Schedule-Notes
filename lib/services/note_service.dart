// services/note_service.dart
// Xử lý toàn bộ logic CRUD cho ghi chú

import '../database/database_helper.dart';
import '../models/note.dart';

class NoteService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Lấy toàn bộ ghi chú (ghim trước, sau đó theo ngày mới nhất)
  Future<List<Note>> getAllNotes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// Tìm kiếm ghi chú theo từ khóa (title hoặc content)
  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) return getAllNotes();

    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// Lấy các ghi chú được ghim
  Future<List<Note>> getPinnedNotes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableNotes,
      where: 'is_pinned = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// Lấy ghi chú theo ID
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

  /// Tạo ghi chú mới, trả về ghi chú với ID được gán
  Future<Note> createNote(Note note) async {
    final db = await _dbHelper.database;
    final id = await db.insert(DatabaseHelper.tableNotes, note.toMap());
    return note.copyWith(id: id);
  }

  /// Cập nhật ghi chú (tự động cập nhật updatedAt)
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

  /// Xóa ghi chú theo ID
  Future<void> deleteNote(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle trạng thái ghim của ghi chú
  Future<void> togglePin(Note note) async {
    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  /// Đếm tổng số ghi chú
  Future<int> getNoteCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableNotes}',
    );
    return result.first['count'] as int;
  }
}
