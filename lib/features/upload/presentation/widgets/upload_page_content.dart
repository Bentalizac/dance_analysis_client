import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../config/routes.dart';
import '../../../../models/dance_style.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/discard_confirmation_dialog.dart';
import '../../../../shared/widgets/timestamp_manager.dart';
import '../controllers/upload_controller.dart';
import '../controllers/upload_state.dart';
import '../controllers/video_player_manager.dart';

/// Main content widget for the upload page.
///
/// Separated from UploadPage to allow testing and cleaner provider access.
/// This widget watches the UploadController and VideoPlayerManager for state changes.
class UploadPageContent extends StatefulWidget {
  const UploadPageContent({super.key});

  @override
  State<UploadPageContent> createState() => _UploadPageContentState();
}

class _UploadPageContentState extends State<UploadPageContent> {
  bool _isCheckingAuthForPicker = false;

  Future<bool> _ensureAuthenticatedForUpload() async {
    final auth = context.read<AuthService>();

    // Already signed in – allow immediately
    if (auth.isAuthenticated) {
      return true;
    }

    setState(() {
      _isCheckingAuthForPicker = true;
    });

    try {
      // Push login page and wait for result
      final result = await context.push<bool>('/login');

      // Consider it successful only if:
      // - login route returned true AND
      // - auth state now reports authenticated
      return result == true && mounted && auth.isAuthenticated;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuthForPicker = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Use addPostFrameCallback to safely access providers after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Listen for video selection to initialize player
      context.read<UploadController>().addListener(_onUploadStateChanged);

      // Register navigation guard for bottom nav
      registerUploadPageGuard(() => _handleNavigationAttempt(context));
    });
  }

  @override
  void dispose() {
    // Safely remove listener
    try {
      context.read<UploadController>().removeListener(_onUploadStateChanged);
    } catch (e) {
      // Controller may already be disposed
    }
    // Unregister navigation guard
    registerUploadPageGuard(null);
    super.dispose();
  }

  void _onUploadStateChanged() {
    if (!mounted) return;

    final controller = context.read<UploadController>();
    final state = controller.state;

    // Initialize video player when video is selected
    if (state.hasVideo) {
      final playerManager = context.read<VideoPlayerManager>();

      // Only initialize if not already initialized
      if (!playerManager.isInitialized) {
        final videoPath = state.video!.path;
        playerManager.initialize(videoPath, isWeb: false).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not load video preview: $e'),
                backgroundColor: AppDesignSystem.errorRed,
              ),
            );
          }
          return null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UploadController>();

    return PopScope(
      canPop: !controller.hasUnsavedWork,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If we reach here, canPop was false, meaning there's unsaved work
        final confirmed = await _handleNavigationAttempt(context);
        if (confirmed && context.mounted) {
          // Clear the work and pop
          controller.clearVideo();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(title: const Text('Upload Video'), centerTitle: true),
        body: Consumer<UploadController>(
          builder: (context, controller, _) {
            final state = controller.state;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Video selection section
                    if (!state.hasVideo)
                      _buildVideoSelectionSection(controller),

                    // Video preview section
                    if (state.hasVideo) _buildVideoPreviewSection(state),

                    const SizedBox(height: AppDesignSystem.spacingLg),

                    // Timestamp management section (only show when video is loaded)
                    if (state.hasVideo) ...[
                      _buildTimestampSection(controller, state),
                      const SizedBox(height: AppDesignSystem.spacingLg),
                    ],

                    // Dance style dropdown
                    _buildDanceStyleDropdown(controller, state),

                    const SizedBox(height: AppDesignSystem.spacingLg),

                    // Upload button
                    _buildUploadButton(controller, state),

                    // Error message
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppDesignSystem.spacingMd),
                      _buildErrorMessage(state.errorMessage!),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoSelectionSection(UploadController controller) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(color: AppDesignSystem.dividerLight, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: AppDesignSystem.mainAccent,
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            'Select a Video',
            style: TextStyle(
              color: AppDesignSystem.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingSm),
          Text(
            'Choose a dance practice video to analyze',
            style: AppDesignSystem.feedbackStyle.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDesignSystem.spacingLg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCheckingAuthForPicker
                      ? null
                      : () async {
                          final allowed = await _ensureAuthenticatedForUpload();
                          if (!allowed || !mounted) return;
                          controller.pickVideo(ImageSource.gallery);
                        },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDesignSystem.spacingMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingMd),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCheckingAuthForPicker
                      ? null
                      : () async {
                          final allowed = await _ensureAuthenticatedForUpload();
                          if (!allowed || !mounted) return;
                          controller.pickVideo(ImageSource.camera);
                        },
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDesignSystem.spacingMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreviewSection(UploadState state) {
    return Consumer<VideoPlayerManager>(
      builder: (context, playerManager, _) {
        if (!playerManager.isInitialized) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppDesignSystem.backgroundMedium,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
              ),
              child: AspectRatio(
                aspectRatio: playerManager.controller!.value.aspectRatio,
                child: VideoPlayer(playerManager.controller!),
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            // Video scrubber
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacingMd,
              ),
              child: Column(
                children: [
                  VideoProgressIndicator(
                    playerManager.controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppDesignSystem.mainAccent,
                      bufferedColor: AppDesignSystem.mainAccent.withValues(
                        alpha: 0.3,
                      ),
                      backgroundColor: AppDesignSystem.dividerLight,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(playerManager.position),
                        style: AppDesignSystem.smallTextStyle.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                      Text(
                        _formatDuration(playerManager.duration),
                        style: AppDesignSystem.smallTextStyle.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    playerManager.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppDesignSystem.mainAccent,
                  ),
                  onPressed: playerManager.togglePlayPause,
                ),
                const SizedBox(width: AppDesignSystem.spacingMd),
                ElevatedButton.icon(
                  onPressed: () => _handleClearVideo(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesignSystem.backgroundMedium,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDanceStyleDropdown(
    UploadController controller,
    UploadState state,
  ) {
    return DropdownButtonFormField<DanceStyle>(
      key: ValueKey(state.danceStyle),
      initialValue: state.danceStyle,
      decoration: InputDecoration(
        labelText: 'Dance Style',
        hintText: 'Select the type of dance',
        prefixIcon: Icon(Icons.music_note, color: AppDesignSystem.mainAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: BorderSide(color: AppDesignSystem.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: const BorderSide(color: AppDesignSystem.mainAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: const BorderSide(color: AppDesignSystem.errorRed),
        ),
      ),
      dropdownColor: AppDesignSystem.backgroundMedium,
      style: TextStyle(color: AppDesignSystem.textPrimary),
      items: DanceStyle.values.map((style) {
        return DropdownMenuItem<DanceStyle>(
          value: style,
          child: Text(style.displayName),
        );
      }).toList(),
      onChanged: (DanceStyle? newValue) {
        controller.updateDanceStyle(newValue);
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a dance style';
        }
        return null;
      },
    );
  }

  Widget _buildUploadButton(UploadController controller, UploadState state) {
    final isUploading =
        state.status == UploadStatus.uploadingToStorage ||
        state.status == UploadStatus.submittingJob;

    if (!isUploading) {
      return ElevatedButton(
        onPressed: state.canUpload ? () => controller.upload() : null,
        style:
            ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingMd,
              ),
              backgroundColor: AppDesignSystem.mainAccent,
              foregroundColor: AppDesignSystem.textPrimary,
              disabledBackgroundColor: AppDesignSystem.backgroundMedium,
              disabledForegroundColor: AppDesignSystem.textDisabled,
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppDesignSystem.backgroundMedium;
                }
                if (states.contains(WidgetState.hovered)) {
                  return AppDesignSystem.mainAccentHover;
                }
                return AppDesignSystem.mainAccent;
              }),
            ),
        child: const Text(
          'Upload Video',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Progress bar that fills the button shape from left to right
    final progress = (state.uploadProgress ?? 0.0).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            // Background track
            const Positioned.fill(
              child: ColoredBox(color: AppDesignSystem.backgroundMedium),
            ),
            // Progress fill
            FractionallySizedBox(
              widthFactor: progress,
              heightFactor: 1.0,
              child: const ColoredBox(color: AppDesignSystem.mainAccent),
            ),
            // Label
            Center(
              child: Text(
                state.status == UploadStatus.submittingJob
                    ? 'Submitting…'
                    : progress >= 1.0
                    ? 'Processing…'
                    : 'Uploading… ${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppDesignSystem.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: AppDesignSystem.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        border: Border.all(color: AppDesignSystem.errorRed),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: AppDesignSystem.errorRed),
          const SizedBox(width: AppDesignSystem.spacingSm),
          Expanded(
            child: Text(
              message,
              style: AppDesignSystem.feedbackStyle.copyWith(
                color: AppDesignSystem.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle navigation attempt with confirmation if there's unsaved work
  Future<bool> _handleNavigationAttempt(BuildContext context) async {
    final controller = context.read<UploadController>();

    // Check if there's unsaved work (video selected with timestamps)
    if (!controller.hasUnsavedWork) {
      return true; // Allow navigation
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DiscardConfirmationDialog(
        timestampCount: controller.state.timestamps.length,
      ),
    );

    return confirmed == true;
  }

  /// Handle clearing video with confirmation if timestamps exist
  Future<void> _handleClearVideo(BuildContext context) async {
    final controller = context.read<UploadController>();
    final state = controller.state;

    // If there are timestamps, show confirmation dialog
    if (state.timestamps.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppDesignSystem.backgroundMedium,
          title: Text(
            'Clear Video?',
            style: TextStyle(color: AppDesignSystem.textPrimary),
          ),
          content: Text(
            'You have ${state.timestamps.length} timestamp${state.timestamps.length == 1 ? '' : 's'}. '
            'Clearing the video will remove all timestamps. This cannot be undone.',
            style: TextStyle(color: AppDesignSystem.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppDesignSystem.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Clear',
                style: TextStyle(color: AppDesignSystem.errorRed),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    controller.clearVideo();
  }

  /// Format duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTimestampSection(
    UploadController controller,
    UploadState state,
  ) {
    return Consumer<VideoPlayerManager>(
      builder: (context, playerManager, _) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppDesignSystem.backgroundMedium,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          ),
          child: TimestampManager(
            timestamps: state.timestamps,
            isAddingTimestamp: state.isAddingTimestamp,
            editingTimestampId: state.editingTimestampId,
            currentVideoPosition: playerManager.position,
            maxDuration: state.video?.duration,
            onAddTimestamp: controller.startAddingTimestamp,
            onSaveTimestamp: (start, end, label) {
              controller.addTimestamp(start, end, label);
            },
            onEditTimestamp: controller.startEditingTimestamp,
            onUpdateTimestamp: (id, start, end, label) {
              controller.updateTimestamp(
                id,
                startTime: start,
                endTime: end,
                label: label,
              );
            },
            onDeleteTimestamp: controller.removeTimestamp,
            onSeekToTimestamp: (time) {
              playerManager.seekTo(time);
            },
            onCancelForm: controller.cancelTimestampForm,
          ),
        );
      },
    );
  }
}
