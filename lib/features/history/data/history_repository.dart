import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../generated/api/models/job_response.dart';
import '../../../generated/api/models/job_status.dart';
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
  }) : _local = localDataSource,
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
    final localByJobId = {for (final s in localSubmissions) s.jobId: s};

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

    // Filter out hidden (soft-deleted) jobs
    items.removeWhere((item) => item.isHidden);

    // Sort newest-first by effective creation date
    items.sort((a, b) => b.effectiveCreatedAt.compareTo(a.effectiveCreatedAt));

    return (items: items, warning: warning);
  }

  // ── Hide / soft-delete ──────────────────────────────────────────────────

  /// Soft-delete a job by setting its status to FAILED_HIDDEN.
  ///
  /// TODO: Replace stub with real backend API call once the endpoint exists.
  Future<void> hideJob(String jobId) async {
    debugPrint('[HistoryRepository] hideJob stub called for jobId=$jobId');
    // Stub: the backend PATCH/PUT endpoint to set status=failed_hidden
    // does not exist yet. When it does, call it here, e.g.:
    //   await _api.client.jobs.hideJobApiV1JobsJobIdHidePatch(jobId: jobId);
  }

  // ── Feedback ────────────────────────────────────────────────────────

  /// Fetch and parse feedback items for a specific job.
  ///
  /// Uses `/api/v1/videos/{job_id}/report` which returns a JSON report
  /// matching the structure in `docs/sample_report.json`.
  ///
  /// Feedback for a given job is immutable once generated, so this method
  /// caches the parsed feedback in [HistoryLocalDataSource] and will only
  /// download it once per jobId.
  Future<List<FeedbackItem>> getJobFeedback(String jobId) async {
    // 1. Try local cache first
    try {
      final cached = _local.getFeedbackEntry(jobId);
      if (cached != null) {
        final cachedItems =
            (cached['feedbackItems'] as List<FeedbackItem>? ?? const []);
        if (cachedItems.isNotEmpty) {
          return cachedItems;
        }
      }
    } catch (e) {
      debugPrint(
        '[HistoryRepository] Failed to read cached feedback for $jobId: $e',
      );
      // Non-fatal, fall through to network
    }

    // 2. Fallback to network fetch
    try {
      final dynamic report = await _api.client.videos
          .getFeedbackReportApiV1VideosJobIdReportGet(jobId: jobId);

      // If the backend ever returns a raw JSON string, decode it.
      final dynamic decoded = report is String ? jsonDecode(report) : report;

      if (decoded is! Map<String, dynamic>) {
        debugPrint(
          '[HistoryRepository] Unexpected report shape for jobId=$jobId: $decoded',
        );
        return const <FeedbackItem>[];
      }

      final items = _parseFeedbackItemsFromReport(decoded);

      // 3. Cache for future use. The report is immutable, so we never need
      // to refresh it for the same jobId.
      try {
        await _local.upsertFeedbackEntry(
          jobId: jobId,
          reportJson: decoded,
          feedbackItems: items,
        );
      } catch (e) {
        debugPrint(
          '[HistoryRepository] Failed to cache feedback for $jobId: $e',
        );
      }

      return items;
    } catch (e) {
      debugPrint('[HistoryRepository] Failed to load feedback for $jobId: $e');
      return const <FeedbackItem>[];
    }
  }

  /// Parse the JSON report structure into a flat list of [FeedbackItem]s.
  ///
  /// Current mapping (based on `docs/sample_report.json`):
  /// - `Timestamps.Faults[*]` becomes negative feedback items with a
  ///   timestamp computed from `Scrub_Frame` and `Frame_Rate`.
  /// - The error/suggestion text is combined into a single feedback string.
  List<FeedbackItem> _parseFeedbackItemsFromReport(
    Map<String, dynamic> report,
  ) {
    final timestamps = report['Timestamps'];
    if (timestamps is! Map<String, dynamic>) {
      return const <FeedbackItem>[];
    }

    final frameRate = (timestamps['Frame_Rate'] as num?)?.toDouble() ?? 30.0;
    final faults = timestamps['Faults'];

    if (faults is! List) {
      return const <FeedbackItem>[];
    }

    final items = <FeedbackItem>[];

    for (final fault in faults) {
      if (fault is! Map<String, dynamic>) continue;

      final scrubFrame = (fault['Scrub_Frame'] as num?)?.toDouble();
      final feedbackMap = fault['Feedback'] as Map<String, dynamic>?;

      final error = feedbackMap?['Error'] as String? ?? '';
      final suggestion = feedbackMap?['Suggestion'] as String? ?? '';

      final description = [
        if (error.isNotEmpty) error,
        if (suggestion.isNotEmpty) 'Suggestion: $suggestion',
      ].join('\n');

      if (scrubFrame == null || description.isEmpty) {
        continue;
      }

      final seconds = scrubFrame / frameRate;
      final duration = Duration(milliseconds: (seconds * 1000).round());

      final timestamp = _formatDurationAsTimestamp(duration);

      items.add(
        FeedbackItem(
          timestamp: timestamp,
          type: FeedbackType.negative,
          feedback: description,
        ),
      );
    }

    return items;
  }

  /// Format a [Duration] as `M:SS` (e.g., `0:05`, `1:23`).
  String _formatDurationAsTimestamp(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final secondsPadded = seconds.toString().padLeft(2, '0');
    return '$minutes:$secondsPadded';
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
