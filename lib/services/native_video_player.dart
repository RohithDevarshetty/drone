import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Native iOS video player service using AVPlayer via platform channels
/// Provides hardware-accelerated playback with precise lifecycle control
class NativeVideoPlayer {
  final MethodChannel _channel = const MethodChannel(CinescopeConstants.videoPlayerChannel);
  final int playerId;

  NativeVideoPlayer(this.playerId);

  /// Initialize player with video URL
  /// Returns video metadata including aspect ratio
  Future<Map<String, dynamic>> initialize(String url) async {
    try {
      final result = await _channel.invokeMethod('initialize', {
        'playerId': playerId,
        'url': url,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw VideoPlayerException('Failed to initialize: ${e.message}');
    }
  }

  /// Start playback
  Future<void> play() async {
    try {
      await _channel.invokeMethod('play', {'playerId': playerId});
    } on PlatformException catch (e) {
      throw VideoPlayerException('Failed to play: ${e.message}');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause', {'playerId': playerId});
    } on PlatformException catch (e) {
      throw VideoPlayerException('Failed to pause: ${e.message}');
    }
  }

  /// Dispose player and release hardware resources
  /// Critical for memory management per NFR5
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose', {'playerId': playerId});
    } on PlatformException catch (e) {
      throw VideoPlayerException('Failed to dispose: ${e.message}');
    }
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    try {
      await _channel.invokeMethod('seekTo', {
        'playerId': playerId,
        'position': position.inMilliseconds,
      });
    } on PlatformException catch (e) {
      throw VideoPlayerException('Failed to seek: ${e.message}');
    }
  }

  /// Set playback volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {
        'playerId': playerId,
        'volume': volume.clamp(0.0, 1.0),
      });
    } on PlatformException catch (e) {
      throw VideoPlayerException('Failed to set volume: ${e.message}');
    }
  }

  /// Get current playback position
  Future<Duration> getPosition() async {
    try {
      final int milliseconds = await _channel.invokeMethod('getPosition', {
        'playerId': playerId,
      });
      return Duration(milliseconds: milliseconds);
    } on PlatformException catch (e) {
      throw VideoPlayerException('Failed to get position: ${e.message}');
    }
  }

  /// Pre-load video for seamless transition (NFR4)
  Future<void> preload(String url) async {
    try {
      await _channel.invokeMethod('preload', {
        'playerId': playerId,
        'url': url,
      });
    } on PlatformException catch (e) {
      throw VideoPlayerException('Failed to preload: ${e.message}');
    }
  }

  /// Stream of playback events
  Stream<VideoPlayerEvent> get eventStream {
    return EventChannel('${CinescopeConstants.videoPlayerChannel}/events/$playerId')
        .receiveBroadcastStream()
        .map((event) => VideoPlayerEvent.fromMap(Map<String, dynamic>.from(event)));
  }
}

/// Video player event types
class VideoPlayerEvent {
  final VideoPlayerEventType type;
  final Map<String, dynamic> data;

  VideoPlayerEvent(this.type, this.data);

  factory VideoPlayerEvent.fromMap(Map<String, dynamic> map) {
    final type = VideoPlayerEventType.values.firstWhere(
      (e) => e.toString() == 'VideoPlayerEventType.${map['type']}',
      orElse: () => VideoPlayerEventType.unknown,
    );
    return VideoPlayerEvent(type, map);
  }
}

enum VideoPlayerEventType {
  initialized,
  playing,
  paused,
  buffering,
  ended,
  error,
  unknown,
}

class VideoPlayerException implements Exception {
  final String message;
  VideoPlayerException(this.message);

  @override
  String toString() => 'VideoPlayerException: $message';
}
