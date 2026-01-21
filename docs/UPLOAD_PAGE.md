# Upload Page Documentation

## Overview

The Upload Page is a comprehensive video upload interface for the Dance Analysis Client. It provides a user-friendly experience for selecting, previewing, annotating, and uploading dance practice videos for analysis.

## Architecture

The Upload Page follows a clean, senior-level architecture with clear separation of concerns:

### Models

- **`VideoTimestamp`** (`lib/models/video_timestamp.dart`)
  - Represents user-defined timestamps marking dance steps or routine segments
  - Includes ID, timestamp (Duration), and label (step name)
  - Provides JSON serialization for backend communication

- **`VideoMetadata`** (`lib/models/video_metadata.dart`)
  - Tracks complete video metadata including trimming and upload information
  - Stores original path, trimmed path, start/end times, and backend reference
  - Enables local persistence and recovery of upload state

### State Management

- **`UploadState`** (`lib/state/upload_state.dart`)
  - Immutable state snapshot using copyWith pattern
  - Tracks upload status, email validation, video info, timestamps, and trim settings
  - Includes computed properties like `exceedsRecommendedLength` and `shouldRecommendTimestamps`

- **`UploadController`** (`lib/state/upload_controller.dart`)
  - ChangeNotifier-based controller coordinating the upload flow
  - Methods for video selection, timestamp management, trimming, and upload
  - Clean separation from UI code for easy testing

### Services

- **`ApiClient`** (updated in `lib/services/api_client.dart`)
  - Enhanced to send timestamps and trim information with video uploads
  - Returns backend reference for uploaded videos
  - Handles cross-platform file uploads (web vs mobile)

### UI Components

#### Main Page

- **`UploadPage`** (`lib/ui/upload_page.dart`)
  - Results-page-style layout with video player, header, and list sections
  - Video player with playback controls
  - Email input and video selection buttons
  - Upload button with validation
  - Timestamp list with add/edit/delete functionality

#### Widgets

- **`TimestampListItem`** (`lib/ui/widgets/timestamp_list_item.dart`)
  - Displays individual timestamp with formatted time and step label
  - Edit and delete action buttons
  - Tap to seek video to timestamp
  - Supports inline editing mode - replaces itself with edit form when active

- **`InlineTimestampForm`** (`lib/ui/widgets/inline_timestamp_form.dart`)
  - Inline form for adding/editing timestamps without dialogs
  - Automatically uses current video position as default time
  - Time display with slider for fine-tuning
  - Step name input field
  - Appears directly in the timestamp list
  - Allows user to interact with video while creating timestamps

- **`RecommendTimestampsDialog`** (`lib/ui/widgets/recommend_timestamps_dialog.dart`)
  - Shown when user tries to upload videos longer than 15 seconds without timestamps
  - Educates users about the benefits of timestamping
  - Allows proceeding anyway or returning to add timestamps

## Features

### 1. Video Selection and Preview

- **Web**: File picker for selecting local videos
- **Mobile**: Record new video or choose from gallery
- **Video Player**: Full playback controls with play/pause, scrubbing, and time display
- **Cross-platform**: Uses `VideoPlayerController` with platform-specific initialization

### 2. Video Timestamping (Inline Editing)

- **Purpose**: Mark different dance steps or routine segments in longer videos
- **Benefits**: Enables better backend analysis by splitting video into logical segments
- **Workflow**:
  - Click "Add" button to open inline form at bottom of list
  - Form automatically captures current video position as default time
  - User can adjust time with slider or play video to desired position
  - Enter step name and save
  - Form appears inline - no dialog popup
  - Edit works the same way - expands the item inline
- **Key Feature**: Users can watch and scrub video while form is open
- **UI**:
  - List displays all timestamps in chronological order
  - Tap timestamp to seek video
  - Edit replaces item with inline form
  - Delete removes timestamp immediately
- **Data**: Timestamps sent to backend as JSON array with video upload

### 3. Length Validation and Recommendations

- **15-Second Threshold**: Videos longer than 15 seconds trigger recommendation
- **Smart Dialog**: Suggests adding timestamps for better analysis
- **User Choice**: Can proceed without timestamps if desired
- **Visual Feedback**: Shows effective duration after trimming

### 4. Video Trimming (TODO)

- **Current State**: UI placeholder exists but not fully implemented
- **Marked as**: TODO for complex implementation
- **Planned Features**:
  - Adjust start/end time sliders
  - Visual preview of trimmed segment
  - Actual video encoding/trimming via service layer
- **Metadata Tracking**: Start/end times already tracked in `VideoMetadata` model

### 5. Video Metadata Persistence (TODO)

- **Current State**: Models exist but local persistence not implemented
- **Challenge**: Backend doesn't return analyzed video, only feedback
- **Solutions**:
  - Store `VideoMetadata` locally (SharedPreferences, SQLite, etc.)
  - Track backend reference ID for later retrieval
  - Store trim start/end times for playback synchronization
- **Use Cases**:
  - Resume uploads after app restart
  - View original video alongside analysis results
  - Re-upload with different parameters

### 6. Email Validation

- **Simple regex validation**: `^[^@]+@[^@]+\.[^@]+$`
- **Real-time feedback**: Shows error when invalid
- **Required for upload**: Button disabled until valid

### 7. Error Handling

- **Network errors**: User-friendly messages
- **Validation errors**: Clear inline feedback
- **Video player errors**: Graceful fallback with retry option
- **Upload failures**: Error displayed with retry ability

## User Flow

1. **Initial State**: Empty state prompting video selection
2. **Select Video**: Choose via camera/gallery (mobile) or file picker (web)
3. **Video Loads**: Player initializes with playback controls
4. **Add Timestamps** (Optional):
   - Play/scrub video to desired position
   - Click "Add" button (form appears inline with current video time)
   - Fine-tune time with slider if needed OR continue watching video to different position
   - Enter step name
   - Click "Save" (form closes automatically)
   - Repeat for each step/segment
5. **Edit Timestamps** (Optional):
   - Click edit icon on any timestamp
   - Item expands to show inline edit form
   - Adjust time and/or label
   - Click "Save" or "Cancel"
6. **Enter Email**: Valid email required
7. **Upload**:
   - Click "Upload for Analysis"
   - If video >15s without timestamps, recommendation dialog appears
   - Upload proceeds with video, email, timestamps, and trim info
   - Success message shown

## Code Quality Features

### Readability

- Clear naming conventions
- Comprehensive documentation comments
- Logical file organization
- Consistent code style
- Inline editing improves user comprehension of workflow

### Extensibility

- Models support JSON serialization for API evolution
- Controller methods easily testable in isolation
- Widget composition allows easy UI customization
- State management pattern scales well
- Inline form is reusable for both add and edit operations

### Testability

- Pure model classes with equality operators
- Controller logic separate from widgets
- Mockable service dependencies
- Clear single-responsibility methods
- Inline form can be tested independently of dialogs

## Future Enhancements

### High Priority

1. **Complete Video Trimming**
   - Implement actual video trimming/encoding
   - Add visual trim preview with handles
   - Support frame-accurate trimming

2. **Video Persistence**
   - Implement local storage for VideoMetadata
   - Add upload history screen
   - Enable video playback from history

### Medium Priority

3. **Batch Upload**: Support multiple videos
4. **Progress Tracking**: Detailed upload progress with percentage
5. **Draft Saving**: Save partial uploads as drafts
6. **Offline Support**: Queue uploads for later

### Low Priority

7. **Video Filters**: Basic adjustments (brightness, contrast)
8. **Multi-language**: Internationalization support
9. **Advanced Timestamps**: Categories, colors, notes
10. **Cloud Sync**: Sync metadata across devices

## Testing Recommendations

### Unit Tests

- Model serialization/deserialization
- State transitions in UploadState (including isAddingTimestamp, editingTimestampId)
- Email validation logic
- Timestamp sorting and management
- Inline form state management (add vs edit mode)

### Widget Tests

- Timestamp list rendering with inline forms
- Inline form expand/collapse behavior
- Form validation
- Button states (disabled when form is open)
- Current video position capture

### Integration Tests

- Complete upload flow with inline timestamp creation
- Video player initialization and position tracking
- Error handling scenarios
- Cross-platform file selection
- Add timestamp while video is playing
- Edit timestamp without losing video state

## Dependencies

- `video_player`: Video playback
- `image_picker`: Video/photo selection
- `http`: Network requests
- Standard Flutter widgets and material design

## Platform-Specific Notes

### Web

- Uses `VideoPlayerController.networkUrl()` for video loading
- File picker only (no camera recording)
- CORS may affect video preview from certain sources

### Mobile (iOS/Android)

- Uses `VideoPlayerController.file()` with `dart:io` File
- Supports both camera recording and gallery selection
- Requires permissions configuration in platform-specific files

### Desktop

- Similar to mobile, uses file-based video loading
- File picker for video selection
- May require additional platform setup

## API Contract

### Upload Endpoint

```http
POST /analyze
Content-Type: multipart/form-data

Fields:
- email: string (required)
- video: file (required)
- trim_start_seconds: int (default: 0)
- trim_end_seconds: int (default: video duration)
- timestamps: JSON array (optional)
  [
    {
      "id": "string",
      "timestamp_seconds": int,
      "label": "string"
    }
  ]

Response:
{
  "video_reference": "string" (optional - backend ID for uploaded video)
}
```

## Performance Considerations

1. **Video Player**: Initialized only when needed, disposed properly
2. **State Updates**: Efficient copyWith pattern minimizes rebuilds
3. **Timestamps**: Sorted once on add, not on every render
4. **Memory**: Video player controller properly disposed to prevent leaks

## Accessibility

- Semantic labels for screen readers
- Keyboard navigation support (Enter to save, Esc to cancel)
- High contrast colors from design system
- Touch targets meet minimum size requirements
- Inline forms provide better context than modal dialogs
- Form appears in natural tab order within list

## User Experience Improvements

### Inline Editing Benefits

1. **Context Preservation**: Users can see video and other timestamps while editing
2. **Current Position Capture**: Default time is always the current video position
3. **No Context Switching**: No modal dialogs interrupting workflow
4. **Visual Feedback**: Form appears exactly where the timestamp will be in the list
5. **Faster Workflow**: Scrub video → Click Add → Type name → Save
6. **Intuitive**: Natural flow matching video editing tools users are familiar with

### Design Decisions

- **Why Inline**: Modal dialogs break the mental model of "marking moments in a video"
- **Why Current Position**: Users naturally pause at the moment they want to mark
- **Why Slider**: Allows fine-tuning without leaving the form
- **Why Auto-close**: Reduces clicks and keeps list clean

---

_Last Updated: [Current Date]_
_Version: 1.0_
_Author: Senior Engineering Team_
