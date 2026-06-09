class Alarm {
  final int? id;
  final String title;
  final String time;
  final List<int> days;
  final String sound;
  final bool vibrate;
  final bool enabled;
  final DateTime createdAt;

  Alarm({
    this.id,
    required this.title,
    required this.time,
    this.days = const [],
    this.sound = 'alarm_default',
    this.vibrate = true,
    this.enabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOneTime => days.isEmpty;

  String get daysLabel {
    if (days.isEmpty) return 'Một lần';
    if (days.length == 7) return 'Mỗi ngày';
    if (days.length == 5 && !days.contains(6) && !days.contains(0)) {
      return 'Thứ 2 - Thứ 6';
    }
    const names = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final sorted = [...days]..sort();
    return sorted.map((d) => names[d]).join(', ');
  }

  String get soundLabel {
    switch (sound) {
      case 'alarm_default': return 'Mặc định';
      case 'alarm_gentle': return 'Nhẹ nhàng';
      case 'alarm_energetic': return 'Năng động';
      default: return sound.split('/').last;
    }
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    final daysStr = map['days'] as String? ?? '';
    final days = daysStr.isEmpty
        ? <int>[]
        : daysStr.split(',').map(int.parse).toList();
    return Alarm(
      id: map['id'] as int?,
      title: map['title'] as String,
      time: map['time'] as String,
      days: days,
      sound: map['sound'] as String? ?? 'alarm_default',
      vibrate: (map['vibrate'] as int? ?? 1) == 1,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'time': time,
      'days': days.join(','),
      'sound': sound,
      'vibrate': vibrate ? 1 : 0,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Alarm copyWith({
    int? id,
    String? title,
    String? time,
    List<int>? days,
    String? sound,
    bool? vibrate,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      days: days ?? this.days,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

const List<Map<String, String>> kBuiltinSounds = [
  {'id': 'alarm_default', 'label': 'Mặc định', 'icon': '🔔'},
  {'id': 'alarm_gentle', 'label': 'Nhẹ nhàng', 'icon': '🎵'},
  {'id': 'alarm_energetic', 'label': 'Năng động', 'icon': '⚡'},
];
