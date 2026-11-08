import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/dashboard_mobile.dart';
import 'web/dashboard_web.dart';
import 'mobile/student_list_mobile.dart';
import 'web/student_list_web.dart';
import 'mobile/activity_log_mobile.dart';
import 'web/activity_log_web.dart';
import 'mobile/badges_mobile.dart';
import 'web/badges_web.dart';
import 'mobile/profile_mobile.dart';
import 'web/profile_web.dart';
import 'mobile/evaluation_detail_mobile.dart';
import 'web/detailed_progress_web.dart';
import 'mobile/books_mobile.dart';
import 'web/books_web.dart';

class TeacherMainScaffold extends StatefulWidget {
  const TeacherMainScaffold({super.key});

  @override
  State<TeacherMainScaffold> createState() => _TeacherMainScaffoldState();
}

class _TeacherMainScaffoldState extends State<TeacherMainScaffold> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: _buildMobileScaffold(context),
        webBody: _buildWebScaffold(context),
      ),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileScaffold(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    final newCount = prov.newReadingSubmissionsCount;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/bg-web.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshTeacherData(context),
              child: SafeArea(
                bottom: false,
                child: _getMobileTabBody(_currentTab),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.85),
              border: const Border(top: BorderSide(color: Colors.white12)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentTab > 5 ? 0 : _currentTab,
              onTap: (index) => setState(() => _currentTab = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF60A5FA),
              unselectedItemColor: Colors.white54,
              selectedLabelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: newCount > 0,
                    backgroundColor: const Color(0xFFEF4444),
                    textColor: Colors.white,
                    label: Text(
                      newCount > 99 ? '99+' : '$newCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Icon(Icons.list_alt_outlined),
                  ),
                  label: 'Students',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  label: 'Books',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Activity',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.workspace_premium),
                  label: 'Badges',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WEB LAYOUT ---
  Widget _buildWebScaffold(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/bg-web.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Row(
        children: [
          // Glassmorphic Sidebar Navigation Rail
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Image.asset(
                      'lib/assets/logo-icon.png',
                      height: 70,
                      width: 70,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BloomTeach',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'TEACHER PORTAL',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
                    _buildSidebarItem(
                      1,
                      Icons.list_alt_outlined,
                      'Students Progress',
                      badgeCount: prov.newReadingSubmissionsCount,
                    ),
                    _buildSidebarItem(2, Icons.menu_book_outlined, 'Books'),
                    _buildSidebarItem(3, Icons.history, 'Activity Log'),
                    _buildSidebarItem(4, Icons.workspace_premium, 'Badges'),
                    _buildSidebarItem(5, Icons.settings_outlined, 'Settings'),
                    const Spacer(),
                    // Teacher User Indicator at bottom
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            child: Text(
                              prov.teacherName.substring(0, 2).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  prov.teacherName,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'TEACHER',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: Colors.white60,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: _getWebTabBody(_currentTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    IconData icon,
    String label, {
    int badgeCount = 0,
  }) {
    final isActive = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.85),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshTeacherData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<TeacherProvider>().refreshData();
    if (!context.mounted || error == null) return;
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  void _navigateToStudentDetail(dynamic student) {
    context.read<TeacherProvider>().selectStudentForEvaluation(student);
    setState(() {
      _currentTab = 6; // Direct to Detail Evaluation Page
    });
  }

  void _navigateBackToDashboard() {
    setState(() {
      _currentTab = 0; // Return to Dashboard
    });
  }

  Widget _getMobileTabBody(int index) {
    switch (index) {
      case 0:
        return DashboardMobileBody(
          onSelectStudent: _navigateToStudentDetail,
          onViewStudents: () => setState(() => _currentTab = 1),
        );
      case 1:
        return const StudentListMobileBody();
      case 2:
        return const BooksMobileBody();
      case 3:
        return const ActivityLogMobileBody();
      case 4:
        return const BadgesMobileBody();
      case 5:
        return const ProfileMobileBody();
      case 6:
        return EvaluationDetailMobileBody(onBack: _navigateBackToDashboard);
      default:
        return DashboardMobileBody(
          onSelectStudent: _navigateToStudentDetail,
          onViewStudents: () => setState(() => _currentTab = 1),
        );
    }
  }

  Widget _getWebTabBody(int index) {
    switch (index) {
      case 0:
        return DashboardWebBody(
          onSelectStudent: _navigateToStudentDetail,
          onViewStudents: () => setState(() => _currentTab = 1),
        );
      case 1:
        return StudentListWebBody(onSelectStudent: _navigateToStudentDetail);
      case 2:
        return const BooksWebBody();
      case 3:
        return const ActivityLogWebBody();
      case 4:
        return const BadgesWebBody();
      case 5:
        return const ProfileWebBody();
      case 6:
        return DetailedProgressWebBody(onBack: _navigateBackToDashboard);
      default:
        return DashboardWebBody(
          onSelectStudent: _navigateToStudentDetail,
          onViewStudents: () => setState(() => _currentTab = 1),
        );
    }
  }
}
