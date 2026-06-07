// models/task.dart
// Model đại diện cho một công việc/lịch trình

enum Priority { low, medium, high }

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return 'Thấp';
      case Priority.medium:
        return 'Trung bình';
      case Priority.high:
        return 'Cao';
    }
  }

  int get value {
    switch (this) {
      case Priority.low:
        return 0;
      case Priority.medium:
        return 1;
      case Priority.high:
        return 2;
    }
  }

  static Priority fromValue(int value) {
    switch (value) {
      case 0:
        return Priority.low;
      case 1:
        return Priority.medium;
      case 2:
        return Priority.high;
      default:
        return Priority.medium;
    }
  }
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final String? time; // Format "HH:mm", nullable nếu không có giờ cụ thể
  final Priority priority;
  final bool completed;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.time,
    this.priority = Priority.medium,
    this.completed = false,
  });

  /// Kiểm tra task có phải hôm nay không
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Kiểm tra task có bị quá hạn không
  bool get isOverdue {
    if (completed) return false;
    final now = DateTime.now();
    if (date.isBefore(DateTime(now.year, now.month, now.day))) return true;
    if (isToday && time != null) {
      final parts = time!.split(':');
      final taskTime = DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      return taskTime.isBefore(now);
    }
    return false;
  }

  /// Tạo Task từ Map (dữ liệu từ SQLite)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String?,
      priority: PriorityExtension.fromValue(map['priority'] as int),
      completed: (map['completed'] as int) == 1,
    );
  }

  /// Chuyển Task thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'priority': priority.value,
      'completed': completed ? 1 : 0,
    };
  }

  /// Tạo bản sao có thay đổi một số trường
  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    Priority? priority,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, date: $date, completed: $completed)';
  }
}
