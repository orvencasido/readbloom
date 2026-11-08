import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';

class JourneyMobileBody extends StatelessWidget {
  const JourneyMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final currentBadge = prov.profile.displayAchievementBadge;

    return Column(
      children: [
        // Top Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'My Journey',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),

        // Scrollable signpost area
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                _buildSignboard(
                  'Learning Completed',
                  '${prov.learningCompletedCount}/${prov.totalBooksCount}',
                  'lib/assets/website/task-icon.png',
                ),
                const SizedBox(height: 16),
                _buildSignboard(
                  'Days Streak',
                  '${prov.profile.daysStreak} days',
                  'lib/assets/website/star-icon.png',
                ),
                const SizedBox(height: 16),
                _buildSignboard(
                  'Achievement',
                  currentBadge,
                  'lib/assets/website/medal-icon.png',
                  onTap: () => _showBadgesPopup(context, prov.profile.badges),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignboard(
    String label,
    String value,
    String assetPath, {
    VoidCallback? onTap,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Image.asset(
                  assetPath,
                  height: 46,
                  width: 46,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 14),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F2E3A),
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Value Pill
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 70,
                      maxWidth: 140,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3FAF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00D37F),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00D37F),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBadgesPopup(BuildContext context, List<String> badges) {
    showDialog(
      context: context,
      builder: (context) {
        return AppDialogFrame(
          title: 'Earned Badges',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
          child: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (badges.isNotEmpty
                      ? badges
                      : [context.read<StudentProvider>().profile.displayAchievementBadge])
                  .map(
                    (badge) => Chip(
                      avatar: const Icon(Icons.workspace_premium),
                      label: Text(badge),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
