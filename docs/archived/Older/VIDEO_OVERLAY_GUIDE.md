# Video Player & Pose Overlay Guide

This guide explains how to integrate video playback with pose skeleton overlays in the dance analysis client.

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────┐
│  User uploads video to server           │
│  (video saved locally on device)        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Server processes video                 │
│  - Pose analysis (X,Y coordinates)      │
│  - Feedback generation                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Server returns JSON (not video!)       │
│  - Feedback items with timestamps       │
│  - Pose data per frame                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Client displays:                       │
│  - Local video file                     │
│  - Pose overlay from server data        │
│  - Feedback list with timestamps        │
└─────────────────────────────────────────┘
```

## 📦 Components

### 1. Data Models

#### `PoseData` (`lib/models/pose_data.dart`)
Represents pose skeleton for a specific frame:

```dart
PoseData(
  timestamp: 0.14,  // seconds
  keypoints: [
    Keypoint(name: 'left_ankle', x: 120.5, y: 480.2, confidence: 0.95),
    Keypoint(name: 'right_knee', x: 180.0, y: 350.0, confidence: 0.89),
    // ... more keypoints
  ],
  highlightedKeypoints: [5, 6],  // indices to highlight (optional)
)
```

#### `Keypoint`
Single point in the pose skeleton:
- `name`: Body part identifier (e.g., 'left_ankle', 'right_wrist')
- `x`, `y`: Coordinates (pixels or normalized 0-1)
- `confidence`: Detection confidence (0-1)

#### `AnalysisResult`
Complete response from backend:

```dart
AnalysisResult(
  feedbackItems: [...],      // List of FeedbackItem
  poseData: [...],           // List of PoseData
  videoPath: '/path/to/local/video.mp4',
)
```

### 2. Widgets

#### `VideoPlayerWithPoseOverlay`
Main video player component with overlay capabilities.

**Features:**
- Plays local video files (mobile/desktop) or network URLs (web)
- Synchronizes pose overlay with video playback
- Automatic pose data selection based on timestamp
- Playback controls (play/pause, scrubbing)
- Error handling and retry

**Usage:**
```dart
VideoPlayerWithPoseOverlay(
  videoPath: '/path/to/video.mp4',
  poseDataList: analysisResult.poseData,
  highlightedKeypointIndices: [5, 6],  // Highlight specific keypoints
  onTimestampChanged: (duration) {
    print('Current time: ${duration.inSeconds}s');
  },
)
```

#### `PoseOverlayPainter`
CustomPainter that draws pose skeleton on top of video.

**What it renders:**
1. **Skeleton lines** (blue) - Connections between keypoints
2. **Keypoint circles** (blue with white center)
3. **Highlight circles** (red) - Around flagged keypoints

**Customization:**
```dart
PoseOverlayPainter(
  poseData: currentPose,
  videoSize: Size(1920, 1080),
  showSkeleton: true,         // Show bone connections
  showKeypoints: true,        // Show joint circles
  highlightedKeypointIndices: [5, 6],  // Red circles
  highlightColor: Colors.red,
)
```

### 3. Pose Skeleton Structure

The `PoseConnections` class defines standard skeleton connections:

```
     nose
    /    \
  eye    eye
   |      |
  ear    ear

shoulder─shoulder
   │  \  /  │
   │   \/   │
   │   /\   │
   │  /  \  │
  hip─────hip
   │       │
  knee    knee
   │       │
 ankle   ankle
```

**Supported keypoints:**
- Head: nose, left_eye, right_eye, left_ear, right_ear
- Torso: left_shoulder, right_shoulder, left_hip, right_hip
- Arms: left_elbow, right_elbow, left_wrist, right_wrist
- Legs: left_knee, right_knee, left_ankle, right_ankle

## 🔧 Implementation Complexity

### ✅ Easy (Already Implemented)
- Basic video playback
- Loading local video files
- Play/pause controls
- Progress bar with scrubbing

### ✅ Medium (Already Implemented)
- Drawing pose skeleton overlay
- Synchronizing overlay with video
- Highlighting specific keypoints
- CustomPainter for rendering

### 🔨 To Implement

#### 1. Update Upload Flow
Modify `UploadController` to keep video reference after upload:

```dart
// In upload_controller.dart
Future<void> upload() async {
  // ... existing upload code ...
  
  // After successful upload, save video path for results
  final videoPath = _state.video!.xFile.path;
  
  // Store for later use
  _uploadedVideoPath = videoPath;
}
```

#### 2. Parse Backend Response
Convert JSON response to models:

```dart
// Example backend response
final json = {
  'feedback_items': [
    {
      'timestamp': '0:14',
      'type': 'negative',
      'feedback': 'left foot should be rotated outward...'
    }
  ],
  'pose_data': [
    {
      'timestamp': 0.14,
      'keypoints': [
        {'name': 'left_ankle', 'x': 120.5, 'y': 480.2, 'confidence': 0.95},
        {'name': 'right_ankle', 'x': 200.0, 'y': 475.0, 'confidence': 0.92},
        // ... more keypoints
      ],
      'highlighted_keypoints': [5, 6]  // Indices to highlight
    },
    // ... more frames
  ]
};

// Parse
final result = AnalysisResult.fromJson(json);
```

#### 3. Navigate to Results
After upload success, navigate to results page:

```dart
// In upload_page.dart or upload_controller.dart
await _controller.upload();

if (_controller.state.status == UploadStatus.success) {
  // Navigate to results
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ResultsPage(
        videoPath: _uploadedVideoPath,
        feedbackItems: parsedFeedbackItems,
        poseDataList: parsedPoseData,
        onTimestampTap: (duration) {
          // Seek video to this timestamp
          videoPlayerKey.currentState?.seekTo(duration);
        },
      ),
    ),
  );
}
```

## 🎨 Coordinate Systems

### Option 1: Pixel Coordinates
Backend sends actual pixel coordinates:

```json
{
  "name": "left_ankle",
  "x": 450,    // pixels from left
  "y": 720,    // pixels from top
  "confidence": 0.95
}
```

**Pros:** Simple, intuitive
**Cons:** Depends on video resolution

### Option 2: Normalized Coordinates (0-1)
Backend sends normalized values:

```json
{
  "name": "left_ankle",
  "x": 0.45,   // 45% from left
  "y": 0.72,   // 72% from top
  "confidence": 0.95
}
```

**Pros:** Resolution-independent, scalable
**Cons:** Requires conversion for rendering

**Recommended:** Use normalized coordinates (0-1) for flexibility.

The `PoseOverlayPainter` automatically scales coordinates to widget size:

```dart
final scaleX = canvasWidth / videoWidth;
final scaleY = canvasHeight / videoHeight;
final screenX = keypointX * scaleX;
final screenY = keypointY * scaleY;
```

## 📡 Backend Integration

### Expected JSON Format

```json
{
  "feedback_items": [
    {
      "timestamp": "0:14",
      "type": "negative",
      "feedback": "left foot should be rotated outward with weight placed on the inside edge of the ball of the foot"
    },
    {
      "timestamp": "0:08",
      "type": "positive"
    }
  ],
  "pose_data": [
    {
      "timestamp": 0.14,
      "keypoints": [
        {"name": "nose", "x": 0.5, "y": 0.2, "confidence": 0.99},
        {"name": "left_shoulder", "x": 0.45, "y": 0.35, "confidence": 0.95},
        {"name": "right_shoulder", "x": 0.55, "y": 0.35, "confidence": 0.96},
        {"name": "left_elbow", "x": 0.40, "y": 0.50, "confidence": 0.93},
        {"name": "right_elbow", "x": 0.60, "y": 0.50, "confidence": 0.94},
        {"name": "left_wrist", "x": 0.38, "y": 0.65, "confidence": 0.90},
        {"name": "right_wrist", "x": 0.62, "y": 0.65, "confidence": 0.91},
        {"name": "left_hip", "x": 0.46, "y": 0.55, "confidence": 0.97},
        {"name": "right_hip", "x": 0.54, "y": 0.55, "confidence": 0.98},
        {"name": "left_knee", "x": 0.44, "y": 0.75, "confidence": 0.92},
        {"name": "right_knee", "x": 0.56, "y": 0.75, "confidence": 0.93},
        {"name": "left_ankle", "x": 0.45, "y": 0.95, "confidence": 0.95},
        {"name": "right_ankle", "x": 0.55, "y": 0.95, "confidence": 0.96}
      ],
      "highlighted_keypoints": [11]  // left_ankle (index 11)
    },
    {
      "timestamp": 0.15,
      "keypoints": [ /* ... */ ]
    }
  ]
}
```

### Sampling Rate

**Recommendation:** Sample pose data every 3-5 frames (not every frame)

**Why:**
- Reduces JSON size (less bandwidth)
- Faster parsing on client
- Smoother UI (less re-rendering)
- Still captures movement accurately

**Example:**
- 30 FPS video
- Sample every 5 frames = 6 pose data points per second
- 10 second video = ~60 pose data points

## 🚀 Advanced Features

### 1. Highlight Keypoints Based on Feedback

Link feedback to specific body parts:

```json
{
  "timestamp": "0:14",
  "type": "negative",
  "feedback": "left foot should be rotated outward...",
  "highlighted_keypoints": ["left_ankle", "left_knee"]
}
```

Then map to indices when rendering:

```dart
final highlightIndices = feedback.highlightedKeypoints
    .map((name) => getKeypointIndex(name))
    .toList();
```

### 2. Pulsing Animation

Add animation to highlighted areas:

```dart
class _ResultsPageState extends State<ResultsPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  // Use in PoseOverlayPainter
  final pulseRadius = 25.0 + (_pulseController.value * 5.0);
}
```

### 3. Side-by-Side Comparison

Show correct form vs user's form:

```dart
Row(
  children: [
    Expanded(
      child: VideoPlayerWithPoseOverlay(
        videoPath: userVideo,
        poseDataList: userPoseData,
      ),
    ),
    Expanded(
      child: VideoPlayerWithPoseOverlay(
        videoPath: referenceVideo,
        poseDataList: referencePoseData,
      ),
    ),
  ],
)
```

### 4. Heat Maps

Show areas of frequent errors:

```dart
// Collect all highlighted keypoints across all feedback
final errorHeatMap = <String, int>{};
for (final feedback in feedbackItems) {
  for (final keypoint in feedback.highlightedKeypoints) {
    errorHeatMap[keypoint] = (errorHeatMap[keypoint] ?? 0) + 1;
  }
}

// Render with intensity based on frequency
```

## 🎯 Performance Tips

### 1. Limit Pose Data Points
- Don't send pose data for every frame
- Sample every 3-5 frames
- Client interpolates between frames

### 2. Filter Low Confidence Keypoints
```dart
final visibleKeypoints = keypoints.where((k) => k.confidence > 0.5);
```

### 3. Debounce Overlay Updates
```dart
Timer? _updateTimer;

void _updatePoseOverlay() {
  _updateTimer?.cancel();
  _updateTimer = Timer(Duration(milliseconds: 50), () {
    setState(() {
      _currentPoseData = findClosestPoseData();
    });
  });
}
```

### 4. Use RepaintBoundary
```dart
RepaintBoundary(
  child: CustomPaint(
    painter: PoseOverlayPainter(...),
  ),
)
```

## 📝 Example Complete Flow

```dart
// 1. User uploads video
await uploadController.upload();

// 2. Get analysis from backend
final response = await apiClient.getAnalysis(uploadId);
final result = AnalysisResult.fromJson(response);

// 3. Navigate to results
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ResultsPage(
      videoPath: uploadedVideoPath,
      feedbackItems: result.feedbackItems,
      poseDataList: result.poseData,
      onTimestampTap: (duration) {
        // Implemented in ResultsPage
      },
    ),
  ),
);
```

## 🐛 Troubleshooting

### Video won't play
- Check file path is correct
- Ensure video codec is supported (H.264 recommended)
- Verify file permissions on mobile

### Overlay not showing
- Check if `poseDataList` is not empty
- Verify coordinates are in correct range (0-1 or pixels)
- Check `videoSize` matches actual video dimensions

### Overlay misaligned
- Ensure coordinate system matches (normalized vs pixels)
- Verify aspect ratio calculation
- Check video rotation/orientation

### Performance issues
- Reduce pose data sampling rate
- Use `const` constructors where possible
- Wrap expensive widgets in `RepaintBoundary`

## 📚 Next Steps

1. ✅ Video player - **DONE**
2. ✅ Pose overlay system - **DONE**
3. 🔨 Update upload controller to keep video path
4. 🔨 Add API endpoint for fetching analysis
5. 🔨 Parse backend response to models
6. 🔨 Add navigation after upload success
7. 🔨 Test with real backend data
8. 🔨 Add loading states
9. 🔨 Add error handling
10. 🔨 Polish UI/UX

The hard part (video player + overlay rendering) is complete! The remaining work is mainly glue code and API integration.
