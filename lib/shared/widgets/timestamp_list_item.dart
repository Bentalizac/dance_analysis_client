import 'package:flutter/material.dart';
import '../../models/video_timestamp.dart';
import '../design_system/theme.dart';

/// A single timestamp item in the list showing time and dance step label
/// Similar in style to FeedbackListItem but for user-created timestamps
/// Supports inline editing when isEditing is true
class TimestampListItem extends StatelessWidget {
  const TimestampListItem({
    super.key,
    required this.timestamp,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.isEditing = false,
    this.editForm,
  });

  final VideoTimestamp timestamp;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isEditing;
  final Widget? editForm;

  @override
  Widget build(BuildContext context) {
    // If in editing mode, show the edit form instead
    if (isEditing && editForm != null) {
      return editForm!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingXs,
        vertical: AppDesignSystem.spacingXs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingSm,
              ),
              child: Row(
                children: [
                  // Time indicator icon
                  const SizedBox(
                    width: 15,
                    child: Icon(
                      Icons.bookmark,
                      size: 16,
                      color: AppDesignSystem.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Time range (start - end)
                  Text(
                    timestamp.formattedTimeRange,
                    style: AppDesignSystem.timestampStyle.copyWith(
                      color: AppDesignSystem.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacingMd),

                  // Label
                  Expanded(
                    child: Text(
                      timestamp.label,
                      style: AppDesignSystem.feedbackStyle.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: onEdit,
                          color: AppDesignSystem.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: onDelete,
                          color: AppDesignSystem.errorRed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(color: AppDesignSystem.dividerLight),
          ),
        ],
      ),
    );
  }
}
