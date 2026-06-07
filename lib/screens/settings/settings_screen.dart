import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/alarm_provider.dart';
import '../../services/notification_service.dart';
import '../../services/export_import_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Thông báo & Báo thức'),

          SwitchListTile(
            secondary: Icon(Icons.notifications_outlined, color: colorScheme.primary),
            title: const Text('Bật thông báo'),
            subtitle: const Text('Nhận nhắc nhở cho các công việc có giờ'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              if (!value) NotificationService().cancelAllNotifications();
            },
          ),

          ListTile(
            leading: Icon(Icons.notification_add_outlined, color: colorScheme.primary),
            title: const Text('Kiểm tra thông báo'),
            subtitle: const Text('Gửi thông báo thử nghiệm'),
            onTap: () async {
              await NotificationService().showImmediateNotification(
                title: '🔔 Schedule Notes',
                body: 'Thông báo hoạt động bình thường!',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi thông báo kiểm tra'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          _SectionHeader(title: 'Sao lưu & Khôi phục'),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.upload_outlined, color: colorScheme.onPrimaryContainer, size: 20),
            ),
            title: const Text('Xuất dữ liệu'),
            subtitle: const Text('Lưu toàn bộ ghi chú, công việc, báo thức ra file JSON'),
            trailing: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _isExporting ? null : () => _exportData(context),
          ),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.download_outlined, color: colorScheme.onSecondaryContainer, size: 20),
            ),
            title: const Text('Nhập dữ liệu'),
            subtitle: const Text('Khôi phục từ file backup JSON'),
            trailing: _isImporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _isImporting ? null : () => _importData(context),
          ),

          const Divider(indent: 16, endIndent: 16),

          _SectionHeader(title: 'Dữ liệu'),

          Consumer3<NoteProvider, TaskProvider, AlarmProvider>(
            builder: (context, noteProvider, taskProvider, alarmProvider, _) {
              return Column(
                children: [
                  _InfoTile(icon: Icons.sticky_note_2_outlined, label: 'Ghi chú', count: noteProvider.notes.length),
                  _InfoTile(icon: Icons.calendar_month_outlined, label: 'Công việc', count: taskProvider.tasks.length),
                  _InfoTile(icon: Icons.alarm_outlined, label: 'Báo thức', count: alarmProvider.alarms.length),
                ],
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: colorScheme.error),
            title: Text('Xóa tất cả dữ liệu', style: TextStyle(color: colorScheme.error)),
            subtitle: const Text('Xóa toàn bộ ghi chú và công việc'),
            onTap: () => _confirmClearData(context),
          ),

          const Divider(indent: 16, endIndent: 16),

          _SectionHeader(title: 'Về ứng dụng'),

          ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.event_note, color: colorScheme.onPrimaryContainer, size: 20),
            ),
            title: const Text('Schedule Notes'),
            subtitle: const Text('Phiên bản 1.2.0'),
          ),

          ListTile(
            leading: Icon(Icons.storage_outlined, color: colorScheme.primary),
            title: const Text('Lưu trữ cục bộ'),
            subtitle: const Text('Tất cả dữ liệu được lưu trên thiết bị của bạn'),
          ),

          ListTile(
            leading: Icon(Icons.wifi_off_outlined, color: colorScheme.primary),
            title: const Text('Hoạt động offline'),
            subtitle: const Text('Không cần kết nối internet'),
          ),

          ListTile(
            leading: Icon(Icons.security_outlined, color: colorScheme.primary),
            title: const Text('Quyền riêng tư'),
            subtitle: const Text('Không thu thập dữ liệu cá nhân'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final service = ExportImportService();
      final path = await service.exportToJson();
      if (mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Đã xuất dữ liệu thành công!\n$path'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã hủy xuất dữ liệu'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi xuất dữ liệu: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.download_rounded, color: Theme.of(context).colorScheme.primary, size: 36),
        title: const Text('Nhập dữ liệu?'),
        content: const Text(
          'Dữ liệu từ file backup sẽ được thêm vào dữ liệu hiện có (không ghi đè). Tiếp tục?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Nhập')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);
    try {
      final service = ExportImportService();
      final result = await service.importFromJson();
      if (mounted) {
        if (result != null) {
          context.read<NoteProvider>().loadNotes();
          context.read<TaskProvider>().loadTasks();
          context.read<AlarmProvider>().loadAlarms();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Đã nhập thành công!\n'
              '📝 ${result.notesImported} ghi chú  '
              '📅 ${result.tasksImported} công việc  '
              '⏰ ${result.alarmsImported} báo thức',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã hủy hoặc file không hợp lệ'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi nhập dữ liệu: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error, size: 40),
        title: const Text('Xóa tất cả dữ liệu?'),
        content: const Text('Hành động này sẽ xóa toàn bộ ghi chú và công việc. Dữ liệu không thể khôi phục!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa tất cả dữ liệu'), behavior: SnackBarBehavior.floating),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  const _InfoTile({required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(label),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
        child: Text(
          '$count',
          style: theme.textTheme.labelLarge?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
