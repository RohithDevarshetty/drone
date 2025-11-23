import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Orientation management service for enforcing landscape-only mode
/// Implements FR2 (Orientation Lock) and FR3 (Portrait Prompt)
class OrientationService {
  static final OrientationService _instance = OrientationService._internal();
  factory OrientationService() => _instance;
  OrientationService._internal();

  final MethodChannel _channel = const MethodChannel(CinescopeConstants.orientationChannel);
  final StreamController<DeviceOrientation> _orientationController =
      StreamController<DeviceOrientation>.broadcast();

  Stream<DeviceOrientation> get orientationStream => _orientationController.stream;

  /// Lock orientation to landscape modes only
  Future<void> lockLandscape() async {
    try {
      await _channel.invokeMethod('lockLandscape');
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } on PlatformException catch (e) {
      throw OrientationException('Failed to lock landscape: ${e.message}');
    }
  }

  /// Unlock orientation (for testing/debugging only)
  Future<void> unlockOrientation() async {
    try {
      await _channel.invokeMethod('unlockOrientation');
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } on PlatformException catch (e) {
      throw OrientationException('Failed to unlock orientation: ${e.message}');
    }
  }

  /// Get current device orientation
  Future<DeviceOrientation> getCurrentOrientation() async {
    try {
      final String orientation = await _channel.invokeMethod('getCurrentOrientation');
      return _parseOrientation(orientation);
    } on PlatformException catch (e) {
      throw OrientationException('Failed to get orientation: ${e.message}');
    }
  }

  /// Check if device is currently in landscape mode
  Future<bool> isLandscape() async {
    final orientation = await getCurrentOrientation();
    return orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
  }

  /// Initialize orientation monitoring
  void startMonitoring() {
    EventChannel('${CinescopeConstants.orientationChannel}/events')
        .receiveBroadcastStream()
        .listen((event) {
      final orientation = _parseOrientation(event.toString());
      _orientationController.add(orientation);
    });
  }

  /// Stop orientation monitoring
  void stopMonitoring() {
    _orientationController.close();
  }

  DeviceOrientation _parseOrientation(String orientationString) {
    switch (orientationString.toLowerCase()) {
      case 'landscapeleft':
        return DeviceOrientation.landscapeLeft;
      case 'landscaperight':
        return DeviceOrientation.landscapeRight;
      case 'portraitup':
        return DeviceOrientation.portraitUp;
      case 'portraitdown':
        return DeviceOrientation.portraitDown;
      default:
        return DeviceOrientation.portraitUp;
    }
  }
}

enum DeviceOrientation {
  portraitUp,
  portraitDown,
  landscapeLeft,
  landscapeRight,
}

class OrientationException implements Exception {
  final String message;
  OrientationException(this.message);

  @override
  String toString() => 'OrientationException: $message';
}
