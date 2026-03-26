import 'package:flutter/material.dart';

import '../../models/video_timestamp.dart';
import '../design_system/theme.dart';
import 'inline_timestamp_form.dart';
import 'timestamp_list_item.dart';

/// Timestamp management widget for displaying and managing dance step markers.
///
/// This widget provides a complete UI for managing timestamps including:
/// - Header with timestamp count and add button
/// - Scrollable list of timestamps with edit/delete actions
/// - Inline form for adding/editing timestamps
/// - Empty state when no timestamps exist
/// - Help text explaining timestamp functionality
///
/// The widget is designed to be reusable across different contexts (upload,
/// results review, comparison views) by accepting timestamps and callbacks
/// as parameters rather than managing state internally.
///
/// Example usage:
/// ```dart
/// TimestampManager(
///   timestamps: state.timestamps,
///   isAddingTimestamp: state.isAddingTimestamp,
///   editingTimestampId: state.editingTimestampId,
///   currentVideoPosition: Duration(seconds: 10),
///   maxDuration: Duration(seconds: 120),
///   onAddTimestamp: () => controller.startAddingTimestamp(),
///   onSaveTimestamp: (start, end, label) => controller.addTimestamp(start, end, label),
///   onEditTimestamp: (id) => controller.startEditingTimestamp(id),
///   onUpdateTimestamp: (id, start, end, label) => controller.updateTimestamp(id, start, end, label),
///   onDeleteTimestamp: (id) => controller.removeTimestamp(id),
///   onSeekToTimestamp: (time) => videoController.seekTo(time),
///   onCancelForm: () => controller.cancelTimestampForm(),
/// )
/// ```
class TimestampManager extends StatelessWidget {
  const TimestampManager({
    super.key,
    required this.timestamps,
    this.isAddingTimestamp = false,
    this.editingTimestampId,
    this.currentVideoPosition = Duration.zero,
    this.maxDuration,
    required this.onAddTimestamp,
    required this.onSaveTimestamp,
    required this.onEditTimestamp,
    required this.onUpdateTimestamp,
    required this.onDeleteTimestamp,
    required this.onSeekToTimestamp,
    required this.onCancelForm,
  });

  /// List of timestamps to display
  final List<VideoTimestamp> timestamps;

  /// Whether the add timestamp form is currently shown
  final bool isAddingTimestamp;

  /// ID of the timestamp currently being edited (null if none)
  final String? editingTimestampId;

  /// Current position of the video player
  /// Used to pre-fill the timestamp form with current time
  final Duration currentVideoPosition;

  /// Maximum duration for timestamp validation
  /// Typically the video duration
  final Duration? maxDuration;

  /// Callback invoked when user taps the "Add" button
  final VoidCallback onAddTimestamp;

  /// Callback invoked when user saves a new timestamp
  /// Receives (startTime, endTime, label)
  final void Function(Duration startTime, Duration endTime, String label)
  onSaveTimestamp;

  /// Callback invoked when user starts editing a timestamp
  /// Receives the timestamp ID
  final ValueChanged<String> onEditTimestamp;

  /// Callback invoked when user saves an edited timestamp
  /// Receives (id, startTime, endTime, label)
  final void Function(
    String id,
    Duration startTime,
    Duration endTime,
    String label,
  )
  onUpdateTimestamp;

  /// Callback invoked when user deletes a timestamp
  /// Receives the timestamp ID
  final ValueChanged<String> onDeleteTimestamp;

  /// Callback invoked when user taps a timestamp to seek the video
  /// Receives the start time to seek to
  final ValueChanged<Duration> onSeekToTimestamp;

  /// Callback invoked when user cancels the add/edit form
  final VoidCallback onCancelForm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with add button
        _buildHeader(),

        // Timestamp list or empty state
        Expanded(
          child: timestamps.isEmpty && !isAddingTimestamp
              ? _buildEmptyState()
              : _buildTimestampList(),
        ),

        // Info text
        _buildInfoText(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dance Steps',
                  style: TextStyle(
                    color: AppDesignSystem.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacingXs),
                Text(
                  timestamps.isEmpty
                      ? 'No timestamps added'
                      : '${timestamps.length} timestamp${timestamps.length == 1 ? '' : 's'}',
                  style: AppDesignSystem.feedbackStyle.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: isAddingTimestamp || editingTimestampId != null
                ? null
                : onAddTimestamp,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignSystem.mainAccent,
              foregroundColor: AppDesignSystem.textOnDark,
              disabledBackgroundColor: AppDesignSystem.textDisabled,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacingMd,
                vertical: AppDesignSystem.spacingSm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingMd,
      ),
      itemCount: timestamps.length + (isAddingTimestamp ? 1 : 0),
      itemBuilder: (context, index) {
        // Show inline add form at the end if adding
        if (isAddingTimestamp && index == timestamps.length) {
          return InlineTimestampForm(
            currentVideoPosition: currentVideoPosition,
            onSave: onSaveTimestamp,
            onCancel: onCancelForm,
            maxDuration: maxDuration,
          );
        }

        final timestamp = timestamps[index];
        final isEditing = editingTimestampId == timestamp.id;

        return TimestampListItem(
          timestamp: timestamp,
          onTap: () => onSeekToTimestamp(timestamp.startTime),
          onEdit: () => onEditTimestamp(timestamp.id),
          onDelete: () => onDeleteTimestamp(timestamp.id),
          isEditing: isEditing,
          editForm: isEditing
              ? InlineTimestampForm(
                  currentVideoPosition: currentVideoPosition,
                  existingTimestamp: timestamp,
                  onSave: (startTime, endTime, label) {
                    onUpdateTimestamp(timestamp.id, startTime, endTime, label);
                  },
                  onCancel: onCancelForm,
                  maxDuration: maxDuration,
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 40,
              color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'No timestamps yet',
              style: AppDesignSystem.feedbackStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingXs),
            Flexible(
              child: Text(
                'Add timestamps to mark different\ndance steps or routine segments',
                textAlign: TextAlign.center,
                style: AppDesignSystem.smallTextStyle.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                overflow: TextOverflow.fade,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      child: Text(
        timestamps.isEmpty
            ? 'Timestamps help mark different dance steps in longer videos for better analysis.'
            : 'Tap a timestamp to seek the video. Edit or delete as needed.',
        textAlign: TextAlign.center,
        style: AppDesignSystem.smallTextStyle.copyWith(
          color: AppDesignSystem.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
