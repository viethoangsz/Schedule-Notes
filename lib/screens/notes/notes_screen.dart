// screens/notes/notes_screen.dart
// Màn hình danh sách ghi chú

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
                onChanged: (query) {
                  context.read<NoteProvider>().search(query);
                },
              )
            : const Text('Ghi chú'),
        actions: [
          // Toggle search
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
        ],
      ),

      body: Consumer<NoteProvider>(
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
                  : 'Chưa có ghi chú',
              subtitle: noteProvider.isSearching
                  ? 'Thử tìm kiếm với từ khóa khác'
                  : 'Tạo ghi chú đầu tiên của bạn',
              actionLabel: noteProvider.isSearching ? null : 'Tạo ghi chú',
              onAction: noteProvider.isSearching
                  ? null
                  : () => _openNoteEditor(context),
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

      // FAB tạo ghi chú mới
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
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    ).then((_) => context.read<NoteProvider>().loadNotes());
  }
}
