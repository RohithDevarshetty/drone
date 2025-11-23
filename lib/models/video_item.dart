import 'package:equatable/equatable.dart';

/// Represents a single video item in the cinematic feed
class VideoItem extends Equatable {
  final String id;
  final String url;
  final double aspectRatio;
  final int width;
  final int height;
  final Duration duration;
  final String codec;

  const VideoItem({
    required this.id,
    required this.url,
    required this.aspectRatio,
    required this.width,
    required this.height,
    required this.duration,
    required this.codec,
  });

  @override
  List<Object?> get props => [id, url, aspectRatio, width, height, duration, codec];

  /// Returns true if this video uses a cinematic aspect ratio
  bool get isCinematic {
    return aspectRatio >= 1.85 && aspectRatio <= 2.40;
  }

  /// Factory constructor for test/mock data
  factory VideoItem.mock({
    String? id,
    String? url,
    double aspectRatio = 2.39,
  }) {
    return VideoItem(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      url: url ?? 'https://example.com/video.mp4',
      aspectRatio: aspectRatio,
      width: 3840,
      height: (3840 / aspectRatio).round(),
      duration: const Duration(seconds: 60),
      codec: 'hevc',
    );
  }
}
