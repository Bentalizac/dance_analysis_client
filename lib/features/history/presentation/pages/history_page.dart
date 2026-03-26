import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/job_status.dart';
import '../../../../models/feedback_item.dart';
import '../../../../models/history_item.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/utils/format_helpers.dart';
import '../../../../shared/utils/job_status_extensions.dart';
import '../../data/history_repository.dart';
import '../controllers/history_controller.dart';
import '../controllers/history_state.dart';
import 'history_detail_page.dart';

/// Displays the user's past uploads with live status from the backend.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final HistoryController _controller;
  bool _isFetchingFeedback = false;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController(
      repository: context.read<HistoryRepository>(),
    );
    _controller.loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(title: const Text('History'), centerTitle: true),
        body: Stack(
          children: [
            Consumer<HistoryController>(
              builder: (context, controller, _) {
                final state = controller.state;

                return switch (state.status) {
                  HistoryStatus.initial || HistoryStatus.loading =>
                    const Center(child: CircularProgressIndicator()),
                  HistoryStatus.error => _buildErrorState(state, controller),
                  HistoryStatus.loaded =>
                    state.items.isEmpty
                        ? _buildEmptyState()
                        : _buildHistoryList(state, controller),
                };
              },
            ),
            if (_isFetchingFeedback)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(HistoryState state, HistoryController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text(
              state.errorMessage ?? 'Something went wrong',
              style: AppDesignSystem.feedbackStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingLg),
            ElevatedButton.icon(
              onPressed: controller.loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text(
              'No uploads yet',
              style: TextStyle(
                color: AppDesignSystem.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'Upload a video to see it here.',
              style: AppDesignSystem.feedbackStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(HistoryState state, HistoryController controller) {
    return Column(
      children: [
        // Warning banner
        if (state.warningMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingMd,
              vertical: AppDesignSystem.spacingSm,
            ),
            color: Colors.orange.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                const SizedBox(width: AppDesignSystem.spacingSm),
                Expanded(
                  child: Text(
                    state.warningMessage!,
                    style: AppDesignSystem.smallTextStyle.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            color: AppDesignSystem.mainAccent,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacingMd,
                vertical: AppDesignSystem.spacingMd,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _HistoryListItem(
                  item: item,
                  onTap: () => _onItemTapped(context, item),
                  onDelete: () => _onDeleteTapped(context, item, controller),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _onDeleteTapped(
    BuildContext context,
    HistoryItem item,
    HistoryController controller,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesignSystem.backgroundMedium,
        title: const Text('Delete job?'),
        content: const Text('This will remove the job from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppDesignSystem.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        controller.hideJob(item.job.jobId);
      }
    });
  }

  Future<void> _onItemTapped(BuildContext context, HistoryItem item) async {
    if (item.hasFeedback) {
      setState(() {
        _isFetchingFeedback = true;
      });

      final repository = context.read<HistoryRepository>();
      List<FeedbackItem> feedbackItems = const [];

      try {
        // Fetch real feedback asynchronously from /videos/{job_id}/report.
        feedbackItems = await repository.getJobFeedback(item.job.jobId);
      } finally {
        if (mounted) {
          setState(() {
            _isFetchingFeedback = false;
          });
        }
      }

      if (!context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              HistoryDetailPage(item: item, feedbackItems: feedbackItems),
        ),
      );
    } else if (item.isInProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This video is still being processed. Check back soon.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (item.isFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.job.errorMessage ?? 'Processing failed for this video.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// A single row in the history list.
class _HistoryListItem extends StatelessWidget {
  const _HistoryListItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignSystem.spacingSm),
      child: Material(
        color: AppDesignSystem.backgroundMedium,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Video availability icon
                    _buildVideoIcon(),
                    const SizedBox(width: AppDesignSystem.spacingMd),

                    // Title + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayTitle,
                            style: TextStyle(
                              color: AppDesignSystem.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppDesignSystem.spacingXs),
                          Text(
                            formatHistoryDate(item.effectiveCreatedAt),
                            style: AppDesignSystem.smallTextStyle.copyWith(
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status chip
                    _buildStatusChip(),

                    // Delete button
                    const SizedBox(width: AppDesignSystem.spacingSm),
                    _buildDeleteButton(),
                  ],
                ),

                // Progress bar for processing jobs
                if (item.isInProgress && item.progress != null)
                  _buildProgressBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoIcon() {
    return Icon(
      item.hasLocalVideo ? Icons.videocam : Icons.videocam_off_outlined,
      color: item.hasLocalVideo
          ? AppDesignSystem.mainAccent
          : AppDesignSystem.textSecondary.withValues(alpha: 0.5),
      size: 28,
    );
  }

  Widget _buildStatusChip() {
    final status = item.effectiveStatus;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingSm,
        vertical: AppDesignSystem.spacingXs,
      ),
      decoration: BoxDecoration(
        color: status.chipColor,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == JobStatus.processing)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: status.chipTextColor,
                ),
              ),
            ),
          Text(
            status.displayLabel,
            style: AppDesignSystem.smallTextStyle.copyWith(
              color: status.chipTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(
          Icons.delete_outline,
          color: AppDesignSystem.textSecondary.withValues(alpha: 0.6),
        ),
        onPressed: onDelete,
        tooltip: 'Delete',
      ),
    );
  }

  Widget _buildProgressBar() {
    final pct = (item.progress! / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: AppDesignSystem.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppDesignSystem.mainAccent.withValues(
                alpha: 0.15,
              ),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppDesignSystem.mainAccent,
              ),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          Text(
            '${item.progress!.round()}% complete',
            style: AppDesignSystem.smallTextStyle.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
