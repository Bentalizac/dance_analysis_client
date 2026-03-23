# Generated API Reference Guide

This guide maps backend API endpoints to generated Flutter client methods.

## Groups API

### List User's Groups
```dart
// Backend: GET /groups
// Generated method:
List<GroupResponse> groups = await client.groups.getGroupsApiV1GroupsGet();

// Usage in data source:
Future<List<GroupResponse>> getGroups() {
  return _client.groups.getGroupsApiV1GroupsGet();
}
```

### Get Group Details
```dart
// Backend: GET /groups/{group_id}
// Generated method:
GroupResponse group = await client.groups.getGroupApiV1GroupsGroupIdGet(
  groupId: 'group-123',
);
```

### Create Group
```dart
// Backend: POST /groups
// Generated method:
GroupResponse newGroup = await client.groups.createGroupApiV1GroupsPost(
  body: GroupCreate(
    name: 'My Dance Group',
    description: 'Description...',
  ),
);
```

### Get Group Members
```dart
// Backend: GET /groups/{group_id}/members
// Generated method:
List<GroupMembershipResponse> members = 
  await client.groups.getGroupMembersApiV1GroupsGroupIdMembersGet(
    groupId: 'group-123',
  );
```

### Add Member to Group
```dart
// Backend: POST /groups/{group_id}/members
// Generated method:
GroupMembershipResponse membership = 
  await client.groups.addMemberApiV1GroupsGroupIdMembersPost(
    groupId: 'group-123',
    body: AddMemberRequest(userId: 'user-123'),
  );
```

### Remove Member from Group
```dart
// Backend: DELETE /groups/{group_id}/members/{user_id}
// Generated method:
await client.groups.removeMemberApiV1GroupsGroupIdMembersUserIdDelete(
  groupId: 'group-123',
  userId: 'user-123',
);
```

---

## Group Invites API

### Create Invite (Send Email)
```dart
// Backend: POST /groups/{group_id}/invites
// Generated method:
GroupInviteResponse invite = 
  await client.groupInvites.createInviteApiV1GroupsGroupIdInvitesPost(
    groupId: 'group-123',
    body: GroupInviteCreate(
      email: 'friend@example.com',
      role: 'member', // or 'admin'
    ),
  );
```

### Get Pending Invites for Current User
```dart
// Backend: GET /user/invites/pending
// Generated method:
List<GroupInviteResponse> pendingInvites = 
  await client.groupInvites.getPendingInvitesApiV1UserInvitesPendingGet();
```

### Accept Invite
```dart
// Backend: POST /invites/{invite_id}/accept
// Generated method:
GroupResponse group = 
  await client.groupInvites.acceptInviteApiV1InvitesInviteIdAcceptPost(
    inviteId: 'invite-123',
    body: AcceptInviteRequest(token: 'token-from-email'),
  );
```

---

## Routines API

### List Routines in Group
```dart
// Backend: GET /groups/{group_id}/routines
// Generated method:
List<RoutineResponse> routines = 
  await client.routines.getRoutinesApiV1GroupsGroupIdRoutinesGet(
    groupId: 'group-123',
  );
```

### Get Routine Details
```dart
// Backend: GET /groups/{group_id}/routines/{routine_id}
// Generated method:
RoutineResponse routine = 
  await client.routines.getRoutineApiV1GroupsGroupIdRoutinesRoutineIdGet(
    groupId: 'group-123',
    routineId: 'routine-456',
  );
```

### Create Routine
```dart
// Backend: POST /groups/{group_id}/routines
// Generated method:
RoutineResponse newRoutine = 
  await client.routines.createRoutineApiV1GroupsGroupIdRoutinesPost(
    groupId: 'group-123',
    body: RoutineCreate(
      name: 'Weekly Practice',
      description: 'Monday practice session',
    ),
  );
```

### Update Routine
```dart
// Backend: PATCH /groups/{group_id}/routines/{routine_id}
// Generated method:
RoutineResponse updated = 
  await client.routines.updateRoutineApiV1GroupsGroupIdRoutinesRoutineIdPatch(
    groupId: 'group-123',
    routineId: 'routine-456',
    body: RoutineUpdate(
      name: 'Updated Name',
      description: 'Updated description',
    ),
  );
```

### Delete Routine
```dart
// Backend: DELETE /groups/{group_id}/routines/{routine_id}
// Generated method:
await client.routines.deleteRoutineApiV1GroupsGroupIdRoutinesRoutineIdDelete(
  groupId: 'group-123',
  routineId: 'routine-456',
);
```

---

## Videos API (Presigned Upload Flow)

### Step 1: Register Video Upload
```dart
// Backend: POST /groups/{group_id}/routines/{routine_id}/videos
// Generated method:
VideoRegisterResponse registration = 
  await client.routineVideos.registerUploadApiV1GroupsGroupIdRoutinesRoutineIdVideosPost(
    groupId: 'group-123',
    routineId: 'routine-456',
    body: VideoRegisterUpload(
      filename: 'dance_video.mp4',
      contentType: 'video/mp4',
      fileSize: 1024 * 1024 * 50, // 50 MB
    ),
  );

// Response contains:
// - registration.video (VideoResponse with id)
// - registration.presignedUrl (S3 upload URL)
// - registration.expiresAt (presigned URL expiration)
```

### Step 2: Upload Video to S3 (via presigned URL)
```dart
// Use Dio to PUT to presigned URL
// Example:
final dio = Dio();
await dio.put(
  registration.presignedUrl,
  data: videoFile.openRead(),
  options: Options(
    headers: {'Content-Type': 'video/mp4'},
  ),
  onSendProgress: (sent, total) {
    // Update progress: sent / total
  },
);
```

### Step 3: Finalize Video Upload
```dart
// Backend: POST /groups/{group_id}/routines/{routine_id}/videos/{video_id}/finalize
// Generated method:
VideoResponse video = 
  await client.routineVideos.finalizeUploadApiV1GroupsGroupIdRoutinesRoutineIdVideosVideoIdFinalizePost(
    groupId: 'group-123',
    routineId: 'routine-456',
    videoId: registration.video.id,
  );
```

### List Videos in Routine
```dart
// Backend: GET /groups/{group_id}/routines/{routine_id}/videos
// Generated method:
List<VideoResponse> videos = 
  await client.routineVideos.getVideosApiV1GroupsGroupIdRoutinesRoutineIdVideosGet(
    groupId: 'group-123',
    routineId: 'routine-456',
  );
```

### Get Video Details
```dart
// Backend: GET /groups/{group_id}/routines/{routine_id}/videos/{video_id}
// Generated method:
VideoResponse video = 
  await client.routineVideos.getVideoApiV1GroupsGroupIdRoutinesRoutineIdVideosVideoIdGet(
    groupId: 'group-123',
    routineId: 'routine-456',
    videoId: 'video-789',
  );
```

### Get Video Download URL
```dart
// Backend: GET /groups/{group_id}/routines/{routine_id}/videos/{video_id}/download
// Generated method:
VideoDownloadResponse downloadUrl = 
  await client.routineVideos.getVideoDownloadUrlApiV1GroupsGroupIdRoutinesRoutineIdVideosVideoIdDownloadGet(
    groupId: 'group-123',
    routineId: 'routine-456',
    videoId: 'video-789',
  );
// Use downloadUrl.url to fetch/stream video
```

### Delete Video
```dart
// Backend: DELETE /groups/{group_id}/routines/{routine_id}/videos/{video_id}
// Generated method:
await client.routineVideos.deleteVideoApiV1GroupsGroupIdRoutinesRoutineIdVideosVideoIdDelete(
  groupId: 'group-123',
  routineId: 'routine-456',
  videoId: 'video-789',
);
```

---

## Notes API

### Add Routine-Level Note
```dart
// Backend: POST /groups/{group_id}/routines/{routine_id}/notes
// Generated method:
NoteResponse note = 
  await client.notes.addRoutineNoteApiV1GroupsGroupIdRoutinesRoutineIdNotesPost(
    groupId: 'group-123',
    routineId: 'routine-456',
    body: RoutineNoteCreate(
      content: 'Remind to practice footwork',
      details: Optional details object,
    ),
  );
```

### Add Video-Level Note (with Timestamp)
```dart
// Backend: POST /groups/{group_id}/routines/{routine_id}/videos/{video_id}/notes
// Generated method:
NoteResponse note = 
  await client.notes.addVideoNoteApiV1GroupsGroupIdRoutinesRoutineIdVideosVideoIdNotesPost(
    groupId: 'group-123',
    routineId: 'routine-456',
    videoId: 'video-789',
    body: VideoNoteCreate(
      videoTimestampMs: 12500, // 12.5 seconds
      content: 'Check posture at this part',
      details: Optional details object,
    ),
  );
```

### Get Routine Notes
```dart
// Backend: GET /groups/{group_id}/routines/{routine_id}/notes
// Generated method:
List<NoteResponse> notes = 
  await client.notes.getRoutineNotesApiV1GroupsGroupIdRoutinesRoutineIdNotesGet(
    groupId: 'group-123',
    routineId: 'routine-456',
  );
```

### Get Video Notes
```dart
// Backend: GET /groups/{group_id}/routines/{routine_id}/videos/{video_id}/notes
// Generated method:
List<NoteResponse> videoNotes = 
  await client.notes.getVideoNotesApiV1GroupsGroupIdRoutinesRoutineIdVideosVideoIdNotesGet(
    groupId: 'group-123',
    routineId: 'routine-456',
    videoId: 'video-789',
  );
```

### Delete Note
```dart
// Backend: DELETE /groups/{group_id}/routines/{routine_id}/notes/{note_id}
// Generated method:
await client.notes.deleteNoteApiV1GroupsGroupIdRoutinesRoutineIdNotesNoteIdDelete(
  groupId: 'group-123',
  routineId: 'routine-456',
  noteId: 'note-999',
);
```

---

## Key Model Classes (Generated)

### GroupResponse
```dart
class GroupResponse {
  String id;
  String name;
  String description;
  DateTime createdAt;
  bool isOwner;
  // + other fields
}
```

### RoutineResponse
```dart
class RoutineResponse {
  String id;
  String groupId;
  String name;
  String? description;
  DateTime createdAt;
  DateTime updatedAt;
  int videoCount;
  // + other fields
}
```

### VideoResponse
```dart
class VideoResponse {
  String id;
  String routineId;
  String uploadedByUserId;
  String uploadedByEmail;
  VideoStatus status;
  DateTime createdAt;
  DateTime? uploadedAt;
  int? fileSize;
  // + other fields
}
```

### NoteResponse
```dart
class NoteResponse {
  String id;
  String routineId;
  String? videoId;
  int? videoTimestampMs;
  String createdByEmail;
  String content;
  Map<String, dynamic>? details;
  bool videoDeleted;
  DateTime createdAt;
  // + other fields
}
```

### VideoRegisterResponse
```dart
class VideoRegisterResponse {
  VideoResponse video;
  String presignedUrl;
  DateTime expiresAt;
}
```

---

## Enums

### VideoStatus
```dart
enum VideoStatus {
  pendingUpload,    // 'pending_upload'
  uploaded,         // 'uploaded'
  processing,       // 'processing'
  ready,            // 'ready'
  failed,           // 'failed'
}
```

### GroupRole
```dart
enum GroupRole {
  admin,
  member,
  guest,
}
```

### GroupInviteStatus
```dart
enum GroupInviteStatus {
  pending,
  accepted,
  expired,
  rejected,
}
```

### NoteType
```dart
enum NoteType {
  routineNote,
  videoNote,
}
```

### NoteSource
```dart
enum NoteSource {
  manual,
  aiGenerated,
}
```

---

## Example Usage in Data Source

```dart
// groups/data/data_sources/groups_api_data_source.dart
class GroupsApiDataSource {
  final RestClient _client;

  GroupsApiDataSource(this._client);

  Future<List<GroupResponse>> getGroups() {
    return _client.groups.getGroupsApiV1GroupsGet();
  }

  Future<GroupResponse> getGroup(String groupId) {
    return _client.groups.getGroupApiV1GroupsGroupIdGet(groupId: groupId);
  }

  Future<GroupResponse> createGroup(GroupCreate request) {
    return _client.groups.createGroupApiV1GroupsPost(body: request);
  }

  Future<List<GroupMembershipResponse>> getMembers(String groupId) {
    return _client.groups.getGroupMembersApiV1GroupsGroupIdMembersGet(
      groupId: groupId,
    );
  }

  Future<void> addMember(String groupId, String userId) {
    return _client.groups.addMemberApiV1GroupsGroupIdMembersPost(
      groupId: groupId,
      body: AddMemberRequest(userId: userId),
    );
  }

  Future<void> removeMember(String groupId, String userId) {
    return _client.groups.removeMemberApiV1GroupsGroupIdMembersUserIdDelete(
      groupId: groupId,
      userId: userId,
    );
  }
}
```

---

## How to Find Available Methods

1. Generated clients are in: `lib/generated/api/clients/`
2. Each client file has method names (example: `getGroupsApiV1GroupsGet`)
3. Method names follow pattern: `{operationId}` from OpenAPI spec
4. Use IDE autocomplete to see all available methods
5. Check method signatures for required/optional parameters
6. Return types are generated models from `lib/generated/api/models/`

---

**Note:** All DioExceptions from these client calls should be caught and mapped to domain exceptions in the data source layer.
