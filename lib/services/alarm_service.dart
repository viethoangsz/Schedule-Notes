import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/alarm.dart';

class AlarmService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Alarm>> getAllAlarms() async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableAlarms,
      orderBy: 'time ASC',
    );
    return maps.map(Alarm.fromMap).toList();
  }

  Future<Alarm> createAlarm(Alarm alarm) async {
    final db = await _db.database;
    final id = await db.insert(
      DatabaseHelper.tableAlarms,
      alarm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return alarm.copyWith(id: id);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableAlarms,
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<void> deleteAlarm(int id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableAlarms,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    await updateAlarm(alarm.copyWith(enabled: !alarm.enabled));
  }
}
