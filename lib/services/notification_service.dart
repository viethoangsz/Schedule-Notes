import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';
import '../models/alarm.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int _alarmIdOffset = 100000;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {}

  AndroidNotificationDetails _androidDetails({String sound = 'alarm_default', bool vibrate = true}) {
    return AndroidNotificationDetails(
      'alarm_channel_$sound',
      'Báo thức & Nhắc nhở',
      channelDescription: 'Thông báo báo thức và lịch trình',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: vibrate,
      sound: RawResourceAndroidNotificationSound(sound),
      fullScreenIntent: true,
    );
  }

  NotificationDetails _notifDetails({String sound = 'alarm_default', bool vibrate = true}) {
    return NotificationDetails(
      android: _androidDetails(sound: sound, vibrate: vibrate),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (task.id == null || task.time == null) return;
    try {
      final parts = task.time!.split(':');
      final scheduledDate = tz.TZDateTime(
        tz.local,
        task.date.year,
        task.date.month,
        task.date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      await _plugin.zonedSchedule(
        task.id!,
        '⏰ ${task.title}',
        task.description.isEmpty
            ? 'Đã đến giờ thực hiện công việc'
            : task.description,
        scheduledDate,
        _notifDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling task notification: $e');
    }
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (alarm.id == null) return;
    try {
      final parts = alarm.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = tz.TZDateTime.now(tz.local);

      if (alarm.days.isEmpty) {
        var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          _alarmIdOffset + alarm.id!,
          '⏰ ${alarm.title}',
          'Báo thức - ${alarm.time}',
          scheduled,
          _notifDetails(sound: alarm.sound, vibrate: alarm.vibrate),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        for (int i = 0; i < alarm.days.length; i++) {
          final dayOfWeek = _toDayOfWeek(alarm.days[i]);
          await _plugin.zonedSchedule(
            _alarmIdOffset + alarm.id! * 10 + i,
            '⏰ ${alarm.title}',
            'Báo thức - ${alarm.time}',
            _nextInstanceOfDay(dayOfWeek, hour, minute),
            _notifDetails(sound: alarm.sound, vibrate: alarm.vibrate),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling alarm: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfDay(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _toDayOfWeek(int appDay) {
    const map = [7, 1, 2, 3, 4, 5, 6];
    return map[appDay % 7];
  }

  Future<void> cancelTaskNotification(int taskId) async {
    await _plugin.cancel(taskId);
  }

  Future<void> cancelAlarm(int alarmId) async {
    await _plugin.cancel(_alarmIdOffset + alarmId);
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_alarmIdOffset + alarmId * 10 + i);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _notifDetails(),
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
