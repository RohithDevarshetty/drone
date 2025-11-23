import 'package:equatable/equatable.dart';
import '../models/video_item.dart';

/// States for VideoFeedBloc
abstract class VideoFeedState extends Equatable {
  const VideoFeedState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VideoFeedInitial extends VideoFeedState {
  const VideoFeedInitial();
}

/// Loading state
class VideoFeedLoading extends VideoFeedState {
  const VideoFeedLoading();
}

/// Feed loaded and ready
class VideoFeedReady extends VideoFeedState {
  final List<VideoItem> videos;
  final int currentIndex;
  final Map<int, int> playerIds; // index -> playerId mapping
  final Set<int> preloadedIndices;
  final bool isPlaying;

  const VideoFeedReady({
    required this.videos,
    required this.currentIndex,
    required this.playerIds,
    required this.preloadedIndices,
    this.isPlaying = false,
  });

  @override
  List<Object?> get props => [videos, currentIndex, playerIds, preloadedIndices, isPlaying];

  VideoFeedReady copyWith({
    List<VideoItem>? videos,
    int? currentIndex,
    Map<int, int>? playerIds,
    Set<int>? preloadedIndices,
    bool? isPlaying,
  }) {
    return VideoFeedReady(
      videos: videos ?? this.videos,
      currentIndex: currentIndex ?? this.currentIndex,
      playerIds: playerIds ?? this.playerIds,
      preloadedIndices: preloadedIndices ?? this.preloadedIndices,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  /// Get current video
  VideoItem get currentVideo => videos[currentIndex];

  /// Get player ID for current video
  int? get currentPlayerId => playerIds[currentIndex];

  /// Check if index has active player
  bool hasPlayerAtIndex(int index) => playerIds.containsKey(index);

  /// Check if index is preloaded
  bool isPreloaded(int index) => preloadedIndices.contains(index);
}

/// Error state
class VideoFeedError extends VideoFeedState {
  final String message;

  const VideoFeedError(this.message);

  @override
  List<Object?> get props => [message];
}
