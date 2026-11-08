import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_models.dart';
import '../../../providers/student_provider.dart';
import '../../assessment/calibration_screen.dart';

class DashboardMobileBody extends StatelessWidget {
  const DashboardMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();

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
            'My Home',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),

        // Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                // Welcome Banner Card
                _buildWelcomeBanner(prov),
                const SizedBox(height: 20),

                // Books List Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildBooksList(context, prov),
                ),
                const SizedBox(height: 20),

                // Stats Section Container (Skills Focus + Achievements)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skills Focus
                      Text(
                        'Skills Focus',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
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
                      const SizedBox(height: 20),

                      // Achievements
                      Text(
                        'Achievements',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
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
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBooksList(BuildContext context, StudentProvider prov) {
    final listHeight = prov.stories.length > 4 ? 264.0 : null;
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildStudentAvatar(prov, 60),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, ${prov.profile.name}!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: prov.profile.name.length > 22
                        ? 14
                        : (prov.profile.name.length > 15 ? 16 : 18),
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currentTier.emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          currentTier.title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF166534),
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFE4F0EA) : const Color(0xFFBBE5D0),
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'BOOK ${story.bookNumber}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          isLocked
              ? const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.lock, color: Colors.black87, size: 20),
                )
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
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C8DF6),
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF2E5CB8),
                          blurRadius: 0,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.eco_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Start Quest',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
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

  Widget _buildGridCard(String title, int level, Color bg) {
    final emoji = getSkillTierEmoji(title, level);

    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 6,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2E3A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level $level',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F2E3A),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 25),
            ),
          ),
        ],
      ),
    );
  }
}
