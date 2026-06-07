import 'package:flutter/material.dart';
import '../models/note.dart';
import '../utils/date_utils.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final bool isGrid;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGrid(context) : _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned) ...[
                    Icon(Icons.push_pin_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Không có tiêu đề' : note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: note.title.isEmpty ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(note.isPinned ? 'Bỏ ghim' : 'Ghim'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 12),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'pin') onTogglePin();
                      if (value == 'delete') _confirmDelete(context);
                    },
                  ),
                ],
              ),

              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 10),
              Text(
                DateTimeUtils.timeAgo(note.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned)
                    Icon(Icons.push_pin_rounded, size: 13, color: colorScheme.primary),
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Không có tiêu đề' : note.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: note.title.isEmpty ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showGridMenu(context),
                    child: Icon(Icons.more_horiz, size: 18, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (note.content.isNotEmpty)
                Expanded(
                  child: Text(
                    note.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    overflow: TextOverflow.fade,
                  ),
                )
              else
                const Spacer(),

              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: note.tags.take(2).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 6),
              Text(
                DateTimeUtils.timeAgo(note.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGridMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              title: Text(note.isPinned ? 'Bỏ ghim' : 'Ghim ghi chú'),
              onTap: () { Navigator.pop(ctx); onTogglePin(); },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text('Xóa', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () { Navigator.pop(ctx); _confirmDelete(context); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); onDelete(); },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
