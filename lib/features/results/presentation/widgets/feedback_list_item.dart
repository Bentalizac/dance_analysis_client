import 'package:flutter/material.dart';
import '../../../../models/feedback_item.dart';
import '../../../../shared/design_system/theme.dart';

/// A single feedback item in the list showing timestamp and optional feedback
class FeedbackListItem extends StatefulWidget {
  const FeedbackListItem({super.key, required this.item, this.onTimestampTap});

  final FeedbackItem item;
  final VoidCallback? onTimestampTap;

  @override
  State<FeedbackListItem> createState() => _FeedbackListItemState();
}

class _FeedbackListItemState extends State<FeedbackListItem> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    if (widget.item.hasFeedback) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    } else if (widget.onTimestampTap != null) {
      widget.onTimestampTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.item.type == FeedbackType.negative;
    final textColor = isError
        ? AppDesignSystem.errorRed
        : AppDesignSystem.textPrimary;
    final dividerColor = isError
        ? AppDesignSystem.dividerError
        : AppDesignSystem.dividerLight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingXs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timestamp row with icon
          InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingXs,
              ),
              child: Row(
                children: [
                  // Icon (up/down arrow)
                  SizedBox(
                    width: 15,
                    child: Text(
                      widget.item.icon,
                      style: AppDesignSystem.timestampStyle.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Timestamp text
                  Expanded(
                    child: Text(
                      widget.item.timestamp,
                      style: AppDesignSystem.timestampStyle.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                  // Expand/collapse indicator for items with feedback
                  if (widget.item.hasFeedback)
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: textColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          // Divider
          Container(height: 1, decoration: BoxDecoration(color: dividerColor)),

          // Detailed feedback (if present and expanded)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: widget.item.hasFeedback
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: 5,
                      left: 10,
                      right: 10,
                      bottom: AppDesignSystem.spacingMd,
                    ),
                    child: Text(
                      widget.item.feedback!,
                      style: AppDesignSystem.feedbackStyle.copyWith(
                        color: AppDesignSystem.textPrimary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
