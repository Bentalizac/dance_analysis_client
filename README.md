# Dance Analysis Client

A Flutter application for AI-powered dance coaching and analysis.

The client lets dancers:

- Upload practice videos for AI analysis
- Track analysis jobs over time
- View feedback and pose overlays
- Manage access via email/password authentication

---

## Overview

This app talks to a backend API that:

- Authenticates users
- Accepts video uploads (with timestamps and metadata)
- Queues and processes analysis jobs
- Returns feedback and pose data for visualization

On the client side we now have:

- A routed, bottom-nav driven app shell
- A production-ready upload flow
- A first implementation of history backed by local storage + backend jobs
- Email/password authentication wired to the backend
- Shared services (API, auth, video) and reusable widgets

---

## Core Features

### ✅ Home & Navigation

- **Home Page**
  - Main landing screen with navigation cards (e.g. Upload, History, Demo)
  - Dark-themed layout using the shared design system
- **Bottom Navigation Shell**
  - Tabs for:
    - Home
    - Upload
    - History
    - (Profile stubbed for now)
  - Integrated with `go_router` and route guards
  - Upload tab includes a navigation guard so you don’t accidentally lose in-progress work

### ✅ Authentication (Email + Password)

- **Login / Register Page**
  - Email + password login
  - Registration with username
  - Shared UI for login vs register modes
  - Optional redirect back to the originally requested route (e.g. `/upload`, `/history`)

- **Auth Service**
  - Backed by generated API client and Dio
  - Handles:
    - `POST /api/v1/auth/login`
    - `POST /api/v1/auth/register`
    - `GET /api/v1/auth/me`
  - Stores JWT access token in memory
  - Configures Dio with the `Authorization` header
  - Exposes:
    - `currentUser`
    - `isAuthenticated`
    - Loading state and error mapping to user-friendly messages

- **Route Guards**
  - `/upload`, `/history`, `/profile` are **protected routes**
  - If user is not authenticated:
    - They are redirected to `/login?from=/desired/path`
  - After successful login:
    - User is sent back to the original route when possible

### ✅ Upload Flow

A full-featured upload flow powered by:

- `UploadController` (business logic)
- `UploadState` (immutable state snapshot)
- `VideoPlayerManager` (video playback state)
- `UploadPage` + `UploadPageContent` (UI with providers)

**Main capabilities:**

- **Video selection**
  - Web: file picker
  - Mobile: record from camera or choose from gallery
  - Unified interface via shared `VideoService` abstraction

- **Video playback**
  - Uses `VideoPlayerWithPoseOverlay` when needed
  - Standard controls (play/pause, scrub, time display)
  - Resilient to platform differences (mobile vs web)

- **Email capture**
  - Email field required to submit
  - Simple regex validation
  - Clear inline error messaging

- **Inline timestamping**
  - Mark logical segments (steps / phrases) in a routine
  - Uses:
    - `VideoTimestamp` model
    - `TimestampListItem` widget
    - `InlineTimestampForm` widget
  - Users can:
    - Add new timestamps using the current video position
    - Fine-tune time via slider while video stays interactive
    - Edit or delete existing timestamps inline
    - Tap timestamps to seek video

- **Length validation & recommendations**
  - Videos longer than a threshold (e.g. 15 seconds) without timestamps
    trigger a **recommendation dialog**:
    - Educates user on why timestamps help
    - Lets user continue anyway or go back to add timestamps

- **Upload request**
  - Sends to backend via `ApiService` / `VideoRepository`:
    - Video file
    - Email
    - Timestamps
    - Basic metadata (duration, etc.)
  - Receives a backend job identifier / storage reference
  - On success:
    - Creates a local **submission record** used by History

- **Unsaved-work navigation guard**
  - When upload page has in-progress state:
    - Bottom nav attempts to leave `/upload` invoke a callback
    - User can confirm discarding work or cancel navigation
  - Guard is registered/unregistered from `UploadPageContent`

> Note: Video trimming and advanced metadata persistence are partially planned and scaffolded but not fully implemented yet.

### ✅ Results & Demo

- **Results Page**
  - Displays:
    - Video (if available)
    - Pose skeleton overlay
    - Timestamped feedback list
  - Accepts:
    - `feedbackItems`
    - `videoPath` (optional)
    - `poseDataList`
    - Optional callbacks for timestamp taps
  - Uses `VideoPlayerWithPoseOverlay` and `PoseOverlayPainter` for visualization

- **Demo Results Page**
  - Standalone screen with demo data
  - Handy for testing UI and design without needing real backend runs

### ✅ History (Partially Implemented but Functional)

History is now a feature, not just a stub. It combines:

- Local submissions saved during upload
- Remote job statuses from the backend `/jobs` (API details abstracted)

**Components:**

- `HistoryItem` model tying together:
  - Local submission (video metadata, paths, dance style, createdAt)
  - Remote job summary (status, timestamps, completion, etc.)
- `HistoryLocalDataSource`:
  - Stores submissions locally (e.g. via shared preferences + JSON)
- `HistoryRepository`:
  - Loads local submissions
  - Fetches remote jobs for current user
  - Merges them into a list of `HistoryItem`s
- `HistoryController` + `HistoryState`:
  - Drives the UI
  - Handles loading, errors, pull-to-refresh, etc.
- `HistoryPage`:
  - Lists submissions with:
    - Status (queued / processing / completed / failed)
    - Basic metadata (date, duration, dance style if available)
    - Indicator for whether the local video still exists
  - Tapping an item navigates to `HistoryDetailPage`
- `HistoryDetailPage`:
  - Shows details for a single history entry
  - Uses results-style layout to show:
    - Video playback when local file exists
    - Feedback items (stub / future: real backend feedback)

**Current state:**

- Local + remote data wiring is in place
- Job statuses are surfaced in the UI
- Navigation to a detail view is implemented
- Real feedback parsing may still be evolving with backend

### 🚧 Profile & Advanced Account Features (Planned / Stubbed)

- Profile tab and page are present in routing but mostly stubbed
- Future work will include:
  - Viewing/updating basic user info
  - Managing auth/session state more deeply
  - Possibly linking OAuth-style flows

---

## Routing & App Shell

Routing is implemented with `go_router` and a central routes configuration.

- **Main routes:**
  - `/` → `HomePage`
  - `/upload` → `UploadPage`
  - `/history` → `HistoryPage`
  - `/login` → `LoginPage`
  - `/demo` → `DemoResultsPage`
  - `/profile` → (stub page)

- **Navigation structure:**

```text
MainScaffold (bottom nav)
├── Home       → HomePage
├── Upload     → UploadPage (protected, upload guard)
├── History    → HistoryPage (protected)
└── Profile    → StubPage (protected)
```

- **Route Guards:**
  - Upload, History, Profile require authentication
  - A global redirect checks auth state:
    - If user is not logged in and hits a protected route → redirect to `/login?from=...`
  - `LoginPage` respects `from` and navigates back after successful auth

- **Upload Navigation Guard:**
  - Central registration function:
    - Upload page registers a callback when mounted
    - Bottom nav checks with this callback before leaving `/upload`
    - Avoids losing in-progress work

---

## Shared Services & Utilities

The codebase uses a clear separation between **features** and **shared** modules.

### Shared Services

- `ApiService`
  - Wraps generated OpenAPI client
  - Configures Dio instance
  - Manages auth token header
  - Provides a single gateway for backend calls

- `AuthService`
  - See “Authentication” section
  - Owns auth state and token

- `VideoService` / `VideoServiceIo` / `VideoServiceWeb`
  - Abstracts file picking and video path handling across platforms
  - Helps the upload and results flows remain platform-agnostic

### Shared Models

- `FeedbackItem`
- `PoseData`
- `VideoTimestamp`
- `VideoMetadata`
- `HistoryItem`
- `Submission`
- `DanceStyle` (if present; used to categorize uploads)

These models support JSON serialization where needed and are used across features.

### Shared Widgets

- `VideoPlayerWithOverlay`
- `PoseOverlayPainter`
- `VideoPlaceholder`
- `TimestampListItem`
- `TimestampManager`
- `InlineTimestampForm`
- `DiscardConfirmationDialog`
- Common buttons, list items, etc. used across upload, results, and history

### Design System

Centralized theming and layout:

- `AppDesignSystem` (`lib/shared/design_system/theme.dart`)
  - Colors:
    - Background dark: `#0F0F0F`
    - Background medium: `#232323`
    - Accent purple: `#C370DF`
    - Error red: `#DE3737`
    - Text primary/secondary
  - Typography:
    - Consistent text styles for headers, body, timestamps, labels
  - Spacing constants
- All feature UIs are built on this shared design system

---

## Project Structure (High-Level)

```text
lib/
├── main.dart                     # App entry point, router and providers bootstrap
├── config/
│   └── routes.dart               # go_router config, guards, bottom nav shell
├── features/
│   ├── auth/
│   │   └── presentation/pages/login_page.dart
│   ├── home/
│   │   └── presentation/...
│   ├── upload/
│   │   ├── data/...
│   │   ├── domain/...
│   │   └── presentation/...
│   ├── history/
│   │   ├── data/history_local_data_source.dart
│   │   ├── data/history_repository.dart
│   │   └── presentation/...
│   └── results/
│       └── presentation/...
├── models/
│   ├── feedback_item.dart
│   ├── pose_data.dart
│   ├── history_item.dart
│   ├── video_metadata.dart
│   ├── video_timestamp.dart
│   ├── submission.dart
│   └── dance_style.dart (if present)
├── shared/
│   ├── design_system/theme.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── video_service.dart
│   │   ├── video_service_io.dart
│   │   └── video_service_web.dart
│   ├── utils/
│   │   ├── format_helpers.dart
│   │   └── job_status_extensions.dart
│   └── widgets/
│       ├── video_player_with_overlay.dart
│       ├── pose_overlay_painter.dart
│       ├── video_placeholder.dart
│       ├── timestamp_list_item.dart
│       ├── timestamp_manager.dart
│       ├── inline_timestamp_form.dart
│       └── discard_confirmation_dialog.dart
└── generated/
    └── api/...                    # OpenAPI-generated client (paths may vary)
```

(Exact paths may vary slightly, but this reflects the current modular design.)

---

## Documentation

Additional, more detailed docs live under `docs/`:

- `docs/UPLOAD_PAGE.md`
  - Deep-dive into the upload architecture, timestamps, validation, and UX
- `docs/VIDEO_PLAYER_SUMMARY.md`
  - Implementation details of the video player
- `docs/VIDEO_OVERLAY_GUIDE.md`
  - Technical guide for pose overlay rendering
- `docs/history_page_plan.md`
  - Design document for the History feature and how it integrates with uploads and backend jobs
- `docs/CODE_QUALITY_ASSESSMENT.md`
  - Notes on code quality, structure, and improvement areas

---

## Getting Started

### Prerequisites

- Flutter SDK (3.10.7+)
- Dart SDK
- iOS/Android tooling (Xcode, Android Studio, or CLI equivalents)
- A running backend with:
  - Auth endpoints
  - Upload/job endpoints
  - CORS and auth configured for this client

### Install & Run

From the project root:

```bash
flutter pub get
flutter run
```

For web:

```bash
flutter run -d chrome
```

Make sure API base URLs and any environment-specific configuration are set correctly (e.g. via flavors, compile-time env, or config files).

---

## Current Status & Next Steps

### Implemented

- Auth: login/register + guarded routes
- Upload:
  - Video selection
  - Email and validation
  - Inline timestamps
  - Length-based recommendations
  - Upload to backend with metadata
  - Local submission recording for history
- Results:
  - Video + pose overlay
  - Feedback list
  - Demo page
- History:
  - Local submissions + remote job fetch
  - List and detail pages
  - Status integration

### In Progress / Planned

- Rich feedback integration from real backend payloads
- Full video trimming pipeline
- More robust persistence for video metadata and downloads
- Profile page (user settings, logout entry point, etc.)
- Better offline behavior for history and submissions
- Cloud storage / CDN integration for serving videos (if backend evolves that way)

---

## License

[Add your license information here]

---

## Support / Contact

[Add support contact information or contribution guidelines here]
