import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/admin_models.dart';
import '../../../providers/admin_provider.dart';
import '../../../theme/app_theme.dart';

class DashboardWebBody extends StatefulWidget {
  const DashboardWebBody({super.key});

  @override
  State<DashboardWebBody> createState() => _DashboardWebBodyState();
}

class _DashboardWebBodyState extends State<DashboardWebBody> {
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
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              // Summary cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Students',
                      '$totalStudents',
                      Icons.people,
                      Colors.blue.shade100,
                      Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Teachers',
                      '$totalTeachers',
                      Icons.school,
                      Colors.indigo.shade100,
                      Colors.indigo.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Paginated Activity Table Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent System Activity',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Showing ${totalItems == 0 ? 0 : startIndex + 1}-$endIndex of $totalItems Entries${query.isNotEmpty ? ' (filtered from ${rawActivities.length})' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AdminTheme.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search and Rows Per Page Toolbar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.black12,
                                width: 1.2,
                              ),
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
                                hintText:
                                    'Search activities by name, role, activity, date, or status...',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.black38,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          size: 18,
                                        ),
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
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AdminTheme.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _itemsPerPage,
                              isDense: true,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 8,
                                  child: Text('8 per page'),
                                ),
                                DropdownMenuItem(
                                  value: 25,
                                  child: Text('25 per page'),
                                ),
                                DropdownMenuItem(
                                  value: 50,
                                  child: Text('50 per page'),
                                ),
                                DropdownMenuItem(
                                  value: 100,
                                  child: Text('100 per page'),
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
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Custom Data Table Layout
                    Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTableHeaderCell('Date & Time'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('User Type'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('Name'),
                              ),
                              Expanded(
                                flex: 5,
                                child: _buildTableHeaderCell('Activity'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('Status'),
                              ),
                            ],
                          ),
                        ),
                        // Table Rows
                        if (paginatedItems.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                                right: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: Text(
                              query.isEmpty
                                  ? 'No system activities found.'
                                  : 'No activities found matching "$query".',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black38,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: paginatedItems.length,
                            itemBuilder: (context, idx) {
                              final log = paginatedItems[idx];
                              final isLast = idx == paginatedItems.length - 1;
                              final isEven = idx % 2 == 0;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isEven
                                      ? Colors.grey.shade50.withValues(
                                          alpha: 0.5,
                                        )
                                      : Colors.white,
                                  borderRadius: isLast
                                      ? const BorderRadius.vertical(
                                          bottom: Radius.circular(12),
                                        )
                                      : null,
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                    right: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        log.dateTime,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
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
                                            color: log.userType == 'Teacher'
                                                ? Colors.indigo.shade50
                                                : Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: log.userType == 'Teacher'
                                                  ? Colors.indigo.shade100
                                                  : Colors.blue.shade100,
                                            ),
                                          ),
                                          child: Text(
                                            log.userType,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: log.userType == 'Teacher'
                                                  ? Colors.indigo.shade700
                                                  : Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        log.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        log.activity,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
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
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            log.status,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
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
                    const SizedBox(height: 20),

                    // Interactive Pagination Controls
                    _buildPagination(safePage, totalPages, totalItems),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int safePage, int totalPages, int totalItems) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'First page',
              onPressed: safePage > 1 ? () => setState(() => _currentPage = 1) : null,
              icon: const Icon(Icons.first_page, size: 20),
              splashRadius: 18,
            ),
            ElevatedButton.icon(
              onPressed: safePage > 1
                  ? () => setState(() => _currentPage = safePage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: safePage,
                  isDense: true,
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
              ' of $totalPages ($totalItems entries)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: safePage < totalPages
                  ? () => setState(() => _currentPage = safePage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Last page',
              onPressed: safePage < totalPages
                  ? () => setState(() => _currentPage = totalPages)
                  : null,
              icon: const Icon(Icons.last_page, size: 20),
              splashRadius: 18,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String val,
    IconData icon,
    Color bg,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: bg,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AdminTheme.mutedText,
                  ),
                ),
                Text(
                  val,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
