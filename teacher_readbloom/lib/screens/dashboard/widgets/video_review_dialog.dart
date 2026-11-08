import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class VideoReviewDialog extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int durationSeconds;

  const VideoReviewDialog({
    super.key,
    required this.videoUrl,
    required this.title,
    this.durationSeconds = 0,
  });

  @override
  State<VideoReviewDialog> createState() => _VideoReviewDialogState();
}

class _VideoReviewDialogState extends State<VideoReviewDialog> {
  late VideoPlayerController _controller;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _hasVideoError = false;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.addListener(_handleVideoTick);
    _controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((_) {
          if (mounted) setState(() => _hasVideoError = true);
        });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoTick);
    _controller.dispose();
    super.dispose();
  }

  void _handleVideoTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: const Color(0xFF111827),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: screenSize.height * 0.84,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _VideoFrame(
                  controller: _controller,
                  hasVideoError: _hasVideoError,
                  onRetry: () {
                    _controller.removeListener(_handleVideoTick);
                    _controller.dispose();
                    setState(() => _initializeVideo());
                  },
                ),
              ),
              const SizedBox(height: 12),
              _VideoControls(
                controller: _controller,
                durationSeconds: widget.durationSeconds,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoFrame extends StatelessWidget {
  final VideoPlayerController controller;
  final bool hasVideoError;
  final VoidCallback onRetry;

  const _VideoFrame({
    required this.controller,
    required this.hasVideoError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = controller.value.isInitialized
            ? controller.value.aspectRatio
            : 16 / 9;
        final safeAspectRatio = aspectRatio <= 0 ? 16 / 9 : aspectRatio;
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final widthFromHeight = maxHeight * safeAspectRatio;
        final videoWidth = widthFromHeight > maxWidth
            ? maxWidth
            : widthFromHeight;
        final videoHeight = videoWidth / safeAspectRatio;

        return Center(
          child: SizedBox(
            width: videoWidth,
            height: videoHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: controller.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: VideoPlayer(controller),
                    )
                  : hasVideoError
                  ? _VideoError(onRetry: onRetry)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      },
    );
  }
}

class _VideoError extends StatelessWidget {
  final VoidCallback onRetry;

  const _VideoError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 36),
            const SizedBox(height: 10),
            Text(
              'Unable to load this reading video.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final int durationSeconds;

  const _VideoControls({
    required this.controller,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final isReady = value.isInitialized;
    final duration = _effectiveDuration(value, durationSeconds);
    final maxSeconds = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds / 1000;
    final currentPosition = value.position > duration
        ? duration
        : value.position;
    final currentSeconds = currentPosition.inMilliseconds <= 0
        ? 0.0
        : (currentPosition.inMilliseconds / 1000).clamp(0.0, maxSeconds);

    return Row(
      children: [
        IconButton.filled(
          onPressed: !isReady
              ? null
              : () {
                  value.isPlaying ? controller.pause() : controller.play();
                },
          icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(currentPosition),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: const Color(0xFF60A5FA),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              min: 0,
              max: maxSeconds,
              value: currentSeconds,
              onChanged: !isReady
                  ? null
                  : (seconds) {
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
    );
  }

  Duration _effectiveDuration(VideoPlayerValue value, int durationSeconds) {
    var effective = Duration(seconds: durationSeconds);
    if (value.duration > effective) effective = value.duration;
    if (value.position > effective) effective = value.position;
    for (final range in value.buffered) {
      if (range.end > effective) effective = range.end;
    }
    return effective;
  }

  String _formatDuration(Duration duration) {
    final safeSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
