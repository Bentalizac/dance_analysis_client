import 'package:flutter/material.dart';

import '../design_system/theme.dart';

/// Confirmation dialog shown when user attempts to discard video with timestamps.
///
/// This dialog prevents accidental data loss by confirming the user wants to
/// discard their progress (timestamps, trim settings, etc.) before clearing
/// the selected video or navigating away.
class DiscardConfirmationDialog extends StatelessWidget {
  const DiscardConfirmationDialog({super.key, this.timestampCount = 0});

  /// Number of timestamps that will be lost
  final int timestampCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Discard Changes?'),
      content: Text(
        timestampCount > 0
            ? 'You have $timestampCount timestamp${timestampCount == 1 ? '' : 's'} that will be lost. Are you sure you want to discard your progress?'
            : 'Are you sure you want to discard your changes?',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
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
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
