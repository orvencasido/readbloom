import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../models/teacher_models.dart';
import '../../../widgets/loading_dialog.dart';

class BadgesMobileBody extends StatefulWidget {
  const BadgesMobileBody({super.key});

  @override
  State<BadgesMobileBody> createState() => _BadgesMobileBodyState();
}

class _BadgesMobileBodyState extends State<BadgesMobileBody> {
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
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        width: 320,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.82,
                        ),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Student Badges',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
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
                              const SizedBox(height: 12),

                              // Student Details Row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      initials,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF0371C2),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            fontSize: 10,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                              const SizedBox(height: 12),

                              _buildSkillLevelControls(context, student),
                              const SizedBox(height: 16),
                              const Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                              const SizedBox(height: 12),

                              // Badges Collection
                              Text(
                                'Earned Badges',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 10),
                              student.badges.isEmpty
                                  ? Text(
                                      'No badges earned yet.',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  : ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 120,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: student.badges.map((badge) {
                                            final color = _getBadgeColor(badge);
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: color.withValues(
                                                    alpha: 0.35,
                                                  ),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .workspace_premium_outlined,
                                                    size: 13,
                                                    color: color,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    badge,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: color,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              const Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                              const SizedBox(height: 12),

                              // Award badge section
                              // Automatic Achievements Info Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text('ℹ️', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Badges and achievements are automatically earned when students pass reading quizzes with 1 or fewer mistakes.',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        _buildSkillStepper(
          context,
          student,
          'Reading',
          student.readingLevel,
          (next) => context.read<TeacherProvider>().updateStudentSkillLevels(
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
          (next) => context.read<TeacherProvider>().updateStudentSkillLevels(
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
          (next) => context.read<TeacherProvider>().updateStudentSkillLevels(
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
          (next) => context.read<TeacherProvider>().updateStudentSkillLevels(
            studentId: student.id,
            readingLevel: student.readingLevel,
            vocabularyLevel: student.vocabularySkillLevel,
            wordMasterLevel: student.wordMasterLevel,
            comprehensionLevel: next,
          ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11,
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
              fontSize: 17,
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
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 12.0),
          child: Text(
            'Badges',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),

        // Search Input (White, black text)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Filters Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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
                        fontSize: 12,
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
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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
                        fontSize: 12,
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

        // Badges list
        Expanded(
          child: filteredStudents.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.4,
                      child: Center(
                        child: Text(
                          'No students found.',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
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
                onTap: () => _showBadgesPopup(context, student),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Text(
                              initials,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF0371C2),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        thickness: 1,
                      ),
                      const SizedBox(height: 8),

                      // Badges preview
                      student.badges.isEmpty
                          ? Text(
                              'No badges earned yet.',
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  student.badges.take(3).map((badge) {
                                    final color = _getBadgeColor(badge);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.35),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.workspace_premium_outlined,
                                            size: 11,
                                            color: color,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            badge,
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
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
                                                    horizontal: 6,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.white24,
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Text(
                                                '+${student.badges.length - 3} More',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
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
      ],
    );
  }
}
