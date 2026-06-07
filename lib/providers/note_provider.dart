// providers/note_provider.dart
// Quản lý state cho ghi chú sử dụng Provider pattern

import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NoteProvider with ChangeNotifier {
  final NoteService _noteService = NoteService();

  List<Note> _notes = [];
  List<Note> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';

  // Getters
  List<Note> get notes => _notes;
  List<Note> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  /// Lấy ghi chú được hiển thị (tìm kiếm hoặc tất cả)
  List<Note> get displayedNotes =>
      _isSearching ? _searchResults : _notes;

  /// Lấy các ghi chú được ghim
  List<Note> get pinnedNotes =>
      _notes.where((note) => note.isPinned).toList();

  /// Tải tất cả ghi chú từ database
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _noteService.getAllNotes();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo ghi chú mới
  Future<Note?> createNote({
    required String title,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      final note = Note(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      final createdNote = await _noteService.createNote(note);
      await loadNotes(); // Reload để cập nhật danh sách
      return createdNote;
    } catch (e) {
      debugPrint('Error creating note: $e');
      return null;
    }
  }

  /// Cập nhật ghi chú
  Future<bool> updateNote(Note note) async {
    try {
      await _noteService.updateNote(note);
      await loadNotes();
      return true;
    } catch (e) {
      debugPrint('Error updating note: $e');
      return false;
    }
  }

  /// Xóa ghi chú
  Future<bool> deleteNote(int id) async {
    try {
      await _noteService.deleteNote(id);
      await loadNotes();
      return true;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return false;
    }
  }

  /// Toggle ghim ghi chú
  Future<void> togglePin(Note note) async {
    try {
      await _noteService.togglePin(note);
      await loadNotes();
    } catch (e) {
      debugPrint('Error toggling pin: $e');
    }
  }

  /// Tìm kiếm ghi chú
  Future<void> search(String query) async {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;

    if (!_isSearching) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await _noteService.searchNotes(query);
    } catch (e) {
      debugPrint('Error searching notes: $e');
      _searchResults = [];
    }
    notifyListeners();
  }

  /// Xóa tìm kiếm
  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }
}
