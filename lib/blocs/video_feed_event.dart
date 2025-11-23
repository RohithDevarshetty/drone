import 'package:equatable/equatable.dart';
import '../models/video_item.dart';

/// Events for VideoFeedBloc
abstract class VideoFeedEvent extends Equatable {
  const VideoFeedEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize feed with video list
class LoadVideoFeed extends VideoFeedEvent {
  final List<VideoItem> videos;

  const LoadVideoFeed(this.videos);

  @override
  List<Object?> get props => [videos];
}

/// User scrolled to a new video index
class ChangeVideoIndex extends VideoFeedEvent {
  final int index;

  const ChangeVideoIndex(this.index);

  @override
  List<Object?> get props => [index];
}

/// Play current video
class PlayCurrentVideo extends VideoFeedEvent {
  const PlayCurrentVideo();
}

/// Pause current video
class PauseCurrentVideo extends VideoFeedEvent {
  const PauseCurrentVideo();
}

/// Video playback event received
class VideoPlaybackEvent extends VideoFeedEvent {
  final int playerId;
  final String eventType;
  final Map<String, dynamic> data;

  const VideoPlaybackEvent(this.playerId, this.eventType, this.data);

  @override
  List<Object?> get props => [playerId, eventType, data];
}

/// Dispose all resources
class DisposeVideoFeed extends VideoFeedEvent {
  const DisposeVideoFeed();
}
