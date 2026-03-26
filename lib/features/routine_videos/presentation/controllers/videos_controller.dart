import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/video_response.dart';
import '../../data/videos_data_source.dart';

/// State for the session videos list.
class VideosState {
  const VideosState({
    this.videos = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<VideoResponse> videos;
  final bool isLoading;
  final String? errorMessage;
}

/// Manages the video list for a session.
///
/// Intended to be scoped to [SessionDetailPage], not provided globally.
class VideosController extends ChangeNotifier {
  VideosController({required VideosDataSource dataSource})
      : _dataSource = dataSource;

  final VideosDataSource _dataSource;

  VideosState _state = const VideosState();
  VideosState get state => _state;

  Future<void> loadVideos(String sessionId) async {
    _state = VideosState(isLoading: true, videos: _state.videos);
    notifyListeners();

    try {
      final videos = await _dataSource.listVideos(sessionId);
      _state = VideosState(videos: videos);
    } on AppException catch (e) {
      _state = VideosState(errorMessage: e.message, videos: _state.videos);
    }
    notifyListeners();
  }

  Future<bool> deleteVideo(String sessionId, String videoId) async {
    try {
      await _dataSource.deleteVideo(sessionId, videoId);
      await loadVideos(sessionId);
      return true;
    } on AppException catch (e) {
      _state = VideosState(errorMessage: e.message, videos: _state.videos);
      notifyListeners();
      return false;
    }
  }
}
