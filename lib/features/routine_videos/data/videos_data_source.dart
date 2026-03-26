import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [SessionVideosClient].
class VideosDataSource {
  VideosDataSource(this._client);

  final RestClient _client;

  Future<VideoRegisterResponse> registerUpload(
    String sessionId, {
    required String filename,
    String contentType = 'video/mp4',
    int? fileSize,
  }) async {
    try {
      return await _client.sessionVideos
          .registerUploadApiV1SessionsSessionIdVideosPost(
        sessionId: sessionId,
        body: VideoRegisterUpload(
          filename: filename,
          contentType: contentType,
          fileSize: fileSize,
        ),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<VideoResponse>> listVideos(String sessionId) async {
    try {
      return await _client.sessionVideos
          .listVideosApiV1SessionsSessionIdVideosGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<VideoResponse> getVideo(String sessionId, String videoId) async {
    try {
      return await _client.sessionVideos
          .getVideoApiV1SessionsSessionIdVideosVideoIdGet(
        sessionId: sessionId,
        videoId: videoId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<VideoResponse> finalizeUpload(
      String sessionId, String videoId) async {
    try {
      return await _client.sessionVideos
          .finalizeUploadApiV1SessionsSessionIdVideosVideoIdFinalizePost(
        sessionId: sessionId,
        videoId: videoId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<VideoDownloadResponse> downloadVideo(
      String sessionId, String videoId) async {
    try {
      return await _client.sessionVideos
          .downloadVideoApiV1SessionsSessionIdVideosVideoIdDownloadGet(
        sessionId: sessionId,
        videoId: videoId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteVideo(String sessionId, String videoId) async {
    try {
      await _client.sessionVideos
          .deleteVideoApiV1SessionsSessionIdVideosVideoIdDelete(
        sessionId: sessionId,
        videoId: videoId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
