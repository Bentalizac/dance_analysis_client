import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/feedback_item.dart';
import '../../../models/submission.dart';

/// Persists [Submission] records and cached feedback reports to local storage
/// using [SharedPreferences].
///
/// Submissions are stored as a JSON-encoded list under a versioned key.
/// Feedback reports are stored as a JSON-encoded map of jobId -> report/
/// feedback data under a separate key.
class HistoryLocalDataSource {
  HistoryLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _submissionsKey = 'history_submissions_v1';
  static const _feedbackKey = 'history_feedback_v1';

  /// Load all locally stored submissions.
  List<Submission> loadSubmissions() {
    final raw = _prefs.getString(_submissionsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Submission.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[HistoryLocalDataSource] Failed to parse submissions: $e');
      return [];
    }
  }

  /// Persist the full list of submissions, replacing any previous data.
  Future<void> saveSubmissions(List<Submission> submissions) async {
    final encoded = jsonEncode(submissions.map((s) => s.toJson()).toList());
    await _prefs.setString(_submissionsKey, encoded);
  }

  /// Add or replace a submission by [Submission.jobId].
  ///
  /// If an entry with the same jobId already exists it is replaced;
  /// otherwise the new submission is appended.
  Future<void> upsertSubmission(Submission submission) async {
    final submissions = loadSubmissions();
    final index = submissions.indexWhere((s) => s.jobId == submission.jobId);

    if (index >= 0) {
      submissions[index] = submission;
    } else {
      submissions.add(submission);
    }

    await saveSubmissions(submissions);
  }

  // ── Feedback cache (jobId -> feedback report) ────────────────────────

  /// Load all cached feedback entries as a map of jobId -> JSON payload.
  ///
  /// Each value is a map with:
  /// - "reportJson": the raw report map returned by the backend
  /// - "feedbackItems": a list of serialized [FeedbackItem]s
  Map<String, Map<String, dynamic>> loadAllFeedbackRaw() {
    final raw = _prefs.getString(_feedbackKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (jobId, value) =>
            MapEntry(jobId, Map<String, dynamic>.from(value as Map)),
      );
    } catch (e) {
      debugPrint('[HistoryLocalDataSource] Failed to parse feedback cache: $e');
      return {};
    }
  }

  /// Persist the entire feedback cache map.
  Future<void> saveAllFeedbackRaw(
    Map<String, Map<String, dynamic>> cache,
  ) async {
    final encoded = jsonEncode(cache);
    await _prefs.setString(_feedbackKey, encoded);
  }

  /// Get cached feedback data for a specific [jobId], or null if not cached.
  ///
  /// Returns a map with:
  /// - "reportJson": Map<String, dynamic>
  /// - "feedbackItems": List<FeedbackItem>
  Map<String, dynamic>? getFeedbackEntry(String jobId) {
    final all = loadAllFeedbackRaw();
    final entry = all[jobId];
    if (entry == null) return null;

    try {
      final reportJson = Map<String, dynamic>.from(
        entry['reportJson'] as Map<dynamic, dynamic>,
      );
      final feedbackItemsRaw = entry['feedbackItems'] as List<dynamic>? ?? [];
      final feedbackItems = feedbackItemsRaw
          .map(
            (e) => FeedbackItem.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList();

      return {'reportJson': reportJson, 'feedbackItems': feedbackItems};
    } catch (e) {
      debugPrint(
        '[HistoryLocalDataSource] Failed to parse feedback entry for $jobId: $e',
      );
      return null;
    }
  }

  /// Upsert a feedback entry for [jobId] containing the raw report and
  /// the derived [feedbackItems].
  Future<void> upsertFeedbackEntry({
    required String jobId,
    required Map<String, dynamic> reportJson,
    required List<FeedbackItem> feedbackItems,
  }) async {
    final all = loadAllFeedbackRaw();
    all[jobId] = {
      'reportJson': reportJson,
      'feedbackItems': feedbackItems.map((f) => f.toJson()).toList(),
    };
    await saveAllFeedbackRaw(all);
  }
}
