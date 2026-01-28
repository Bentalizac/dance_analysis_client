import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/pose_data.dart';
import 'pose_overlay_painter.dart';

/// Video player with pose skeleton overlay
/// Displays local video file with synchronized pose annotations
class VideoPlayerWithPoseOverlay extends StatefulWidget {
  const VideoPlayerWithPoseOverlay({
    super.key,
    required this.videoPath,
    required this.poseDataList,
    this.onTimestampChanged,
    this.highlightedKeypointIndices = const [],
    this.showControls = true,
  });

  /// Path to local video file
  final String videoPath;

  /// List of pose data for different timestamps
  final List<PoseData> poseDataList;

  /// Callback when video timestamp changes
  final Function(Duration)? onTimestampChanged;

  /// Indices of keypoints to highlight
  final List<int> highlightedKeypointIndices;

  /// Whether to show playback controls
  final bool showControls;

  @override
  State<VideoPlayerWithPoseOverlay> createState() =>
      _VideoPlayerWithPoseOverlayState();
}

class _VideoPlayerWithPoseOverlayState
    extends State<VideoPlayerWithPoseOverlay> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  PoseData? _currentPoseData;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      VideoPlayerController controller;

      if (kIsWeb) {
        // For web, use network/asset approach
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
        );
      } else {
        // For mobile/desktop, use file
        controller = VideoPlayerController.file(File(widget.videoPath));
      }

      await controller.initialize();

      controller.addListener(() {
        if (mounted) {
          _updateCurrentPoseData();
          widget.onTimestampChanged?.call(controller.value.position);
        }
      });

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  /// Find pose data closest to current video timestamp
  void _updateCurrentPoseData() {
    if (_controller == null || widget.poseDataList.isEmpty) {
      setState(() => _currentPoseData = null);
      return;
    }

    final currentSeconds = _controller!.value.position.inMilliseconds / 1000.0;

    // Find closest pose data by timestamp
    PoseData? closest;
    double minDiff = double.infinity;

    for (final poseData in widget.poseDataList) {
      final diff = (poseData.timestamp - currentSeconds).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = poseData;
      }
    }

    // Only update if within 100ms (to avoid showing wrong frame data)
    if (minDiff < 0.1 && closest != _currentPoseData) {
      setState(() => _currentPoseData = closest);
    }
  }

  /// Seek to specific timestamp
  void seekTo(Duration duration) {
    _controller?.seekTo(duration);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isInitialized || _controller == null) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        // Video with overlay
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            children: [
              // Video player
              VideoPlayer(_controller!),

              // Pose overlay
              if (_currentPoseData != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: PoseOverlayPainter(
                      poseData: _currentPoseData,
                      videoSize: _controller!.value.size,
                      highlightedKeypointIndices:
                          widget.highlightedKeypointIndices,
                    ),
                  ),
                ),

              // Play/pause overlay button
              if (widget.showControls)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: _controller!.value.isPlaying
                            ? const SizedBox.shrink()
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(16),
                                child: const Icon(
                                  Icons.play_arrow,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Video controls
        if (widget.showControls) _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.blue,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.black26,
            ),
          ),
          const SizedBox(height: 8),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_controller!.value.position),
                style: const TextStyle(fontSize: 14),
              ),
              const Text(' / '),
              Text(
                _formatDuration(_controller!.value.duration),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading video...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Failed to load video'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
              });
              _initializeVideoPlayer();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
