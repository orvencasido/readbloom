import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';

class JourneyWebBody extends StatelessWidget {
  const JourneyWebBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final isCompact = MediaQuery.of(context).size.width < 1150;
    final currentBadge = prov.profile.displayAchievementBadge;

    final imageWidget = Image.asset(
      'lib/assets/website/girl-icon.png',
      height: isCompact ? 280 : 540,
      fit: BoxFit.contain,
    );

    final signboardsWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSignboard(
          'Learning Completed',
          '${prov.learningCompletedCount}/${prov.totalBooksCount}',
          'lib/assets/website/task-icon.png',
          0.0,
          isCompact,
        ),
        SizedBox(height: isCompact ? 16 : 16),
        _buildSignboard(
          'Days Streak',
          '${prov.profile.daysStreak} days',
          'lib/assets/website/star-icon.png',
          isCompact ? 0.0 : 45.0,
          isCompact,
        ),
        SizedBox(height: isCompact ? 16 : 16),
        _buildSignboard(
          'Achievement',
          currentBadge,
          'lib/assets/website/medal-icon.png',
          isCompact ? 0.0 : 90.0,
          isCompact,
          onTap: () => _showBadgesPopup(context, prov.profile.badges),
        ),
      ],
    );

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: isCompact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [signboardsWidget],
                )
              : SizedBox(
                  width: 910,
                  height: 540,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 235,
                        top: 0,
                        child: signboardsWidget,
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: IgnorePointer(
                          child: imageWidget,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignboard(
    String label,
    String value,
    String assetPath,
    double leftPadding,
    bool isCompact, {
    VoidCallback? onTap,
  }) {
    final maxWidth = isCompact ? 500.0 : 580.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(44),
          child: Container(
            height: isCompact ? 80 : 88,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 18 : 22,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(44),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  assetPath,
                  height: isCompact ? 44 : 50,
                  width: isCompact ? 44 : 50,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: isCompact ? 14 : 18),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F2E3A),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  constraints: BoxConstraints(
                    minWidth: isCompact ? 100 : 130,
                    maxWidth: isCompact ? 170 : 210,
                  ),
                  height: isCompact ? 54 : 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: GoogleFonts.outfit(
                        fontSize: isCompact ? 17 : 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00D37F),
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
            width: 360,
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
