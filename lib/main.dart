import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/video_feed_bloc.dart';
import 'blocs/video_feed_event.dart';
import 'models/video_item.dart';
import 'services/orientation_service.dart';
import 'ui/screens/portrait_prompt_screen.dart';
import 'ui/screens/video_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientation (FR2)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI for immersive experience
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const CinescopeApp());
}

class CinescopeApp extends StatelessWidget {
  const CinescopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinescope',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (context) => VideoFeedBloc()
          ..add(LoadVideoFeed(_getMockVideos())),
        child: const OrientationGate(),
      ),
    );
  }

  /// Mock video data for testing
  /// In production, this would be fetched from API
  List<VideoItem> _getMockVideos() {
    return [
      VideoItem.mock(
        id: '1',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        aspectRatio: 2.39, // Anamorphic
      ),
      VideoItem.mock(
        id: '2',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        aspectRatio: 1.85, // Widescreen
      ),
      VideoItem.mock(
        id: '3',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        aspectRatio: 2.00, // Univisium
      ),
    ];
  }
}

/// Orientation Gate
/// Implements FR3: Shows portrait prompt or video feed based on orientation
class OrientationGate extends StatefulWidget {
  const OrientationGate({super.key});

  @override
  State<OrientationGate> createState() => _OrientationGateState();
}

class _OrientationGateState extends State<OrientationGate> {
  final OrientationService _orientationService = OrientationService();
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _checkOrientation();
    _orientationService.startMonitoring();
    _orientationService.orientationStream.listen(_handleOrientationChange);
  }

  @override
  void dispose() {
    _orientationService.stopMonitoring();
    super.dispose();
  }

  Future<void> _checkOrientation() async {
    final isLandscape = await _orientationService.isLandscape();
    if (mounted) {
      setState(() {
        _isLandscape = isLandscape;
      });
    }
  }

  void _handleOrientationChange(DeviceOrientation orientation) {
    final isLandscape = orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;

    if (mounted && _isLandscape != isLandscape) {
      setState(() {
        _isLandscape = isLandscape;
      });

      // Pause video when switching to portrait
      if (!isLandscape) {
        context.read<VideoFeedBloc>().add(const PauseCurrentVideo());
      } else {
        // Resume playback when returning to landscape
        context.read<VideoFeedBloc>().add(const PlayCurrentVideo());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery as fallback orientation detection
    final mediaQuery = MediaQuery.of(context);
    final screenIsLandscape = mediaQuery.size.width > mediaQuery.size.height;

    // Show video feed only in landscape
    if (_isLandscape || screenIsLandscape) {
      return const VideoFeedScreen();
    }

    // Show portrait prompt in portrait mode
    return const PortraitPromptScreen();
  }
}
