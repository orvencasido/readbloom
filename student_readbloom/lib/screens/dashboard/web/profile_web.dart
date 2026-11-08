import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/loading_dialog.dart';

class ProfileWebBody extends StatelessWidget {
  const ProfileWebBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar/Name card
                _buildAvatarCard(context, prov),
                const SizedBox(height: 20),

                // Personal Info Card
                _buildPersonalInfoCard(prov),
                const SizedBox(height: 28),

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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFD9EAF5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _buildAvatarImage(prov, 110),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _buildAvatarEditButton(context, prov),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prov.profile.name,
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _latestBadge(prov),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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
      color: Colors.black,
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFD9EAF5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Email:', prov.profile.email),
          const SizedBox(height: 16),
          _buildInfoRow('Grade:', prov.profile.grade),
          const SizedBox(height: 16),
          _buildInfoRow('Section:', prov.profile.section),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<StudentProvider>().logout();
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFD62A24),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF911612),
              blurRadius: 0,
              offset: Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Logout',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
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
