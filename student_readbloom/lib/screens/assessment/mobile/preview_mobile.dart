import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../read_aloud_screen.dart';
import '../uploading_screen.dart';
import '../widgets/recording_widgets.dart';

class PreviewMobileBody extends StatelessWidget {
  const PreviewMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title Capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Preview your Video',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Video Preview Card
            Container(
              width: 320,
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
                child: const RecordedVideoPreview(
                  width: 296,
                  height: 196,
                  borderRadius: 20,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Start Over Button (Blue 3D Capsule)
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
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      mainAxisSize: MainAxisSize.min,
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
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // I'm Done Button (Green 3D Capsule)
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
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D37F),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF009C5E),
                          blurRadius: 0,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                            fontSize: 15,
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
