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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(
          color: colorScheme.outline,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            message,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingXl,
            ),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
