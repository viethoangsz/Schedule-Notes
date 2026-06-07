import '../database/database_helper.dart';
import '../models/task.dart';

class TaskService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Task>> getAllTasks() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      orderBy: 'date ASC, priority DESC, time ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      where: "date LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: 'priority DESC, time ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTodayTasks() async {
    return getTasksByDate(DateTime.now());
  }

  Future<List<Task>> getTasksByMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date ASC, priority DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<Set<String>> getDatesWithTasks(int year, int month) async {
    final tasks = await getTasksByMonth(year, month);
    return tasks.map((t) => t.date.toIso8601String().substring(0, 10)).toSet();
  }

  Future<List<Task>> getUpcomingTasks() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      where: 'date >= ? AND date < ? AND completed = 0',
      whereArgs: [today.toIso8601String(), nextWeek.toIso8601String()],
      orderBy: 'date ASC, priority DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> searchTasks(String query) async {
    if (query.trim().isEmpty) return getAllTasks();
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTasks,
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date ASC, priority DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

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

  Future<Task> createTask(Task task) async {
    final db = await _dbHelper.database;
    final id = await db.insert(DatabaseHelper.tableTasks, task.toMap());
    return task.copyWith(id: id);
  }

  Future<void> updateTask(Task task) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableTasks, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleComplete(Task task) async {
    await updateTask(task.copyWith(completed: !task.completed));
  }

  Future<Map<String, int>> getTodayStats() async {
    final todayTasks = await getTodayTasks();
    final completed = todayTasks.where((t) => t.completed).length;
    return {
      'total': todayTasks.length,
      'completed': completed,
      'pending': todayTasks.length - completed,
    };
  }

  Future<Map<String, int>> getOverallStats() async {
    final db = await _dbHelper.database;
    final total = (await db.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableTasks}')).first['c'] as int;
    final completed = (await db.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableTasks} WHERE completed = 1')).first['c'] as int;
    return {'total': total, 'completed': completed, 'pending': total - completed};
  }

  Future<int> getTaskCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTasks}');
    return result.first['count'] as int;
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableTasks);
  }
}
