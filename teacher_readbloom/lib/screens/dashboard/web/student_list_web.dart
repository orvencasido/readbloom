import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../models/teacher_models.dart';
import 'evaluation_detail_popup.dart';

class StudentListWebBody extends StatefulWidget {
  final Function(StudentProgress) onSelectStudent;
  const StudentListWebBody({super.key, required this.onSelectStudent});

  @override
  State<StudentListWebBody> createState() => _StudentListWebBodyState();
}

class _StudentListWebBodyState extends State<StudentListWebBody> {
  String _searchQuery = '';
  String _selectedGrade = 'All Grades';
  String _selectedSection = 'All Sections';

  void _showReadingHistoryPopup(BuildContext context, StudentProgress student) {
    final prov = context.read<TeacherProvider>();
    final submissions = prov.getReadingReviewsForStudent(student.id);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext context) {
        return Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reading History',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select a story to view the oral reading evaluation details for ${student.name}.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white24, thickness: 1),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: submissions.isEmpty
                              ? 1
                              : submissions.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            if (submissions.isEmpty) {
                              return Text(
                                'No submitted reading attempts yet.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }
                            final submission = submissions[idx];
                            return InkWell(
                                onTap: () {
                                  prov.markSubmissionAsViewed(submission.id);
                                  Navigator.of(
                                    context,
                                  ).pop(); // Close reading history popup
                                  final eval = prov.getEvaluationForStudent(
                                    student.id,
                                  );
                                  showDialog(
                                    context: context,
                                    barrierColor: Colors.black.withValues(
                                      alpha: 0.45,
                                    ),
                                    builder: (context) => EvaluationDetailPopup(
                                      student: student,
                                      eval: eval,
                                      storyTitle: submission.bookTitle,
                                      submission: submission,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.menu_book_outlined,
                                        color: Color(0xFF60A5FA),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              submission.bookTitle,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${student.grade} • ${student.section} • ${submission.submittedAtLabel}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (submission.isPendingReview &&
                                          !prov.isSubmissionViewed(submission.id)) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'NEW',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    const Icon(
                                      Icons.chevron_right_outlined,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    final query = _searchQuery;
    final selectedGrade = _selectedGrade;
    final selectedSection = _selectedSection;

    // Filtering logic
    final filteredStudents = prov.students.where((student) {
      final matchesSearch = student.name.toLowerCase().contains(
        query.toLowerCase(),
      );
      final matchesGrade =
          selectedGrade == 'All Grades' || student.grade == selectedGrade;
      final matchesSection =
          selectedSection == 'All Sections' ||
          student.section == selectedSection;
      return matchesSearch && matchesGrade && matchesSection;
    }).toList();

    final gradeOptions = prov.availableGrades.contains(selectedGrade)
        ? prov.availableGrades
        : ['All Grades', ...prov.availableGrades.skip(1), selectedGrade];
    final sectionOptions = prov.availableSections.contains(selectedSection)
        ? prov.availableSections
        : ['All Sections', ...prov.availableSections.skip(1), selectedSection];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glassmorphic Header
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
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(
                'Students Progress',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Search & Filtering Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(28.0, 24.0, 28.0, 12.0),
          child: Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search student name...',
                      hintStyle: const TextStyle(color: Colors.black38),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Grade Filter Dropdown
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedGrade,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGrade = newValue!;
                        });
                      },
                      items: gradeOptions.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Section Filter Dropdown
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSection,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSection = newValue!;
                        });
                      },
                      items: sectionOptions.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable List of Students
        Expanded(
          child: SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(28.0),
              itemCount: filteredStudents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final initials = student.name
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase();

                return InkWell(
                  onTap: () => _showReadingHistoryPopup(context, student),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Small avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Text(
                            initials,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF0371C2),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Smaller Name + Grade/Section Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                student.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${student.grade} • ${student.section}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (prov.getNewReadingSubmissionsCountForStudent(student.id) > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              prov.getNewReadingSubmissionsCountForStudent(student.id) > 99
                                  ? '99+'
                                  : '${prov.getNewReadingSubmissionsCountForStudent(student.id)}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Icon(
                          Icons.chevron_right_outlined,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
