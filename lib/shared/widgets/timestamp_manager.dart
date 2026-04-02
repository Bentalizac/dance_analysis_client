import 'package:flutter/material.dart';

import '../models/video_timestamp.dart';
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
  final Duration currentVideoPosition;

  /// Maximum duration for timestamp validation
  final Duration? maxDuration;

  final VoidCallback onAddTimestamp;
  final void Function(Duration startTime, Duration endTime, String label)
  onSaveTimestamp;
  final ValueChanged<String> onEditTimestamp;
  final void Function(
    String id,
    Duration startTime,
    Duration endTime,
    String label,
  )
  onUpdateTimestamp;
  final ValueChanged<String> onDeleteTimestamp;
  final ValueChanged<Duration> onSeekToTimestamp;
  final VoidCallback onCancelForm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: timestamps.isEmpty && !isAddingTimestamp
              ? _buildEmptyState(context)
              : _buildTimestampList(context),
        ),
        _buildInfoText(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dance Steps',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppDesignSystem.spacingXs),
                Text(
                  timestamps.isEmpty
                      ? 'No timestamps added'
                      : '${timestamps.length} timestamp${timestamps.length == 1 ? '' : 's'}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampList(BuildContext context) {
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

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'No timestamps yet',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingXs),
            Flexible(
              child: Text(
                'Add timestamps to mark different\ndance steps or routine segments',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
                overflow: TextOverflow.fade,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      child: Text(
        timestamps.isEmpty
            ? 'Timestamps help mark different dance steps in longer videos for better analysis.'
            : 'Tap a timestamp to seek the video. Edit or delete as needed.',
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
