import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../shared/design_system/theme.dart';
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
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();

    // Use addPostFrameCallback to safely access providers after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Listen for email changes
      _emailController.addListener(() {
        if (mounted) {
          context.read<UploadController>().updateEmail(_emailController.text);
        }
      });

      // Listen for video selection to initialize player
      context.read<UploadController>().addListener(_onUploadStateChanged);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    // Safely remove listener
    try {
      context.read<UploadController>().removeListener(_onUploadStateChanged);
    } catch (e) {
      // Controller may already be disposed
    }
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
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(
        title: const Text('Upload Video'),
        centerTitle: true,
      ),
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
                  if (!state.hasVideo) _buildVideoSelectionSection(controller),

                  // Video preview section
                  if (state.hasVideo) _buildVideoPreviewSection(state),

                  const SizedBox(height: AppDesignSystem.spacingLg),

                  // Email input
                  _buildEmailInput(state),

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
            color: AppDesignSystem.accentBlue,
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
                  onPressed: () => controller.pickVideo(ImageSource.gallery),
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
                  onPressed: () => controller.pickVideo(ImageSource.camera),
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
            child: const Center(
              child: CircularProgressIndicator(),
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    playerManager.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppDesignSystem.accentBlue,
                  ),
                  onPressed: playerManager.togglePlayPause,
                ),
                const SizedBox(width: AppDesignSystem.spacingMd),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<UploadController>().clearVideo();
                  },
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

  Widget _buildEmailInput(UploadState state) {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: AppDesignSystem.textPrimary),
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email address',
        prefixIcon: Icon(Icons.email, color: AppDesignSystem.accentBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: BorderSide(color: AppDesignSystem.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: const BorderSide(color: AppDesignSystem.accentBlue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: const BorderSide(color: AppDesignSystem.errorRed),
        ),
        errorText: state.email.isNotEmpty && !state.isEmailValid
            ? 'Please enter a valid email'
            : null,
      ),
    );
  }

  Widget _buildUploadButton(UploadController controller, UploadState state) {
    final isUploading = state.status == UploadStatus.uploading;

    return ElevatedButton(
      onPressed: state.canUpload && !isUploading
          ? () => controller.upload()
          : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacingMd),
        backgroundColor: AppDesignSystem.accentBlue,
        disabledBackgroundColor: AppDesignSystem.backgroundMedium,
      ),
      child: isUploading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Upload Video',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
}

