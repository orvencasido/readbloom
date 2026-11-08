import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_models.dart';
import '../../../providers/student_provider.dart';

class CongratsMobileBody extends StatelessWidget {
  const CongratsMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final result = prov.lastQuizResult;
    final didLevelUp = result?.didLevelUp == true;
    final currentTier = result?.newTier ??
        getTierByNameOrTitle(
          prov.profile.level.isNotEmpty ? prov.profile.level : '',
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            const Spacer(),
            // Logo Image
            Image.asset(
              'lib/assets/website/logo-nobg.png',
              height: didLevelUp ? 130 : 160,
              width: didLevelUp ? 130 : 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Congratulations Bloomer',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(-1.5, -1.5),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1.5, -1.5),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: Colors.black,
                    offset: Offset(-1.5, 1.5),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: Colors.black38,
                    offset: Offset(0, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'CURIOSITY IS THE KEY TO DISCOVERING NEW THINGS.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.black,
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),

            if (didLevelUp) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFB300), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Color(0xFFFFB300), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'ACHIEVEMENT UNLOCKED!',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentTier.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F2E3A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Awesome! You passed with only ${result!.totalQuestions - result.score} mistake!',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Current Rank: ${currentTier.displayName}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2E3A),
                  ),
                ),
              ),
            ],

            const Spacer(),

            InkWell(
              onTap: () {
                context.read<StudentProvider>().resetQuiz();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Container(
                width: double.infinity,
                height: 52,
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
                alignment: Alignment.center,
                child: Text(
                  'Done',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
