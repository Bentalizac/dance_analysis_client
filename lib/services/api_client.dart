import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/video_timestamp.dart';
import '../state/upload_state.dart';

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

  /// Perform the upload request with video, metadata, timestamps, and trim info.
  ///
  /// Returns the backend reference ID for the uploaded video.
  /// Throws [ApiException] on any non-successful response or network error.
  Future<String?> uploadVideo({
    required SelectedVideo video,
    required String email,
    List<VideoTimestamp> timestamps = const [],
    Duration trimStart = Duration.zero,
    Duration? trimEnd,
  }) async {
    if (_analyzeUrl.isEmpty) {
      // Failing fast here makes misconfiguration obvious during development.
      throw const ApiException(
        'ANALYZE_API_URL is not set. Pass --dart-define=ANALYZE_API_URL=… at build/run time.',
      );
    }

    final uri = Uri.parse(_analyzeUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['email'] = email
      ..fields['trim_start_seconds'] = trimStart.inSeconds.toString()
      ..fields['trim_end_seconds'] =
          (trimEnd?.inSeconds ?? video.duration.inSeconds).toString();

    // Add timestamps as JSON if present
    if (timestamps.isNotEmpty) {
      final timestampsJson = timestamps.map((t) => t.toJson()).toList();
      request.fields['timestamps'] = jsonEncode(timestampsJson);
    }

    // Use XFile for cross-platform compatibility (web and mobile/desktop)
    if (kIsWeb) {
      // On web, read bytes from XFile since we don't have direct file path access
      final bytes = await video.xFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          bytes,
          filename: video.xFile.name,
        ),
      );
    } else {
      // On mobile/desktop, use the more efficient fromPath method
      request.files.add(await http.MultipartFile.fromPath('video', video.path));
    }

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
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
