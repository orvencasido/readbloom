import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoController(String path) {
  return VideoPlayerController.networkUrl(Uri.parse(path));
}
