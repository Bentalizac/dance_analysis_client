import 'package:flutter/material.dart';

import '../../../../models/feedback_item.dart';
import '../../../../models/history_item.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../results/presentation/pages/results_page.dart';

/// Detail view for a completed history item.
///
/// Reuses [ResultsPage] for video playback and feedback display.
/// If the local video file is unavailable, ResultsPage shows a placeholder.
class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({
    super.key,
    required this.item,
    required this.feedbackItems,
  });

  final HistoryItem item;
  final List<FeedbackItem> feedbackItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(
        title: Text(item.displayTitle),
        centerTitle: true,
      ),
      body: ResultsPage(
        videoPath: item.localVideoPath,
        feedbackItems: feedbackItems,
        onTimestampTap: (duration) {
          // Video scrubbing is handled internally by ResultsPage's
          // VideoPlayerWithPoseOverlay. This callback is available
          // for additional actions if needed.
        },
      ),
    );
  }
}
