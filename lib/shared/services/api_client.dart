import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/dance_style.dart';
import '../../models/video_timestamp.dart';

/// API client responsible for calling the backend `/analyze` endpoint.
///
/// The base URL is provided via a compile-time environment variable so
/// we can point different builds at different backends without code changes.
class ApiClient {
  ApiClient({http.Client? client, String? analyzeUrl})
    : _client = client ?? http.Client(),
      _analyzeUrl =
          analyzeUrl ?? const String.fromEnvironment('ANALYZE_API_URL');

  final http.Client _client;
  final String _analyzeUrl;

  /// Submit an analysis job to the backend with metadata and storage reference.
  ///
  /// The video should already be uploaded to storage; this method submits
  /// the job for asynchronous processing by the backend worker.
  ///
  /// Returns the backend reference ID for tracking the analysis job.
  /// Throws [ApiException] on any non-successful response or network error.
  Future<String?> submitAnalysisJob({
    required String storageReference,
    required String email,
    required DanceStyle danceStyle,
    List<VideoTimestamp> timestamps = const [],
    Duration trimStart = Duration.zero,
    Duration? trimEnd,
    required Duration videoDuration,
  }) async {
    if (_analyzeUrl.isEmpty) {
      // Failing fast here makes misconfiguration obvious during development.
      throw const ApiException(
        'ANALYZE_API_URL is not set. Pass --dart-define=ANALYZE_API_URL=… at build/run time.',
      );
    }

    final uri = Uri.parse(_analyzeUrl);

    // Build JSON request body
    final requestBody = <String, dynamic>{
      'email': email,
      'dance_style': danceStyle.toJson(),
      'trim_start_seconds': trimStart.inSeconds,
      'trim_end_seconds': (trimEnd?.inSeconds ?? videoDuration.inSeconds),
      'video_reference': storageReference,
    };

    // Add timestamps as JSON array if present
    if (timestamps.isNotEmpty) {
      requestBody['timestamps'] = timestamps.map((t) => t.toJson()).toList();
    }

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('Server error: HTTP ${response.statusCode}.');
      }

      // Try to extract backend reference from response
      // Backend may return a reference ID or URL for the uploaded video
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['video_reference'] as String?;
      } catch (_) {
        // If response doesn't contain a reference, return null
        return null;
      }
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on SocketException {
      throw const ApiException('Network error. Check your connection.');
    } on http.ClientException catch (e) {
      throw ApiException('Request failed: ${e.message}');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}
