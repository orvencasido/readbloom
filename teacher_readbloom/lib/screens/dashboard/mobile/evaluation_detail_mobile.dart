import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../models/teacher_models.dart';
import '../../../widgets/app_dialogs.dart';
import '../web/evaluation_detail_popup.dart';

class EvaluationDetailMobileBody extends StatefulWidget {
  final VoidCallback onBack;
  const EvaluationDetailMobileBody({super.key, required this.onBack});

  @override
  State<EvaluationDetailMobileBody> createState() =>
      _EvaluationDetailMobileBodyState();
}

class _EvaluationDetailMobileBodyState
    extends State<EvaluationDetailMobileBody> {
  final TextEditingController _feedbackController = TextEditingController();
  String _initialFeedback = '';

  @override
  void initState() {
    super.initState();
    final prov = context.read<TeacherProvider>();
    final student = prov.selectedStudentForEvaluation;
    if (student != null) {
      _feedbackController.text = prov
          .getEvaluationForStudent(student.id)
          .feedback;
      _initialFeedback = _feedbackController.text;
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _feedbackController.text.trim() != _initialFeedback.trim();

  Future<void> _handleBack() async {
    if (_isDirty) {
      final shouldLeave = await showAppConfirmDialog(
        context,
        title: 'Discard Feedback Changes?',
        message: 'Your edited feedback has not been sent to the student.',
        confirmLabel: 'Discard',
        isDanger: true,
      );
      if (!shouldLeave || !mounted) return;
    }
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    final student = prov.selectedStudentForEvaluation;
    if (student == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'No student selected.',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final eval = prov.getEvaluationForStudent(student.id);
    final submissions = prov.getReadingReviewsForStudent(student.id);
    final latestSubmission = submissions.isNotEmpty ? submissions.first : null;
    final initials = student.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleBack,
          ),
          title: Text(
            'Evaluation Detail',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 32.0),
            child: Column(
              children: [
                // Student Card Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white,
                        child: Text(
                          initials,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0371C2),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        student.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.grade} • ${student.section}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons (Clean glass outline buttons)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (latestSubmission == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No reading submissions available yet for ${student.name}.',
                                ),
                              ),
                            );
                            return;
                          }
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withValues(alpha: 0.45),
                            builder: (context) => EvaluationDetailPopup(
                              student: student,
                              eval: eval,
                              storyTitle: latestSubmission.bookTitle,
                              submission: latestSubmission,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'REVIEW VIDEO',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF60A5FA),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'GENERATE REPORT',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Metrics Grid
                _buildMetricsGrid(eval),
                const SizedBox(height: 24),

                // Color-coded Story analysis box
                _buildStoryCard(latestSubmission),
                const SizedBox(height: 24),

                // Feedback Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FEEDBACK',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _feedbackController,
                          maxLines: 4,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            hintText: 'Enter feedback message...',
                            hintStyle: TextStyle(color: Colors.black38),
                          ),
                          onChanged: (val) {
                            eval.feedback = val;
                            prov.updateEvaluation(
                              student.id,
                              eval.omissions,
                              eval.repetitions,
                              eval.selfCorrections,
                              eval.mispronunciations,
                              val,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(EvaluationMetrics eval) {
    return Row(
      children: [
        Expanded(
          child: _buildPopupErrorTile(
            'OMISSION',
            eval.omissions,
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPopupErrorTile(
            'REPETITION',
            eval.repetitions,
            const Color(0xFFF472B6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPopupErrorTile(
            'SELF CORRECTION',
            eval.selfCorrections,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPopupErrorTile(
            'MISPRONUNCIATION',
            eval.mispronunciations,
            const Color(0xFFEAB308),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupErrorTile(String title, int count, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(ReadingSubmissionReview? submission) {
    if (submission == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oral Reading Analysis',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.black.withValues(alpha: 0.12), thickness: 1),
            const SizedBox(height: 14),
            Text(
              'No reading submissions available yet. Once the student submits a reading recording, their speech analysis and remark breakdown will appear here.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final words = submission.alignment.isNotEmpty
        ? submission.alignment
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Story: ${submission.bookTitle}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${submission.submittedAtLabel} • ${submission.readingAccuracy != null ? "${submission.readingAccuracy!.toStringAsFixed(1)}% Accuracy" : "Pending Evaluation"}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.black.withValues(alpha: 0.12), thickness: 1),
          const SizedBox(height: 14),
          if (words != null && words.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: words.map((diff) {
                Color textColor = Colors.black87;
                Color bgColor = Colors.transparent;
                Color borderColor = Colors.transparent;

                final status = diff.status.toLowerCase();
                if (status == 'omission') {
                  textColor = Colors.red;
                  bgColor = Colors.red.withValues(alpha: 0.12);
                  borderColor = Colors.red;
                } else if (status == 'repetition') {
                  textColor = const Color(0xFFF472B6);
                  bgColor = const Color(0xFFF472B6).withValues(alpha: 0.12);
                  borderColor = const Color(0xFFF472B6);
                } else if (status == 'self_correction' ||
                    status == 'selfcorrection') {
                  textColor = const Color(0xFF10B981);
                  bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                  borderColor = const Color(0xFF10B981);
                } else if (status == 'mispronunciation') {
                  textColor = const Color(0xFFEAB308);
                  bgColor = const Color(0xFFEAB308).withValues(alpha: 0.12);
                  borderColor = const Color(0xFFEAB308);
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    diff.word,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: borderColor != Colors.transparent
                          ? FontWeight.bold
                          : FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              submission.passageText.isNotEmpty
                  ? submission.passageText
                  : submission.rawTranscript.isNotEmpty
                      ? submission.rawTranscript
                      : 'No text content available for this submission.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.black87,
                height: 1.7,
              ),
            ),
        ],
      ),
    );
  }
}
