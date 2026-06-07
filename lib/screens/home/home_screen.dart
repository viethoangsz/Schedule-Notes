import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/note_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/alarm_provider.dart';
import '../../models/task.dart';
import '../../utils/date_utils.dart';
import '../../utils/app_theme.dart';
import '../tasks/task_form_screen.dart';
import '../notes/note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
      context.read<NoteProvider>().loadNotes();
      context.read<AlarmProvider>().loadAlarms();
      _initSpeech();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final permission = await Permission.microphone.request();
    if (permission.isGranted) {
      _speechAvailable = await _speech.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể nhận dạng giọng nói trên thiết bị này')),
          );
        }
        return;
      }
    }
    setState(() { _isListening = true; _recognizedText = ''; });
    await _speech.listen(
      onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult) {
          _stopListening();
          if (_recognizedText.isNotEmpty) _showVoiceResultSheet(_recognizedText);
        }
      },
      localeId: 'vi_VN',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _showVoiceResultSheet(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.mic, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                const Text('Đã nhận dạng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('"$text"', style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 20),
            const Text('Dùng văn bản này để:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _openNoteWithText(text); },
                    icon: const Icon(Icons.sticky_note_2_outlined),
                    label: const Text('Ghi chú'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () { Navigator.pop(ctx); _openTaskWithText(text); },
                    icon: const Icon(Icons.add_task),
                    label: const Text('Công việc'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openNoteWithText(String text) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(initialContent: text)),
    ).then((_) => context.read<NoteProvider>().loadNotes());
  }

  void _openTaskWithText(String text) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(initialTitle: text)),
    ).then((_) => context.read<TaskProvider>().loadTasks());
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng! ☀️';
    if (hour < 18) return 'Chào buổi chiều! 🌤️';
    return 'Chào buổi tối! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.tertiary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.onPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.event_note_rounded, color: cs.onPrimary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Schedule Notes',
                              style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getGreeting(),
                          style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeUtils.formatDateFull(now),
                          style: TextStyle(color: cs.onPrimary.withOpacity(0.75), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: cs.primary,
            toolbarHeight: 0,
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _StatsSection(),
                const SizedBox(height: 16),
                _ProgressSection(),
                const SizedBox(height: 20),
                _WeekStrip(),
                const SizedBox(height: 24),
                _QuickActionsSection(
                  onVoiceNote: () => _openNoteWithText(''),
                  onVoiceTask: () => _openTaskWithText(''),
                  onVoice: _startListening,
                ),
                const SizedBox(height: 24),
                _TodayTasksSection(),
                const SizedBox(height: 24),
                _PinnedNotesSection(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _isListening
                  ? [BoxShadow(color: cs.error.withOpacity(0.5), blurRadius: 24, spreadRadius: 6)]
                  : [BoxShadow(color: cs.primary.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)],
            ),
            child: FloatingActionButton(
              heroTag: 'voice_fab',
              onPressed: _isListening ? _stopListening : _startListening,
              backgroundColor: _isListening ? cs.error : cs.primary,
              foregroundColor: _isListening ? cs.onError : cs.onPrimary,
              tooltip: 'Nhập bằng giọng nói',
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  key: ValueKey(_isListening),
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onVoiceNote;
  final VoidCallback onVoiceTask;
  final VoidCallback onVoice;

  const _QuickActionsSection({
    required this.onVoiceNote,
    required this.onVoiceTask,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _QuickBtn(icon: Icons.add_task_rounded, label: 'Thêm việc', color: cs.primary, onTap: onVoiceTask),
          const SizedBox(width: 10),
          _QuickBtn(icon: Icons.note_add_outlined, label: 'Ghi chú', color: cs.secondary, onTap: onVoiceNote),
          const SizedBox(width: 10),
          _QuickBtn(icon: Icons.mic_rounded, label: 'Giọng nói', color: cs.tertiary, onTap: onVoice),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final stats = taskProvider.todayStats;
        final total = stats['total'] ?? 0;
        final completed = stats['completed'] ?? 0;
        final progress = total == 0 ? 0.0 : completed / total;

        if (total == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ hôm nay',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '$completed/$total việc',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: cs.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppTheme.priorityLow : cs.primary,
                    ),
                  ),
                ),
                if (progress == 1.0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.celebration_outlined, size: 14, color: AppTheme.priorityLow),
                      const SizedBox(width: 6),
                      Text(
                        'Hoàn thành tất cả! Tuyệt vời 🎉',
                        style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.priorityLow, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tuần này',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(7, (i) {
                  final day = days[i];
                  final isToday = day.day == now.day && day.month == now.month;
                  final dateStr = day.toIso8601String().substring(0, 10);
                  final hasTasks = taskProvider.datesWithTasks.contains(dateStr);

                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          dayNames[i],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isToday ? cs.primary : cs.onSurfaceVariant,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday ? cs.primary : Colors.transparent,
                            border: Border.all(
                              color: isToday ? cs.primary : cs.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isToday ? cs.onPrimary : cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasTasks
                                ? (isToday ? cs.primary : cs.secondary)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskProvider, NoteProvider>(
      builder: (context, taskProvider, noteProvider, _) {
        final stats = taskProvider.todayStats;
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatCard(label: 'Hôm nay', value: '${stats['total']}', icon: Icons.today_outlined, color: cs.primary),
              const SizedBox(width: 10),
              _StatCard(label: 'Hoàn thành', value: '${stats['completed']}', icon: Icons.check_circle_outline, color: AppTheme.priorityLow),
              const SizedBox(width: 10),
              _StatCard(label: 'Ghi chú', value: '${noteProvider.notes.length}', icon: Icons.sticky_note_2_outlined, color: cs.secondary),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayTasksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final todayTasks = taskProvider.todayTasks;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Công việc hôm nay', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (todayTasks.isNotEmpty)
                    Text('${todayTasks.length} việc', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (todayTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.celebration_outlined, color: cs.primary, size: 20),
                      const SizedBox(width: 12),
                      Text('Không có công việc hôm nay!',
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              ...todayTasks.take(5).map((task) => _HomeTodayTaskItem(
                task: task,
                onToggle: () => taskProvider.toggleComplete(task),
              )),
          ],
        );
      },
    );
  }
}

class _HomeTodayTaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const _HomeTodayTaskItem({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priorityColor = AppTheme.priorityColor(task.priority);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: task.completed ? cs.surfaceContainerHighest.withOpacity(0.5) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.completed ? AppTheme.priorityLow : Colors.transparent,
              border: Border.all(color: task.completed ? AppTheme.priorityLow : cs.outline, width: 2),
            ),
            child: task.completed ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
        ),
        title: Text(
          task.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            if (task.time != null) ...[
              Icon(Icons.access_time, size: 11, color: task.isOverdue ? AppTheme.priorityHigh : cs.primary),
              const SizedBox(width: 3),
              Text(
                task.time!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: task.isOverdue ? AppTheme.priorityHigh : cs.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (task.hasRepeat) ...[
              Icon(Icons.repeat, size: 11, color: cs.secondary),
              const SizedBox(width: 3),
              Text(task.repeatLabel, style: theme.textTheme.labelSmall?.copyWith(color: cs.secondary)),
            ],
          ],
        ),
        dense: true,
      ),
    );
  }
}

class _PinnedNotesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Consumer<NoteProvider>(
      builder: (context, noteProvider, _) {
        final pinnedNotes = noteProvider.pinnedNotes;
        if (pinnedNotes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.push_pin_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Ghi chú ghim', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: pinnedNotes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final note = pinnedNotes[index];
                  return Container(
                    width: 200,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.push_pin_rounded, size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                note.title.isEmpty ? 'Không có tiêu đề' : note.title,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            note.content,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onPrimaryContainer.withOpacity(0.8),
                              height: 1.4,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        if (note.tags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: note.tags.take(2).map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tag, style: theme.textTheme.labelSmall?.copyWith(color: cs.primary, fontSize: 9)),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
