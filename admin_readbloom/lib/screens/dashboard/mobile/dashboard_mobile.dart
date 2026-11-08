import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/admin_models.dart';
import '../../../providers/admin_provider.dart';
import '../../../theme/app_theme.dart';

class DashboardMobileBody extends StatefulWidget {
  const DashboardMobileBody({super.key});

  @override
  State<DashboardMobileBody> createState() => _DashboardMobileBodyState();
}

class _DashboardMobileBodyState extends State<DashboardMobileBody> {
  int _currentPage = 1;
  int _itemsPerPage = 8;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    final rawActivities = prov.activities;
    final totalStudents = prov.users
        .where((user) => user.role.toLowerCase() == 'student')
        .length;
    final totalTeachers = prov.users
        .where((user) => user.role.toLowerCase() == 'teacher')
        .length;

    final query = _searchQuery.trim().toLowerCase();
    final activities = rawActivities.where((log) {
      if (query.isEmpty) return true;
      return log.name.toLowerCase().contains(query) ||
          log.userType.toLowerCase().contains(query) ||
          log.activity.toLowerCase().contains(query) ||
          log.dateTime.toLowerCase().contains(query) ||
          log.status.toLowerCase().contains(query);
    }).toList();

    final totalItems = activities.length;
    final isShowAll = _itemsPerPage <= 0;
    final totalPages = totalItems == 0
        ? 1
        : isShowAll
            ? 1
            : (totalItems / _itemsPerPage).ceil();

    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = isShowAll ? 0 : (safePage - 1) * _itemsPerPage;
    final endIndex = isShowAll
        ? totalItems
        : (startIndex + _itemsPerPage < totalItems)
            ? startIndex + _itemsPerPage
            : totalItems;
    final paginatedItems = totalItems == 0
        ? const <SystemActivity>[]
        : activities.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 20.0,
            bottom: 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome / Header section
              Text(
                'Dashboard Overview',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Summary cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Students',
                      '$totalStudents',
                      Icons.people,
                      Colors.blue.shade50,
                      Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Teachers',
                      '$totalTeachers',
                      Icons.school,
                      Colors.indigo.shade50,
                      Colors.indigo.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Activity Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent System Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing ${totalItems == 0 ? 0 : startIndex + 1}-$endIndex of $totalItems Entries${query.isNotEmpty ? ' (filtered from ${rawActivities.length})' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AdminTheme.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search field and page size
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12, width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _currentPage = 1;
                          });
                        },
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search activities...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.black38,
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.black54,
                            size: 18,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _currentPage = 1;
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Show: ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _itemsPerPage,
                              isDense: true,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 8,
                                  child: Text('8 / page'),
                                ),
                                DropdownMenuItem(
                                  value: 25,
                                  child: Text('25 / page'),
                                ),
                                DropdownMenuItem(
                                  value: 50,
                                  child: Text('50 / page'),
                                ),
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text('Show all'),
                                ),
                              ],
                              onChanged: (newSize) {
                                if (newSize != null) {
                                  setState(() {
                                    _itemsPerPage = newSize;
                                    _currentPage = 1;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Mobile log list rows
                    if (paginatedItems.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          query.isEmpty
                              ? 'No system activities found.'
                              : 'No activities found matching "$query".',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.black38,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paginatedItems.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 16),
                        itemBuilder: (context, idx) {
                          final log = paginatedItems[idx];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: log.userType == 'Teacher'
                                              ? Colors.indigo.shade50
                                              : Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          log.userType,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: log.userType == 'Teacher'
                                                ? Colors.indigo.shade700
                                                : Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        log.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _timeOnly(log.dateTime),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                log.activity,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Pagination Control Row with Jump to Page
                    _buildMobilePagination(safePage, totalPages, totalItems),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePagination(
    int safePage,
    int totalPages,
    int totalItems,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'First',
              onPressed: safePage > 1 ? () => setState(() => _currentPage = 1) : null,
              icon: const Icon(Icons.first_page, size: 18),
            ),
            InkWell(
              onTap: safePage > 1
                  ? () => setState(() => _currentPage = safePage - 1)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: safePage > 1
                      ? Colors.grey.shade100
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Prev',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: safePage > 1 ? Colors.black87 : Colors.black26,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Page ',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: safePage,
                  isDense: true,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.primary,
                  ),
                  items: List.generate(totalPages, (i) => i + 1).map((p) {
                    return DropdownMenuItem<int>(
                      value: p,
                      child: Text('$p'),
                    );
                  }).toList(),
                  onChanged: (newP) {
                    if (newP != null && newP != safePage) {
                      setState(() => _currentPage = newP);
                    }
                  },
                ),
              ),
            ),
            Text(
              ' of $totalPages',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: safePage < totalPages
                  ? () => setState(() => _currentPage = safePage + 1)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: safePage < totalPages
                      ? Colors.grey.shade100
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: safePage < totalPages
                        ? Colors.black87
                        : Colors.black26,
                  ),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Last',
              onPressed: safePage < totalPages
                  ? () => setState(() => _currentPage = totalPages)
                  : null,
              icon: const Icon(Icons.last_page, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  String _timeOnly(String dateTime) {
    if (dateTime.length >= 19) return dateTime.substring(11, 19);
    return dateTime;
  }

  Widget _buildSummaryCard(
    String title,
    String val,
    IconData icon,
    Color bg,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: bg,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AdminTheme.mutedText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  val,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
