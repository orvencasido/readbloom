import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_models.dart';
import '../../../providers/student_provider.dart';
import '../../assessment/calibration_screen.dart';

class DashboardWebBody extends StatelessWidget {
  const DashboardWebBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();

    final booksPanel = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildBooksList(context, prov),
    );

    final sidebarPanel = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          _buildSkillsSection(prov),
          const SizedBox(height: 24),
          _buildAchievementsSection(prov),
        ],
      ),
    );

    final isCompact = MediaQuery.of(context).size.width < 1100;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner Card
            _buildWelcomeBanner(prov),
            const SizedBox(height: 24),

            // Books List + Sidebar split
            isCompact
                ? Column(
                    children: [
                      booksPanel,
                      const SizedBox(height: 24),
                      sidebarPanel,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: booksPanel),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: sidebarPanel),
                    ],
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksList(BuildContext context, StudentProvider prov) {
    final listHeight = prov.stories.length > 4 ? 328.0 : null;
    final list = ListView.builder(
      shrinkWrap: listHeight == null,
      physics: listHeight == null
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: prov.stories.length,
      itemBuilder: (context, index) {
        return _buildBookCard(context, prov.stories[index]);
      },
    );

    if (listHeight == null) return list;
    return SizedBox(height: listHeight, child: list);
  }

  Widget _buildWelcomeBanner(StudentProvider prov) {
    final currentTier = getTierByNameOrTitle(
      prov.profile.level.isNotEmpty
          ? prov.profile.level
          : (prov.profile.badges.isNotEmpty ? prov.profile.badges.first : ''),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isNarrow = availableWidth < 900;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 20 : 24,
            vertical: isNarrow ? 16 : 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isNarrow ? 28 : 60),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildStudentAvatar(prov, 64),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${prov.profile.name}!',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F2E3A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              _buildCurrentAchievementPill(currentTier),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildStackedBadgesTrail(
                        currentTier,
                        badgeSize: 44.0,
                        overlapOffset: 32.0,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _buildStudentAvatar(prov, 80),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Welcome, ${prov.profile.name}!',
                                  style: GoogleFonts.outfit(
                                    fontSize: availableWidth < 1100 ? 22 : 28,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F2E3A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                _buildCurrentAchievementPill(currentTier),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildStackedBadgesTrail(
                            currentTier,
                            badgeSize: availableWidth < 1100 ? 46.0 : 54.0,
                            overlapOffset: availableWidth < 1100 ? 34.0 : 40.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStackedBadgesTrail(
    AchievementTier currentTier, {
    double badgeSize = 54.0,
    double overlapOffset = 40.0,
  }) {
    final totalWidth = badgeSize + (kAchievementTiers.length - 1) * overlapOffset;
    final currentIndex = kAchievementTiers.indexWhere(
      (t) => t.level == currentTier.level,
    );
    final safeCurrentIndex = currentIndex >= 0 ? currentIndex : 0;
    final emojiSize = badgeSize * 0.44;
    final currentBadgeSize = badgeSize + 8;
    final currentEmojiSize = emojiSize * 1.25;

    // Paint order:
    // 1. Locked badges to the right of current (painted from rightmost to leftmost so left overlaps right).
    // 2. Unlocked badges to the left of current (painted from leftmost to current - 1 so right overlaps left).
    // 3. Current badge (painted last of all so it is 100% full circle, overlapping both left and right neighbors).
    final sortedIndices = List.generate(kAchievementTiers.length, (i) => i)
      ..sort((a, b) {
        int priority(int index) {
          if (index == safeCurrentIndex) return 1000;
          if (index < safeCurrentIndex) return 100 + index;
          return 50 + (kAchievementTiers.length - index);
        }

        return priority(a).compareTo(priority(b));
      });

    return Container(
      height: currentBadgeSize + 8,
      width: totalWidth + 14,
      alignment: Alignment.centerRight,
      child: Stack(
        clipBehavior: Clip.none,
        children: sortedIndices.map((index) {
          final tier = kAchievementTiers[index];
          final isUnlocked = tier.level <= currentTier.level;
          final isCurrent = tier.level == currentTier.level;

          return Positioned(
            left: index * overlapOffset,
            top: isCurrent ? 2 : 6,
            child: Tooltip(
              message: '${tier.displayName}${isUnlocked ? ' (Achieved)' : ' (Locked)'}',
              textStyle: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2E3A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isCurrent ? currentBadgeSize : badgeSize,
                height: isCurrent ? currentBadgeSize : badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? (isCurrent
                          ? const Color(0xFFFFF9C4)
                          : const Color(0xFFE8F5E9))
                      : const Color(0xFFF3F4F6),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFFFFB300)
                        : (isUnlocked
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFD1D5DB)),
                    width: isCurrent ? 3.0 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCurrent
                          ? const Color(0xFFFFB300).withValues(alpha: 0.40)
                          : (isUnlocked
                              ? Colors.black.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.03)),
                      blurRadius: isCurrent ? 12 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.35,
                  child: Text(
                    tier.emoji,
                    style: TextStyle(
                      fontSize: isCurrent ? currentEmojiSize : emojiSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentAchievementPill(AchievementTier currentTier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentTier.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            currentTier.title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAvatar(StudentProvider prov, double size) {
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


  Widget _buildBookCard(BuildContext context, dynamic story) {
    final isLocked = story.isLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFE4ECE8) : const Color(0xFFAFD6C4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.title,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F2E3A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'BOOK ${story.bookNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          isLocked
              ? const Icon(Icons.lock, color: Colors.black, size: 20)
              : InkWell(
                  onTap: () {
                    if (!context.read<StudentProvider>().canStartStory(story)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This book is not ready for reading yet.',
                          ),
                        ),
                      );
                      return;
                    }
                    context.read<StudentProvider>().selectStory(story);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CalibrationScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C8DF6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF2E5CB8),
                          blurRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Start Quest',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(StudentProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills Focus',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F2E3A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                'Reading',
                prov.profile.readingLevel,
                const Color(0xFFE98D93),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridCard(
                'Vocabulary',
                prov.profile.vocabularyLevel,
                const Color(0xFF4EE39B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(StudentProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F2E3A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                'Word Master',
                prov.profile.wordMasterLevel,
                const Color(0xFF63C2FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridCard(
                'Comprehension',
                prov.profile.comprehensionLevel,
                const Color(0xFFF7DD68),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCard(String title, int level, Color bg) {
    final emoji = getSkillTierEmoji(title, level);

    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2E3A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Level $level',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F2E3A),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
        ],
      ),
    );
  }
}
