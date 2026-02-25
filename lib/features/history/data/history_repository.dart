import 'package:flutter/foundation.dart' show debugPrint;

import '../../../generated/api/models/job_response.dart';
import '../../../models/feedback_item.dart';
import '../../../models/history_item.dart';
import '../../../models/submission.dart';
import '../../../shared/services/api_service.dart';
import 'history_local_data_source.dart';

/// Orchestrates local submission storage and remote `/jobs` API calls
/// to produce a merged [HistoryItem] list for the History page.
class HistoryRepository {
  HistoryRepository({
    required HistoryLocalDataSource localDataSource,
    required ApiService apiService,
  })  : _local = localDataSource,
        _api = apiService;

  final HistoryLocalDataSource _local;
  final ApiService _api;

  // ── Local operations ────────────────────────────────────────────────

  /// Record a submission after a successful upload.
  Future<void> recordSubmission(Submission submission) =>
      _local.upsertSubmission(submission);

  /// Load locally cached submissions (no network).
  List<Submission> getLocalSubmissions() => _local.loadSubmissions();

  // ── Remote + merge ──────────────────────────────────────────────────

  /// Fetch remote jobs and merge with local submissions.
  ///
  /// Returns a tuple-like record:
  /// - `items`: merged history list sorted newest-first.
  /// - `warning`: non-null if the remote fetch failed but local data exists.
  ///
  /// Throws if both remote and local are empty/failed.
  Future<({List<HistoryItem> items, String? warning})> loadHistory() async {
    final localSubmissions = _local.loadSubmissions();
    final localByJobId = {
      for (final s in localSubmissions) s.jobId: s,
    };

    List<JobResponse> remoteJobs;
    String? warning;

    try {
      remoteJobs = await _api.client.jobs.listUserJobsApiV1JobsGet();
    } catch (e) {
      debugPrint('[HistoryRepository] Failed to fetch remote jobs: $e');

      if (localSubmissions.isEmpty) {
        throw HistoryLoadException(
          'Could not load history. Please check your connection and try again.',
        );
      }

      // Return local-only items with a warning
      warning = 'Could not refresh from server. Statuses may be out of date.';
      // Build items from local data only — we don't have remote JobResponse
      // objects, so we can't create HistoryItems (they require a JobResponse).
      // Instead, rethrow so the controller can decide how to handle it.
      throw HistoryLoadException(warning, hasLocalFallback: true);
    }

    // Merge: for each remote job, attach local submission if available.
    final items = <HistoryItem>[];
    final seenJobIds = <String>{};

    for (final job in remoteJobs) {
      seenJobIds.add(job.jobId);
      final submission = localByJobId[job.jobId];

      items.add(HistoryItem(submission: submission, job: job));

      // Update local cache with latest status
      if (submission != null && submission.lastKnownStatus != job.status) {
        final updated = submission.copyWith(lastKnownStatus: job.status);
        localByJobId[job.jobId] = updated;
      }
    }

    // Persist any status updates back to local storage
    await _local.saveSubmissions(localByJobId.values.toList());

    // Sort newest-first by effective creation date
    items.sort((a, b) => b.effectiveCreatedAt.compareTo(a.effectiveCreatedAt));

    return (items: items, warning: warning);
  }

  // ── Feedback (stubbed) ──────────────────────────────────────────────

  /// Returns stubbed feedback items for a completed job.
  ///
  /// In the future this will parse real feedback from the backend response.
  List<FeedbackItem> getStubbedFeedback(String jobId) {
    return const [
      FeedbackItem(timestamp: '0:05', type: FeedbackType.positive),
      FeedbackItem(
        timestamp: '0:12',
        type: FeedbackType.negative,
        feedback:
            'Left foot should be rotated outward with weight on the inside edge.',
      ),
      FeedbackItem(timestamp: '0:18', type: FeedbackType.positive),
      FeedbackItem(
        timestamp: '0:25',
        type: FeedbackType.negative,
        feedback: 'Arms should be extended more fully to create better lines.',
      ),
      FeedbackItem(timestamp: '0:30', type: FeedbackType.positive),
    ];
  }
}

/// Exception thrown when loading history fails.
class HistoryLoadException implements Exception {
  const HistoryLoadException(this.message, {this.hasLocalFallback = false});

  final String message;

  /// If true, local data is available and can be shown with a warning.
  final bool hasLocalFallback;

  @override
  String toString() => 'HistoryLoadException: $message';
}
