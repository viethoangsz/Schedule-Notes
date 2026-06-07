import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/empty_state.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm ghi chú...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
                onChanged: (query) => context.read<NoteProvider>().search(query),
              )
            : const Text('Ghi chú'),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  context.read<NoteProvider>().clearSearch();
                }
              });
            },
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
                key: ValueKey(_isGridView),
              ),
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Xem danh sách' : 'Xem lưới',
          ),
        ],
      ),

      body: Column(
        children: [
          Consumer<NoteProvider>(
            builder: (context, noteProvider, _) {
              final tags = noteProvider.allTags;
              if (tags.isEmpty || _isSearchVisible) return const SizedBox.shrink();
              return Container(
                height: 44,
                color: cs.surface,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    _TagChip(
                      label: 'Tất cả',
                      selected: noteProvider.activeTag == null,
                      onTap: () => noteProvider.filterByTag(null),
                    ),
                    ...tags.map((tag) => _TagChip(
                      label: tag,
                      selected: noteProvider.activeTag == tag,
                      onTap: () => noteProvider.filterByTag(
                        noteProvider.activeTag == tag ? null : tag,
                      ),
                    )),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: Consumer<NoteProvider>(
              builder: (context, noteProvider, _) {
                if (noteProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = noteProvider.displayedNotes;

                if (notes.isEmpty) {
                  return EmptyState(
                    icon: Icons.note_outlined,
                    title: noteProvider.isSearching
                        ? 'Không tìm thấy ghi chú'
                        : noteProvider.activeTag != null
                            ? 'Không có ghi chú với tag "${noteProvider.activeTag}"'
                            : 'Chưa có ghi chú',
                    subtitle: noteProvider.isSearching
                        ? 'Thử tìm kiếm với từ khóa khác'
                        : 'Tạo ghi chú đầu tiên của bạn',
                    actionLabel: (noteProvider.isSearching || noteProvider.activeTag != null) ? null : 'Tạo ghi chú',
                    onAction: (noteProvider.isSearching || noteProvider.activeTag != null)
                        ? null
                        : () => _openNoteEditor(context),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteCard(
                        note: note,
                        isGrid: true,
                        onTap: () => _openNoteEditor(context, note: note),
                        onTogglePin: () => noteProvider.togglePin(note),
                        onDelete: () => noteProvider.deleteNote(note.id!),
                      );
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => _openNoteEditor(context, note: note),
                      onTogglePin: () => noteProvider.togglePin(note),
                      onDelete: () => noteProvider.deleteNote(note.id!),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Ghi chú mới'),
      ),
    );
  }

  void _openNoteEditor(BuildContext context, {note}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    ).then((_) => context.read<NoteProvider>().loadNotes());
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: cs.primaryContainer,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
