import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/empty_state.dart';
import '../../utils/date_utils.dart';
import '../../utils/app_theme.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch trình'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Danh sách'),
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Lịch'),
          ],
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListTab(onOpenForm: (task) => _openTaskForm(context, task: task)),
          _CalendarTab(onOpenForm: (task) => _openTaskForm(context, task: task)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
    );
  }

  void _openTaskForm(BuildContext context, {task}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    ).then((_) => context.read<TaskProvider>().loadTasks());
  }
}

class _ListTab extends StatelessWidget {
  final Function(dynamic) onOpenForm;

  const _ListTab({required this.onOpenForm});

  Future<void> _pickDate(BuildContext context, TaskProvider taskProvider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: taskProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) taskProvider.setSelectedDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        if (taskProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = taskProvider.selectedDateTasks;
        final pendingTasks = tasks.where((t) => !t.completed).toList();
        final completedTasks = tasks.where((t) => t.completed).toList();

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
              ),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => taskProvider.setSelectedDate(
                      taskProvider.selectedDate.subtract(const Duration(days: 1)),
                    ),
                    icon: const Icon(Icons.chevron_left),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(context, taskProvider),
                      child: Column(
                        children: [
                          Text(
                            DateTimeUtils.formatDateFull(taskProvider.selectedDate),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (taskProvider.selectedDate.year == DateTime.now().year &&
                              taskProvider.selectedDate.month == DateTime.now().month &&
                              taskProvider.selectedDate.day == DateTime.now().day)
                            Text(
                              'HÔM NAY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => taskProvider.setSelectedDate(
                      taskProvider.selectedDate.add(const Duration(days: 1)),
                    ),
                    icon: const Icon(Icons.chevron_right),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            Expanded(
              child: tasks.isEmpty
                  ? EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'Không có công việc',
                      subtitle: 'Không có công việc nào vào ${DateTimeUtils.friendlyDate(taskProvider.selectedDate)}',
                      actionLabel: 'Thêm công việc',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                      ).then((_) => taskProvider.loadTasks()),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      children: [
                        if (pendingTasks.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                            onTap: () => onOpenForm(task),
                            onToggleComplete: () => taskProvider.toggleComplete(task),
                            onDelete: () => taskProvider.deleteTask(task.id!),
                          )),
                        ],
                        if (completedTasks.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                            onTap: () => onOpenForm(task),
                            onToggleComplete: () => taskProvider.toggleComplete(task),
                            onDelete: () => taskProvider.deleteTask(task.id!),
                          )),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CalendarTab extends StatefulWidget {
  final Function(dynamic) onOpenForm;

  const _CalendarTab({required this.onOpenForm});

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth(TaskProvider provider) {
    setState(() {
      if (_month == 1) { _month = 12; _year--; }
      else { _month--; }
    });
    provider.loadCalendarMonth(_year, _month);
  }

  void _nextMonth(TaskProvider provider) {
    setState(() {
      if (_month == 12) { _month = 1; _year++; }
      else { _month++; }
    });
    provider.loadCalendarMonth(_year, _month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final firstDay = DateTime(_year, _month, 1);
        final daysInMonth = DateTime(_year, _month + 1, 0).day;
        final startWeekday = firstDay.weekday % 7;
        final totalCells = startWeekday + daysInMonth;
        final rows = (totalCells / 7).ceil();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _prevMonth(taskProvider),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      'Tháng $_month/$_year',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _nextMonth(taskProvider),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() { _year = now.year; _month = now.month; });
                      taskProvider.loadCalendarMonth(_year, _month);
                    },
                    child: const Text('Hôm nay'),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'].map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 6),
            const Divider(height: 1),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.85,
                ),
                itemCount: rows * 7,
                itemBuilder: (context, index) {
                  final dayNum = index - startWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final thisDate = DateTime(_year, _month, dayNum);
                  final isToday = thisDate.year == now.year && thisDate.month == now.month && thisDate.day == now.day;
                  final isSelected = thisDate.year == taskProvider.selectedDate.year &&
                      thisDate.month == taskProvider.selectedDate.month &&
                      thisDate.day == taskProvider.selectedDate.day;
                  final dateStr = thisDate.toIso8601String().substring(0, 10);
                  final hasTasks = taskProvider.datesWithTasks.contains(dateStr);
                  final isSunday = index % 7 == 0;

                  return GestureDetector(
                    onTap: () {
                      taskProvider.setSelectedDate(thisDate);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary
                            : isToday
                                ? cs.primaryContainer.withOpacity(0.6)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? cs.onPrimary
                                  : isToday
                                      ? cs.primary
                                      : isSunday
                                          ? cs.error
                                          : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasTasks
                                  ? (isSelected ? cs.onPrimary.withOpacity(0.7) : cs.primary)
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),
            _SelectedDayTasks(
              taskProvider: taskProvider,
              onOpenForm: widget.onOpenForm,
            ),
          ],
        );
      },
    );
  }
}

class _SelectedDayTasks extends StatelessWidget {
  final TaskProvider taskProvider;
  final Function(dynamic) onOpenForm;

  const _SelectedDayTasks({required this.taskProvider, required this.onOpenForm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tasks = taskProvider.selectedDateTasks;
    final date = taskProvider.selectedDate;

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(color: cs.surfaceContainerLowest),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              DateTimeUtils.formatDateFull(date),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Không có công việc',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final pColor = AppTheme.priorityColor(task.priority);
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Container(
                      width: 10, height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: pColor),
                    ),
                    title: Text(
                      task.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                        color: task.completed ? cs.onSurfaceVariant : cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: task.time != null
                        ? Text(task.time!, style: theme.textTheme.labelSmall?.copyWith(color: cs.primary))
                        : null,
                    onTap: () => onOpenForm(task),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
