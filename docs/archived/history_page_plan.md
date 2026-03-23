# History Page Implementation Plan

This document outlines a concrete implementation plan for the **History** feature in the Flutter client. The goal is:

> When a user navigates to the History page, they can see their previous uploads, the current status of each upload (from the backend job queue), and – when complete – a stubbed view of feedback data. The video files themselves are not served from the backend, so we must rely on local file path references stored on the client.

We will leverage the backend `/jobs` endpoint to fetch all jobs tied to the currently authenticated user.

---

## 1. Requirements Overview

### Functional

1. **History list**
   - Display a list of past submissions (jobs) for the logged-in user.
   - Each list item shows:
     - Dance style (if known).
     - Created/updated time.
     - Status (`queued`, `processing`, `completed`, `failed`, etc.).
     - A local video/file presence indicator (if we know the local path and it still exists).
   - Status values are driven by `/jobs` (backend source of truth).

2. **Job status integration**
   - On visiting the History page:
     - Load locally cached submissions (for local video path and metadata).
     - Fetch `/jobs` for the current user to:
       - Sync remote job list with local submissions.
       - Update statuses and add any new jobs we might not know about.
   - Show a clear, user-friendly status for each submission.

3. **Feedback stubbing**
   - For completed jobs:
     - Show a “View feedback” action.
     - Navigate to a detail view that:
       - Uses the **video scrubbing capabilities** we already have (results/upload video player).
       - Shows stubbed feedback as timestamped items.
   - Feedback format is in flux, but we know it will eventually be “timestamp → feedback text”.
   - For now, we:
     - Stub feedback locally (e.g., sample `FeedbackItem`s), or
     - Show a simple “Feedback coming soon” state.

4. **Video handling**
   - Video files are not returned from the backend.
   - We must keep and use the **local file path** stored on the client from the upload flow.
   - If the local file is missing:
     - Show that playback is unavailable, but still show status & feedback.

5. **Reusability**
   - Reuse:
     - Upload page’s upload progress visualization for jobs in-flight (concept and styling).
     - Existing video player / scrubbing used in the Results page.
   - Do **not** include timestamp creation UI from the upload page in History/Results.

---

## 2. Data & Domain Design

### 2.1. Job model from `/jobs`

We assume `/jobs` returns a list of job objects for the current user. A simplified representation:

- `id` – backend job ID (we already store this as `storageReference` on upload success).
- `createdAt` / `updatedAt`
- `status` – string enum (e.g., `"queued"`, `"processing"`, `"completed"`, `"failed"`).
- `danceStyle` / `metadata` – if available.
- `feedback` (optional) – final feedback payload. For now we’ll assume either:
  - It’s not present yet, or
  - It’s a shape we can later parse into timestamped items.

We will create a `JobSummary` domain model for this:

- `jobId: String`
- `status: JobStatus` (app enum mapping server status strings).
- `createdAt: DateTime`
- `updatedAt: DateTime?`
- `danceStyle: DanceStyle?` (optional mapping if available in the job metadata).
- `hasFeedback: bool` (based on status or presence of feedback data).
- `rawFeedback: Map<String, dynamic>?` or similar (for future parsing; stub for now).

### 2.2. Local submission record

We already maintain `VideoMetadata` and store `storageReference` (job id) on success in `UploadController`.

We now formalize a `Submission` model that ties local data to remote job data:

- `localId: String` – local UUID (from `VideoMetadata.id`).
- `jobId: String` – backend job id (`storageReference`).
- `localVideoPath: String` – local path to the video (`VideoMetadata.originalPath`).
- `totalDuration: Duration` – from `VideoMetadata.totalDuration`.
- `danceStyle: DanceStyle?` – from upload state at the time of submission.
- `createdAt: DateTime` – set at submission time.
- `lastKnownStatus: JobStatus` – cached status from last sync (initialized as `queued` or `processing` on successful submission).
- `hasLocalVideo: bool` (derived at runtime by checking file existence, not persisted necessarily).

These will be stored as a list in local persistence (e.g., `shared_preferences`) using JSON serialization.

### 2.3. Combined History item

The History page will present a merged view of:

- Local `Submission` (for video path, dance style, createdAt).
- Remote `JobSummary` (for up-to-date status, feedback presence).

Define `HistoryItem`:

- `submission: Submission?`
- `job: JobSummary`
- `effectiveStatus: JobStatus` (primarily from `job.status`).
- `effectiveCreatedAt: DateTime` (prefer `submission.createdAt`, else `job.createdAt`).
- `localVideoPath: String?` (from `submission` if available).
- `hasLocalVideo: bool`
- `hasFeedback: bool` (based on `job` and/or `feedback` stub).

---

## 3. Persistence & Sync Flow

### 3.1. Local storage strategy

Create a small data source for History:

- `HistoryLocalDataSource`
  - `Future<List<Submission>> loadSubmissions()`
  - `Future<void> saveSubmissions(List<Submission>)`
  - `Future<void> upsertSubmission(Submission)` (add or replace by `jobId` / `localId`)

Implementation details:

- Use `shared_preferences` initially:
  - Store under a key like `history_submissions_v1`.
  - JSON-encode a list of submissions.
- Provide migration room via a versioned key or an envelope object with a `version` field.

### 3.2. Write submissions at upload time

Extend the upload flow:

- When `UploadController.upload()` completes successfully and sets:

  - `status: UploadStatus.success`
  - `videoMetadata: updatedMetadata`
  - `storageReference: jobId`

- Add a call to `HistoryRepository.recordSubmission(...)`:
  - Build a `Submission` with:
    - `localId = videoMetadata.id`
    - `jobId = storageReference`
    - `localVideoPath = videoMetadata.originalPath`
    - `totalDuration = videoMetadata.totalDuration`
    - `danceStyle = state.danceStyle`
    - `createdAt = DateTime.now()` (or server timestamp if available)
    - `lastKnownStatus = JobStatus.queued` (or `processing`, depending on backend semantics).
  - Persist via `HistoryLocalDataSource.upsertSubmission`.

This ensures that once a user uploads a video and the server job is created, we have a local record that the History page can show immediately (even before the first `/jobs` sync).

### 3.3. Sync with `/jobs` on History load

On History page load (and on pull-to-refresh):

1. Load local submissions:
   - `final localSubmissions = await historyLocalDataSource.loadSubmissions();`

2. Fetch remote jobs:
   - `final remoteJobs = await apiService.fetchUserJobs();`
   - This calls `GET /jobs` with the current user’s auth context.

3. Build a map:
   - `final localByJobId = { submission.jobId : submission }`
   - `final remoteByJobId = { job.jobId : job }`

4. For each remote job:
   - Create/merge a `HistoryItem`:
     - `submission = localByJobId[job.jobId]` (if exists).
     - `effectiveStatus = job.status`.
     - `effectiveCreatedAt`:
       - `submission.createdAt` if exists, else `job.createdAt`.
     - `localVideoPath = submission?.localVideoPath`.
     - `hasLocalVideo`:
       - As a first pass, treat it as `submission != null`.
       - As an enhancement, check file existence asynchronously.

5. Update local submissions’ `lastKnownStatus`:
   - For each matching submission, update `lastKnownStatus = job.status` and persist the updated list.
   - For jobs that exist remotely but not locally:
     - Optionally create synthetic submissions with `localVideoPath = null` to keep a single source of truth.
     - Or just show them from remote-only data without persisting; depends on desired behavior.

6. Produce `HistoryState` with the resulting `List<HistoryItem>`.

---

## 4. State Management & Controller

### 4.1. History state

Define:

- `enum HistoryStatus { initial, loading, loaded, error }`

- `class HistoryState`:
  - `HistoryStatus status`
  - `List<HistoryItem> items`
  - `String? errorMessage`
  - Optional: `bool isRefreshing` if we want a separate “pull-to-refresh” state.

### 4.2. History controller

Create `HistoryController extends ChangeNotifier`:

Responsibilities:

1. **Loading data**
   - `Future<void> loadHistory()`
     - Set `status = loading`.
     - Load local submissions.
     - Try to fetch `/jobs`.
     - Merge into `items`.
     - On success: `status = loaded`.
     - On failure:
       - If remote fails but local exists:
         - Show local-only entries with a warning (e.g., “Could not update from server”).
       - If everything fails:
         - `status = error` + `errorMessage`.

2. **Refreshing**
   - `Future<void> refresh()`
     - Same as `loadHistory`, but retains existing items while refreshing.
     - Allows pull-to-refresh behaviour.

3. **Navigation to detail**
   - For a tapped `HistoryItem`:
     - If `effectiveStatus` is `completed`:
       - Trigger navigation to a detail screen (see Section 6).
     - Else:
       - Optionally show a bottom sheet or snack bar (“Job is still processing”).

The controller receives:

- `HistoryRepository` (exposes both local data source and `/jobs` API).
- `ApiService` (or similar) underneath.

---

## 5. UI & Navigation

### 5.1. Routing

In `config/routes.dart`, replace the stub `History` page:

- Current snippet:

  - `child: _StubPage(title: 'History', icon: Icons.history),`

- Change to:

  - `child: const HistoryPage(),`

`HistoryPage` should be a widget under something like:

- `lib/features/history/presentation/pages/history_page.dart`

### 5.2. HistoryPage widget

High-level structure:

- `Scaffold`
  - `AppBar(title: const Text('History'))`
  - `body`:
    - Connect to `HistoryController` via `ChangeNotifierProvider` & `Consumer` (consistent with upload feature).
    - Render based on `state.status`:

      - `initial`:
        - Trigger `loadHistory()` in `initState` and show a spinner.
      - `loading`:
        - Full-screen `CircularProgressIndicator`.
      - `error`:
        - Error message + “Retry” button (calls `controller.loadHistory()`).
      - `loaded`:
        - If `items.isEmpty`:
          - Empty state: icon + text “No uploads yet. Upload a video to see it here.”
        - Else:
          - `RefreshIndicator` + `ListView.builder` of `HistoryItem`.

### 5.3. History list item

For each `HistoryItem`:

- Show a card with:
  - Left:
    - A video icon or small thumbnail.
    - If `hasLocalVideo == true`, use a “video available” icon.
    - If `hasLocalVideo == false`, muted/outlined icon with tooltip (“Video file not available on this device”).
  - Center:
    - Title:
      - `danceStyle.displayName` if available.
      - Else “Dance analysis”.
    - Subtitle:
      - Human-readable `effectiveCreatedAt` (e.g., “Uploaded Jan 10, 2025, 8:21 PM”).
  - Right:
    - Status chip:
      - `JobStatus.queued` → “Queued”
      - `JobStatus.processing` → “Processing…”
      - `JobStatus.completed` → “Completed”
      - `JobStatus.failed` → “Failed”
    - For in-flight statuses:
      - Optionally show an indeterminate spinner next to the label.
    - For `processing`:
      - Optionally show a small progress bar using the shared upload-like progress component.

- Tap actions:
  - `onTap`:
    - If `JobStatus.completed` and either:
      - `hasLocalVideo == true` OR we want to show feedback alone:
        - Navigate to detail (see Section 6).
    - Otherwise:
      - Show a non-blocking message: “This video is still being processed. Check back soon.”

---

## 6. Feedback & Detail View

### 6.1. Feedback representation

We already have:

- `FeedbackItem` model used by `ResultsPage`.
- `ResultsPage` itself displays:
  - A video player (via `VideoPlayerWithPoseOverlay`).
  - A list of timestamped feedback items, and scrubbing behavior.

Since feedback format is not finalized, we will **not** implement real parsing yet. Instead:

- For completed jobs in the History page:
  - We will either:
    - Use stubbed data:
      - A fixed list of `FeedbackItem`s with different timestamps, or
    - Leave `feedbackItems` empty but show a placeholder message inside Results page (“Feedback not yet available.”).

### 6.2. Reusing ResultsPage

To avoid duplicating behavior and to get video scrubbing:

- Use `ResultsPage` as the detail view for completed submissions.
- Define a simple navigation method in the History controller (or UI):

  - `void openSubmission(BuildContext context, HistoryItem item)`

  Implementation idea:

  - Gather:
    - `final videoPath = item.localVideoPath;`
    - `final feedbackItems = await historyRepository.getStubbedFeedback(item.job.jobId);`
  - Push a route to `ResultsPage`:
    - `Navigator.of(context).push(MaterialPageRoute(...))`
    - or define an additional named route `/results/:jobId` that loads feedback by job id.

- For now, stub `getStubbedFeedback`:

  - It can:
    - Return a constant list of `FeedbackItem`s (e.g., 3–5 items).
    - Or an empty list and rely on `ResultsPage` to show an informative blank state.

### 6.3. Video scrubbing requirements

The user explicitly wants “video scrubbing capabilities from the upload page, but not the timestamp creation”.

We already have:

- A scrubber in `UploadPageContent` using `VideoProgressIndicator`.
- `VideoPlayerWithPoseOverlay` plus `ResultsPage` that support scrubbing & timestamp navigation.

To meet requirements:

- For History/Results:
  - Use `VideoPlayerWithPoseOverlay` and `ResultsPage`.
  - Do NOT reuse the upload UI that includes timestamp creation controls; just the playback + progress sections.
- If needed, centralize video playback logic:
  - Consider moving any reusable video manager into a shared location used by both Upload and Results, but implementation-wise, `VideoPlayerWithPoseOverlay` is likely sufficient.

---

## 7. Reusable UI Components

### 7.1. Progress bar from Upload page

Upload has a button that visually fills as upload progresses.

To reuse its look for History:

1. Extract the core “fill bar” into a shared widget, e.g.:

   - `ProgressFillBar` or `LinearFillProgress`:
     - Properties: `double progress`, optional `Color` overrides.

2. Use it in:
   - Upload page’s upload button.
   - History list item (for jobs in `processing` state).
     - Even if we don’t have actual numeric progress from backend, we can:
       - Use a `progress == null` path and an indeterminate animation, or
       - Skip numeric progress and just show the label + spinner.

### 7.2. Shared formatting

Centralize:

- Date/time formatting for `createdAt`.
- Status → label/color mapping (e.g., via a small helper class or extension).

This avoids duplication between History and any future “job details” views.

---

## 8. Error Handling & Edge Cases

### 8.1. Network errors

- If `/jobs` fails:
  - If local submissions exist:
    - Show them, but indicate that “Statuses may be out of date, failed to refresh.”
  - If no local submissions:
    - Show an error with a retry button.

### 8.2. Local file missing

When user opens a completed submission:

- Try to initialize the video player with `localVideoPath`.
- If file is not found or fails to open:
  - Show a message in the detail page (“Video file not available on this device.”).
  - Hide or disable video controls.
  - Still display feedback list (if any).

### 8.3. Desynchronized state

- Cases:
  - `/jobs` returns jobs we’ve never seen locally (e.g., uploads from another device).
  - Local submission exists but `/jobs` no longer includes that job (deleted server-side).
- Strategy:
  - For remote-only jobs:
    - Show them, but mark as having no local video (“Uploaded from another device”).
  - For local-only submissions:
    - Either:
      - Drop them (they may be stale).
      - Or show them with a “Job not found on server” status.
  - Document this behavior and keep it simple for v1.

---

## 9. Implementation Phases

To reduce risk, implement in stages:

### Phase 1 – Data groundwork

1. Define:
   - `JobStatus` enum.
   - `JobSummary` model (from `/jobs`).
   - `Submission` model with JSON serialization.
   - `HistoryItem` model.
2. Implement:
   - `HistoryLocalDataSource` with `shared_preferences`.
   - `HistoryRepository` interface:
     - `Future<List<Submission>> getLocalSubmissions()`
     - `Future<void> upsertSubmission(Submission)`
     - `Future<List<JobSummary>> getRemoteJobs()`

### Phase 2 – Wire upload to history

3. In `UploadController.upload()`:
   - After success:
     - Construct `Submission` and call `HistoryRepository.upsertSubmission`.
4. Add small unit tests around:
   - `Submission.toJson/fromJson`.
   - Local upsert behavior (e.g., updating status).

### Phase 3 – History controller & basic UI

5. Implement `HistoryController` and `HistoryState`.
6. Implement `HistoryPage` with:
   - Loading & error states.
   - List of basic text-only items (job ID, status).
7. Switch the `/history` route to `HistoryPage`.

### Phase 4 – Rich UI & navigation

8. Implement:
   - Proper `HistoryItem` layout:
     - Title, subtitle, status chip, icons.
   - Empty state view.
   - Pull-to-refresh.
9. Navigation:
   - On tap of completed item:
     - Navigate to a stub detail page that just shows job info.

### Phase 5 – Feedback stubbing & results integration

10. Implement `getStubbedFeedback(jobId)` in HistoryRepository or a dedicated Feedback service.
11. Reuse `ResultsPage` as the detail view:
    - Pass `videoPath` (if local) and stubbed `feedbackItems`.
12. Confirm:
    - Video scrubbing works.
    - Timestamp list is visible and interactive.

### Phase 6 – Polish & resilience

13. Handle:
    - Missing local video files gracefully.
    - Partial network failures (server unavailable).
    - Minor UX improvements:
      - Icons, colors, spacing, etc.
14. Add integration tests where feasible (e.g., golden tests for History list layout, or widget tests that mock `/jobs` and local storage).

---

## 10. Summary

- **Source of truth** for job status is the backend `/jobs` endpoint.
- **Source of truth** for local video paths is a client-side `Submission` store, written at upload success time.
- The **History page** merges these two sources into a user-friendly view of past uploads and their processing state.
- For **feedback**, we stub timestamped items and reuse the existing `ResultsPage` video player and UI to support scrubbing, without exposing timestamp creation tools.
- We reuse and refactor shared components (progress bar and video controls) where appropriate to maintain consistency with the Upload page.

This plan should give us a clear, incremental path from the current stub History route to a functional, backend-integrated History feature with forward-compatible hooks for real feedback parsing once the backend format is finalized.
