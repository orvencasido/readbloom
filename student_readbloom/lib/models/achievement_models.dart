class AchievementTier {
  final int level;
  final String emoji;
  final String title;
  final int requiredBooksPassed;

  const AchievementTier({
    required this.level,
    required this.emoji,
    required this.title,
    required this.requiredBooksPassed,
  });

  String get displayName => '$emoji $title';
}

const List<AchievementTier> kAchievementTiers = [
  AchievementTier(
    level: 1,
    emoji: '📖',
    title: 'Reading Explorer',
    requiredBooksPassed: 0,
  ),
  AchievementTier(
    level: 2,
    emoji: '🌟',
    title: 'Reading Star',
    requiredBooksPassed: 1,
  ),
  AchievementTier(
    level: 3,
    emoji: '🏆',
    title: 'Reading Champion',
    requiredBooksPassed: 2,
  ),
  AchievementTier(
    level: 4,
    emoji: '🔍',
    title: 'Word Detective',
    requiredBooksPassed: 3,
  ),
  AchievementTier(
    level: 5,
    emoji: '🧠',
    title: 'Vocabulary Builder',
    requiredBooksPassed: 4,
  ),
  AchievementTier(
    level: 6,
    emoji: '👑',
    title: 'Word Master',
    requiredBooksPassed: 5,
  ),
  AchievementTier(
    level: 7,
    emoji: '💡',
    title: 'Story Thinker',
    requiredBooksPassed: 6,
  ),
  AchievementTier(
    level: 8,
    emoji: '🔎',
    title: 'Reading Detective',
    requiredBooksPassed: 7,
  ),
  AchievementTier(
    level: 9,
    emoji: '🏅',
    title: 'Comprehension Wonderer',
    requiredBooksPassed: 8,
  ),
  AchievementTier(
    level: 10,
    emoji: '✨',
    title: 'Word Wizard',
    requiredBooksPassed: 9,
  ),
];

AchievementTier getTierByPassedBooks(int passedBooksCount) {
  if (passedBooksCount <= 0) return kAchievementTiers.first;
  for (var i = kAchievementTiers.length - 1; i >= 0; i--) {
    if (passedBooksCount >= kAchievementTiers[i].requiredBooksPassed) {
      return kAchievementTiers[i];
    }
  }
  return kAchievementTiers.first;
}

AchievementTier getTierByNameOrTitle(String name) {
  final clean = name.trim().toLowerCase();
  for (final tier in kAchievementTiers) {
    if (tier.title.toLowerCase() == clean ||
        tier.displayName.toLowerCase() == clean ||
        clean.contains(tier.title.toLowerCase())) {
      return tier;
    }
  }
  return kAchievementTiers.first;
}

class QuizSubmissionResult {
  final bool didLevelUp;
  final AchievementTier newTier;
  final AchievementTier previousTier;
  final bool isQuizPassed;
  final int score;
  final int totalQuestions;
  final int distinctPassedBooksCount;

  const QuizSubmissionResult({
    required this.didLevelUp,
    required this.newTier,
    required this.previousTier,
    required this.isQuizPassed,
    required this.score,
    required this.totalQuestions,
    required this.distinctPassedBooksCount,
  });
}

/// Returns a unique, upgrading emoji for each of the 4 skill focus categories.
/// The emoji upgrades every 2 levels and is capped at Level 10 (no changes above Level 10).
String getSkillTierEmoji(String skillTitle, int level) {
  final cleanTitle = skillTitle.trim().toLowerCase();
  final effectiveLevel = level < 1 ? 1 : level;
  // Levels 1-2 -> 0, 3-4 -> 1, 5-6 -> 2, 7-8 -> 3, 9-10+ -> 4
  final stage = ((effectiveLevel - 1) ~/ 2).clamp(0, 4);

  if (cleanTitle.contains('reading')) {
    const readingEmojis = ['📚', '👓', '🦅', '🚀', '🌌'];
    return readingEmojis[stage];
  } else if (cleanTitle.contains('vocab')) {
    const vocabEmojis = ['🌱', '🌿', '🌳', '💎', '⚡'];
    return vocabEmojis[stage];
  } else if (cleanTitle.contains('word')) {
    const wordEmojis = ['✏️', '🧩', '🗝️', '🛡️', '🔮'];
    return wordEmojis[stage];
  } else if (cleanTitle.contains('comprehen')) {
    const compEmojis = ['👁️', '🧭', '🎯', '🔭', '🌠'];
    return compEmojis[stage];
  }

  const fallbackEmojis = ['🌱', '🌿', '🌳', '💎', '⚡'];
  return fallbackEmojis[stage];
}
