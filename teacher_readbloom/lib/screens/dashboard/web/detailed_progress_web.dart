import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../models/teacher_models.dart';
import 'evaluation_detail_popup.dart';

// Helper class to draw dashed borders in Flutter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dashLength,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = _buildDashedPath(path, dashLength, gap);
    canvas.drawPath(dashPath, paint);
  }

  Path _buildDashedPath(Path source, double dashWidth, double dashGap) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashWidth : dashGap;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashLength;
  final double gap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const DashedContainer({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1.5,
    this.borderRadius = 12.0,
    this.dashLength = 6.0,
    this.gap = 4.0,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        borderRadius: borderRadius,
        dashLength: dashLength,
        gap: gap,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

class DetailedProgressWebBody extends StatefulWidget {
  final VoidCallback onBack;
  const DetailedProgressWebBody({super.key, required this.onBack});

  @override
  State<DetailedProgressWebBody> createState() =>
      _DetailedProgressWebBodyState();
}

class _DetailedProgressWebBodyState extends State<DetailedProgressWebBody> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<TeacherProvider>();
    final student = prov.selectedStudentForEvaluation;
    if (student != null) {
      _feedbackController.text = prov
          .getEvaluationForStudent(student.id)
          .feedback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    final student = prov.selectedStudentForEvaluation;
    if (student == null) {
      return Center(
        child: Text(
          'No student selected.',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
      );
    }

    final eval = prov.getEvaluationForStudent(student.id);
    final submissions = prov.getReadingReviewsForStudent(student.id);
    final latestSubmission = submissions.isNotEmpty ? submissions.first : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header with Back Button
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                height: 85,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white24, width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Evaluation Detail: ${student.name}',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable layout columns
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Avatar + Actions)
                    SizedBox(
                      width: 250,
                      child: _buildLeftColumn(student, eval, latestSubmission),
                    ),
                    const SizedBox(width: 28),
                    // Right Column (Metrics + Story Text)
                    Expanded(
                      child: _buildRightColumn(eval, latestSubmission),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(
    StudentProgress student,
    EvaluationMetrics eval,
    ReadingSubmissionReview? latestSubmission,
  ) {
    return Column(
      children: [
        // Beautiful Rounded Student Photo frame (Matches mockup avatar container)
        Container(
          width: 220,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF60A5FA), width: 3.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'lib/assets/student_avatar.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // REVIEW VIDEO BUTTON
        InkWell(
          onTap: () {
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
          borderRadius: BorderRadius.circular(24),
          child: DashedContainer(
            color: Colors.black,
            backgroundColor: Colors.white,
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'REVIEW VIDEO',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // GENERATE REPORT BUTTON
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: DashedContainer(
            color: Colors.black,
            backgroundColor: Colors.white,
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'GENERATE REPORT',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // FEEDBACK BOX (Mockup style feedback block)
        DashedContainer(
          color: Colors.black,
          backgroundColor: Colors.white,
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'FEEDBACK',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                eval.feedback.isNotEmpty
                    ? eval.feedback
                    : "Well done, Read more books and focus on the words that your not familiar with",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(
    EvaluationMetrics eval,
    ReadingSubmissionReview? submission,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error metrics row (mockup style capsules with dashed borders)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildPopupErrorTile(
                'OMISSION',
                eval.omissions,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPopupErrorTile(
                'REPETITION',
                eval.repetitions,
                const Color(0xFFF472B6),
              ),
            ), // Pinkish
            const SizedBox(width: 12),
            Expanded(
              child: _buildPopupErrorTile(
                'SELF CORRECTION',
                eval.selfCorrections,
                const Color(0xFF10B981),
              ),
            ), // Emerald green
            const SizedBox(width: 12),
            Expanded(
              child: _buildPopupErrorTile(
                'MISPRONUNCIATION',
                eval.mispronunciations,
                const Color(0xFFEAB308),
              ),
            ), // Amber yellow
          ],
        ),
        const SizedBox(height: 28),

        // Color-coded Story analysis box
        _buildStoryCard(submission),
      ],
    );
  }

  Widget _buildPopupErrorTile(String title, int count, Color textColor) {
    return DashedContainer(
      color: Colors.black,
      backgroundColor: Colors.white,
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 26,
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
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.black12, thickness: 1),
            const SizedBox(height: 12),
            Text(
              'No reading submissions available yet. Once the student submits a reading recording, their speech analysis and remark breakdown will appear here.',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.black54,
                height: 1.6,
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted: ${submission.submittedAtLabel} • ${submission.readingAccuracy != null ? "${submission.readingAccuracy!.toStringAsFixed(1)}% Accuracy" : "Pending Evaluation"}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 16),
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
                      fontSize: 16,
                      color: textColor,
                      fontWeight: borderColor != Colors.transparent
                          ? FontWeight.bold
                          : FontWeight.w500,
                      height: 1.4,
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
                fontSize: 16,
                color: Colors.black87,
                height: 1.8,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }
}
