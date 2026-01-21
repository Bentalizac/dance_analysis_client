import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../services/api_client.dart';
import '../services/video_service.dart';
import '../state/upload_controller.dart';
import '../state/upload_state.dart';
import 'design_system.dart';
import 'widgets/recommend_timestamps_dialog.dart';
import 'widgets/timestamp_manager.dart';
import 'widgets/video_info_card.dart';
import 'widgets/video_placeholder.dart';
import 'widgets/video_player_widget.dart';
import 'widgets/video_selection_buttons.dart';

/// Upload page with video preview, timestamp management, and trimming controls.
///
/// Layout is similar to ResultsPage for consistency, with:
/// - Video player at top (with playback controls)
/// - Header section with upload info and actions
/// - Timestamp/step list below (similar to feedback list)
/// - Trimming controls (marked as TODO for complex implementation)
class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  late final UploadController _controller;
  late final TextEditingController _emailController;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Get services from Provider
    final videoService = context.read<VideoService>();
    final apiClient = context.read<ApiClient>();

    _controller = UploadController(
      videoService: videoService,
      apiClient: apiClient,
    );
    _emailController = TextEditingController();

    // Listen for email changes
    _emailController.addListener(() {
      _controller.updateEmail(_emailController.text);
    });

    // Listen for video selection to initialize player
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final state = _controller.state;

    // Initialize video player when video is selected
    if (state.hasVideo && _videoPlayerController == null) {
      _initializeVideoPlayer();
    }

    // Clean up video player when video is cleared
    if (!state.hasVideo && _videoPlayerController != null) {
      _disposeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    final video = _controller.state.video;
    if (video == null) return;

    try {
      VideoPlayerController controller;

      if (kIsWeb) {
        // For web, use network URL
        controller = VideoPlayerController.networkUrl(Uri.parse(video.path));
      } else {
        // For mobile/desktop, use file
        controller = VideoPlayerController.file(File(video.path));
      }

      await controller.initialize();

      if (mounted) {
        setState(() {
          _videoPlayerController = controller;
          _isVideoPlayerInitialized = true;
        });
      }
    } catch (e) {
      // Video player initialization failed - show placeholder instead
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load video preview: $e'),
            backgroundColor: AppDesignSystem.errorRed,
          ),
        );
      }
    }
  }

  void _disposeVideoPlayer() {
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    // Only call setState if still mounted
    if (mounted) {
      setState(() {
        _isVideoPlayerInitialized = false;
      });
    } else {
      // If not mounted, just update the field directly
      _isVideoPlayerInitialized = false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _disposeVideoPlayer();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    final state = _controller.state;

    // Check if we should recommend timestamps
    if (state.shouldRecommendTimestamps) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) =>
            RecommendTimestampsDialog(videoDuration: state.effectiveDuration),
      );

      // If user chose to add timestamps instead, don't proceed with upload
      if (shouldProceed == false) {
        return;
      }
    }

    // Proceed with upload
    await _controller.upload();

    // Show success message if upload succeeded
    if (mounted && _controller.state.status == UploadStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Duration get _currentVideoPosition =>
      _videoPlayerController?.value.position ?? Duration.zero;

  void _seekToTimestamp(Duration startTime) {
    _videoPlayerController?.seekTo(startTime);
  }

  bool _isBusy(UploadState state) {
    return switch (state.status) {
      UploadStatus.uploading || UploadStatus.processing => true,
      _ => false,
    };
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Practice Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Video player or placeholder
                  if (state.hasVideo && _isVideoPlayerInitialized)
                    VideoPlayerWidget(
                      controller: _videoPlayerController!,
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    )
                  else if (state.hasVideo)
                    _buildVideoLoadingPlaceholder()
                  else
                    const VideoPlaceholder(),

                  // Header section with actions
                  _buildHeaderSection(state),

                  // Timestamp list (similar to feedback list)
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 200,
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppDesignSystem.backgroundMedium,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDesignSystem.radiusSm),
                        topRight: Radius.circular(AppDesignSystem.radiusSm),
                      ),
                    ),
                    child: state.hasVideo
                        ? TimestampManager(
                            timestamps: state.timestamps,
                            isAddingTimestamp: state.isAddingTimestamp,
                            editingTimestampId: state.editingTimestampId,
                            currentVideoPosition: _currentVideoPosition,
                            maxDuration: state.video?.duration,
                            onAddTimestamp: _controller.startAddingTimestamp,
                            onSaveTimestamp: _controller.addTimestamp,
                            onEditTimestamp: _controller.startEditingTimestamp,
                            onUpdateTimestamp: (id, start, end, label) {
                              _controller.updateTimestamp(
                                id,
                                startTime: start,
                                endTime: end,
                                label: label,
                              );
                            },
                            onDeleteTimestamp: _controller.removeTimestamp,
                            onSeekToTimestamp: _seekToTimestamp,
                            onCancelForm: _controller.cancelTimestampForm,
                          )
                        : _buildEmptyVideoState(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoLoadingPlaceholder() {
    return Container(
      height: 300,
      color: AppDesignSystem.backgroundDark,
      child: const Center(
        child: CircularProgressIndicator(color: AppDesignSystem.accentBlue),
      ),
    );
  }

  Widget _buildHeaderSection(UploadState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email input
          if (!state.hasVideo) ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppDesignSystem.textPrimary),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(
                  color: AppDesignSystem.textSecondary,
                ),
                hintText: 'you@example.com',
                hintStyle: TextStyle(
                  color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                ),
                errorText: state.email.isEmpty || state.isEmailValid
                    ? null
                    : 'Enter a valid email',
                filled: true,
                fillColor: AppDesignSystem.backgroundMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
          ],

          // Video selection buttons or video info
          if (!state.hasVideo)
            VideoSelectionButtons(
              onVideoSelected: _controller.pickVideo,
              isBusy: _isBusy(state),
            )
          else
            VideoInfoCard(
              durationSeconds: state.effectiveDuration.inSeconds,
              sizeMb: state.video!.sizeBytes / (1024 * 1024),
              isTrimmed: state.isTrimmed,
              trimStartFormatted: _formatDuration(state.trimStart),
              trimEndFormatted: _formatDuration(
                state.trimEnd ?? state.video!.duration,
              ),
              canUpload: state.canUpload,
              isBusy: _isBusy(state),
              statusLabel: state.statusLabel,
              onUpload: _handleUpload,
              onRemove: () {
                setState(() {
                  _controller.pickVideo(ImageSource.gallery);
                });
              },
            ),

          // Error message
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppDesignSystem.spacingSm),
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: AppDesignSystem.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                border: Border.all(
                  color: AppDesignSystem.errorRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppDesignSystem.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingSm),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: AppDesignSystem.feedbackStyle.copyWith(
                        color: AppDesignSystem.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyVideoState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
            const Text(
              'No video selected',
              style: TextStyle(
                color: AppDesignSystem.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'Select or record a video to get started',
              textAlign: TextAlign.center,
              style: AppDesignSystem.smallTextStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
