import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/loading_dialog.dart';

class PrivacyMobileBody extends StatelessWidget {
  const PrivacyMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/main-bg-2.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green Shield with Blue Checkmark
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shield,
                      size: 75,
                      color: Color(0xFF4CAF50),
                    ),
                    Positioned(
                      top: 20,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 24,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Safety & Privacy Agreement',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: const Color(0xFF0F2E3A),
                  ),
                ),
                const SizedBox(height: 12),

                // Description Subtitle
                Text(
                  'To help our teachers monitor progress\nand pronunciation, BloomStu uses\nthe camera and microphone during\nlearning sessions.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F2E3A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Content card (Glassmorphic)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPrivacyBullet(
                        title: 'Engagement Monitoring: ',
                        desc:
                            'The camera helps teachers see if students are focused during reading activities.',
                        icon: Icons.videocam,
                        iconColor: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 20),
                      _buildPrivacyBullet(
                        title: 'Oral Reading: ',
                        desc:
                            'The microphone is used to assess pronunciation and reading speed during assessments.',
                        icon: Icons.mic,
                        iconColor: Colors.red.shade600,
                      ),
                      const SizedBox(height: 20),
                      _buildPrivacyBullet(
                        title: 'Secure Storage: ',
                        desc:
                            'Recordings are processed privately and are only viewable by assigned teachers for academic support.',
                        icon: Icons.lock,
                        iconColor: Colors.green.shade600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 155,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await runWithLoadingDialog(
                              context,
                              () => context
                                  .read<StudentProvider>()
                                  .acceptPrivacy(),
                              message: 'Saving agreement...',
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            await showAppMessageDialog(
                              context,
                              title: 'Agreement Not Saved',
                              message:
                                  'Unable to save agreement right now. Please try again.',
                              isDanger: true,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D37F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text("I Agree, Let's Bloom!"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 155,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<StudentProvider>().logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6D7E2),
                          foregroundColor: const Color(0xFF1C1D24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text("No thanks, Keep off"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'PARENTAL CONSENT REQUIRED',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyBullet({
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF0F2E3A),
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: desc,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
