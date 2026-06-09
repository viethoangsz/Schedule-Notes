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
  Set<String> _datesWithTasks = {};
  int _calendarYear = DateTime.now().year;
  int _calendarMonth = DateTime.now().month;

  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  Map<String, int> get todayStats => _todayStats;
  Set<String> get datesWithTasks => _datesWithTasks;
  int get calendarYear => _calendarYear;
  int get calendarMonth => _calendarMonth;

  List<Task> get selectedDateTasks {
    return _tasks.where((task) {
      return task.date.year == _selectedDate.year &&
          task.date.month == _selectedDate.month &&
          task.date.day == _selectedDate.day;
    }).toList();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _taskService.getAllTasks();
      _todayTasks = await _taskService.getTodayTasks();
      _todayStats = await _taskService.getTodayStats();
      await _loadCalendarDots();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCalendarDots() async {
    _datesWithTasks = await _taskService.getDatesWithTasks(_calendarYear, _calendarMonth);
  }

  Future<void> loadCalendarMonth(int year, int month) async {
    _calendarYear = year;
    _calendarMonth = month;
    await _loadCalendarDots();
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<Task?> createTask({
    required String title,
    required String description,
    required DateTime date,
    String? time,
    TaskPriority priority = TaskPriority.medium,
    RepeatType repeatType = RepeatType.none,
    List<int> repeatDays = const [],
  }) async {
    try {
      final task = Task(
        title: title,
        description: description,
        date: date,
        time: time,
        priority: priority,
        repeatType: repeatType,
        repeatDays: repeatDays,
      );
      final createdTask = await _taskService.createTask(task);
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

  Future<bool> updateTask(Task task) async {
    try {
      await _taskService.updateTask(task);
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

  Future<void> toggleComplete(Task task) async {
    try {
      await _taskService.toggleComplete(task);
      if (!task.completed && task.id != null) {
        await _notificationService.cancelTaskNotification(task.id!);
      } else if (task.completed && task.id != null && task.time != null) {
        final uncompleted = task.copyWith(completed: false);
        await _notificationService.scheduleTaskNotification(uncompleted);
      }
      await loadTasks();
    } catch (e) {
      debugPrint('Error toggling task complete: $e');
    }
  }
}
