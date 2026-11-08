import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/loading_dialog.dart';
import '../congrats_screen.dart';

class QuizWebBody extends StatefulWidget {
  const QuizWebBody({super.key});

  @override
  State<QuizWebBody> createState() => _QuizWebBodyState();
}

class _QuizWebBodyState extends State<QuizWebBody> {
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
    final isCompact = MediaQuery.of(context).size.width < 1000;
    final optionFontSize =
        isCompact ? 16.0 : _calculateOptionFontSize(currentQ.options);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Quiz progress indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(story.questions.length, (idx) {
                  final active = idx <= prov.currentQuizQuestionIndex;
                  return Container(
                    width: 12,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF5C8DF6) : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Exercise Title Capsule
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'EXERCISE ${prov.currentQuizQuestionIndex + 1}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Question
              Text(
                currentQ.questionText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isCompact ? 24 : 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 48),

              // Options list (Horizontal on wide, Vertical on narrow)
              isCompact
                  ? Column(
                      children: List.generate(
                        currentQ.options.length,
                        (idx) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildOptionCard(
                            currentQ.options[idx],
                            idx,
                            fontSize: optionFontSize,
                          ),
                        ),
                      ),
                    )
                  : IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(
                          currentQ.options.length,
                          (idx) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: _buildOptionCard(
                                currentQ.options[idx],
                                idx,
                                fontSize: optionFontSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 48),

              // Next Button
              InkWell(
                onTap: _selectedOptionIndex == null || prov.isSubmittingQuiz
                    ? null
                    : () => _handleNext(provider: prov, isLast: isLast),
                child: Container(
                  width: 200,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _selectedOptionIndex == null || prov.isSubmittingQuiz
                        ? const Color(0xFFB0C4DE)
                        : const Color(0xFF5C8DF6),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow:
                        _selectedOptionIndex == null || prov.isSubmittingQuiz
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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLast ? 'Finish' : 'Next',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateOptionFontSize(List<String> options) {
    int maxLen = 0;
    for (final opt in options) {
      if (opt.trim().length > maxLen) {
        maxLen = opt.trim().length;
      }
    }
    if (options.length <= 2) {
      if (maxLen > 80) return 15.0;
      return 17.0;
    }
    if (options.length == 3) {
      if (maxLen > 80) return 14.0;
      if (maxLen > 50) return 15.5;
      return 17.0;
    }
    // 4 or more options side-by-side
    if (maxLen > 80) return 12.5;
    if (maxLen > 60) return 13.5;
    if (maxLen > 40) return 14.5;
    if (maxLen > 25) return 15.5;
    return 17.0;
  }

  Widget _buildOptionCard(
    String optionText,
    int index, {
    double fontSize = 16.0,
  }) {
    final isSelected = _selectedOptionIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOptionIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5C8DF6) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black, width: 2.5),
        ),
        alignment: Alignment.center,
        child: Text(
          optionText,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.black,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}
