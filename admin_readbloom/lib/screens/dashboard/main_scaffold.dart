import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/dashboard_mobile.dart';
import 'web/dashboard_web.dart';
import 'mobile/users_mobile.dart';
import 'web/users_web.dart';
import 'management_body.dart';

class AdminMainScaffold extends StatefulWidget {
  const AdminMainScaffold({super.key});

  @override
  State<AdminMainScaffold> createState() => _AdminMainScaffoldState();
}

class _AdminMainScaffoldState extends State<AdminMainScaffold> {
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

  Widget _buildMobileScaffold(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _buildAdminHeader(context, prov, compact: true),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshAdminData(context),
              child: _getMobileTabBody(_currentTab),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentTab > 4 ? 0 : _currentTab,
              onTap: (index) {
                setState(() => _currentTab = index);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: AdminTheme.primary,
              unselectedItemColor: AdminTheme.mutedText,
              selectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.class_outlined),
                  label: 'Sections',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  label: 'Books',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  label: 'History',
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
    final prov = context.watch<AdminProvider>();
    return Row(
      children: [
        // Sidebar Navigation Rail
        Container(
          width: 250,
          decoration: const BoxDecoration(color: Color(0xFF111827)),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'BloomAdmin',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'ADMIN PORTAL',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              _buildAdminHeader(context, prov),
              const SizedBox(height: 12),
              _buildLogoutItem(context),
              const SizedBox(height: 24),
              _buildSidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
              _buildSidebarItem(1, Icons.people_outline, 'Users'),
              _buildSidebarItem(2, Icons.class_outlined, 'Sections'),
              _buildSidebarItem(3, Icons.menu_book_outlined, 'Books'),
              _buildSidebarItem(4, Icons.history_outlined, 'Reading History'),
              const Spacer(),
            ],
          ),
        ),
        // Main Content Area
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: _getWebTabBody(_currentTab),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminHeader(
    BuildContext context,
    AdminProvider prov, {
    bool compact = false,
  }) {
    final initials = prov.account.name
        .split(' ')
        .map((part) => part.isNotEmpty ? part[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    final avatar = Stack(
      children: [
        CircleAvatar(
          radius: compact ? 24 : 36,
          backgroundColor: compact ? AdminTheme.primary : Colors.white,
          backgroundImage: prov.account.avatarUrl.isNotEmpty
              ? NetworkImage(prov.account.avatarUrl)
              : null,
          child: prov.account.avatarUrl.isEmpty
              ? Text(
                  initials.isEmpty ? 'A' : initials,
                  style: GoogleFonts.inter(
                    color: compact ? Colors.white : AdminTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 14 : 20,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: compact ? const Color(0xFF111827) : AdminTheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: prov.isUploadingAvatar
                  ? null
                  : () async {
                      final error = await runWithLoadingDialog(
                        context,
                        () => context
                            .read<AdminProvider>()
                            .updateProfilePicture(),
                        message: 'Updating profile picture...',
                      );
                      if (error != null) {
                        if (!context.mounted) return;
                        await showAppMessageDialog(
                          context,
                          title: 'Profile Picture Not Updated',
                          message: error,
                          isDanger: true,
                        );
                      }
                    },
              child: SizedBox(
                width: compact ? 22 : 28,
                height: compact ? 22 : 28,
                child: prov.isUploadingAvatar
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white,
                        size: compact ? 13 : 16,
                      ),
              ),
            ),
          ),
        ),
      ],
    );

    if (compact) {
      return Row(
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prov.account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: AdminTheme.text,
                  ),
                ),
                Text(
                  prov.account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AdminTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.read<AdminProvider>().logout(),
            icon: const Icon(Icons.logout, color: Colors.black54),
          ),
        ],
      );
    }

    return Column(
      children: [
        avatar,
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            prov.account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            prov.account.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isActive = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AdminTheme.primary : Colors.white70),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isActive ? AdminTheme.text : Colors.white70,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAdminData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AdminProvider>().refreshData();
    if (!context.mounted || error == null) return;
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  Widget _buildLogoutItem(BuildContext context) {
    return InkWell(
      onTap: () => context.read<AdminProvider>().logout(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.white70),
            const SizedBox(width: 14),
            Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getMobileTabBody(int index) {
    switch (index) {
      case 0:
        return const DashboardMobileBody();
      case 1:
        return const UsersMobileBody();
      case 2:
        return const AdminManagementBody(view: AdminManagementView.sections);
      case 3:
        return const AdminManagementBody(view: AdminManagementView.books);
      case 4:
        return const AdminManagementBody(
          view: AdminManagementView.readingHistory,
        );
      default:
        return const DashboardMobileBody();
    }
  }

  Widget _getWebTabBody(int index) {
    switch (index) {
      case 0:
        return const DashboardWebBody();
      case 1:
        return const UsersWebBody();
      case 2:
        return const AdminManagementBody(view: AdminManagementView.sections);
      case 3:
        return const AdminManagementBody(view: AdminManagementView.books);
      case 4:
        return const AdminManagementBody(
          view: AdminManagementView.readingHistory,
        );
      default:
        return const DashboardWebBody();
    }
  }
}
