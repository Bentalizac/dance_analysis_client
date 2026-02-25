import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/job_status.dart';
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
        backgroundColor: AppDesignSystem.backgroundDark,
        appBar: AppBar(title: const Text('History'), centerTitle: true),
        body: Consumer<HistoryController>(
          builder: (context, controller, _) {
            final state = controller.state;

            return switch (state.status) {
              HistoryStatus.initial ||
              HistoryStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
              HistoryStatus.error => _buildErrorState(state, controller),
              HistoryStatus.loaded => state.items.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(state, controller),
            };
          },
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
            color: AppDesignSystem.accentBlue,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacingMd,
                vertical: AppDesignSystem.spacingMd,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                return _HistoryListItem(
                  item: state.items[index],
                  onTap: () => _onItemTapped(context, state.items[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _onItemTapped(BuildContext context, HistoryItem item) {
    if (item.hasFeedback) {
      final repository = context.read<HistoryRepository>();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HistoryDetailPage(
            item: item,
            feedbackItems: repository.getStubbedFeedback(item.job.jobId),
          ),
        ),
      );
    } else if (item.isInProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This video is still being processed. Check back soon.'),
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
  const _HistoryListItem({required this.item, required this.onTap});

  final HistoryItem item;
  final VoidCallback onTap;

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
            child: Row(
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
          ? AppDesignSystem.accentBlue
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
}
