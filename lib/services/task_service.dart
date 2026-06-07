// services/task_service.dart
// Xử lý toàn bộ logic CRUD cho công việc/lịch trình

import '../database/database_helper.dart';
import '../models/task.dart';

class TaskService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Lấy toàn bộ công việc (theo ngày, sau đó theo priority)
  Future<List<Task>> getAllTasks() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      orderBy: 'date ASC, priority DESC, time ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Lấy công việc theo ngày cụ thể
  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await _dbHelper.database;
    // Lấy các task trong ngày đó (bỏ qua giờ/phút/giây)
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      where: "date LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: 'priority DESC, time ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Lấy công việc hôm nay
  Future<List<Task>> getTodayTasks() async {
    return getTasksByDate(DateTime.now());
  }

  /// Lấy công việc sắp tới (từ hôm nay đến 7 ngày tới)
  Future<List<Task>> getUpcomingTasks() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final maps = await db.query(
      DatabaseHelper.tableTasks,
      where: 'date >= ? AND date < ? AND completed = 0',
      whereArgs: [
        today.toIso8601String(),
        nextWeek.toIso8601String(),
      ],
      orderBy: 'date ASC, priority DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Lấy task theo ID
  Future<Task?> getTaskById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  /// Tạo công việc mới
  Future<Task> createTask(Task task) async {
    final db = await _dbHelper.database;
    final id = await db.insert(DatabaseHelper.tableTasks, task.toMap());
    return task.copyWith(id: id);
  }

  /// Cập nhật công việc
  Future<void> updateTask(Task task) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Xóa công việc theo ID
  Future<void> deleteTask(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle trạng thái hoàn thành
  Future<void> toggleComplete(Task task) async {
    await updateTask(task.copyWith(completed: !task.completed));
  }

  /// Thống kê: đếm task hôm nay
  Future<Map<String, int>> getTodayStats() async {
    final todayTasks = await getTodayTasks();
    final completed = todayTasks.where((t) => t.completed).length;
    return {
      'total': todayTasks.length,
      'completed': completed,
      'pending': todayTasks.length - completed,
    };
  }

  /// Đếm tổng số task
  Future<int> getTaskCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTasks}',
    );
    return result.first['count'] as int;
  }
}
