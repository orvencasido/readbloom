import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../read_aloud_screen.dart';
import '../widgets/recording_widgets.dart';

class CalibrationMobileBody extends StatelessWidget {
  final VoidCallback? onStart;
  final VoidCallback? onCancel;

  const CalibrationMobileBody({
    super.key,
    this.onStart,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final cameraController = prov.cameraController;

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final previewSize = cameraController?.value.previewSize;
    double? cameraAspect;
    if (cameraController != null &&
        cameraController.value.isInitialized &&
        previewSize != null &&
        previewSize.width > 0 &&
        previewSize.height > 0) {
      final pWidth = kIsWeb ? previewSize.width : previewSize.height;
      final pHeight = kIsWeb ? previewSize.height : previewSize.width;
      if (pHeight > 0) {
        cameraAspect = pWidth / pHeight;
      }
    }

    const double innerHeight = 196.0;
    final double innerWidth =
        (isPortrait && cameraAspect != null && cameraAspect < 1.0)
            ? (innerHeight * cameraAspect)
            : 296.0;
    final double outerWidth = innerWidth + 24.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera Preview Card
            Container(
              width: outerWidth,
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ReadingCameraPreview(
                  width: innerWidth,
                  height: innerHeight,
                  borderRadius: 20,
                  fit: BoxFit.cover,
                  placeholder: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          color: Colors.black54,
                          size: 50,
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
            const SizedBox(height: 24),

            // Mic levels Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic, color: Color(0xFF00D37F), size: 24),
                const SizedBox(width: 6),
                ...List.generate(10, (index) {
                  final isActive = index < (prov.micLevel * 10).toInt();
                  return Container(
                    width: 8,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF5C8DF6) // blue active
                          : const Color(0xFFB4F3BE), // light green inactive
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                const Icon(
                  Icons.play_arrow,
                  color: Color(0xFF00D37F),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // START Button (3D White Capsule)
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
                width: 180,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFD0D4DC),
                      blurRadius: 0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: prov.isCameraInitializing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'START',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
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
            Text(
              '5 minutes to read',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
