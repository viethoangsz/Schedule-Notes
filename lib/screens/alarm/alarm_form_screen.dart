import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/alarm.dart';
import '../../providers/alarm_provider.dart';

class AlarmFormScreen extends StatefulWidget {
  final Alarm? alarm;
  const AlarmFormScreen({super.key, this.alarm});

  @override
  State<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends State<AlarmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TimeOfDay _time;
  late List<int> _days;
  late String _sound;
  late bool _vibrate;
  bool _isSaving = false;

  bool get _isEditing => widget.alarm != null;

  static const List<String> _dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    _titleCtrl = TextEditingController(text: a?.title ?? 'Báo thức');
    _sound = a?.sound ?? 'alarm_default';
    _vibrate = a?.vibrate ?? true;
    _days = a?.days != null ? List.from(a!.days) : [];

    if (a?.time != null) {
      final parts = a!.time.split(':');
      _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      _time = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa báo thức' : 'Báo thức mới'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
              color: cs.error,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TimePickerCard(
              time: _time,
              onTap: _pickTime,
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên báo thức',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên báo thức' : null,
            ),

            const SizedBox(height: 24),

            Text(
              'Lặp lại',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _DaySelector(
              selected: _days,
              onChanged: (days) => setState(() => _days = days),
            ),

            const SizedBox(height: 24),

            Text(
              'Âm thanh',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _SoundSelector(
              selected: _sound,
              onChanged: (s) => setState(() => _sound = s),
              onPickFile: _pickAudioFile,
            ),

            const SizedBox(height: 20),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.vibration, color: cs.primary),
              title: const Text('Rung'),
              subtitle: const Text('Rung khi báo thức'),
              value: _vibrate,
              onChanged: (v) => setState(() => _vibrate = v),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditing ? 'Cập nhật' : 'Đặt báo thức',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) setState(() => _sound = path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chọn file âm thanh')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    final alarm = Alarm(
      id: widget.alarm?.id,
      title: _titleCtrl.text.trim(),
      time: timeStr,
      days: _days,
      sound: _sound,
      vibrate: _vibrate,
    );

    final provider = context.read<AlarmProvider>();
    bool success;
    if (_isEditing) {
      success = await provider.updateAlarm(alarm);
    } else {
      success = await provider.createAlarm(alarm) != null;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật báo thức' : 'Đã đặt báo thức lúc $timeStr'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa báo thức?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AlarmProvider>().deleteAlarm(widget.alarm!.id!);
              if (mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerCard({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w200,
                color: cs.onPrimary,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: cs.onPrimary.withOpacity(0.7), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Chạm để đổi giờ',
                  style: TextStyle(color: cs.onPrimary.withOpacity(0.7), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({required this.selected, required this.onChanged});

  static const _names = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isSelected = selected.contains(i);
        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selected);
            if (isSelected) updated.remove(i);
            else updated.add(i);
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _names[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SoundSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickFile;

  const _SoundSelector({
    required this.selected,
    required this.onChanged,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCustom = !kBuiltinSounds.any((s) => s['id'] == selected);

    return Column(
      children: [
        Row(
          children: kBuiltinSounds.map((s) {
            final isSelected = selected == s['id'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onChanged(s['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? cs.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(s['icon']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          s['label']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPickFile,
          icon: Icon(
            Icons.folder_open_outlined,
            color: isCustom ? cs.primary : null,
          ),
          label: Text(
            isCustom
                ? '✓ ${selected.split('/').last}'
                : 'Chọn nhạc từ điện thoại',
            style: TextStyle(color: isCustom ? cs.primary : null),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            side: BorderSide(
              color: isCustom ? cs.primary : cs.outline,
            ),
          ),
        ),
      ],
    );
  }
}
