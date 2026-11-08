import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/loading_dialog.dart';
import '../congrats_screen.dart';

class QuizMobileBody extends StatefulWidget {
  const QuizMobileBody({super.key});

  @override
  State<QuizMobileBody> createState() => _QuizMobileBodyState();
}

class _QuizMobileBodyState extends State<QuizMobileBody> {
  int? _selectedOptionIndex;

  Future<void> _handleNext({
    required StudentProvider provider,
    required bool isLast,
  }) async {
    final selectedIndex = _selectedOptionIndex;
    if (selectedIndex == null || provider.isSubmittingQuiz) return;

    provider.answerQuizQuestion(selectedIndex);
    if (!isLast) {
      setState(() {
        _selectedOptionIndex = null;
      });
      return;
    }

    final navigator = Navigator.of(context);
    final error = await runWithLoadingDialog(
      context,
      provider.submitQuizAnswers,
      message: 'Submitting quiz...',
    );
    if (!mounted) return;
    if (error != null) {
      await showAppMessageDialog(
        context,
        title: 'Cannot submit quiz',
        message: error,
        isDanger: true,
      );
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => const CongratsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final story = prov.selectedStory;
    if (story == null || story.questions.isEmpty) {
      return const CongratsScreen();
    }

    final currentQ = story.questions[prov.currentQuizQuestionIndex];
    final isLast = prov.currentQuizQuestionIndex == story.questions.length - 1;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Progress Bar Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(story.questions.length, (idx) {
                final active = idx <= prov.currentQuizQuestionIndex;
                return Container(
                  width: 32,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF5C8DF6) : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.black12, width: 1),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Exercise Capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'EXERCISE ${prov.currentQuizQuestionIndex + 1}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Question Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                currentQ.questionText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Options List (Vertical Stack with larger touch targets & readable text)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentQ.options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) =>
                  _buildOptionCard(currentQ.options[idx], idx),
            ),

            const SizedBox(height: 36),

            // Next / Finish Button (3D Blue Capsule)
            InkWell(
              onTap: _selectedOptionIndex == null || prov.isSubmittingQuiz
                  ? null
                  : () => _handleNext(provider: prov, isLast: isLast),
              borderRadius: BorderRadius.circular(20),
              child: Opacity(
                opacity: _selectedOptionIndex == null || prov.isSubmittingQuiz
                    ? 0.6
                    : 1.0,
                child: Container(
                  width: 200,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C8DF6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _selectedOptionIndex == null
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0xFF2E5CB8),
                              blurRadius: 0,
                              offset: Offset(0, 5),
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: prov.isSubmittingQuiz
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLast ? 'Finish' : 'Next',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
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

  Widget _buildOptionCard(String optionText, int index) {
    final isSelected = _selectedOptionIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOptionIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5C8DF6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2E5CB8)
                  : const Color(0xFFD0D4DC),
              blurRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          optionText,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.black,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
