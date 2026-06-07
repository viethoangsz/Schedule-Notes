// providers/task_provider.dart
// Quản lý state cho công việc/lịch trình sử dụng Provider pattern

import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();

  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  Map<String, int> _todayStats = {'total': 0, 'completed': 0, 'pending': 0};

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  Map<String, int> get todayStats => _todayStats;

  /// Tasks của ngày được chọn
  List<Task> get selectedDateTasks {
    return _tasks.where((task) {
      return task.date.year == _selectedDate.year &&
          task.date.month == _selectedDate.month &&
          task.date.day == _selectedDate.day;
    }).toList();
  }

  /// Tải tất cả tasks
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _taskService.getAllTasks();
      _todayTasks = await _taskService.getTodayTasks();
      _todayStats = await _taskService.getTodayStats();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải tasks của ngày được chọn
  Future<void> loadTasksByDate(DateTime date) async {
    _selectedDate = date;
    try {
      _tasks = await _taskService.getAllTasks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks by date: $e');
    }
  }

  /// Thay đổi ngày được chọn
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Tạo công việc mới
  Future<Task?> createTask({
    required String title,
    required String description,
    required DateTime date,
    String? time,
    Priority priority = Priority.medium,
  }) async {
    try {
      final task = Task(
        title: title,
        description: description,
        date: date,
        time: time,
        priority: priority,
      );
      final createdTask = await _taskService.createTask(task);

      // Lên lịch thông báo nếu có giờ
      if (time != null) {
        await _notificationService.scheduleTaskNotification(createdTask);
      }

      await loadTasks();
      return createdTask;
    } catch (e) {
      debugPrint('Error creating task: $e');
      return null;
    }
  }

  /// Cập nhật công việc
  Future<bool> updateTask(Task task) async {
    try {
      await _taskService.updateTask(task);

      // Hủy notification cũ và tạo mới
      await _notificationService.cancelTaskNotification(task.id!);
      if (task.time != null && !task.completed) {
        await _notificationService.scheduleTaskNotification(task);
      }

      await loadTasks();
      return true;
    } catch (e) {
      debugPrint('Error updating task: $e');
      return false;
    }
  }

  /// Xóa công việc
  Future<bool> deleteTask(int id) async {
    try {
      await _notificationService.cancelTaskNotification(id);
      await _taskService.deleteTask(id);
      await loadTasks();
      return true;
    } catch (e) {
      debugPrint('Error deleting task: $e');
      return false;
    }
  }

  /// Toggle trạng thái hoàn thành
  Future<void> toggleComplete(Task task) async {
    try {
      await _taskService.toggleComplete(task);

      // Hủy notification nếu task đã hoàn thành
      if (!task.completed && task.id != null) {
        await _notificationService.cancelTaskNotification(task.id!);
      }

      await loadTasks();
    } catch (e) {
      debugPrint('Error toggling task complete: $e');
    }
  }
}
