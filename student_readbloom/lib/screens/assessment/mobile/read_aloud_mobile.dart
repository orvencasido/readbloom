import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_models.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../preview_screen.dart';
import '../widgets/recording_widgets.dart';

class ReadAloudMobileBody extends StatelessWidget {
  const ReadAloudMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedStory = context.select<StudentProvider, Story?>(
      (prov) => prov.selectedStory,
    );
    final isStoppingRecording = context.select<StudentProvider, bool>(
      (prov) => prov.isStoppingRecording,
    );
    final cameraController = context.select<StudentProvider, CameraController?>(
      (prov) => prov.cameraController,
    );

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

    const double innerHeight = 124.0;
    final double innerWidth =
        (isPortrait && cameraAspect != null && cameraAspect < 1.0)
            ? (innerHeight * cameraAspect)
            : 204.0;
    final double outerWidth = innerWidth + 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        children: [
          // Camera Preview Box
          Container(
            width: outerWidth,
            height: 140,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ReadingCameraPreview(
                width: innerWidth,
                height: innerHeight,
                borderRadius: 16,
                fit: BoxFit.cover,
                placeholder: const Center(
                  child: Icon(Icons.face, color: Colors.black54, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tabs and Story Card
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabs Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF81AB8F),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Read Aloud',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF81AB8F),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Recording',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const RecordingTimerPill(),
                  ],
                ),
                const SizedBox(height: 8),
                // Story Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF81AB8F),
                        width: 3,
                      ),
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                selectedStory?.title.toUpperCase() ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedStory?.text ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black,
                                height: 1.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Buttons Row (Cancel + I'm Done)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel Button
              InkWell(
                onTap: () async {
                  final shouldCancel = await showAppConfirmDialog(
                    context,
                    title: 'Cancel Reading?',
                    message:
                        'Your current recording will be discarded and you will return to the dashboard.',
                    confirmLabel: 'Discard',
                    isDanger: true,
                  );
                  if (!shouldCancel || !context.mounted) return;
                  final navigator = Navigator.of(context);
                  await context
                      .read<StudentProvider>()
                      .cancelReadingRecording();
                  navigator.popUntil((route) => route.isFirst);
                },
                child: Container(
                  width: 130,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFD0D4DC),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFD0D4DC),
                        blurRadius: 0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.outfit(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // I'm Done Button
              InkWell(
                onTap: isStoppingRecording
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final error = await context
                            .read<StudentProvider>()
                            .stopReadingRecording();
                        if (error != null) {
                          if (!context.mounted) return;
                          await showAppMessageDialog(
                            context,
                            title: 'Recording Not Saved',
                            message: error,
                            isDanger: true,
                          );
                          return;
                        }
                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const PreviewScreen(),
                          ),
                        );
                      },
                child: Container(
                  width: 140,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C8DF6),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF2E5CB8),
                        blurRadius: 0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isStoppingRecording
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "I'm Done",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
