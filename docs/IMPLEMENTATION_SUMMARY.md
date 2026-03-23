# Flutter Client: Groups/Routines/Videos/Notes - Quick Implementation Summary

## Overview

You're adding 5 major features to the Flutter client. The backend is complete with OpenAPI specs regenerated. All API clients and models have been auto-generated in `lib/generated/api/`.

## What's Already Generated

✅ API Clients: GroupsClient, GroupInvitesClient, RoutinesClient, RoutineVideosClient, NotesClient  
✅ Models: All request/response models (GroupResponse, RoutineResponse, VideoResponse, NoteResponse, etc.)  
✅ Enums: GroupRole, VideoStatus, GroupInviteStatus, NoteType, etc.

Located in: `lib/generated/api/clients/` and `lib/generated/api/models/`

## Architecture to Follow

**Stack:** Provider (state mgmt) + go_router (navigation) + Clean Architecture (domain/data/presentation)

**Pattern:** Same as existing features (auth, upload, history)

## Quick Implementation Roadmap

### Phase 1: Domain & Data Layer (Weeks 1-2)

1. **Create domain entities** that mirror API responses
   - `groups/domain/entities/group.dart`
   - `routines/domain/entities/routine.dart`
   - `routine_videos/domain/entities/routine_video.dart`
   - `routine_notes/domain/entities/routine_note.dart`
   - `group_invites/domain/entities/group_invite.dart`

2. **Create abstract repositories**
   - `*/domain/repositories/*_repository.dart` (abstract interfaces)

3. **Create API data sources** that use generated clients
   - `*/data/data_sources/*_api_data_source.dart`
   - Call methods like: `_client.groups.getGroupsApiV1GroupsGet()`

4. **Create repository implementations**
   - `*/data/repositories/*_repository.dart` (implementations)
   - Map API responses to domain entities

5. **Add exception classes**
   - `core/exceptions/app_exceptions.dart`
   - NotFoundException, PermissionException, NetworkException, etc.
   - Map DioException → domain exceptions in data sources

### Phase 2: State Management (Weeks 2-3)

1. **Create state classes** (immutable data holders)
   - `*/presentation/controllers/*_state.dart`
   - Include fields: data, isLoading, error, selectedItem

2. **Create controllers** (ChangeNotifier)
   - `*/presentation/controllers/*_controller.dart`
   - Inject repository, manage state, handle async operations

3. **Register providers** in `main.dart`
   ```dart
   Provider<DataSource>(create: (_) => DataSource(apiService.client)),
   Provider<Repository>(create: (c) => RepositoryImpl(c.read<DataSource>())),
   ChangeNotifierProvider<Controller>(create: (c) => Controller(c.read<Repository>())),
   ```

### Phase 3: UI Layer (Weeks 3-5)

1. **Groups Feature**
   - `groups/presentation/pages/groups_list_page.dart`
   - `groups/presentation/pages/group_detail_page.dart`
   - Widgets: group_card, create_group_dialog, members_tab, invites_tab

2. **Pending Invites Page**
   - `group_invites/presentation/pages/pending_invites_page.dart`
   - Show email invites user can accept

3. **Routines Feature**
   - `routines/presentation/pages/routines_list_page.dart`
   - `routines/presentation/pages/routine_detail_page.dart`
   - Widgets: routine_card, create_routine_dialog

4. **Videos Feature**
   - `routine_videos/presentation/pages/video_upload_page.dart` (3-step upload)
   - `routine_videos/presentation/pages/video_player_page.dart`
   - Widgets: video_card, upload_progress_indicator

5. **Notes Feature**
   - Add widgets to display routine/video notes
   - Widgets: note_card, add_note_dialog

### Phase 4: Navigation & Integration (Week 5)

1. **Update `config/routes.dart`** with new routes
   - `/groups` → GroupsListPage
   - `/groups/:groupId` → GroupDetailPage
   - `/groups/:groupId/routines/:routineId` → RoutineDetailPage
   - `/pending-invites` → PendingInvitesPage

2. **Update Home page** with navigation card to Groups

3. **Test navigation flows**

### Phase 5: Testing (Week 6)

1. **Unit tests** for data/domain layer (100% coverage)
2. **Integration tests** for key flows
3. **Widget tests** for UI components
4. **Manual testing** on device

## Key Implementation Notes

### Groups Flow
- User creates group → backend stores
- Owner invites via email (pre-account)
- Invites have token-based accept flow
- Group members can be removed

### Video Upload (3-Step)
1. Register upload → get presigned S3 URL
2. PUT video bytes to presigned URL (with progress)
3. Finalize upload → mark complete, trigger processing

### Notes
- **Routine notes**: Apply to whole routine
- **Video notes**: Tied to video + timestamp (ms)
- Format timestamp as MM:SS for display

### Error Handling
- 404: "Not found" (don't leak group existence)
- 403: Becomes 404 on backend (privacy)
- Map all DioExceptions to domain exceptions
- Show user-friendly messages in UI

## File Structure

```
lib/features/
├── groups/
│   ├── data/data_sources/groups_api_data_source.dart
│   ├── data/repositories/groups_repository.dart
│   ├── domain/entities/group.dart
│   ├── domain/repositories/groups_repository.dart (abstract)
│   └── presentation/
│       ├── controllers/{state,controller}.dart
│       ├── pages/{list,detail}.dart
│       └── widgets/{card,dialog,tabs}.dart
├── routines/ (same structure)
├── routine_videos/ (same structure + special video upload handling)
├── routine_notes/ (same structure)
└── group_invites/ (same structure)
```

## Testing Strategy

```dart
// Test pattern 1: Data source (mock RestClient)
test('DataSource calls API and returns response', () async {
  when(mockClient.groups.getGroupsApiV1GroupsGet())
    .thenAnswer((_) => Future.value([...]));
  final result = await dataSource.getGroups();
  expect(result, isNotEmpty);
});

// Test pattern 2: Repository (mock DataSource)
test('Repository maps response to entity', () async {
  when(mockDataSource.getGroups()).thenAnswer((_) => Future.value([...]));
  final result = await repository.getGroups();
  expect(result.first, isA<Group>());
});

// Test pattern 3: Controller (mock Repository)
test('Controller updates state on loadGroups', () async {
  when(mockRepository.getGroups()).thenAnswer((_) => Future.value([...]));
  await controller.loadGroups();
  expect(controller.state.isLoading, false);
  expect(controller.state.groups, isNotEmpty);
});
```

## Provider Setup Example

```dart
// In main.dart MultiProvider
ChangeNotifierProvider<GroupsController>(
  create: (context) {
    final apiService = context.read<ApiService>();
    final dataSource = GroupsApiDataSource(apiService.client);
    final repository = GroupsRepositoryImpl(dataSource);
    return GroupsController(repository);
  },
),
```

## Next Steps

1. ✅ You've already regenerated OpenAPI spec
2. ✅ All API code is generated
3. Start Phase 1: Create domain entities and exceptions
4. Build bottom-up: Domain → Data → Controllers → UI
5. Test as you go (unit tests first)

## Key Generated Client Access

```dart
// All clients available via RestClient (from ApiService)
final apiService = ApiService();
final client = apiService.client;

// Example calls:
await client.groups.getGroupsApiV1GroupsGet();
await client.routines.getRoutinesApiV1GroupsGroupIdRoutinesGet(groupId: id);
await client.routineVideos.registerUploadApiV1GroupsGroupIdRoutinesRoutineIdVideosPost(...);
```

## Success Criteria

- All entities, repositories, and data sources created
- All controllers and state classes managing UI state
- Routes added and navigation working
- Key flows tested (create group → invite → create routine → upload video)
- Error handling in place (404, 403, network, etc.)
- Loading/empty/error states shown in UI

## Estimated Timeline

| Phase | Duration |
|-------|----------|
| Phase 1 (Domain/Data) | 2 weeks |
| Phase 2 (State Mgmt) | 1.5 weeks |
| Phase 3 (UI) | 2 weeks |
| Phase 4 (Integration) | 1 week |
| Phase 5 (Testing) | 1 week |
| **Total** | **~7-8 weeks** |

Can be parallelized (UI work while testing completes).

---

**Good luck! Refer to existing features (auth, upload) for architectural patterns.**
