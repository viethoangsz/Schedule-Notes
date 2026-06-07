import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../models/alarm.dart';
import 'note_service.dart';
import 'task_service.dart';
import 'alarm_service.dart';

class ExportImportService {
  final NoteService _noteService = NoteService();
  final TaskService _taskService = TaskService();
  final AlarmService _alarmService = AlarmService();

  Future<String?> exportToJson() async {
    try {
      final notes = await _noteService.getAllNotes();
      final tasks = await _taskService.getAllTasks();
      final alarms = await _alarmService.getAllAlarms();

      final data = {
        'version': 3,
        'exported_at': DateTime.now().toIso8601String(),
        'notes': notes.map((n) => n.toMap()).toList(),
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'alarms': alarms.map((a) => a.toMap()).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Chọn thư mục lưu file backup',
      );
      if (dir == null) return null;

      final fileName = 'schedule_notes_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('$dir/$fileName');
      await file.writeAsString(jsonStr, encoding: utf8);
      return file.path;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  Future<ImportResult?> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Chọn file backup',
      );
      if (result == null || result.files.single.path == null) return null;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString(encoding: utf8);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      int notesImported = 0;
      int tasksImported = 0;
      int alarmsImported = 0;

      if (data['notes'] != null) {
        final notesList = data['notes'] as List<dynamic>;
        for (final noteMap in notesList) {
          try {
            final map = Map<String, dynamic>.from(noteMap as Map);
            map.remove('id');
            final note = Note.fromMap({
              ...map,
              'id': null,
              'is_pinned': map['is_pinned'] ?? 0,
              'tags': map['tags'] ?? '',
            });
            await _noteService.createNote(note);
            notesImported++;
          } catch (e) {
            debugPrint('Error importing note: $e');
          }
        }
      }

      if (data['tasks'] != null) {
        final tasksList = data['tasks'] as List<dynamic>;
        for (final taskMap in tasksList) {
          try {
            final map = Map<String, dynamic>.from(taskMap as Map);
            map.remove('id');
            final task = Task.fromMap({
              ...map,
              'id': null,
              'completed': map['completed'] ?? 0,
              'repeat_type': map['repeat_type'] ?? 'none',
              'repeat_days': map['repeat_days'] ?? '',
            });
            await _taskService.createTask(task);
            tasksImported++;
          } catch (e) {
            debugPrint('Error importing task: $e');
          }
        }
      }

      if (data['alarms'] != null) {
        final alarmsList = data['alarms'] as List<dynamic>;
        for (final alarmMap in alarmsList) {
          try {
            final map = Map<String, dynamic>.from(alarmMap as Map);
            map.remove('id');
            final alarm = Alarm.fromMap({
              ...map,
              'id': null,
              'vibrate': map['vibrate'] ?? 1,
              'enabled': map['enabled'] ?? 1,
            });
            await _alarmService.createAlarm(alarm);
            alarmsImported++;
          } catch (e) {
            debugPrint('Error importing alarm: $e');
          }
        }
      }

      return ImportResult(
        notesImported: notesImported,
        tasksImported: tasksImported,
        alarmsImported: alarmsImported,
      );
    } catch (e) {
      debugPrint('Import error: $e');
      return null;
    }
  }
}

class ImportResult {
  final int notesImported;
  final int tasksImported;
  final int alarmsImported;

  ImportResult({
    required this.notesImported,
    required this.tasksImported,
    required this.alarmsImported,
  });

  int get total => notesImported + tasksImported + alarmsImported;
}
