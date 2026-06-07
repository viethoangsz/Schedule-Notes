import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/task.dart';
import '../../services/note_service.dart';
import '../../services/task_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_utils.dart';
import '../notes/note_editor_screen.dart';
import '../tasks/task_form_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _noteService = NoteService();
  final _taskService = TaskService();

  List<Note> _notes = [];
  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _notes = []; _tasks = []; _hasSearched = false; });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final notes = await _noteService.searchNotes(query);
      final tasks = await _taskService.searchTasks(query);
      setState(() {
        _notes = notes;
        _tasks = tasks;
        _hasSearched = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = _notes.length + _tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm ghi chú, công việc...',
            border: InputBorder.none,
            fillColor: Colors.transparent,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: _search,
        ),
        bottom: _hasSearched
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        _isLoading ? 'Đang tìm...' : 'Tìm thấy $total kết quả',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
              ? _buildHint(theme, cs)
              : total == 0
                  ? _buildEmpty(theme, cs)
                  : _buildResults(theme, cs),
    );
  }

  Widget _buildHint(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 72, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Nhập từ khóa để tìm kiếm',
            style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm trong ghi chú, công việc và tags',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 72, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử từ khóa khác',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (_notes.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.sticky_note_2_outlined,
            title: 'Ghi chú',
            count: _notes.length,
            color: cs.primary,
          ),
          ..._notes.map((note) => _NoteResultTile(
            note: note,
            query: _searchController.text,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
            ).then((_) => _search(_searchController.text)),
          )),
        ],
        if (_tasks.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.task_alt_outlined,
            title: 'Công việc',
            count: _tasks.length,
            color: cs.secondary,
          ),
          ..._tasks.map((task) => _TaskResultTile(
            task: task,
            query: _searchController.text,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
            ).then((_) => _search(_searchController.text)),
          )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteResultTile extends StatelessWidget {
  final Note note;
  final String query;
  final VoidCallback onTap;

  const _NoteResultTile({required this.note, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            note.isPinned ? Icons.push_pin : Icons.sticky_note_2_outlined,
            color: cs.onPrimaryContainer,
            size: 18,
          ),
        ),
        title: Text(
          note.title.isEmpty ? 'Không có tiêu đề' : note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.content.isNotEmpty)
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 11, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Text(
                  DateTimeUtils.timeAgo(note.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...note.tags.take(2).map((tag) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag, style: theme.textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer)),
                  )),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _TaskResultTile extends StatelessWidget {
  final Task task;
  final String query;
  final VoidCallback onTap;

  const _TaskResultTile({required this.task, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priorityColor = AppTheme.priorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            task.completed ? Icons.task_alt : Icons.radio_button_unchecked,
            color: priorityColor,
            size: 18,
          ),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 11, color: cs.onSurfaceVariant),
            const SizedBox(width: 3),
            Text(
              DateTimeUtils.friendlyDate(task.date),
              style: theme.textTheme.labelSmall?.copyWith(
                color: task.isOverdue ? cs.error : cs.onSurfaceVariant,
              ),
            ),
            if (task.time != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 11, color: cs.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(
                task.time!,
                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.priority.label,
                style: theme.textTheme.labelSmall?.copyWith(color: priorityColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
