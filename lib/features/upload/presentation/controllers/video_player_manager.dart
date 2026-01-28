import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Manages video player lifecycle separately from business logic.
///
/// This controller handles:
/// - Video player initialization
/// - Playback controls
/// - Position tracking
/// - Proper disposal
///
/// By separating video player management from upload business logic,
/// we achieve better testability and separation of concerns.
class VideoPlayerManager extends ChangeNotifier {
  VideoPlayerController? _controller;

  VideoPlayerController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isPlaying => _controller?.value.isPlaying ?? false;
  Duration get position => _controller?.value.position ?? Duration.zero;
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  /// Initialize video player with the given video path.
  ///
  /// Disposes any existing player before creating a new one.
  Future<void> initialize(String videoPath, {bool isWeb = false}) async {
    await disposeController();

    try {
      final VideoPlayerController controller;

      if (isWeb) {
        // For web, use network URL
        controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
      } else {
        // For mobile/desktop, use file
        controller = VideoPlayerController.file(File(videoPath));
      }

      await controller.initialize();

      // Add listener to notify when playback state changes
      controller.addListener(() {
        notifyListeners();
      });

      _controller = controller;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize video player: $e');
      rethrow;
    }
  }

  /// Play the video
  Future<void> play() async {
    await _controller?.play();
    notifyListeners();
  }

  /// Pause the video
  Future<void> pause() async {
    await _controller?.pause();
    notifyListeners();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seek to a specific position
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
    notifyListeners();
  }

  /// Dispose of the current video controller without disposing the manager itself.
  ///
  /// This allows the manager to be reused for different videos.
  Future<void> disposeController() async {
    await _controller?.dispose();
    _controller = null;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await disposeController();
    super.dispose();
  }
}
