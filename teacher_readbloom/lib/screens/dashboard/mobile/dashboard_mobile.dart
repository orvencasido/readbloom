import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../models/teacher_models.dart';

class DashboardMobileBody extends StatelessWidget {
  final Function(StudentProgress) onSelectStudent;
  final VoidCallback? onViewStudents;
  const DashboardMobileBody({
    super.key,
    required this.onSelectStudent,
    this.onViewStudents,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard header
            Text(
              'Welcome back, ${prov.teacherName}',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            if (prov.teacherDataError != null) ...[
              const SizedBox(height: 16),
              _buildDataWarning(prov.teacherDataError!),
            ],
            if (prov.newReadingSubmissionsCount > 0) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: onViewStudents,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have ${prov.newReadingSubmissionsCount} new student reading ${prov.newReadingSubmissionsCount == 1 ? 'submission' : 'submissions'} waiting for evaluation.',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (onViewStudents != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Review',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFCA5A5),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFFFCA5A5),
                          size: 10,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            _buildClassesAndOverview(context, prov),
          ],
        ),
      ),
    );
  }

  Widget _buildDataWarning(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildClassesAndOverview(BuildContext context, TeacherProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Classes',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal list of classes
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: prov.classes.map((cls) => _buildClassCard(cls)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(ClassStats cls) {
    Color accentColor = const Color(0xFF4ADE80); // Green
    if (cls.grade.contains('5')) {
      accentColor = const Color(0xFFC084FC); // Purple
    }
    if (cls.grade.contains('6')) accentColor = const Color(0xFFFBBF24); // Gold

    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              cls.grade,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: accentColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildClassStatRow('Total Students', '${cls.totalStudents}'),
          const SizedBox(height: 4),
          _buildClassStatRow(
            'Completion',
            '${(cls.completionRate * 100).toInt()}%',
          ),
          const SizedBox(height: 4),
          _buildClassStatRow('Total Lessons', '${cls.totalLessons}'),
        ],
      ),
    );
  }

  Widget _buildClassStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
