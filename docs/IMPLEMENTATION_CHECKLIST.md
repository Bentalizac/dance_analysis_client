# Implementation Checklist for Groups/Routines/Videos/Notes

Use this checklist to track progress as you implement each feature. Features should be implemented bottom-up: Foundation → Groups → Routines → Videos → Notes → Integration.

---

## Phase 0: Foundation & Setup

- [ ] Review `docs/IMPLEMENTATION_SUMMARY.md` for overview
- [ ] Review `docs/GENERATED_API_REFERENCE.md` for API methods
- [ ] Review generated clients in `lib/generated/api/clients/`
- [ ] Create `lib/core/exceptions/app_exceptions.dart` with domain exception classes
- [ ] Create feature folder structure for all 5 features
- [ ] Set up testing framework (mockito, etc.)

---

## Phase 1: Groups Feature

### 1.1 Domain Layer

- [ ] Create `lib/features/groups/domain/entities/group.dart`
  - [ ] Fields: id, name, description, createdAt, isOwner
  - [ ] Factory `fromResponse(GroupResponse)`
  - [ ] toJson() method

- [ ] Create `lib/features/groups/domain/entities/group_member.dart`
  - [ ] Fields: userId, email, displayName, role, joinedAt
  - [ ] Factory `fromResponse(GroupMembershipResponse)`

- [ ] Create `lib/features/groups/domain/repositories/groups_repository.dart` (abstract)
  - [ ] getGroups(): Future<List<Group>>
  - [ ] getGroup(String groupId): Future<Group>
  - [ ] createGroup(String name, String description): Future<Group>
  - [ ] getMembers(String groupId): Future<List<GroupMember>>
  - [ ] addMember(String groupId, String userId): Future<void>
  - [ ] removeMember(String groupId, String userId): Future<void>
  - [ ] createInvite(String groupId, String email, String role): Future<void>

### 1.2 Data Layer

- [ ] Create `lib/features/groups/data/data_sources/groups_api_data_source.dart`
  - [ ] Inject RestClient in constructor
  - [ ] getGroups() → calls client.groups.getGroupsApiV1GroupsGet()
  - [ ] getGroup(String groupId) → calls client API
  - [ ] createGroup(GroupCreate) → calls client API
  - [ ] getMembers(String groupId) → calls client API
  - [ ] addMember(String groupId, String userId) → calls client API
  - [ ] removeMember(String groupId, String userId) → calls client API
  - [ ] createInvite(String groupId, GroupInviteCreate) → calls client API
  - [ ] All methods handle DioException and throw domain exceptions

- [ ] Create `lib/features/groups/data/repositories/groups_repository.dart` (impl)
  - [ ] Inject GroupsApiDataSource
  - [ ] Implement abstract repository interface
  - [ ] Map GroupResponse → Group entity
  - [ ] Map GroupMembershipResponse → GroupMember entity
  - [ ] Handle exceptions from data source

### 1.3 State Management

- [ ] Create `lib/features/groups/presentation/controllers/groups_state.dart`
  - [ ] Fields: groups: List<Group>, isLoading: bool, error: String?, selectedGroup: Group?
  - [ ] copyWith() method for immutability

- [ ] Create `lib/features/groups/presentation/controllers/groups_controller.dart`
  - [ ] Extend ChangeNotifier
  - [ ] Inject GroupsRepository
  - [ ] loadGroups() method
  - [ ] selectGroup(String groupId) method
  - [ ] createGroup(String name, String description) method
  - [ ] removeGroup(String groupId) method
  - [ ] loadMembers(String groupId) method
  - [ ] addMember(String groupId, String userId) method
  - [ ] removeMember(String groupId, String userId) method
  - [ ] createInvite(String groupId, String email, String role) method

### 1.4 Presentation

- [ ] Create `lib/features/groups/presentation/pages/groups_list_page.dart`
  - [ ] StatefulWidget with TabController (Groups, Members, Invites tabs)
  - [ ] Read GroupsController from Provider
  - [ ] Call loadGroups() in initState
  - [ ] Display list of groups with GestureDetector for navigation
  - [ ] FAB for create group dialog

- [ ] Create `lib/features/groups/presentation/pages/group_detail_page.dart`
  - [ ] Receive groupId as parameter
  - [ ] Load group details
  - [ ] Display group info with edit capability

- [ ] Create `lib/features/groups/presentation/widgets/group_card.dart`
  - [ ] Display group name, description, member count
  - [ ] Show "Owner" badge if isOwner = true

- [ ] Create `lib/features/groups/presentation/widgets/create_group_dialog.dart`
  - [ ] Form with name & description fields
  - [ ] Create button that calls controller.createGroup()
  - [ ] Show error/loading states

- [ ] Create `lib/features/groups/presentation/widgets/groups_tab.dart`
  - [ ] List of group cards
  - [ ] Empty state message
  - [ ] Loading indicator

- [ ] Create `lib/features/groups/presentation/widgets/members_tab.dart`
  - [ ] Display group members
  - [ ] Remove member button (owner only)
  - [ ] Add member button with dialog

- [ ] Create `lib/features/groups/presentation/widgets/invites_tab.dart`
  - [ ] Form to create invite (email, role)
  - [ ] List of pending invites with expiration status
  - [ ] Delete invite button

### 1.5 Testing

- [ ] Unit tests: `test/features/groups/data/groups_api_data_source_test.dart`
  - [ ] Test each method
  - [ ] Mock RestClient
  - [ ] Verify DioException → domain exception mapping

- [ ] Unit tests: `test/features/groups/data/groups_repository_test.dart`
  - [ ] Test mapping logic
  - [ ] Mock GroupsApiDataSource

- [ ] Unit tests: `test/features/groups/presentation/groups_controller_test.dart`
  - [ ] Test state changes
  - [ ] Mock repository

- [ ] Widget tests: `test/features/groups/presentation/group_card_test.dart`
- [ ] Widget tests: `test/features/groups/presentation/groups_list_page_test.dart`

---

## Phase 2: Group Invites Feature

### 2.1 Domain Layer

- [ ] Create `lib/features/group_invites/domain/entities/group_invite.dart`
  - [ ] Fields: id, groupId, groupName, email, status, createdAt, expiresAt, role, token
  - [ ] Computed property: isExpired
  - [ ] Computed property: formattedExpiresIn

- [ ] Create `lib/features/group_invites/domain/repositories/group_invites_repository.dart`
  - [ ] getPendingInvites(): Future<List<GroupInvite>>
  - [ ] acceptInvite(String inviteId, String token): Future<Group>

### 2.2 Data Layer

- [ ] Create `lib/features/group_invites/data/data_sources/group_invites_api_data_source.dart`
  - [ ] getPendingInvites()
  - [ ] acceptInvite(String inviteId, String token)

- [ ] Create `lib/features/group_invites/data/repositories/group_invites_repository.dart`
  - [ ] Map GroupInviteResponse → GroupInvite

### 2.3 State Management

- [ ] Create `lib/features/group_invites/presentation/controllers/pending_invites_state.dart`
- [ ] Create `lib/features/group_invites/presentation/controllers/pending_invites_controller.dart`
  - [ ] loadPendingInvites() method
  - [ ] acceptInvite(String inviteId, String token) method

### 2.4 Presentation

- [ ] Create `lib/features/group_invites/presentation/pages/pending_invites_page.dart`
  - [ ] Show pending email invites
  - [ ] Accept button for each invite
  - [ ] Display expiration time ("Expires in X days")
  - [ ] Empty state if no invites

- [ ] Create `lib/features/group_invites/presentation/widgets/invite_card.dart`

### 2.5 Testing

- [ ] Unit tests for data/domain layer
- [ ] Widget tests for page and cards

---

## Phase 3: Routines Feature

### 3.1 Domain Layer

- [ ] Create `lib/features/routines/domain/entities/routine.dart`
  - [ ] Fields: id, groupId, name, description, createdAt, updatedAt, videoCount
  - [ ] Factory `fromResponse(RoutineResponse)`

- [ ] Create `lib/features/routines/domain/repositories/routines_repository.dart`
  - [ ] getRoutines(String groupId): Future<List<Routine>>
  - [ ] getRoutine(String groupId, String routineId): Future<Routine>
  - [ ] createRoutine(String groupId, String name, String description): Future<Routine>
  - [ ] updateRoutine(String groupId, String routineId, String name, String description): Future<Routine>
  - [ ] deleteRoutine(String groupId, String routineId): Future<void>

### 3.2 Data Layer

- [ ] Create `lib/features/routines/data/data_sources/routines_api_data_source.dart`
- [ ] Create `lib/features/routines/data/repositories/routines_repository.dart`

### 3.3 State Management

- [ ] Create `lib/features/routines/presentation/controllers/routines_state.dart`
- [ ] Create `lib/features/routines/presentation/controllers/routines_controller.dart`
  - [ ] loadRoutines(String groupId)
  - [ ] selectRoutine(String routineId)
  - [ ] createRoutine(String groupId, String name, String description)
  - [ ] updateRoutine(String groupId, String routineId, ...)
  - [ ] deleteRoutine(String groupId, String routineId)

### 3.4 Presentation

- [ ] Create `lib/features/routines/presentation/pages/routines_list_page.dart`
  - [ ] Receive groupId from route params
  - [ ] Display list of routines in group
  - [ ] FAB for create routine dialog
  - [ ] Navigation to routine detail page

- [ ] Create `lib/features/routines/presentation/pages/routine_detail_page.dart`
  - [ ] Receive groupId and routineId
  - [ ] Display routine info
  - [ ] Tab for videos in routine
  - [ ] Tab for notes
  - [ ] Edit/delete buttons

- [ ] Create `lib/features/routines/presentation/widgets/routine_card.dart`
  - [ ] Display name, description, video count

- [ ] Create `lib/features/routines/presentation/widgets/create_routine_dialog.dart`

- [ ] Create `lib/features/routines/presentation/widgets/routines_tab.dart` (for group detail page)

### 3.5 Testing

- [ ] Unit tests for data/domain/controller
- [ ] Widget tests for pages and cards

---

## Phase 4: Routine Videos Feature

### 4.1 Domain Layer

- [ ] Create `lib/features/routine_videos/domain/entities/routine_video.dart`
  - [ ] Fields: id, routineId, uploadedByUserId, uploadedByEmail, status, createdAt, uploadedAt, fileSize
  - [ ] Computed: isUploaded, isPendingUpload
  - [ ] Factory from VideoResponse

- [ ] Create `lib/features/routine_videos/domain/repositories/routine_videos_repository.dart`
  - [ ] getVideos(String groupId, String routineId): Future<List<RoutineVideo>>
  - [ ] getVideo(String groupId, String routineId, String videoId): Future<RoutineVideo>
  - [ ] registerVideoUpload(...): Future<VideoUploadSession>
  - [ ] uploadVideoFile(String presignedUrl, File file, onProgress): Future<void>
  - [ ] finalizeVideoUpload(...): Future<RoutineVideo>
  - [ ] deleteVideo(...): Future<void>
  - [ ] getVideoDownloadUrl(...): Future<String>

### 4.2 Data Layer

- [ ] Create `lib/features/routine_videos/data/data_sources/videos_api_data_source.dart`
  - [ ] All methods above, using generated clients

- [ ] Create `lib/features/routine_videos/data/repositories/routine_videos_repository.dart`

### 4.3 State Management

- [ ] Create `lib/features/routine_videos/presentation/controllers/videos_state.dart`
- [ ] Create `lib/features/routine_videos/presentation/controllers/videos_controller.dart`
  - [ ] loadVideos(String groupId, String routineId)
  - [ ] selectVideo(String videoId)
  - [ ] deleteVideo(String groupId, String routineId, String videoId)

- [ ] Create `lib/features/routine_videos/presentation/controllers/video_upload_state.dart`
  - [ ] Fields: isSelectingFile, isRegisteringUpload, isUploading, uploadProgress, error, successVideoId

- [ ] Create `lib/features/routine_videos/presentation/controllers/video_upload_controller.dart`
  - [ ] selectVideoFile(): Future<File?>
  - [ ] uploadVideo(String groupId, String routineId, File videoFile): Future<void>
    - [ ] Step 1: registerVideoUpload()
    - [ ] Step 2: uploadVideoFile() with progress tracking
    - [ ] Step 3: finalizeVideoUpload()
  - [ ] reset() method to clear success state

### 4.4 Presentation

- [ ] Create `lib/features/routine_videos/presentation/pages/video_upload_page.dart`
  - [ ] Receive groupId and routineId from route params
  - [ ] File picker button
  - [ ] Show selected file name
  - [ ] Upload button that calls controller.uploadVideo()
  - [ ] Progress indicator during upload (0-100%)
  - [ ] Success message after finalization
  - [ ] Error message if upload fails with retry button

- [ ] Create `lib/features/routine_videos/presentation/pages/video_player_page.dart`
  - [ ] Receive groupId, routineId, videoId
  - [ ] Get video download URL
  - [ ] Use VideoPlayer to play
  - [ ] Display video metadata (uploader, date, status)
  - [ ] Show notes overlay (timed notes appear as video plays)

- [ ] Create `lib/features/routine_videos/presentation/widgets/video_card.dart`
  - [ ] Display uploader, date, status badge
  - [ ] Tap to navigate to video player page

- [ ] Create `lib/features/routine_videos/presentation/widgets/upload_progress_indicator.dart`
  - [ ] Animated circular progress with percentage text

- [ ] Create `lib/features/routine_videos/presentation/widgets/videos_tab.dart` (for routine detail page)

### 4.5 Testing

- [ ] Unit tests for data/domain/controllers (including progress tracking)
- [ ] Widget tests for upload page, video card, progress indicator
- [ ] Test 3-step upload flow in integration tests

---

## Phase 5: Routine Notes Feature

### 5.1 Domain Layer

- [ ] Create `lib/features/routine_notes/domain/entities/routine_note.dart`
  - [ ] Fields: id, routineId, videoId, videoTimestampMs, createdByEmail, content, details, videoDeleted, createdAt
  - [ ] Computed: isVideoNote, formattedTimestamp
  - [ ] Factory from NoteResponse

- [ ] Create `lib/features/routine_notes/domain/repositories/routine_notes_repository.dart`
  - [ ] getRoutineNotes(String groupId, String routineId): Future<List<RoutineNote>>
  - [ ] getVideoNotes(String groupId, String routineId, String videoId): Future<List<RoutineNote>>
  - [ ] addRoutineNote(String groupId, String routineId, String content): Future<RoutineNote>
  - [ ] addVideoNote(String groupId, String routineId, String videoId, int timestampMs, String content): Future<RoutineNote>
  - [ ] deleteNote(String groupId, String routineId, String noteId): Future<void>

### 5.2 Data Layer

- [ ] Create `lib/features/routine_notes/data/data_sources/notes_api_data_source.dart`
- [ ] Create `lib/features/routine_notes/data/repositories/routine_notes_repository.dart`

### 5.3 State Management

- [ ] Create `lib/features/routine_notes/presentation/controllers/notes_state.dart`
- [ ] Create `lib/features/routine_notes/presentation/controllers/notes_controller.dart`
  - [ ] loadRoutineNotes(String groupId, String routineId)
  - [ ] loadVideoNotes(String groupId, String routineId, String videoId)
  - [ ] addRoutineNote(...)
  - [ ] addVideoNote(...)
  - [ ] deleteNote(...)

### 5.4 Presentation

- [ ] Create `lib/features/routine_notes/presentation/widgets/note_card.dart`
  - [ ] Display note content, creator, timestamp (if video note)
  - [ ] Delete button

- [ ] Create `lib/features/routine_notes/presentation/widgets/add_note_dialog.dart`
  - [ ] Form to add routine or video note
  - [ ] For video notes: show current video timestamp or allow manual entry
  - [ ] Submit button calls controller method

- [ ] Create `lib/features/routine_notes/presentation/widgets/notes_tab.dart` (for routine detail page)
  - [ ] List of routine notes

- [ ] Create `lib/features/routine_notes/presentation/widgets/video_notes_overlay.dart` (for video player)
  - [ ] Display notes as video scrubber
  - [ ] Highlight current timestamp
  - [ ] Tap to jump to timestamp

### 5.5 Testing

- [ ] Unit tests for data/domain/controllers
- [ ] Widget tests for note cards and dialogs

---

## Phase 6: Integration & Navigation

### 6.1 Routing

- [ ] Update `lib/config/routes.dart` with new routes:
  - [ ] `/groups` → GroupsListPage
  - [ ] `/groups/:groupId` → GroupDetailPage with nested routes
  - [ ] `/groups/:groupId/routines/:routineId` → RoutineDetailPage
  - [ ] `/groups/:groupId/routines/:routineId/upload-video` → VideoUploadPage
  - [ ] `/groups/:groupId/routines/:routineId/videos/:videoId` → VideoPlayerPage
  - [ ] `/pending-invites` → PendingInvitesPage

- [ ] Add route guards for authentication (already existing, verify they work)

- [ ] Test deep linking to each route

### 6.2 Provider Registration

- [ ] Update `lib/main.dart` with all new providers:
  - [ ] GroupsApiDataSource → GroupsRepository → GroupsController
  - [ ] GroupInvitesApiDataSource → GroupInvitesRepository → PendingInvitesController
  - [ ] RoutinesApiDataSource → RoutinesRepository → RoutinesController
  - [ ] VideosApiDataSource → VideosRepository → VideosController + VideoUploadController
  - [ ] NotesApiDataSource → NotesRepository → NotesController

### 6.3 Home Page Integration

- [ ] Update `lib/features/home/presentation/pages/home_page.dart`
  - [ ] Add NavigationCard for "Groups & Routines"
  - [ ] Tap navigates to `/groups`
  - [ ] Display pending invites count (if any)

### 6.4 Navigation Testing

- [ ] Test all route transitions
- [ ] Test back button behavior
- [ ] Test navigation with parameters
- [ ] Test deep links

---

## Phase 7: Polish & Testing

### 7.1 Error Handling

- [ ] All data sources properly map exceptions
- [ ] All controllers display user-friendly error messages
- [ ] Test 404 (not found) vs 403 (permission denied) handling
- [ ] Test network error handling and retry

### 7.2 Loading & Empty States

- [ ] Add skeleton loaders for list pages
- [ ] Add "No groups yet" empty state
- [ ] Add "No routines yet" empty state
- [ ] Add "No videos yet" empty state
- [ ] Add "No notes yet" empty state

### 7.3 Form Validation

- [ ] Group name required, non-empty
- [ ] Routine name required, non-empty
- [ ] Email validation for invites
- [ ] Note content required, non-empty

### 7.4 UI Polish

- [ ] Consistent spacing and colors
- [ ] Proper loading indicators (spinners, progress bars)
- [ ] Snackbars for success/error messages
- [ ] Disabled buttons during loading
- [ ] Proper AppBar titles and back buttons

### 7.5 Documentation

- [ ] Add inline code comments for complex logic
- [ ] Document API method calls in data sources
- [ ] Create example usage docs for other developers

### 7.6 Final Testing

- [ ] [ ] Manual testing on physical device (iOS)
- [ ] [ ] Manual testing on physical device (Android)
- [ ] [ ] Test complete flow: Login → Create Group → Invite → Create Routine → Upload Video → Add Note
- [ ] [ ] Test error scenarios
- [ ] [ ] Test network loss recovery
- [ ] [ ] Test presigned URL expiration handling
- [ ] [ ] Performance testing (large lists, etc.)

---

## Provider Registration Template

Copy this into `main.dart` and update with all features:

```dart
MultiProvider(
  providers: [
    // ... existing providers ...
    
    // Groups Feature
    Provider<GroupsApiDataSource>(
      create: (context) {
        final apiService = context.read<ApiService>();
        return GroupsApiDataSource(apiService.client);
      },
    ),
    Provider<GroupsRepository>(
      create: (context) => GroupsRepositoryImpl(
        context.read<GroupsApiDataSource>(),
      ),
    ),
    ChangeNotifierProvider<GroupsController>(
      create: (context) => GroupsController(
        context.read<GroupsRepository>(),
      ),
    ),
    
    // Group Invites Feature
    Provider<GroupInvitesApiDataSource>(
      create: (context) {
        final apiService = context.read<ApiService>();
        return GroupInvitesApiDataSource(apiService.client);
      },
    ),
    Provider<GroupInvitesRepository>(
      create: (context) => GroupInvitesRepositoryImpl(
        context.read<GroupInvitesApiDataSource>(),
      ),
    ),
    ChangeNotifierProvider<PendingInvitesController>(
      create: (context) => PendingInvitesController(
        context.read<GroupInvitesRepository>(),
      ),
    ),
    
    // Routines Feature
    Provider<RoutinesApiDataSource>(
      create: (context) {
        final apiService = context.read<ApiService>();
        return RoutinesApiDataSource(apiService.client);
      },
    ),
    Provider<RoutinesRepository>(
      create: (context) => RoutinesRepositoryImpl(
        context.read<RoutinesApiDataSource>(),
      ),
    ),
    ChangeNotifierProvider<RoutinesController>(
      create: (context) => RoutinesController(
        context.read<RoutinesRepository>(),
      ),
    ),
    
    // Videos Feature
    Provider<VideosApiDataSource>(
      create: (context) {
        final apiService = context.read<ApiService>();
        return VideosApiDataSource(apiService.client);
      },
    ),
    Provider<VideosRepository>(
      create: (context) => VideosRepositoryImpl(
        context.read<VideosApiDataSource>(),
      ),
    ),
    ChangeNotifierProvider<VideosController>(
      create: (context) => VideosController(
        context.read<VideosRepository>(),
      ),
    ),
    ChangeNotifierProvider<VideoUploadController>(
      create: (context) => VideoUploadController(
        context.read<VideosRepository>(),
      ),
    ),
    
    // Notes Feature
    Provider<NotesApiDataSource>(
      create: (context) {
        final apiService = context.read<ApiService>();
        return NotesApiDataSource(apiService.client);
      },
    ),
    Provider<NotesRepository>(
      create: (context) => NotesRepositoryImpl(
        context.read<NotesApiDataSource>(),
      ),
    ),
    ChangeNotifierProvider<NotesController>(
      create: (context) => NotesController(
        context.read<NotesRepository>(),
      ),
    ),
  ],
  child: MaterialApp.router(...),
)
```

---

## Success Metrics

When complete, you should have:

- ✅ 100% of domain entities created
- ✅ 100% of API data sources created
- ✅ 100% of repositories implemented
- ✅ 100% of controllers and state classes created
- ✅ All UI pages and widgets created
- ✅ All routes added to go_router
- ✅ All providers registered
- ✅ Full end-to-end flows working (login → create group → create routine → upload video → add note)
- ✅ Error handling for all error cases
- ✅ Loading/empty states for all pages
- ✅ Unit tests for domain and data layers
- ✅ Widget tests for key UI components
- ✅ Integration tests for critical flows
- ✅ Manual testing on device passes

---

## Notes

- Work feature-by-feature, completing all layers (domain → data → presentation) for each
- Write tests as you implement, not at the end
- Use existing auth/upload features as reference for architecture patterns
- Commit frequently and create PRs for review
- Ask for help if stuck on generated client method signatures
- Remember: 404 means "not found" (don't leak group existence even if user doesn't have access)

---

**Status:** Ready to start implementation  
**Last Updated:** 2024
