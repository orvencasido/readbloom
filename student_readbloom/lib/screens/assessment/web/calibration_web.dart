import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../read_aloud_screen.dart';
import '../widgets/recording_widgets.dart';

class CalibrationWebBody extends StatelessWidget {
  final VoidCallback? onStart;
  final VoidCallback? onCancel;

  const CalibrationWebBody({
    super.key,
    this.onStart,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final isCompact = MediaQuery.of(context).size.width < 1100;

    final cameraSection = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Camera Preview Card
        Container(
          width: 380,
          height: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const ReadingCameraPreview(
              width: 356,
              height: 226,
              borderRadius: 22,
              placeholder: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_outlined,
                      color: Colors.black54,
                      size: 60,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Camera Ready',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Mic levels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, color: Color(0xFF00D37F), size: 28),
            const SizedBox(width: 8),
            ...List.generate(10, (index) {
              final isActive = index < (prov.micLevel * 10).toInt();
              return Container(
                width: 10,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF5C8DF6) // blue active
                      : const Color(0xFFB4F3BE), // light green inactive
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ],
        ),
      ],
    );

    final startSection = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: prov.isCameraInitializing
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  final error = await context
                      .read<StudentProvider>()
                      .prepareRecordingSession();
                  if (error != null) {
                    if (!context.mounted) return;
                    await showAppMessageDialog(
                      context,
                      title: 'Camera Not Ready',
                      message: error,
                      isDanger: true,
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  onStart?.call();
                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const ReadAloudScreen(),
                    ),
                  );
                },
          child: Container(
            width: 200,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD0D4DC),
                  blurRadius: 0,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                prov.isCameraInitializing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.play_arrow,
                        color: Color(0xFF00D37F),
                        size: 36,
                      ),
                const SizedBox(width: 6),
                Text(
                  'START',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Cancel / Back Button
        InkWell(
          onTap: () async {
            if (onCancel != null) {
              onCancel!();
              return;
            }
            final navigator = Navigator.of(context);
            await context.read<StudentProvider>().disposeCamera();
            if (context.mounted) {
              navigator.popUntil((route) => route.isFirst);
            }
          },
          child: Container(
            width: 140,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD0D4DC), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD0D4DC),
                  blurRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
            children: const [
              TextSpan(
                text: '5 minutes ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: 'to read'),
            ],
          ),
        ),
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: isCompact
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  cameraSection,
                  const SizedBox(height: 40),
                  startSection,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  cameraSection,
                  const SizedBox(width: 48),
                  startSection,
                ],
              ),
      ),
    );
  }
}
