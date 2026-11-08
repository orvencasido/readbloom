import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/teacher_provider.dart';

class ActivityLogWebBody extends StatefulWidget {
  const ActivityLogWebBody({super.key});

  @override
  State<ActivityLogWebBody> createState() => _ActivityLogWebBodyState();
}

class _ActivityLogWebBodyState extends State<ActivityLogWebBody> {
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    final activityRows = prov.activities.map((activity) {
      final student = prov.students.cast<dynamic>().firstWhere(
        (student) => student.name == activity.studentName,
        orElse: () => null,
      );
      return {
        'studentName': activity.studentName,
        'grade': student?.grade?.toString() ?? '',
        'section': student?.section?.toString() ?? '',
        'bookRead': activity.activityTitle.replaceFirst('Read: ', ''),
        'date': activity.date,
        'status': activity.score >= 1 ? 'Finished' : 'Processing',
      };
    }).toList();

    // Compute paginated items
    final totalItems = activityRows.length;
    final totalPages = totalItems == 0
        ? 1
        : (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < totalItems)
        ? startIndex + _itemsPerPage
        : totalItems;
    final paginatedItems = totalItems == 0
        ? <Map<String, String>>[]
        : activityRows.sublist(startIndex, endIndex);

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
                'Activity Log',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Table Content
        Expanded(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Student Activity Log Table',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Showing ${startIndex + 1}-$endIndex of $totalItems Entries',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Custom Glassmorphic Table
                    Column(
                      children: [
                        // Table Header Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTableHeaderCell('Student Name'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('Grade'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('Section'),
                              ),
                              Expanded(
                                flex: 4,
                                child: _buildTableHeaderCell('Book Read'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('Date Finished'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('Status'),
                              ),
                            ],
                          ),
                        ),

                        // Table Body Rows
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginatedItems.length,
                          itemBuilder: (context, idx) {
                            final act = paginatedItems[idx];
                            final isLast = idx == paginatedItems.length - 1;
                            final isEven = idx % 2 == 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isEven
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.transparent,
                                borderRadius: isLast
                                    ? const BorderRadius.vertical(
                                        bottom: Radius.circular(16),
                                      )
                                    : null,
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  right: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Name
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      act['studentName']!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Grade
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      act['grade']!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  // Section
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      act['section']!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  // Book Read
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      act['bookRead']!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF60A5FA),
                                      ),
                                    ),
                                  ),
                                  // Date
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      act['date']!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  // Status Badge
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (act['status'] == 'Finished'
                                                      ? const Color(0xFF4ADE80)
                                                      : const Color(0xFFFBBF24))
                                                  .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                (act['status'] == 'Finished'
                                                        ? const Color(
                                                            0xFF4ADE80,
                                                          )
                                                        : const Color(
                                                            0xFFFBBF24,
                                                          ))
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          act['status']!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: act['status'] == 'Finished'
                                                ? const Color(0xFF4ADE80)
                                                : const Color(0xFFFBBF24),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pagination Control Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous Button
                        ElevatedButton.icon(
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                          icon: const Icon(Icons.chevron_left, size: 18),
                          label: Text(
                            'Previous',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.05,
                            ),
                            disabledForegroundColor: Colors.white30,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _currentPage > 1
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.white10,
                              ),
                            ),
                          ),
                        ),

                        // Page Indicator
                        Text(
                          'Page $_currentPage of $totalPages',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),

                        // Next Button
                        ElevatedButton.icon(
                          onPressed: _currentPage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                          icon: const Icon(Icons.chevron_right, size: 18),
                          label: Text(
                            'Next',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.05,
                            ),
                            disabledForegroundColor: Colors.white30,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _currentPage < totalPages
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.white10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
