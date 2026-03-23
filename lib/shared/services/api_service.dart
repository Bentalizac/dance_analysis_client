import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;

import '../../generated/api/export.dart';
import '../../features/upload/presentation/controllers/upload_state.dart';
import 'token_refresh_interceptor.dart';

/// Service for all API communication using the generated REST client.
///
/// Handles:
/// - Dio configuration (base URL, timeouts, interceptors)
/// - Presigned URL upload flow for video analysis
/// - Error transformation to user-friendly messages
class ApiService {
  ApiService({Dio? dio, String? baseUrl})
    : _baseUrl = baseUrl ?? _getBaseUrl(),
      _dio = dio ?? Dio() {
    _configureDio();
    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  final Dio _dio;
  final String _baseUrl;
  late final RestClient _client;
  String? _authToken;

  // In-memory cookie jar so the HTTP-only refresh token cookie set by the
  // backend on /login is automatically sent with subsequent requests (e.g.
  // /refresh). On web the browser manages cookies natively, so we skip this.
  final CookieJar _cookieJar = CookieJar();

  /// Access to the generated REST client for direct API calls.
  RestClient get client => _client;

  static String _getBaseUrl() {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    if (baseUrl.isNotEmpty) return baseUrl;

    // Fallback: derive from legacy ANALYZE_API_URL
    const analyzeUrl = String.fromEnvironment('ANALYZE_API_URL');
    if (analyzeUrl.isNotEmpty) {
      // Strip /analyze suffix if present to get base URL
      if (analyzeUrl.endsWith('/analyze')) {
        return analyzeUrl.substring(0, analyzeUrl.length - 8);
      }
      return analyzeUrl;
    }

    return '';
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 5), // Longer for uploads
      // On web, instruct XMLHttpRequest to include credentials (cookies) for
      // cross-origin requests so the browser sends the refresh token cookie.
      extra: kIsWeb ? {'withCredentials': true} : {},
    );

    // On native platforms, manage cookies explicitly so the HTTP-only refresh
    // token cookie is persisted and attached to every request automatically.
    // On web the browser already handles this — adding CookieManager there
    // could interfere with browser-managed cookies.
    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }

    // Auth interceptor: injects Bearer token into every request when available.
    // This is more reliable than setting headers on BaseOptions because it
    // guarantees the current token is attached at request time.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    // Error interceptor for consistent error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Transform DioExceptions to more user-friendly messages
          handler.next(error);
        },
      ),
    );
  }

  /// Set the bearer auth token for all subsequent API calls.
  ///
  /// The token is stored in memory and injected into each request by the auth
  /// interceptor, ensuring the current token is always used.
  ///
  /// Passing `null` is equivalent to [clearAuthToken].
  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      clearAuthToken();
      return;
    }

    _authToken = token;
  }

  /// Clear any configured auth token.
  void clearAuthToken() {
    _authToken = null;
  }

  /// Attach the [TokenRefreshInterceptor] to Dio.
  ///
  /// Called once by [AuthService] after it is constructed so the interceptor
  /// can use [AuthService]'s own methods as callbacks without creating a
  /// circular dependency at construction time.
  ///
  /// - [refreshAccessToken]: Calls the backend refresh endpoint and returns
  ///   the new access token. Must also update the token in this service as a
  ///   side effect.
  /// - [onSessionExpired]: Called when the session cannot be recovered (e.g.
  ///   the refresh token itself is expired or invalid). Should clear local
  ///   auth state without making further authenticated network calls.
  void attachTokenRefreshInterceptor({
    required Future<String?> Function() refreshAccessToken,
    required Future<void> Function() onSessionExpired,
  }) {
    _dio.interceptors.add(
      TokenRefreshInterceptor(
        dio: _dio,
        refreshAccessToken: refreshAccessToken,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  /// Upload a video using the presigned URL flow and submit for analysis.
  ///
  /// Flow:
  /// 1. Request presigned upload URL from backend
  /// 2. PUT video bytes directly to S3
  /// 3. Confirm upload to start analysis processing
  ///
  /// Returns the job ID for tracking the analysis.
  /// Throws [ApiServiceException] on failure.
  Future<String> uploadAndSubmitVideo(
    SelectedVideo video, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    debugPrint(
      '[ApiService] uploadAndSubmitVideo start: '
      'file=${video.xFile.name}, path=${video.xFile.path}, '
      'size=${video.sizeBytes} bytes, duration=${video.duration.inMilliseconds}ms',
    );

    if (_baseUrl.isEmpty) {
      debugPrint('[ApiService] uploadAndSubmitVideo abort: empty _baseUrl');
      throw const ApiServiceException(
        'API_BASE_URL is not configured. '
        'Pass --dart-define=API_BASE_URL=... at build/run time.',
      );
    }

    try {
      // Step 1: Get presigned upload URL
      debugPrint('[ApiService] Requesting presigned upload URL…');
      final uploadUrlResponse = await _client.analyze
          .requestUploadUrlApiV1AnalyzeUploadUrlPost(
            filename: video.xFile.name,
            contentType: 'video/mp4',
          );
      debugPrint(
        '[ApiService] Received upload URL response keys: '
        '${uploadUrlResponse.keys.toList()}',
      );

      final uploadUrl = uploadUrlResponse['upload_url'] as String?;
      final jobId = uploadUrlResponse['job_id'] as String?;
      final s3Key = uploadUrlResponse['s3_key'] as String?;

      if (uploadUrl == null || jobId == null || s3Key == null) {
        debugPrint(
          '[ApiService] Invalid upload URL response: uploadUrl=$uploadUrl, '
          'jobId=$jobId, s3Key=$s3Key',
        );
        throw const ApiServiceException(
          'Invalid response from upload URL endpoint.',
        );
      }

      debugPrint(
        '[ApiService] Starting upload to storage: '
        'jobId=$jobId, s3Key=$s3Key, uploadUrl(length)=${uploadUrl.length}',
      );

      // Step 2: Upload video bytes directly to S3
      await _uploadToPresignedUrl(
        uploadUrl,
        video,
        onSendProgress: onSendProgress,
      );

      debugPrint(
        '[ApiService] Upload to storage completed, confirming upload for jobId=$jobId',
      );

      // Step 3: Confirm upload and start analysis
      await _client.analyze
          .confirmUploadAndStartAnalysisApiV1AnalyzeConfirmPost(
            jobId: jobId,
            s3Key: s3Key,
          );

      debugPrint(
        '[ApiService] confirmUploadAndStartAnalysis successful for jobId=$jobId',
      );
      return jobId;
    } on DioException catch (e, stack) {
      debugPrint(
        '[ApiService] DioException in uploadAndSubmitVideo: '
        'type=${e.type}, message=${e.message}, error=${e.error}',
      );
      debugPrint('[ApiService] DioException stack trace:\n$stack');
      throw ApiServiceException(
        'Network error during upload: ${e.message ?? e.error ?? 'Unknown Dio error'}',
      );
    } on ApiServiceException {
      // Re-throw with previous debugPrints already logged.
      rethrow;
    } catch (e, stack) {
      debugPrint(
        '[ApiService] Unexpected exception in uploadAndSubmitVideo: $e',
      );
      debugPrint('[ApiService] Stack trace:\n$stack');
      throw ApiServiceException('Unexpected error during upload: $e');
    }
  }

  /// PUT video bytes to the presigned S3 URL.
  Future<void> _uploadToPresignedUrl(
    String uploadUrl,
    SelectedVideo video, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    debugPrint(
      '[ApiService] _uploadToPresignedUrl: preparing file stream for '
      'path=${video.xFile.path}, originalSize=${video.sizeBytes}',
    );

    final file = File(video.xFile.path);

    if (!await file.exists()) {
      debugPrint(
        '[ApiService] _uploadToPresignedUrl: file does not exist at path=${video.xFile.path}',
      );
      throw const ApiServiceException(
        'Local video file no longer exists. Please re-select the video.',
      );
    }

    final length = await file.length();
    debugPrint(
      '[ApiService] _uploadToPresignedUrl: actual file length=$length bytes',
    );

    final stream = file.openRead();

    // Use a separate Dio instance for S3 upload (no auth headers, different base)
    final s3Dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        // Increase send timeout further to avoid server-side timeouts on slow networks
        sendTimeout: const Duration(minutes: 15),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    try {
      debugPrint(
        '[ApiService] _uploadToPresignedUrl: initiating PUT to presigned URL '
        '(length header=$length)…',
      );

      // Stream from disk with an explicit Content-Length.
      // This avoids loading the whole file into memory and prevents
      // Dio from falling back to chunked transfer encoding.
      await s3Dio.put<void>(
        uploadUrl,
        data: stream,
        options: Options(
          headers: {'Content-Type': 'video/mp4', 'Content-Length': length},
          // Ensure we don't accidentally add auth or other headers
          followRedirects: true,
        ),
        onSendProgress: (sent, total) {
          debugPrint(
            '[ApiService] _uploadToPresignedUrl onSendProgress: '
            '$sent / $total bytes',
          );
          if (onSendProgress != null) {
            onSendProgress(sent, total);
          }
        },
      );

      debugPrint(
        '[ApiService] _uploadToPresignedUrl: PUT completed successfully.',
      );
    } on DioException catch (e, stack) {
      debugPrint(
        '[ApiService] _uploadToPresignedUrl DioException: '
        'type=${e.type}, message=${e.message}, error=${e.error}, '
        'responseStatus=${e.response?.statusCode}, '
        'responseData=${e.response?.data}',
      );
      debugPrint('[ApiService] _uploadToPresignedUrl stack trace:\n$stack');

      final status = e.response?.statusCode;
      final reason = e.response?.statusMessage;
      final body = e.response?.data;

      final messageBuffer = StringBuffer('Failed to upload video to storage.');
      if (status != null) {
        messageBuffer.write(' HTTP $status');
        if (reason != null) {
          messageBuffer.write(' ($reason)');
        }
        messageBuffer.write('.');
      }
      if (e.message != null) {
        messageBuffer.write(' ${e.message}');
      }
      if (body != null) {
        messageBuffer.write(' Response body: $body');
      }

      throw ApiServiceException(messageBuffer.toString());
    } catch (e, stack) {
      debugPrint('[ApiService] _uploadToPresignedUrl unexpected exception: $e');
      debugPrint('[ApiService] _uploadToPresignedUrl stack trace:\n$stack');
      throw ApiServiceException(
        'Unexpected error while uploading to storage: $e',
      );
    } finally {
      debugPrint('[ApiService] _uploadToPresignedUrl: closing Dio instance.');
      s3Dio.close();
    }
  }

  /// Get the status of an analysis job.
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final result = await _client.analyze
        .getAnalysisStatusApiV1AnalyzeJobIdStatusGet(jobId: jobId);
    return result as Map<String, dynamic>;
  }

  /// Get the results of a completed analysis job.
  Future<Map<String, dynamic>> getJobResult(String jobId) async {
    final result = await _client.analyze
        .getAnalysisResultApiV1AnalyzeJobIdResultGet(jobId: jobId);
    return result as Map<String, dynamic>;
  }

  void dispose() {
    _dio.close();
  }
}

/// Exception thrown when API operations fail.
class ApiServiceException implements Exception {
  const ApiServiceException(this.message);

  final String message;

  @override
  String toString() => 'ApiServiceException: $message';
}
