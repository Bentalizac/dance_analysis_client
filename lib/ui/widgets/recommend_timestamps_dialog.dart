import 'package:flutter/material.dart';
import '../design_system.dart';

/// Dialog shown when user attempts to upload a video longer than 15 seconds
/// without adding timestamps, recommending they add timestamps for better analysis
class RecommendTimestampsDialog extends StatelessWidget {
  const RecommendTimestampsDialog({super.key, required this.videoDuration});

  final Duration videoDuration;

  String get _formattedDuration {
    final minutes = videoDuration.inMinutes;
    final seconds = videoDuration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppDesignSystem.backgroundMedium,
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: AppDesignSystem.accentBlue, size: 24),
          SizedBox(width: AppDesignSystem.spacingSm),
          Text(
            'Long Video Detected',
            style: TextStyle(
              color: AppDesignSystem.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your video is $_formattedDuration long, which is longer than the recommended 15 seconds for single-step analysis.',
            style: AppDesignSystem.feedbackStyle.copyWith(
              color: AppDesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            decoration: BoxDecoration(
              color: AppDesignSystem.backgroundDark,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              border: Border.all(
                color: AppDesignSystem.accentBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bookmark_outline,
                      color: AppDesignSystem.accentBlue,
                      size: 18,
                    ),
                    const SizedBox(width: AppDesignSystem.spacingSm),
                    Text(
                      'Recommendation',
                      style: AppDesignSystem.tabStyle.copyWith(
                        color: AppDesignSystem.accentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignSystem.spacingSm),
                Text(
                  'Add timestamps to mark different dance steps or routine segments. This will help our analysis engine provide more accurate feedback for each move.',
                  style: AppDesignSystem.smallTextStyle.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            'You can still upload without timestamps, but the analysis may be less precise for longer videos.',
            style: AppDesignSystem.smallTextStyle.copyWith(
              color: AppDesignSystem.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Upload Anyway',
            style: AppDesignSystem.tabStyle.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesignSystem.accentBlue,
            foregroundColor: AppDesignSystem.backgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
            ),
          ),
          child: const Text('Add Timestamps', style: AppDesignSystem.tabStyle),
        ),
      ],
    );
  }
}
