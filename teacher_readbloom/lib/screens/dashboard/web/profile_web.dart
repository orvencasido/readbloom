import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../widgets/loading_dialog.dart';

class ProfileWebBody extends StatelessWidget {
  const ProfileWebBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    final initials = prov.teacherName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

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
                'Settings',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Settings Body Area
        Expanded(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 550,
                  margin: const EdgeInsets.all(28),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile Avatar
                      _buildAvatar(context, prov, initials),
                      const SizedBox(height: 20),

                      // Name & Title
                      Text(
                        prov.teacherName,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subject Teacher • ${prov.school}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.15),
                        thickness: 1.5,
                      ),
                      const SizedBox(height: 16),

                      // Info Rows
                      _buildInfoRow('Email Address', prov.email),
                      _buildInfoRow('Last Log In', prov.lastLoginDate),

                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<TeacherProvider>().logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Logout',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    TeacherProvider prov,
    String initials,
  ) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white,
          backgroundImage: prov.avatarUrl.isNotEmpty
              ? NetworkImage(prov.avatarUrl)
              : null,
          child: prov.avatarUrl.isEmpty
              ? Text(
                  initials,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0371C2),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: const Color(0xFF0371C2),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Edit profile picture',
              iconSize: 18,
              icon: prov.isUploadingAvatar
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                    ),
              onPressed: prov.isUploadingAvatar
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final error = await runWithLoadingDialog(
                        context,
                        () => context
                            .read<TeacherProvider>()
                            .updateProfilePicture(),
                        message: 'Updating profile picture...',
                      );
                      if (error != null) {
                        messenger.showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
