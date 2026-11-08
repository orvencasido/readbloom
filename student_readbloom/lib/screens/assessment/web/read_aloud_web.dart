import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_models.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../preview_screen.dart';
import '../widgets/recording_widgets.dart';

class ReadAloudWebBody extends StatelessWidget {
  const ReadAloudWebBody({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedStory = context.select<StudentProvider, Story?>(
      (prov) => prov.selectedStory,
    );
    final isStoppingRecording = context.select<StudentProvider, bool>(
      (prov) => prov.isStoppingRecording,
    );
    final isCompact = MediaQuery.of(context).size.width < 1100;

    final cameraSection = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                    Icon(Icons.face, color: Colors.black54, size: 60),
                    SizedBox(height: 8),
                    Text(
                      'Camera Active',
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
      ],
    );

    final tabsSection = Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF81AB8F), width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Read Aloud',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF81AB8F), width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'Recording',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const RecordingTimerPill(),
      ],
    );

    final storyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            selectedStory?.title.toUpperCase() ?? '',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          selectedStory?.text ?? '',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black,
            height: 1.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final buttonsSection = Row(
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
            await context.read<StudentProvider>().cancelReadingRecording();
            navigator.popUntil((route) => route.isFirst);
          },
          child: Container(
            width: 140,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFD0D4DC), width: 1.5),
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
        // "I'm Done" Button
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
            width: 160,
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
    );

    if (isCompact) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            cameraSection,
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  Align(alignment: Alignment.centerLeft, child: tabsSection),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 350,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFF81AB8F),
                        width: 3,
                      ),
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(child: storyContent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  buttonsSection,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cameraSection,
          const SizedBox(width: 48),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(alignment: Alignment.centerLeft, child: tabsSection),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0xFF81AB8F),
                          width: 3,
                        ),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(child: storyContent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  buttonsSection,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
