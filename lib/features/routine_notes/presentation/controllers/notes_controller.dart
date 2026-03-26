import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/note_response.dart';
import '../../../../generated/api/models/note_type.dart';
import '../../data/notes_data_source.dart';

/// State for the notes list.
class NotesState {
  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<NoteResponse> notes;
  final bool isLoading;
  final String? errorMessage;
}

/// Manages notes for a session or a specific video within a session.
///
/// Intended to be scoped to [SessionDetailPage], not provided globally.
class NotesController extends ChangeNotifier {
  NotesController({required NotesDataSource dataSource})
      : _dataSource = dataSource;

  final NotesDataSource _dataSource;

  NotesState _state = const NotesState();
  NotesState get state => _state;

  Future<void> loadSessionNotes(String sessionId) async {
    _state = NotesState(isLoading: true, notes: _state.notes);
    notifyListeners();

    try {
      final notes = await _dataSource.listSessionNotes(sessionId);
      _state = NotesState(notes: notes);
    } on AppException catch (e) {
      _state = NotesState(errorMessage: e.message, notes: _state.notes);
    }
    notifyListeners();
  }

  Future<void> loadVideoNotes(String sessionId, String videoId) async {
    _state = NotesState(isLoading: true, notes: _state.notes);
    notifyListeners();

    try {
      final notes = await _dataSource.listVideoNotes(sessionId, videoId);
      _state = NotesState(notes: notes);
    } on AppException catch (e) {
      _state = NotesState(errorMessage: e.message, notes: _state.notes);
    }
    notifyListeners();
  }

  Future<bool> addSessionNote({
    required String sessionId,
    required NoteType noteType,
    required String contents,
  }) async {
    try {
      await _dataSource.createSessionNote(sessionId,
          noteType: noteType, contents: contents);
      await loadSessionNotes(sessionId);
      return true;
    } on AppException catch (e) {
      _state = NotesState(errorMessage: e.message, notes: _state.notes);
      notifyListeners();
      return false;
    }
  }

  Future<bool> addVideoNote({
    required String sessionId,
    required String videoId,
    required NoteType noteType,
    required String contents,
    int? videoTimestampMs,
  }) async {
    try {
      await _dataSource.createVideoNote(sessionId, videoId,
          noteType: noteType,
          contents: contents,
          videoTimestampMs: videoTimestampMs);
      await loadVideoNotes(sessionId, videoId);
      return true;
    } on AppException catch (e) {
      _state = NotesState(errorMessage: e.message, notes: _state.notes);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNote(String sessionId, String noteId) async {
    try {
      await _dataSource.deleteNote(sessionId, noteId);
      await loadSessionNotes(sessionId);
      return true;
    } on AppException catch (e) {
      _state = NotesState(errorMessage: e.message, notes: _state.notes);
      notifyListeners();
      return false;
    }
  }
}
