import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../design_system.dart';

/// A reusable video player widget with playback controls.
///
/// This widget provides a consistent video playback experience across the app,
/// with customizable controls including play/pause, scrubbing, and position display.
/// It automatically handles aspect ratio and responsive sizing.
///
/// Example usage:
/// ```dart
/// VideoPlayerWidget(
///   controller: myVideoPlayerController,
///   maxHeight: MediaQuery.of(context).size.height * 0.4,
///   onPositionChanged: (position) => print('Current position: $position'),
/// )
/// ```
class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.controller,
    this.maxHeight,
    this.showControls = true,
    this.onPositionChanged,
    this.overlayWidget,
  });

  /// The video player controller managing the video playback
  final VideoPlayerController controller;

  /// Optional maximum height constraint for the video player
  final double? maxHeight;

  /// Whether to show playback controls (play/pause, scrubber, position)
  final bool showControls;

  /// Optional callback invoked when video position changes
  /// Useful for syncing timestamps or other time-based features
  final ValueChanged<Duration>? onPositionChanged;

  /// Optional widget to overlay on top of the video player
  /// Useful for pose visualization, annotations, etc.
  final Widget? overlayWidget;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onVideoPositionChanged);
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onVideoPositionChanged);
      widget.controller.addListener(_onVideoPositionChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onVideoPositionChanged);
    super.dispose();
  }

  void _onVideoPositionChanged() {
    if (widget.onPositionChanged != null) {
      widget.onPositionChanged!(widget.controller.value.position);
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final child = AspectRatio(
      aspectRatio: widget.controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Video player
          VideoPlayer(widget.controller),

          // Optional overlay (for pose visualization, etc.)
          if (widget.overlayWidget != null)
            Positioned.fill(child: widget.overlayWidget!),

          // Playback controls
          if (widget.showControls) _buildControls(),
        ],
      ),
    );

    // Apply max height constraint if provided
    if (widget.maxHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: child,
      );
    }

    return child;
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Row(
        children: [
          // Play/Pause button
          IconButton(
            icon: Icon(
              widget.controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
            tooltip: widget.controller.value.isPlaying ? 'Pause' : 'Play',
          ),

          // Progress scrubber
          Expanded(
            child: VideoProgressIndicator(
              widget.controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppDesignSystem.accentBlue,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),

          // Current position display
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingSm,
            ),
            child: Text(
              _formatDuration(widget.controller.value.position),
              style: AppDesignSystem.smallTextStyle.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
