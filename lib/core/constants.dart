/// Cinescope Core Constants
/// Defines all application-level constants for performance and visual fidelity

class CinescopeConstants {
  // Performance Requirements
  static const int targetFrameRate = 60;
  static const int maxActivePlayerInstances = 3;

  // Supported Cinematic Aspect Ratios
  static const double aspectRatioWidescreen = 1.85; // 1.85:1
  static const double aspectRatioAnamorphic = 2.39; // 2.39:1 (Scope)
  static const double aspectRatioUnivisium = 2.00; // 2.00:1

  // Video Quality
  static const int maxVideoResolutionWidth = 3840; // 4K
  static const int maxVideoResolutionHeight = 2160;
  static const int maxVideoFrameRate = 60;

  // Letterbox Aesthetics
  static const int letterboxColorHex = 0xFF000000; // Pure black

  // Pre-fetching Configuration
  static const int prefetchOffset = 1; // Pre-load N+1 only

  // Orientation
  static const double landscapeAspectRatioThreshold = 1.2;

  // Platform Channel Names
  static const String videoPlayerChannel = 'com.cinescope/videoplayer';
  static const String orientationChannel = 'com.cinescope/orientation';

  // Video Codec Preferences
  static const String preferredCodec = 'hevc'; // H.265
  static const String fallbackCodec = 'h264'; // H.264
}
