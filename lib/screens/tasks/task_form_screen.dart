// screens/tasks/task_form_screen.dart
// Màn hình tạo/chỉnh sửa công việc

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
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? widget.initialTitle ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _selectedDate = task?.date ?? DateTime.now();
    _selectedPriority = task?.priority ?? Priority.medium;

    // Parse time nếu có
    if (task?.time != null) {
      final parts = task!.time!.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa' : 'Thêm công việc'),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tiêu đề
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề *',
                hintText: 'Nhập tên công việc',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Mô tả
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

            // Ngày
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: const Text('Ngày'),
              subtitle: Text(
                DateTimeUtils.friendlyDate(_selectedDate),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: _pickDate,
            ),

            const Divider(height: 1),

            // Giờ
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.access_time,
                  color: colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              title: const Text('Giờ'),
              subtitle: Text(
                _selectedTime != null
                    ? DateTimeUtils.formatTimeOfDay(
                        _selectedTime!.hour, _selectedTime!.minute)
                    : 'Không có giờ cụ thể',
                style: TextStyle(
                  color: _selectedTime != null
                      ? colorScheme.secondary
                      : colorScheme.onSurfaceVariant,
                  fontWeight:
                      _selectedTime != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              trailing: _selectedTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _selectedTime = null),
                      tooltip: 'Xóa giờ',
                    )
                  : null,
              onTap: _pickTime,
            ),

            const Divider(height: 1),
            const SizedBox(height: 20),

            // Priority
            Text(
              'Mức độ ưu tiên',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Priority selector
            Row(
              children: Priority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                final color = AppTheme.priorityColor(priority);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPriority = priority),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.15)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.flag,
                              color: isSelected
                                  ? color
                                  : colorScheme.onSurfaceVariant,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              priority.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? color
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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

            const SizedBox(height: 32),

            // Nút lưu
            FilledButton(
              onPressed: _isSaving ? null : _saveTask,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final taskProvider = context.read<TaskProvider>();
    final timeStr = _selectedTime != null
        ? DateTimeUtils.formatTimeOfDay(
            _selectedTime!.hour, _selectedTime!.minute)
        : null;

    bool success;

    if (_isEditing) {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        time: timeStr,
        priority: _selectedPriority,
      );
      success = await taskProvider.updateTask(updatedTask);
    } else {
      final created = await taskProvider.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        time: timeStr,
        priority: _selectedPriority,
      );
      success = created != null;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật!' : 'Đã thêm công việc!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi lưu công việc')),
        );
      }
    }
  }
}
