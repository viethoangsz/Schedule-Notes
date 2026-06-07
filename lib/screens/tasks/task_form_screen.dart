import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final String? initialTitle;

  const TaskFormScreen({super.key, this.task, this.initialTitle});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late Priority _selectedPriority;
  late RepeatType _selectedRepeatType;
  List<int> _selectedRepeatDays = [];
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  static const List<Map<String, dynamic>> _weekDays = [
    {'short': 'CN', 'value': 0},
    {'short': 'T2', 'value': 1},
    {'short': 'T3', 'value': 2},
    {'short': 'T4', 'value': 3},
    {'short': 'T5', 'value': 4},
    {'short': 'T6', 'value': 5},
    {'short': 'T7', 'value': 6},
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? widget.initialTitle ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _selectedDate = task?.date ?? DateTime.now();
    _selectedPriority = task?.priority ?? Priority.medium;
    _selectedRepeatType = task?.repeatType ?? RepeatType.none;
    _selectedRepeatDays = List<int>.from(task?.repeatDays ?? []);

    if (task?.time != null) {
      final parts = task!.time!.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Chỉnh sửa' : 'Thêm công việc')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề *',
                hintText: 'Nhập tên công việc',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Thêm mô tả chi tiết (tùy chọn)',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.calendar_today, color: colorScheme.onPrimaryContainer, size: 20),
              ),
              title: const Text('Ngày'),
              subtitle: Text(
                DateTimeUtils.friendlyDate(_selectedDate),
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
              ),
              onTap: _pickDate,
            ),

            const Divider(height: 1),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.access_time, color: colorScheme.onSecondaryContainer, size: 20),
              ),
              title: const Text('Giờ'),
              subtitle: Text(
                _selectedTime != null
                    ? DateTimeUtils.formatTimeOfDay(_selectedTime!.hour, _selectedTime!.minute)
                    : 'Không có giờ cụ thể',
                style: TextStyle(
                  color: _selectedTime != null ? colorScheme.secondary : colorScheme.onSurfaceVariant,
                  fontWeight: _selectedTime != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              trailing: _selectedTime != null
                  ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => setState(() => _selectedTime = null))
                  : null,
              onTap: _pickTime,
            ),

            const Divider(height: 1),
            const SizedBox(height: 20),

            Text('Mức độ ưu tiên', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            Row(
              children: Priority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                final color = AppTheme.priorityColor(priority);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPriority = priority),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.15) : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.flag_rounded, color: isSelected ? color : colorScheme.onSurfaceVariant, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              priority.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isSelected ? color : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

            const SizedBox(height: 24),

            Text('Lặp lại', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RepeatType.values.map((type) {
                final isSelected = _selectedRepeatType == type;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type == RepeatType.none ? Icons.block_outlined : Icons.repeat_rounded,
                        size: 14,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(type.label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedRepeatType = type;
                      if (type != RepeatType.custom) _selectedRepeatDays = [];
                    });
                  },
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            if (_selectedRepeatType == RepeatType.custom) ...[
              const SizedBox(height: 12),
              Text(
                'Chọn ngày trong tuần',
                style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: _weekDays.map((day) {
                  final val = day['value'] as int;
                  final isSelected = _selectedRepeatDays.contains(val);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedRepeatDays.remove(val);
                          } else {
                            _selectedRepeatDays.add(val);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          day['short'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (_selectedRepeatType != RepeatType.none) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedRepeatType == RepeatType.daily
                            ? 'Công việc này sẽ được nhắc hàng ngày'
                            : _selectedRepeatType == RepeatType.weekly
                                ? 'Công việc này sẽ được nhắc hàng tuần'
                                : _selectedRepeatDays.isEmpty
                                    ? 'Chọn ngày lặp lại bên trên'
                                    : 'Lặp lại vào: ${Task(title: '', description: '', date: DateTime.now(), repeatType: _selectedRepeatType, repeatDays: _selectedRepeatDays).repeatLabel}',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isSaving ? null : _saveTask,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _isEditing ? 'Cập nhật' : 'Thêm công việc',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final taskProvider = context.read<TaskProvider>();
    final timeStr = _selectedTime != null
        ? DateTimeUtils.formatTimeOfDay(_selectedTime!.hour, _selectedTime!.minute)
        : null;

    bool success;

    if (_isEditing) {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        time: timeStr,
        priority: _selectedPriority,
        repeatType: _selectedRepeatType,
        repeatDays: _selectedRepeatDays,
      );
      success = await taskProvider.updateTask(updatedTask);
    } else {
      final created = await taskProvider.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        time: timeStr,
        priority: _selectedPriority,
        repeatType: _selectedRepeatType,
        repeatDays: _selectedRepeatDays,
      );
      success = created != null;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Đã cập nhật!' : 'Đã thêm công việc!'),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi lưu công việc')),
        );
      }
    }
  }
}
