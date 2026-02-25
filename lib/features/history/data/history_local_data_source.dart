import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/submission.dart';

/// Persists [Submission] records to local storage using [SharedPreferences].
///
/// Data is stored as a JSON-encoded list under a versioned key to allow
/// future schema migrations.
class HistoryLocalDataSource {
  HistoryLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'history_submissions_v1';

  /// Load all locally stored submissions.
  List<Submission> loadSubmissions() {
    final raw = _prefs.getString(_key);
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
    await _prefs.setString(_key, encoded);
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
}
