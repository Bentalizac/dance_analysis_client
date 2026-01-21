import 'package:flutter/material.dart';
import '../models/feedback_item.dart';
import '../models/pose_data.dart';
import 'design_system.dart';
import 'widgets/feedback_list_item.dart';
import 'widgets/video_placeholder.dart';
import 'widgets/video_player_with_overlay.dart';

/// Results page showing video analysis feedback with timestamps
class ResultsPage extends StatefulWidget {
  const ResultsPage({
    super.key,
    required this.feedbackItems,
    this.videoPath,
    this.poseDataList = const [],
    this.onTimestampTap,
  });

  final List<FeedbackItem> feedbackItems;
  final String? videoPath;
  final List<PoseData> poseDataList;
  final Function(Duration)? onTimestampTap;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Video player (if video path is provided)
          if (widget.videoPath != null)
            VideoPlayerWithPoseOverlay(
              videoPath: widget.videoPath!,
              poseDataList: widget.poseDataList,
              onTimestampChanged: (duration) {
                // Timestamp updates tracked by video player
              },
            )
          else
            _buildVideoPlaceholder(),

          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingMd,
              vertical: AppDesignSystem.spacingLg,
            ),
            child: Column(
              children: [
                const Text(
                  'Analysis Results',
                  style: TextStyle(
                    color: AppDesignSystem.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacingSm),
                Text(
                  '${widget.feedbackItems.length} timestamps',
                  style: AppDesignSystem.feedbackStyle.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Feedback list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundMedium,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDesignSystem.radiusSm),
                  topRight: Radius.circular(AppDesignSystem.radiusSm),
                ),
              ),
              child: widget.feedbackItems.isEmpty
                  ? _buildEmptyState()
                  : _buildFeedbackList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: AppDesignSystem.textSecondary,
          ),
          SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            'No feedback available',
            style: TextStyle(
              color: AppDesignSystem.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingXl,
      ),
      itemCount: widget.feedbackItems.length,
      itemBuilder: (context, index) {
        final item = widget.feedbackItems[index];
        return FeedbackListItem(
          item: item,
          onTimestampTap: widget.onTimestampTap != null
              ? () => widget.onTimestampTap!(item.duration)
              : null,
        );
      },
    );
  }

  Widget _buildVideoPlaceholder() {
    return const VideoPlaceholder();
  }
}
