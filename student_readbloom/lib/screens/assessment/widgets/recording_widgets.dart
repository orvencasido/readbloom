import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../providers/student_provider.dart';
import 'video_player_controller_factory.dart';

class ReadingCameraPreview extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Widget placeholder;
  final BoxFit fit;

  const ReadingCameraPreview({
    super.key,
    this.width,
    required this.height,
    required this.borderRadius,
    required this.placeholder,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isCameraInitializing = context.select<StudentProvider, bool>(
      (prov) => prov.isCameraInitializing,
    );
    final controller = context.select<StudentProvider, CameraController?>(
      (prov) => prov.cameraController,
    );

    if (isCameraInitializing) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(width: width, height: height, child: placeholder);
    }

    final previewSize = controller.value.previewSize;
    final previewWidth = kIsWeb
        ? previewSize?.width ?? (width ?? 200)
        : previewSize?.height ?? (width ?? 200);
    final previewHeight = kIsWeb
        ? previewSize?.height ?? height
        : previewSize?.width ?? height;

    final double effectiveAspect = (previewHeight > 0)
        ? (previewWidth / previewHeight)
        : 1.0;
    final double effectiveWidth = width ?? (height * effectiveAspect);

    return SizedBox(
      width: effectiveWidth,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: const Color(0xFFF2F4F7),
          child: Center(
            child: FittedBox(
              fit: fit,
              child: SizedBox(
                width: previewWidth,
                height: previewHeight,
                child: CameraPreview(
                  controller,
                  key: ValueKey('camera_preview_${controller.cameraId}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RecordingTimerPill extends StatelessWidget {
  const RecordingTimerPill({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final elapsed = _formatDuration(prov.recordingElapsedSeconds);
    final remaining = prov.recordingRemainingSeconds <= 0
        ? '00:00'
        : _formatDuration(prov.recordingRemainingSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: prov.isRecordingOvertime
            ? const Color(0xFFFFE3E0)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: prov.isRecordingOvertime
              ? const Color(0xFFD62A24)
              : const Color(0xFF81AB8F),
          width: 2,
        ),
      ),
      child: Text(
        prov.isRecordingOvertime ? 'Overtime $elapsed' : '$remaining left',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: prov.isRecordingOvertime
              ? const Color(0xFFD62A24)
              : Colors.black,
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class RecordedVideoPreview extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const RecordedVideoPreview({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<RecordedVideoPreview> createState() => _RecordedVideoPreviewState();
}

class _RecordedVideoPreviewState extends State<RecordedVideoPreview> {
  VideoPlayerController? _controller;
  String? _videoPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final video = context.watch<StudentProvider>().recordedVideo;
    final path = video?.path;
    if (path == _videoPath) return;
    _videoPath = path;
    _controller?.removeListener(_handleVideoTick);
    _controller?.dispose();
    _controller = null;
    if (path == null || path.isEmpty) return;

    final controller = createRecordedVideoController(path);
    _controller = controller;
    controller.addListener(_handleVideoTick);
    controller.initialize().then((_) {
      if (!mounted) return;
      controller.setLooping(true);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  void _handleVideoTick() {
    if (mounted) setState(() {});
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return _placeholder('No video recorded yet');
    }
    if (!controller.value.isInitialized) {
      return _placeholder('Loading video...');
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlayback,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              Center(
                child: IgnorePointer(
                  ignoring: controller.value.isPlaying,
                  child: AnimatedOpacity(
                    opacity: controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: IconButton.filled(
                      iconSize: 42,
                      onPressed: _togglePlayback,
                      icon: const Icon(Icons.play_arrow),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 8,
                child: _VideoTimeline(controller: controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String label) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _VideoTimeline extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoTimeline({required this.controller});

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration;
    final position = value.position > duration ? duration : value.position;
    final maxSeconds = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds / 1000;
    final currentSeconds = position.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / 1000).clamp(0.0, maxSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            _formatDuration(position),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: const Color(0xFF00D37F),
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
              ),
              child: Slider(
                min: 0,
                max: maxSeconds,
                value: currentSeconds,
                onChanged: (seconds) {
                  controller.seekTo(
                    Duration(milliseconds: (seconds * 1000).round()),
                  );
                },
              ),
            ),
          ),
          Text(
            _formatDuration(duration),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
