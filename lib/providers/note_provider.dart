import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NoteProvider with ChangeNotifier {
  final NoteService _noteService = NoteService();

  List<Note> _notes = [];
  List<Note> _searchResults = [];
  List<String> _allTags = [];
  String? _activeTag;
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';

  List<Note> get notes => _notes;
  List<Note> get searchResults => _searchResults;
  List<String> get allTags => _allTags;
  String? get activeTag => _activeTag;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  List<Note> get displayedNotes {
    if (_isSearching) return _searchResults;
    if (_activeTag != null) {
      return _notes.where((n) => n.tags.contains(_activeTag)).toList();
    }
    return _notes;
  }

  List<Note> get pinnedNotes => _notes.where((note) => note.isPinned).toList();

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notes = await _noteService.getAllNotes();
      _allTags = await _noteService.getAllTags();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Note?> createNote({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    try {
      final now = DateTime.now();
      final note = Note(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        tags: tags,
      );
      final createdNote = await _noteService.createNote(note);
      await loadNotes();
      return createdNote;
    } catch (e) {
      debugPrint('Error creating note: $e');
      return null;
    }
  }

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

  Future<void> togglePin(Note note) async {
    try {
      await _noteService.togglePin(note);
      await loadNotes();
    } catch (e) {
      debugPrint('Error toggling pin: $e');
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;
    _activeTag = null;
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

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  void filterByTag(String? tag) {
    _activeTag = tag;
    _isSearching = false;
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }
}
