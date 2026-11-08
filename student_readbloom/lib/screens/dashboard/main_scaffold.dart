import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/dashboard_mobile.dart';
import 'web/dashboard_web.dart';
import 'mobile/journey_mobile.dart';
import 'web/journey_web.dart';
import 'mobile/messages_mobile.dart';
import 'web/messages_web.dart';
import 'mobile/profile_mobile.dart';
import 'web/profile_web.dart';

class StudentMainScaffold extends StatefulWidget {
  const StudentMainScaffold({super.key});

  @override
  State<StudentMainScaffold> createState() => _StudentMainScaffoldState();
}

class _StudentMainScaffoldState extends State<StudentMainScaffold> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final isTopRoute = ModalRoute.of(context)?.isCurrent ?? false;
    final hasActiveCamera = context.select<StudentProvider, bool>(
      (prov) => prov.cameraController != null,
    );
    if (isTopRoute && hasActiveCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final prov = context.read<StudentProvider>();
        if (prov.cameraController != null &&
            (ModalRoute.of(context)?.isCurrent ?? false)) {
          prov.disposeCamera();
        }
      });
    }

    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: _buildMobileScaffold(context),
        webBody: _buildWebScaffold(context),
      ),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileScaffold(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/main-bg-2.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () => _refreshStudentData(context),
              child: SafeArea(
                bottom: false,
                child: _getMobileTabBody(_currentTab),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) => setState(() => _currentTab = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: StudentTheme.primary,
            unselectedItemColor: StudentTheme.mutedText,
            selectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.route_outlined),
                label: 'Journey',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: prov.unreadMessagesCount > 0,
                  backgroundColor: const Color(0xFFEF4444),
                  label: Text(
                    prov.unreadMessagesCount > 99
                        ? '99+'
                        : '${prov.unreadMessagesCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WEB LAYOUT ---
  Widget _buildWebScaffold(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    return Column(
      children: [
        // Top Header Bar
        Container(
          height: 65,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'lib/assets/website/header-logo.png',
                height: 38,
                fit: BoxFit.contain,
              ),
              InkWell(
                onTap: () => setState(() => _currentTab = 2),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: prov.unreadMessagesCount > 0
                        ? const Color(0xFFFEF2F2)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: prov.unreadMessagesCount > 0
                          ? const Color(0xFFFCA5A5)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Badge(
                    isLabelVisible: prov.unreadMessagesCount > 0,
                    backgroundColor: const Color(0xFFEF4444),
                    label: Text(
                      prov.unreadMessagesCount > 99
                          ? '99+'
                          : '${prov.unreadMessagesCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 22,
                      color: prov.unreadMessagesCount > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF344054),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sidebar + Content Area
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/website/bg-website.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Row(
              children: [
                // Sidebar Navigation Rail
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E9384).withValues(alpha: 0.12),
                    border: const Border(
                      right: BorderSide(color: Colors.white12),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      _buildSidebarItem(0, 'Dashboard'),
                      _buildSidebarItem(1, 'My Journey'),
                      _buildSidebarItem(
                        2,
                        'Messages',
                        badgeCount: prov.unreadMessagesCount,
                      ),
                      _buildSidebarItem(3, 'Profile'),
                    ],
                  ),
                ),
                // Main Content Area
                Expanded(child: _getWebTabBody(_currentTab)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, String label, {int badgeCount = 0}) {
    final isActive = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFF5C8DF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.white : const Color(0xFF3B6CC7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFFB0B3BC)
                  : const Color(0xFF2E5CB8),
              blurRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.black : Colors.white,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66EF4444),
                      blurRadius: 4,
                      offset: Offset(0, 2),
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
          ],
        ),
      ),
    );
  }

  Future<void> _refreshStudentData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<StudentProvider>().refreshData();
    if (!context.mounted || error == null) return;
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  Widget _getMobileTabBody(int index) {
    switch (index) {
      case 0:
        return const DashboardMobileBody();
      case 1:
        return const JourneyMobileBody();
      case 2:
        return const MessagesMobileBody();
      case 3:
        return const ProfileMobileBody();
      default:
        return const DashboardMobileBody();
    }
  }

  Widget _getWebTabBody(int index) {
    switch (index) {
      case 0:
        return const DashboardWebBody();
      case 1:
        return const JourneyWebBody();
      case 2:
        return const MessagesWebBody();
      case 3:
        return const ProfileWebBody();
      default:
        return const DashboardWebBody();
    }
  }
}
