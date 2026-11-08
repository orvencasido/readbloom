import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoController(String path) {
  return VideoPlayerController.file(File(path));
}
