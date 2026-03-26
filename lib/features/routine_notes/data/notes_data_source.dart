import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [NotesClient].
class NotesDataSource {
  NotesDataSource(this._client);

  final RestClient _client;

  Future<List<NoteResponse>> listSessionNotes(String sessionId) async {
    try {
      return await _client.notes
          .listSessionNotesApiV1SessionsSessionIdNotesGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<NoteResponse> createSessionNote(
    String sessionId, {
    required NoteType noteType,
    required String contents,
    dynamic details,
  }) async {
    try {
      return await _client.notes
          .createSessionNoteApiV1SessionsSessionIdNotesPost(
        sessionId: sessionId,
        body: RoutineNoteCreate(
          noteType: noteType,
          contents: contents,
          details: details,
        ),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<NoteResponse>> listVideoNotes(
      String sessionId, String videoId) async {
    try {
      return await _client.notes
          .listVideoNotesApiV1SessionsSessionIdVideosVideoIdNotesGet(
        sessionId: sessionId,
        videoId: videoId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<NoteResponse> createVideoNote(
    String sessionId,
    String videoId, {
    required NoteType noteType,
    required String contents,
    int? videoTimestampMs,
    dynamic details,
  }) async {
    try {
      return await _client.notes
          .createVideoNoteApiV1SessionsSessionIdVideosVideoIdNotesPost(
        sessionId: sessionId,
        videoId: videoId,
        body: VideoNoteCreate(
          noteType: noteType,
          contents: contents,
          videoTimestampMs: videoTimestampMs,
          details: details,
        ),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteNote(String sessionId, String noteId) async {
    try {
      await _client.notes
          .deleteNoteApiV1SessionsSessionIdNotesNoteIdDelete(
        sessionId: sessionId,
        noteId: noteId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
