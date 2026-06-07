enum Priority { low, medium, high }

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.low: return 'Thấp';
      case Priority.medium: return 'Trung bình';
      case Priority.high: return 'Cao';
    }
  }

  int get value {
    switch (this) {
      case Priority.low: return 0;
      case Priority.medium: return 1;
      case Priority.high: return 2;
    }
  }

  static Priority fromValue(int value) {
    switch (value) {
      case 0: return Priority.low;
      case 1: return Priority.medium;
      case 2: return Priority.high;
      default: return Priority.medium;
    }
  }
}

enum RepeatType { none, daily, weekly, custom }

extension RepeatTypeExtension on RepeatType {
  String get value {
    switch (this) {
      case RepeatType.none: return 'none';
      case RepeatType.daily: return 'daily';
      case RepeatType.weekly: return 'weekly';
      case RepeatType.custom: return 'custom';
    }
  }

  String get label {
    switch (this) {
      case RepeatType.none: return 'Không lặp';
      case RepeatType.daily: return 'Hàng ngày';
      case RepeatType.weekly: return 'Hàng tuần';
      case RepeatType.custom: return 'Tùy chỉnh';
    }
  }

  static RepeatType fromValue(String value) {
    switch (value) {
      case 'daily': return RepeatType.daily;
      case 'weekly': return RepeatType.weekly;
      case 'custom': return RepeatType.custom;
      default: return RepeatType.none;
    }
  }
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final String? time;
  final Priority priority;
  final bool completed;
  final RepeatType repeatType;
  final List<int> repeatDays;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.time,
    this.priority = Priority.medium,
    this.completed = false,
    this.repeatType = RepeatType.none,
    this.repeatDays = const [],
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool get isOverdue {
    if (completed) return false;
    final now = DateTime.now();
    if (date.isBefore(DateTime(now.year, now.month, now.day))) return true;
    if (isToday && time != null) {
      final parts = time!.split(':');
      final taskTime = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      return taskTime.isBefore(now);
    }
    return false;
  }

  bool get hasRepeat => repeatType != RepeatType.none;

  String get repeatLabel {
    if (repeatType == RepeatType.none) return '';
    if (repeatType == RepeatType.daily) return 'Hàng ngày';
    if (repeatType == RepeatType.weekly) return 'Hàng tuần';
    if (repeatDays.isEmpty) return 'Tùy chỉnh';
    const names = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final sorted = [...repeatDays]..sort();
    return sorted.map((d) => names[d % 7]).join(', ');
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final repeatDaysStr = map['repeat_days'] as String? ?? '';
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String?,
      priority: PriorityExtension.fromValue(map['priority'] as int),
      completed: (map['completed'] as int) == 1,
      repeatType: RepeatTypeExtension.fromValue(map['repeat_type'] as String? ?? 'none'),
      repeatDays: repeatDaysStr.isEmpty
          ? []
          : repeatDaysStr.split(',').map(int.parse).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'priority': priority.value,
      'completed': completed ? 1 : 0,
      'repeat_type': repeatType.value,
      'repeat_days': repeatDays.join(','),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    Priority? priority,
    bool? completed,
    RepeatType? repeatType,
    List<int>? repeatDays,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  @override
  String toString() => 'Task(id: $id, title: $title, date: $date, completed: $completed, repeat: ${repeatType.value})';
}
