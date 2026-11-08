import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../read_aloud_screen.dart';
import '../uploading_screen.dart';
import '../widgets/recording_widgets.dart';

class PreviewWebBody extends StatelessWidget {
  const PreviewWebBody({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final previewWidth = screenWidth >= 1200 ? 640.0 : 560.0;
    final previewHeight = previewWidth * 0.64;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title Capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Preview your Video',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Video box (matches calibration camera box)
            Container(
              width: previewWidth,
              height: previewHeight,
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
                child: RecordedVideoPreview(
                  width: previewWidth - 24,
                  height: previewHeight - 24,
                  borderRadius: 22,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Start Over Button
                InkWell(
                  onTap: () async {
                    final shouldStartOver = await showAppConfirmDialog(
                      context,
                      title: 'Start Over?',
                      message: 'Your current recorded video will be discarded.',
                      confirmLabel: 'Discard',
                      isDanger: true,
                    );
                    if (!shouldStartOver || !context.mounted) return;
                    final navigator = Navigator.of(context);
                    await context
                        .read<StudentProvider>()
                        .discardRecordedVideo();
                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const ReadAloudScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 170,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Start Over',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // I'm Done Button
                InkWell(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await context
                        .read<StudentProvider>()
                        .finishPreviewForUpload();
                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const UploadingScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 170,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D37F),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF0E9384),
                          blurRadius: 0,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "I'm Done",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
