import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/video_feed_bloc.dart';
import '../../blocs/video_feed_event.dart';
import '../../blocs/video_feed_state.dart';
import '../widgets/cinematic_video_player.dart';

/// Video Feed Screen (FR1, FR4)
/// Implements full-screen vertical paging with snapping behavior
class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0, // Full screen
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<VideoFeedBloc, VideoFeedState>(
        builder: (context, state) {
          if (state is VideoFeedLoading || state is VideoFeedInitial) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          if (state is VideoFeedError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (state is VideoFeedReady) {
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const PageScrollPhysics(), // FR4: Snapping behavior
              itemCount: state.videos.length,
              onPageChanged: (index) {
                context.read<VideoFeedBloc>().add(ChangeVideoIndex(index));
              },
              itemBuilder: (context, index) {
                final video = state.videos[index];
                final playerId = state.playerIds[index];

                if (playerId == null) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                return CinematicVideoPlayer(
                  video: video,
                  playerId: playerId,
                  isPlaying: state.currentIndex == index && state.isPlaying,
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
