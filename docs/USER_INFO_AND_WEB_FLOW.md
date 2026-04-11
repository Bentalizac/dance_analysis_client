# User Info Refactor + Web Flow Changes

Two parallel workstreams: adding first/last name support from the new `user_info` backend table, and splitting the web presence into a TS marketing site and the existing Flutter app.

---

## 1. User Info Refactor

The backend adds a `user_info` table (one-to-one with `users`) and exposes two new endpoints. The client needs to consume the new fields and surface them in the UI.

### Generated API models

Re-run code generation after the backend OpenAPI spec is updated, or manually add:

**New file: `lib/generated/api/models/user_info_response.dart`**
```dart
class UserInfoResponse {
  const UserInfoResponse({this.firstName, this.lastName});

  @JsonKey(name: 'first_name') final String? firstName;
  @JsonKey(name: 'last_name')  final String? lastName;
}
```

**`lib/generated/api/models/user_response.dart`**
Add optional field:
```dart
@JsonKey(name: 'user_info') final UserInfoResponse? userInfo;
```

**New file: `lib/generated/api/models/user_info_update.dart`**
```dart
class UserInfoUpdate {
  const UserInfoUpdate({this.firstName, this.lastName});

  @JsonKey(name: 'first_name') final String? firstName;
  @JsonKey(name: 'last_name')  final String? lastName;
}
```

**New generated client: `lib/generated/api/clients/user_info_client.dart`**
Wraps:
- `GET  /api/v1/users/me/info`
- `PATCH /api/v1/users/me/info`

### `AuthUser` model (`lib/shared/services/auth_service.dart`)

Add fields and update `displayName` derivation:
```dart
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.firstName,
    this.lastName,
  });

  final String  id;
  final String  email;
  final String  displayName;
  final String? firstName;
  final String? lastName;
}
```

In `signIn`, build `AuthUser` from `userResponse.userInfo` when available:
```dart
final info = userResponse.userInfo;
final hasName = info?.firstName != null || info?.lastName != null;
_currentUser = AuthUser(
  id:          userResponse.id.toString(),
  email:       userResponse.email,
  firstName:   info?.firstName,
  lastName:    info?.lastName,
  displayName: hasName
      ? [info?.firstName, info?.lastName]
            .whereType<String>()
            .join(' ')
      : userResponse.username.isNotEmpty
          ? userResponse.username
          : _deriveDisplayNameFromEmail(userResponse.email),
);
```

### Registration UI

Add optional first/last name fields to the registration screen. These are sent via `PATCH /api/v1/users/me/info` immediately after auto-login completes (not in the register call itself, which stays unchanged).

### Profile editing

Add a profile edit screen (or expand an existing settings screen) that calls `PATCH /api/v1/users/me/info`. Display fields:
- First name (optional)
- Last name (optional)

---

## 2. Web Flow: TS Landing Page + Flutter App Split

### Domain structure

| Domain | What lives here |
|--------|----------------|
| `dance-note.com` | New TypeScript/Next.js marketing + login site |
| `app.dance-note.com` | Existing Flutter web app (unchanged) |

### Auth handoff

Both domains share the `.dance-note.com` parent, so the backend's HTTP-only refresh token cookie can be scoped to `Domain=.dance-note.com`. Flow:

1. User visits `dance-note.com`, fills in the login form.
2. TS page calls `POST /api/v1/auth/login`. Backend sets the refresh token cookie on `.dance-note.com`.
3. TS page redirects to `app.dance-note.com`.
4. Flutter app starts, calls `POST /api/v1/auth/refresh` — cookie is present, gets access token, proceeds normally.

**No Flutter changes required for this flow.** The app already calls `/refresh` on startup via `TokenRefreshInterceptor`.

### Flutter app changes (minimal)

- Ensure `app.dance-note.com` is the deployment URL (update any hardcoded base URL config if needed).
- The login page within the Flutter app remains available as a fallback for users who navigate directly to `app.dance-note.com` without a valid cookie.

### New landing page repo

See the separate `dance-note-web` repository. Key responsibilities:

- Marketing content (hero, features, pricing, etc.)
- Login form — calls the same FastAPI backend
- Registration form — calls `/api/v1/auth/register`, then logs in, then redirects to `app.dance-note.com`
- Invite acceptance page — currently lives in the Flutter app as a web route (`/invite`); consider moving to the TS site for a better UX

### Backend changes required

**`app/core/config.py`**
```python
COOKIE_DOMAIN: str | None = None  # Set to ".dance-note.com" in prod
```

**`app/api/v1/auth.py`**
Pass `domain=settings.COOKIE_DOMAIN` to all `response.set_cookie(...)` and `response.delete_cookie(...)` calls.
