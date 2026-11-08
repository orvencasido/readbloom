import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/loading_dialog.dart';

class ProfileMobileBody extends StatelessWidget {
  const ProfileMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar/Name card
                _buildAvatarCard(context, prov),
                const SizedBox(height: 16),

                // Personal Info Card
                _buildPersonalInfoCard(prov),
                const SizedBox(height: 24),

                // Logout Button
                _buildLogoutButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCard(BuildContext context, StudentProvider prov) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFCBE3D5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: ClipOval(child: _buildAvatarImage(prov, 120)),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _buildAvatarEditButton(context, prov),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              prov.profile.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: _calculateNameFontSize(prov.profile.name),
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F2E3A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _latestBadge(prov),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F2E3A),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateNameFontSize(String name) {
    final len = name.trim().length;
    if (len > 24) return 20;
    if (len > 18) return 22;
    if (len > 14) return 26;
    if (len > 10) return 28;
    return 32;
  }

  Widget _buildAvatarImage(StudentProvider prov, double size) {
    if (prov.profile.avatarUrl.isNotEmpty) {
      return Image.network(
        prov.profile.avatarUrl,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          'lib/assets/website/student-img.png',
          height: size,
          width: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      'lib/assets/website/student-img.png',
      height: size,
      width: size,
      fit: BoxFit.cover,
    );
  }

  Widget _buildAvatarEditButton(BuildContext context, StudentProvider prov) {
    return Material(
      color: const Color(0xFF0F2E3A),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Edit profile picture',
        icon: prov.isUploadingAvatar
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.photo_camera_outlined, color: Colors.white),
        onPressed: prov.isUploadingAvatar
            ? null
            : () async {
                final error = await runWithLoadingDialog(
                  context,
                  () => context.read<StudentProvider>().updateProfilePicture(),
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
      ),
    );
  }

  Widget _buildPersonalInfoCard(StudentProvider prov) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFCBE3D5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F2E3A),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Email:', prov.profile.email),
          const SizedBox(height: 12),
          _buildInfoRow('Grade:', prov.profile.grade),
          const SizedBox(height: 12),
          _buildInfoRow('Section:', prov.profile.section),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          context.read<StudentProvider>().logout();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD62A24),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: Text(
          'Logout',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F2E3A),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F2E3A),
            ),
          ),
        ),
      ],
    );
  }

  String _latestBadge(StudentProvider prov) {
    return prov.profile.displayAchievementBadge;
  }
}
