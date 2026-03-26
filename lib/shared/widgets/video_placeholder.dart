import 'package:flutter/material.dart';
import '../design_system/theme.dart';

/// Placeholder widget shown when video is not available
class VideoPlaceholder extends StatelessWidget {
  const VideoPlaceholder({
    super.key,
    this.height = 250,
    this.message = 'Video Playback Unavailable',
    this.subtitle =
        'The original video was not saved locally.\nReview the analysis feedback below.',
    this.icon = Icons.video_library_outlined,
  });

  /// Height of the placeholder container
  final double height;

  /// Main message to display
  final String message;

  /// Subtitle/description text
  final String subtitle;

  /// Icon to display
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(
          color: AppDesignSystem.dividerLight,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            decoration: BoxDecoration(
              color: AppDesignSystem.backgroundMedium,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppDesignSystem.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),

          // Main message
          Text(
            message,
            style: AppDesignSystem.timestampStyle.copyWith(
              color: AppDesignSystem.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingXl,
            ),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppDesignSystem.feedbackStyle.copyWith(
                color: AppDesignSystem.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
