import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/video_item.dart';

/// Cinematic Video Player Widget
/// Implements FR5 (Dynamic Aspect Ratio Support) and FR6 (Letterboxing)
class CinematicVideoPlayer extends StatelessWidget {
  final VideoItem video;
  final int playerId;
  final bool isPlaying;

  const CinematicVideoPlayer({
    super.key,
    required this.video,
    required this.playerId,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(CinescopeConstants.letterboxColorHex),
      child: Center(
        child: AspectRatio(
          aspectRatio: video.aspectRatio,
          child: _NativeVideoView(
            playerId: playerId,
            isPlaying: isPlaying,
          ),
        ),
      ),
    );
  }
}

/// Native video view using platform view
/// This will be implemented in iOS using AVPlayerLayer
class _NativeVideoView extends StatelessWidget {
  final int playerId;
  final bool isPlaying;

  const _NativeVideoView({
    required this.playerId,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    // Platform view for iOS AVPlayer
    // The actual implementation connects to Swift AVPlayerViewController
    return UiKitView(
      viewType: 'com.cinescope/videoplayer/view',
      creationParams: {
        'playerId': playerId,
        'isPlaying': isPlaying,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
