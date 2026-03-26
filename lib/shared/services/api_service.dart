import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;

import '../../generated/api/export.dart';
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
