import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../generated/api/export.dart';
import '../../shared/services/api_service.dart';

/// Authentication service backed by the API `AuthClient`.
///
/// Responsibilities:
/// - Manage current authenticated user
/// - Perform login and registration against the backend
/// - Hold the access token in memory and configure Dio auth header
/// - Expose loading + error states for the UI
class AuthService extends ChangeNotifier {
  AuthService(this._apiService) {
    _registerRefreshHandling();
  }

  final ApiService _apiService;

  AuthUser? _currentUser;
  String? _accessToken;
  bool _isLoading = false;

  /// Currently authenticated user, or null if logged out.
  AuthUser? get currentUser => _currentUser;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _currentUser != null && _accessToken != null;

  /// Whether an auth action is in progress (login/register/logout).
  bool get isLoading => _isLoading;

  /// Access token for authorized API calls (in-memory only for now).
  String? get accessToken => _accessToken;

  // ---------------------------------------------------------------------------
  // Refresh handling
  // ---------------------------------------------------------------------------

  /// Registers this service's refresh and session-expiry callbacks with
  /// [ApiService] so [TokenRefreshInterceptor] can transparently renew tokens.
  ///
  /// Called once from the constructor. Uses `this` method references rather
  /// than lambdas so the callbacks always dispatch to the live instance.
  void _registerRefreshHandling() {
    _apiService.attachTokenRefreshInterceptor(
      refreshAccessToken: _refreshAccessToken,
      onSessionExpired: _signOutLocally,
    );
  }

  /// Called by [TokenRefreshInterceptor] when the current access token expires.
  ///
  /// Calls `POST /api/v1/auth/refresh`. The backend reads the HTTP-only
  /// refresh token cookie and—if valid—returns a new access token and rotates
  /// the refresh token cookie.
  ///
  /// Returns the new access token on success, or `null` if the refresh fails
  /// (which causes the interceptor to call [_signOutLocally]).
  Future<String?> _refreshAccessToken() async {
    debugPrint('[AuthService] _refreshAccessToken: requesting new token…');
    try {
      final token =
          await _apiService.client.auth.refreshTokenApiV1AuthRefreshPost();

      if (token.accessToken.isEmpty) {
        debugPrint(
          '[AuthService] _refreshAccessToken: received empty token.',
        );
        return null;
      }

      _accessToken = token.accessToken;
      _apiService.setAuthToken(token.accessToken);
      debugPrint('[AuthService] _refreshAccessToken: token updated.');
      // No notifyListeners here — the UI does not need to rebuild solely
      // because an invisible background refresh occurred.
      return token.accessToken;
    } catch (e) {
      debugPrint('[AuthService] _refreshAccessToken failed: $e');
      return null;
    }
  }

  /// Clears local auth state without making any network calls.
  ///
  /// Used by [TokenRefreshInterceptor] when the session cannot be recovered
  /// (e.g. the refresh token itself is expired). Triggers a UI rebuild via
  /// [notifyListeners] so router guards redirect to the login screen.
  Future<void> _signOutLocally() async {
    debugPrint('[AuthService] _signOutLocally: clearing local session.');
    _currentUser = null;
    _accessToken = null;
    _apiService.clearAuthToken();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Public auth actions
  // ---------------------------------------------------------------------------

  /// Login using email + password via backend.
  ///
  /// Flow:
  /// 1. Validate basic email/password format
  /// 2. Call `/api/v1/auth/login` to get JWT token
  /// 3. Store token in memory and on Dio as Authorization header
  /// 4. Call `/api/v1/auth/me` to fetch user profile
  /// 5. Expose user via [currentUser]
  ///
  /// Throws [AuthException] for user-facing errors.
  Future<void> signIn({required String email, required String password}) async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      final trimmedEmail = email.trim();

      if (trimmedEmail.isEmpty) {
        throw const AuthException('Please enter your email.');
      }

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(trimmedEmail)) {
        throw const AuthException('Please enter a valid email address.');
      }

      if (password.isEmpty) {
        throw const AuthException('Please enter your password.');
      }

      if (password.length < 8) {
        throw const AuthException(
          'Password must be at least 8 characters long.',
        );
      }

      // 1. Call login endpoint
      final loginBody = UserLogin(email: trimmedEmail, password: password);
      final token = await _apiService.client.auth.loginApiV1AuthLoginPost(
        body: loginBody,
      );

      if (token.accessToken.isEmpty) {
        throw const AuthException('Received empty token from server.');
      }

      // 2. Store token and configure Dio auth header
      _accessToken = token.accessToken;
      _apiService.setAuthToken(token.accessToken);

      // 3. Fetch current user info
      final userResponse = await _apiService.client.auth
          .getCurrentUserInfoApiV1AuthMeGet();

      _currentUser = AuthUser(
        id: userResponse.id.toString(),
        email: userResponse.email,
        displayName: userResponse.username.isNotEmpty
            ? userResponse.username
            : _deriveDisplayNameFromEmail(userResponse.email),
      );

      notifyListeners();
    } on DioException catch (e) {
      // Map common HTTP errors to user-friendly messages
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const AuthException('Invalid email or password.');
      }
      throw AuthException(
        'Failed to sign in. ${e.message ?? 'Please try again.'}',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Failed to sign in. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Register a new user via backend.
  ///
  /// Flow:
  /// 1. Validate basic fields
  /// 2. Call `/api/v1/auth/register`
  /// 3. Optionally auto-login by calling [signIn]
  ///
  /// Throws [AuthException] for user-facing errors.
  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      final trimmedEmail = email.trim();
      final trimmedUsername = username.trim();

      if (trimmedEmail.isEmpty) {
        throw const AuthException('Please enter your email.');
      }

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(trimmedEmail)) {
        throw const AuthException('Please enter a valid email address.');
      }

      if (trimmedUsername.isEmpty) {
        throw const AuthException('Please enter a username.');
      }

      if (trimmedUsername.length < 3) {
        throw const AuthException(
          'Username must be at least 3 characters long.',
        );
      }

      if (password.isEmpty) {
        throw const AuthException('Please enter your password.');
      }

      if (password.length < 8) {
        throw const AuthException(
          'Password must be at least 8 characters long.',
        );
      }

      final body = UserCreate(
        email: trimmedEmail,
        username: trimmedUsername,
        password: password,
      );

      await _apiService.client.auth.registerUserApiV1AuthRegisterPost(
        body: body,
      );

      // Optionally auto-login after successful registration
      await signIn(email: trimmedEmail, password: password);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 422) {
        // Backend likely returns validation errors (e.g. email already used)
        throw const AuthException(
          'Could not create account. Check your details and try again.',
        );
      }
      if (status == 409) {
        throw const AuthException('Email or username already in use.');
      }
      throw AuthException(
        'Failed to create account. ${e.message ?? 'Please try again.'}',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Failed to create account. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out the current user.
  ///
  /// Calls `POST /api/v1/auth/logout` on the backend to clear the HTTP-only
  /// refresh token cookie, then clears all local auth state.
  ///
  /// The backend call is **best-effort**: a network error will not prevent
  /// local sign-out from completing so the user is never stuck logged-in.
  Future<void> signOut() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Tell the server to clear the refresh token cookie.
      // Fire-and-forget: don't let a network error block sign-out.
      try {
        await _apiService.client.auth.logoutApiV1AuthLogoutPost();
        debugPrint('[AuthService] signOut: backend logout succeeded.');
      } on DioException catch (e) {
        debugPrint(
          '[AuthService] signOut: backend logout failed (${e.message}) '
          '— proceeding with local sign-out.',
        );
      }

      await _signOutLocally();
    } finally {
      _setLoading(false);
    }
  }

  /// Internal helper to update the loading flag and notify listeners.
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  String _deriveDisplayNameFromEmail(String email) {
    final localPart = email.split('@').first;
    if (localPart.isEmpty) return email;

    // Convert "john.doe_123" -> "John Doe 123"
    final sanitized = localPart.replaceAll(RegExp(r'[\.\_\-]+'), ' ');
    if (sanitized.isEmpty) return email;

    return sanitized
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          if (part.length == 1) return part.toUpperCase();
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

/// Simple in-memory representation of an authenticated user.
///
/// This intentionally keeps only a few basic fields.
/// Extend this later based on backend needs (e.g. avatar URL, roles, etc.).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  /// Unique identifier for the user.
  ///
  /// In a real system this would come from your backend / identity provider.
  final String id;

  /// Email address used to sign in.
  final String email;

  /// Display name for UI purposes.
  final String displayName;
}

/// Exception type used by [AuthService] for user-facing auth errors.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
