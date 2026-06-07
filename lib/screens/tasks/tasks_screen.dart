// screens/tasks/tasks_screen.dart
// Màn hình quản lý công việc/lịch trình

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/empty_state.dart';
import '../../utils/date_utils.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch trình'),
        actions: [
          // Nút chọn ngày
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) => TextButton.icon(
              onPressed: () => _pickDate(context, taskProvider),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                DateTimeUtils.friendlyDate(taskProvider.selectedDate),
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ),
        ],
      ),

      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = taskProvider.selectedDateTasks;

          // Phân loại: chưa hoàn thành và đã hoàn thành
          final pendingTasks = tasks.where((t) => !t.completed).toList();
          final completedTasks = tasks.where((t) => t.completed).toList();

          if (tasks.isEmpty) {
            return EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Không có công việc',
              subtitle:
                  'Không có công việc nào vào ${DateTimeUtils.friendlyDate(taskProvider.selectedDate)}',
              actionLabel: 'Thêm công việc',
              onAction: () => _openTaskForm(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            children: [
              // Header ngày được chọn
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  DateTimeUtils.formatDateFull(taskProvider.selectedDate),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Công việc chưa hoàn thành
              if (pendingTasks.isNotEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Cần thực hiện (${pendingTasks.length})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...pendingTasks.map((task) => TaskCard(
                      task: task,
                      onTap: () => _openTaskForm(context, task: task),
                      onToggleComplete: () =>
                          taskProvider.toggleComplete(task),
                      onDelete: () => taskProvider.deleteTask(task.id!),
                    )),
              ],

              // Công việc đã hoàn thành
              if (completedTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Đã hoàn thành (${completedTasks.length})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...completedTasks.map((task) => TaskCard(
                      task: task,
                      onTap: () => _openTaskForm(context, task: task),
                      onToggleComplete: () =>
                          taskProvider.toggleComplete(task),
                      onDelete: () => taskProvider.deleteTask(task.id!),
                    )),
              ],
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
    );
  }

  /// Mở date picker để chọn ngày
  Future<void> _pickDate(
      BuildContext context, TaskProvider taskProvider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: taskProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      taskProvider.setSelectedDate(picked);
    }
  }

  void _openTaskForm(BuildContext context, {task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task),
      ),
    ).then((_) => context.read<TaskProvider>().loadTasks());
  }
}
