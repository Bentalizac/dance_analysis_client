import 'package:flutter/material.dart';
import '../models/feedback_item.dart';
import 'results_page.dart';

/// Demo page showing the ResultsPage with sample feedback data
/// This demonstrates what the analysis results will look like
class DemoResultsPage extends StatelessWidget {
  const DemoResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResultsPage(
        // No videoPath provided - will show placeholder
        feedbackItems: _sampleFeedbackItems,
        onTimestampTap: (duration) {
          // In a real app, this would seek the video to this timestamp
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Demo: Would seek to ${duration.inSeconds}s'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  /// Sample feedback data matching the Figma design
  static final List<FeedbackItem> _sampleFeedbackItems = [
    const FeedbackItem(timestamp: '0:08', type: FeedbackType.positive),
    const FeedbackItem(timestamp: '0:12', type: FeedbackType.positive),
    const FeedbackItem(
      timestamp: '0:14',
      type: FeedbackType.negative,
      feedback:
          'left foot should be rotated outward with weight placed on the inside edge of the ball of the foot',
    ),
    const FeedbackItem(timestamp: '0:24', type: FeedbackType.positive),
    const FeedbackItem(timestamp: '0:28', type: FeedbackType.positive),
    const FeedbackItem(
      timestamp: '0:32',
      type: FeedbackType.negative,
      feedback: 'arms should be extended more fully to create better lines',
    ),
    const FeedbackItem(timestamp: '0:45', type: FeedbackType.positive),
    const FeedbackItem(
      timestamp: '0:52',
      type: FeedbackType.negative,
      feedback: 'hip alignment needs adjustment - keep hips level and square',
    ),
    const FeedbackItem(timestamp: '1:03', type: FeedbackType.positive),
  ];
}
