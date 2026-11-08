import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_models.dart';
import '../../../providers/student_provider.dart';

class CongratsWebBody extends StatelessWidget {
  const CongratsWebBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final result = prov.lastQuizResult;
    final didLevelUp = result?.didLevelUp == true;
    final currentTier = result?.newTier ??
        getTierByNameOrTitle(
          prov.profile.level.isNotEmpty ? prov.profile.level : '',
        );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Image
            Image.asset(
              'lib/assets/website/logo-nobg.png',
              height: didLevelUp ? 150 : 180,
              width: didLevelUp ? 150 : 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Congratulations Bloomer',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              'CURIOSITY IS THE KEY TO DISCOVERING NEW THINGS.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.black87,
              ),
            ),
            if (didLevelUp) ...[
              const SizedBox(height: 24),
              Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFB300), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Color(0xFFFFB300), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'ACHIEVEMENT UNLOCKED!',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentTier.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F2E3A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Awesome! You passed with only ${result!.totalQuestions - result.score} mistake!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Current Rank: ${currentTier.displayName}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2E3A),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 36),
            InkWell(
              onTap: () {
                context.read<StudentProvider>().resetQuiz();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Container(
                width: 180,
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
          ],
        ),
      ),
    );
  }
}
