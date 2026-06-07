import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
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
  late TextEditingController _tagController;
  late List<String> _tags;
  bool _hasChanges = false;
  bool _isSaving = false;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? widget.initialContent ?? '',
    );
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.note?.tags ?? []);
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final permission = await Permission.microphone.request();
    if (permission.isGranted) {
      _speechAvailable = await _speech.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          if (text.isNotEmpty) {
            final current = _contentController.text;
            final sel = _contentController.selection;
            final pos = sel.isValid ? sel.baseOffset : current.length;
            final prefix = current.substring(0, pos);
            final suffix = current.substring(pos);
            _contentController.text = '$prefix$text$suffix';
            _contentController.selection = TextSelection.collapsed(offset: pos + text.length);
          }
          setState(() => _isListening = false);
        }
      },
      localeId: 'vi_VN',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _addTag(String tag) {
    tag = tag.trim().toLowerCase();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _hasChanges = true;
    });
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final note = widget.note;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasChanges) {
          final shouldDiscard = await _showDiscardDialog();
          if (shouldDiscard && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Chỉnh sửa ghi chú' : 'Ghi chú mới'),
          actions: [
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _isSaving ? null : _saveNote,
                child: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),

        body: Column(
          children: [
            if (_isEditing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(Icons.history, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Cập nhật: ${DateTimeUtils.timeAgo(note!.updatedAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

                    TextField(
                      controller: _contentController,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
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

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(Icons.label_outline, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Tags',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _tags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => _removeTag(tag),
                          backgroundColor: colorScheme.primaryContainer,
                          labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: InputDecoration(
                              hintText: 'Thêm tag...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(Icons.add, size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                            onSubmitted: _addTag,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _addTag(_tagController.text),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Thêm', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: IconButton.filled(
                    onPressed: _toggleVoiceInput,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        key: ValueKey(_isListening),
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isListening ? colorScheme.error : colorScheme.primary,
                      foregroundColor: _isListening ? colorScheme.onError : colorScheme.onPrimary,
                    ),
                    tooltip: _isListening ? 'Dừng' : 'Ghi bằng giọng nói',
                  ),
                ),
                const SizedBox(width: 12),
                if (_isListening)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.graphic_eq, size: 16, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            'Đang nghe... Nói ngay bây giờ',
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'Nhấn mic để nhập bằng giọng nói',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    final noteProvider = context.read<NoteProvider>();
    bool success;

    if (_isEditing) {
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
        tags: _tags,
      );
      success = await noteProvider.updateNote(updatedNote);
    } else {
      final created = await noteProvider.createNote(
        title: title,
        content: content,
        tags: _tags,
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tiếp tục chỉnh sửa')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy')),
        ],
      ),
    );
    return result ?? false;
  }
}
