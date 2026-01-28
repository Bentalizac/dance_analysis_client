import 'package:flutter/material.dart';

import '../design_system/theme.dart';

/// Confirmation dialog shown when user attempts to discard video with timestamps.
///
/// This dialog prevents accidental data loss by confirming the user wants to
/// discard their progress (timestamps, trim settings, etc.) before clearing
/// the selected video or navigating away.
class DiscardConfirmationDialog extends StatelessWidget {
  const DiscardConfirmationDialog({
    super.key,
    this.timestampCount = 0,
  });

  /// Number of timestamps that will be lost
  final int timestampCount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppDesignSystem.backgroundMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
      ),
      title: const Text(
        'Discard Changes?',
        style: TextStyle(
          color: AppDesignSystem.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        timestampCount > 0
            ? 'You have $timestampCount timestamp${timestampCount == 1 ? '' : 's'} that will be lost. Are you sure you want to discard your progress?'
            : 'Are you sure you want to discard your changes?',
        style: AppDesignSystem.feedbackStyle.copyWith(
          color: AppDesignSystem.textSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppDesignSystem.tabStyle.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
          ),
        ),
        // Discard button
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            backgroundColor: AppDesignSystem.errorRed.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingSm,
            ),
            child: Text(
              'Discard',
              style: AppDesignSystem.tabStyle.copyWith(
                color: AppDesignSystem.errorRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
