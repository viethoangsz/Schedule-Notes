// screens/notes/note_editor_screen.dart
// Màn hình tạo/chỉnh sửa ghi chú

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note.dart';
import '../../providers/note_provider.dart';
import '../../utils/date_utils.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String? initialContent;

  const NoteEditorScreen({super.key, this.note, this.initialContent});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _hasChanges = false;
  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? widget.initialContent ?? '');

    // Lắng nghe thay đổi để biết có cần lưu không
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final note = widget.note;

    return PopScope(
      // Hỏi xác nhận nếu có thay đổi chưa lưu
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasChanges) {
          final shouldDiscard = await _showDiscardDialog();
          if (shouldDiscard && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Chỉnh sửa ghi chú' : 'Ghi chú mới'),
          actions: [
            // Toggle pin
            if (_isEditing)
              IconButton(
                icon: Icon(
                  note!.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: note.isPinned ? colorScheme.primary : null,
                ),
                onPressed: () async {
                  await context.read<NoteProvider>().togglePin(note);
                  if (context.mounted) Navigator.pop(context);
                },
                tooltip: note.isPinned ? 'Bỏ ghim' : 'Ghim',
              ),

            // Nút lưu
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _isSaving ? null : _saveNote,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),

        body: Column(
          children: [
            // Info bar (nếu đang chỉnh sửa)
            if (_isEditing)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cập nhật: ${DateTimeUtils.timeAgo(note!.updatedAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // Editor
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Tiêu đề
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tiêu đề',
                        hintStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const Divider(),
                    const SizedBox(height: 8),

                    // Nội dung
                    TextField(
                      controller: _contentController,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Bắt đầu viết...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          height: 1.6,
                        ),
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    // Padding dưới để tránh bàn phím che nội dung
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Không lưu nếu cả hai đều trống
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    final noteProvider = context.read<NoteProvider>();
    bool success;

    if (_isEditing) {
      // Cập nhật ghi chú
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      success = await noteProvider.updateNote(updatedNote);
    } else {
      // Tạo ghi chú mới
      final created = await noteProvider.createNote(
        title: title,
        content: content,
      );
      success = created != null;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi lưu ghi chú')),
        );
      }
    }
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy thay đổi?'),
        content: const Text('Các thay đổi sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục chỉnh sửa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
