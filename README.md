# Cinescope - Cinematic Video Feed

High-fidelity mobile video streaming application optimized for cinematic aspect ratios on iOS.

## Architecture

### Core Technology Stack
- **Framework**: Flutter 3.x with Dart
- **State Management**: flutter_bloc (BLoC pattern)
- **Native Integration**: Platform Channels (Swift/AVPlayer)
- **Video Codec**: H.265 (HEVC) primary, H.264 fallback
- **Min iOS Version**: 16.0+

### System Design

```
┌─────────────────────────────────────────┐
│          Flutter UI Layer               │
│  ┌────────────────────────────────┐    │
│  │  OrientationGate               │    │
│  │  ├─ PortraitPromptScreen       │    │
│  │  └─ VideoFeedScreen            │    │
│  └────────────────────────────────┘    │
│                 ↓                       │
│  ┌────────────────────────────────┐    │
│  │  VideoFeedBloc (State Mgmt)    │    │
│  │  ├─ Pre-fetching Logic         │    │
│  │  ├─ Resource Disposal          │    │
│  │  └─ Player Lifecycle           │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│      Platform Channel Bridge            │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│       iOS Native Layer (Swift)          │
│  ┌────────────────────────────────┐    │
│  │  VideoPlayerPlugin             │    │
│  │  ├─ AVPlayer Management        │    │
│  │  ├─ Hardware Acceleration      │    │
│  │  └─ HEVC Codec Support         │    │
│  └────────────────────────────────┘    │
│  ┌────────────────────────────────┐    │
│  │  OrientationPlugin             │    │
│  │  └─ Landscape Lock Enforcement │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Implementation Details

### Performance Optimizations (60fps Target)

1. **Hardware Acceleration** (NFR3)
   - Exclusive use of AVPlayer with GPU decoding
   - `AVPlayerLayer.drawsAsynchronously = true`
   - Zero software fallback

2. **Intelligent Pre-fetching** (NFR4)
   - Pre-load N+1 video during N playback
   - Async asset initialization
   - Buffer ahead strategy

3. **Aggressive Resource Management** (NFR5)
   - Max 3 active player instances (N-1, N, N+1)
   - Immediate disposal on scroll
   - Memory pressure handling

### Cinematic Aspect Ratio Support (FR5, FR6)

Supported ratios:
- 1.85:1 (Widescreen)
- 2.39:1 (Anamorphic/Scope)
- 2.00:1 (Univisium)

Implementation:
```dart
AspectRatio(
  aspectRatio: video.aspectRatio,
  child: NativeVideoView(playerId: playerId),
)
```

Pure black (#000000) letterboxing maintains cinematic aesthetic.

### Vertical Paging with Snapping (FR4)

```dart
PageView.builder(
  scrollDirection: Axis.vertical,
  physics: PageScrollPhysics(), // Snapping behavior
  onPageChanged: (index) {
    // Trigger pre-fetch & disposal
  },
)
```

### Orientation Enforcement (FR2, FR3)

- Landscape-only mode enforced in `Info.plist`
- Runtime orientation lock via platform channel
- Portrait prompt animation when device rotated

## File Structure

```
cinescope/
├── lib/
│   ├── main.dart                    # Entry point & OrientationGate
│   ├── core/
│   │   └── constants.dart           # App-wide constants
│   ├── models/
│   │   └── video_item.dart          # Video data model
│   ├── services/
│   │   ├── native_video_player.dart # Platform channel interface
│   │   └── orientation_service.dart # Orientation management
│   ├── blocs/
│   │   ├── video_feed_bloc.dart     # State management
│   │   ├── video_feed_event.dart    # BLoC events
│   │   └── video_feed_state.dart    # BLoC states
│   └── ui/
│       ├── screens/
│       │   ├── video_feed_screen.dart       # Main feed
│       │   └── portrait_prompt_screen.dart  # Rotation prompt
│       └── widgets/
│           └── cinematic_video_player.dart  # Video player widget
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift                # App initialization
│   │   ├── VideoPlayerPlugin.swift          # AVPlayer plugin
│   │   ├── VideoPlayerViewFactory.swift     # Platform view factory
│   │   ├── OrientationPlugin.swift          # Orientation plugin
│   │   └── Info.plist                       # iOS configuration
│   └── Podfile                              # CocoaPods dependencies
├── pubspec.yaml                             # Flutter dependencies
└── CLAUDE.md                                # Requirements spec
```

## Build & Run

### Prerequisites
- Flutter SDK 3.0+
- Xcode 14+
- iOS 16+ device/simulator
- CocoaPods

### Steps

```bash
# Install Flutter dependencies
flutter pub get

# Navigate to iOS directory
cd ios

# Install CocoaPods
pod install

# Return to root
cd ..

# Run on iOS device
flutter run -d <device-id>
```

## Technical Decisions

### Why BLoC over Provider/Riverpod?
- Explicit event-driven architecture
- Better separation of business logic
- Easier to test state transitions
- Clear pre-fetch/disposal lifecycle

### Why Platform Channels over video_player plugin?
- Direct AVPlayer access for hardware control
- Custom HEVC preference implementation
- Fine-grained buffer management
- Zero middleware overhead

### Why Landscape-Only?
- Cinematic content optimized for horizontal viewing
- Prevents accidental orientation during viewing
- Enforces director's intended aspect ratio

## Performance Benchmarks

Target metrics:
- **Frame Rate**: Solid 60fps during scroll
- **Memory**: <500MB for 3 active players (4K content)
- **Buffer Time**: <100ms for N+1 pre-fetch
- **Transition**: <16ms snap animation

## Future Enhancements

- [ ] HDR support (Dolby Vision)
- [ ] Adaptive bitrate streaming (HLS)
- [ ] Advanced audio (Spatial Audio)
- [ ] Analytics integration
- [ ] Content recommendation engine

## License

See LICENSE file for details.
