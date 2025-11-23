import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants.dart';
import '../models/video_item.dart';
import '../services/native_video_player.dart';
import 'video_feed_event.dart';
import 'video_feed_state.dart';

/// Video Feed BLoC
/// Implements intelligent pre-fetching (NFR4) and resource disposal (NFR5)
/// Maintains max 3 active player instances at any time
class VideoFeedBloc extends Bloc<VideoFeedEvent, VideoFeedState> {
  final Map<int, NativeVideoPlayer> _players = {};
  int _nextPlayerId = 0;

  VideoFeedBloc() : super(const VideoFeedInitial()) {
    on<LoadVideoFeed>(_onLoadVideoFeed);
    on<ChangeVideoIndex>(_onChangeVideoIndex);
    on<PlayCurrentVideo>(_onPlayCurrentVideo);
    on<PauseCurrentVideo>(_onPauseCurrentVideo);
    on<DisposeVideoFeed>(_onDisposeVideoFeed);
  }

  /// Load video feed and initialize first player
  Future<void> _onLoadVideoFeed(
    LoadVideoFeed event,
    Emitter<VideoFeedState> emit,
  ) async {
    emit(const VideoFeedLoading());

    try {
      if (event.videos.isEmpty) {
        emit(const VideoFeedError('No videos to display'));
        return;
      }

      // Initialize first video player
      final firstPlayerId = _createPlayer(0);
      await _players[firstPlayerId]!.initialize(event.videos[0].url);

      // Preload next video (NFR4)
      if (event.videos.length > 1) {
        await _preloadNextVideo(event.videos, 0);
      }

      emit(VideoFeedReady(
        videos: event.videos,
        currentIndex: 0,
        playerIds: {0: firstPlayerId},
        preloadedIndices: event.videos.length > 1 ? {1} : {},
        isPlaying: false,
      ));
    } catch (e) {
      emit(VideoFeedError('Failed to load video feed: $e'));
    }
  }

  /// Handle video index change with pre-fetching and disposal
  Future<void> _onChangeVideoIndex(
    ChangeVideoIndex event,
    Emitter<VideoFeedState> emit,
  ) async {
    if (state is! VideoFeedReady) return;

    final currentState = state as VideoFeedReady;
    final newIndex = event.index;

    // Validate index
    if (newIndex < 0 || newIndex >= currentState.videos.length) {
      return;
    }

    // Pause current video
    if (currentState.currentPlayerId != null) {
      await _players[currentState.currentPlayerId]!.pause();
    }

    // Dispose old players (NFR5: Resource Disposal)
    await _disposeOldPlayers(newIndex, currentState);

    // Ensure player exists for new index
    if (!currentState.hasPlayerAtIndex(newIndex)) {
      final playerId = _createPlayer(newIndex);
      await _players[playerId]!.initialize(currentState.videos[newIndex].url);
      currentState.playerIds[newIndex] = playerId;
    }

    // Preload next video (NFR4)
    await _preloadNextVideo(currentState.videos, newIndex);

    emit(currentState.copyWith(
      currentIndex: newIndex,
      isPlaying: false,
    ));

    // Auto-play new video
    add(const PlayCurrentVideo());
  }

  /// Play current video
  Future<void> _onPlayCurrentVideo(
    PlayCurrentVideo event,
    Emitter<VideoFeedState> emit,
  ) async {
    if (state is! VideoFeedReady) return;

    final currentState = state as VideoFeedReady;
    if (currentState.currentPlayerId == null) return;

    try {
      await _players[currentState.currentPlayerId]!.play();
      emit(currentState.copyWith(isPlaying: true));
    } catch (e) {
      emit(VideoFeedError('Failed to play video: $e'));
    }
  }

  /// Pause current video
  Future<void> _onPauseCurrentVideo(
    PauseCurrentVideo event,
    Emitter<VideoFeedState> emit,
  ) async {
    if (state is! VideoFeedReady) return;

    final currentState = state as VideoFeedReady;
    if (currentState.currentPlayerId == null) return;

    try {
      await _players[currentState.currentPlayerId]!.pause();
      emit(currentState.copyWith(isPlaying: false));
    } catch (e) {
      emit(VideoFeedError('Failed to pause video: $e'));
    }
  }

  /// Dispose all resources
  Future<void> _onDisposeVideoFeed(
    DisposeVideoFeed event,
    Emitter<VideoFeedState> emit,
  ) async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    emit(const VideoFeedInitial());
  }

  /// Create new player instance
  int _createPlayer(int index) {
    final playerId = _nextPlayerId++;
    _players[playerId] = NativeVideoPlayer(playerId);
    return playerId;
  }

  /// Preload next video for seamless transition (NFR4)
  Future<void> _preloadNextVideo(List<VideoItem> videos, int currentIndex) async {
    final nextIndex = currentIndex + CinescopeConstants.prefetchOffset;
    if (nextIndex >= videos.length) return;

    // Create player for next video if doesn't exist
    if (!_players.values.any((p) => p.playerId == nextIndex)) {
      final playerId = _createPlayer(nextIndex);
      await _players[playerId]!.preload(videos[nextIndex].url);
    }
  }

  /// Dispose players outside the active window (NFR5)
  /// Keep only: previous, current, next
  Future<void> _disposeOldPlayers(int newIndex, VideoFeedReady currentState) async {
    final keepIndices = {
      if (newIndex > 0) newIndex - 1, // Previous
      newIndex, // Current
      if (newIndex < currentState.videos.length - 1) newIndex + 1, // Next
    };

    final playerIdsToDispose = <int>[];

    currentState.playerIds.forEach((index, playerId) {
      if (!keepIndices.contains(index)) {
        playerIdsToDispose.add(playerId);
      }
    });

    // Dispose old players
    for (final playerId in playerIdsToDispose) {
      await _players[playerId]?.dispose();
      _players.remove(playerId);
      currentState.playerIds.removeWhere((_, id) => id == playerId);
    }
  }

  @override
  Future<void> close() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    return super.close();
  }
}
