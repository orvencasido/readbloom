import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../models/teacher_models.dart';
import '../../../widgets/loading_dialog.dart';

class BadgesWebBody extends StatefulWidget {
  const BadgesWebBody({super.key});

  @override
  State<BadgesWebBody> createState() => _BadgesWebBodyState();
}

class _BadgesWebBodyState extends State<BadgesWebBody> {
  String _searchQuery = '';
  String _selectedGrade = 'All Grades';
  String _selectedSection = 'All Sections';

  Color _getBadgeColor(String badgeText) {
    final text = badgeText.toLowerCase();
    if (text.contains('star') ||
        text.contains('boss') ||
        text.contains('super')) {
      return const Color(0xFFFBBF24); // Gold / Amber
    }
    if (text.contains('growing') || text.contains('reader')) {
      return const Color(0xFFC084FC); // Purple
    }
    return const Color(0xFF60A5FA); // Blue
  }

  void _showBadgesPopup(BuildContext context, StudentProgress initialStudent) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Read fresh student data from provider to show updated badges instantly
            final prov = context.watch<TeacherProvider>();
            final student = prov.students.firstWhere(
              (s) => s.id == initialStudent.id,
              orElse: () => initialStudent,
            );
            final initials = student.name
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
                .toUpperCase();

            return Center(
              child: Dialog(
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        width: 550,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.86,
                        ),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Student Badges',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Student Details Row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      initials,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF0371C2),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
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
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                              const SizedBox(height: 20),

                              _buildSkillLevelControls(context, student),
                              const SizedBox(height: 20),
                              const Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                              const SizedBox(height: 20),

                              // Badges List wrap
                              Text(
                                'Earned Badges Collection',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 12),
                              student.badges.isEmpty
                                  ? Text(
                                      'No badges earned yet.',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white38,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: student.badges.map((badge) {
                                        final color = _getBadgeColor(badge);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: color.withValues(
                                                alpha: 0.35,
                                              ),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons
                                                    .workspace_premium_outlined,
                                                size: 15,
                                                color: color,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                badge,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              const SizedBox(height: 28),
                              const Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                              const SizedBox(height: 20),

                              // Automatic Achievements Info Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text('ℹ️', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Badges and achievements are automatically earned when students pass reading quizzes with 1 or fewer mistakes.',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          height: 1.3,
                                        ),
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
                  ),
                ),
              );
            },
          );
        },
      );
    }

  Widget _buildSkillLevelControls(
    BuildContext context,
    StudentProgress student,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Levels',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSkillStepper(
              context,
              student,
              'Reading',
              student.readingLevel,
              (next) =>
                  context.read<TeacherProvider>().updateStudentSkillLevels(
                    studentId: student.id,
                    readingLevel: next,
                    vocabularyLevel: student.vocabularySkillLevel,
                    wordMasterLevel: student.wordMasterLevel,
                    comprehensionLevel: student.comprehensionLevel,
                  ),
            ),
            _buildSkillStepper(
              context,
              student,
              'Vocabulary',
              student.vocabularySkillLevel,
              (next) =>
                  context.read<TeacherProvider>().updateStudentSkillLevels(
                    studentId: student.id,
                    readingLevel: student.readingLevel,
                    vocabularyLevel: next,
                    wordMasterLevel: student.wordMasterLevel,
                    comprehensionLevel: student.comprehensionLevel,
                  ),
            ),
            _buildSkillStepper(
              context,
              student,
              'Word Master',
              student.wordMasterLevel,
              (next) =>
                  context.read<TeacherProvider>().updateStudentSkillLevels(
                    studentId: student.id,
                    readingLevel: student.readingLevel,
                    vocabularyLevel: student.vocabularySkillLevel,
                    wordMasterLevel: next,
                    comprehensionLevel: student.comprehensionLevel,
                  ),
            ),
            _buildSkillStepper(
              context,
              student,
              'Comprehension',
              student.comprehensionLevel,
              (next) =>
                  context.read<TeacherProvider>().updateStudentSkillLevels(
                    studentId: student.id,
                    readingLevel: student.readingLevel,
                    vocabularyLevel: student.vocabularySkillLevel,
                    wordMasterLevel: student.wordMasterLevel,
                    comprehensionLevel: next,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillStepper(
    BuildContext context,
    StudentProgress student,
    String label,
    int level,
    Future<String?> Function(int nextLevel) onChanged,
  ) {
    return Container(
      width: 235,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: level <= 1
                ? null
                : () => _saveSkillLevel(context, level - 1, onChanged),
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.white70,
            disabledColor: Colors.white24,
          ),
          Text(
            '$level',
            style: GoogleFonts.outfit(
              color: const Color(0xFF60A5FA),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: level >= 10
                ? null
                : () => _saveSkillLevel(context, level + 1, onChanged),
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.white70,
            disabledColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Future<void> _saveSkillLevel(
    BuildContext context,
    int nextLevel,
    Future<String?> Function(int nextLevel) onChanged,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await runWithLoadingDialog(
      context,
      () => onChanged(nextLevel),
      message: 'Updating skill level...',
    );
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    final query = _searchQuery;
    final gradeOptions = prov.availableGrades;
    final sectionOptions = prov.availableSections;
    final selectedGrade = gradeOptions.contains(_selectedGrade)
        ? _selectedGrade
        : 'All Grades';
    final selectedSection = sectionOptions.contains(_selectedSection)
        ? _selectedSection
        : 'All Sections';

    // Filter students
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
                border: const Border(
                  bottom: BorderSide(color: Colors.white24, width: 1.5),
                ),
              ),
              child: Text(
                'Badges',
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

        // Scrollable Grid of Student Badge Cards
        Expanded(
          child: SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(28.0),
              itemCount: filteredStudents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final initials = student.name
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase();

                return InkWell(
                  onTap: () => _showBadgesPopup(context, student),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
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
                        // Student Header Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Text(
                                initials,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF0371C2),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
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
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                          thickness: 1.5,
                        ),
                        const SizedBox(height: 16),

                        // Badges Wrap list
                        student.badges.isEmpty
                            ? Text(
                                'No badges earned yet. Click card to award one.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children:
                                    student.badges.take(3).map((badge) {
                                      final color = _getBadgeColor(badge);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: color.withValues(
                                              alpha: 0.35,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.workspace_premium_outlined,
                                              size: 15,
                                              color: color,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              badge,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList()..addAll(
                                      student.badges.length > 3
                                          ? [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Text(
                                                  '+${student.badges.length - 3} More',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ]
                                          : [],
                                    ),
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
