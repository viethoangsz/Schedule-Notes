import 'package:flutter/foundation.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';

class AlarmProvider with ChangeNotifier {
  final AlarmService _alarmService = AlarmService();
  final NotificationService _notifService = NotificationService();

  List<Alarm> _alarms = [];
  bool _isLoading = false;

  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;
  int get enabledCount => _alarms.where((a) => a.enabled).length;

  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();
    try {
      _alarms = await _alarmService.getAllAlarms();
    } catch (e) {
      debugPrint('Error loading alarms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Alarm?> createAlarm(Alarm alarm) async {
    try {
      final created = await _alarmService.createAlarm(alarm);
      if (created.enabled) {
        await _notifService.scheduleAlarm(created);
      }
      await loadAlarms();
      return created;
    } catch (e) {
      debugPrint('Error creating alarm: $e');
      return null;
    }
  }

  Future<bool> updateAlarm(Alarm alarm) async {
    try {
      await _alarmService.updateAlarm(alarm);
      await _notifService.cancelAlarm(alarm.id!);
      if (alarm.enabled) {
        await _notifService.scheduleAlarm(alarm);
      }
      await loadAlarms();
      return true;
    } catch (e) {
      debugPrint('Error updating alarm: $e');
      return false;
    }
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    try {
      final updated = alarm.copyWith(enabled: !alarm.enabled);
      await _alarmService.updateAlarm(updated);
      if (updated.enabled) {
        await _notifService.scheduleAlarm(updated);
      } else {
        await _notifService.cancelAlarm(alarm.id!);
      }
      await loadAlarms();
    } catch (e) {
      debugPrint('Error toggling alarm: $e');
    }
  }

  Future<bool> deleteAlarm(int id) async {
    try {
      await _notifService.cancelAlarm(id);
      await _alarmService.deleteAlarm(id);
      await loadAlarms();
      return true;
    } catch (e) {
      debugPrint('Error deleting alarm: $e');
      return false;
    }
  }
}
