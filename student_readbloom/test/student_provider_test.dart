import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_readbloom/models/student_models.dart';
import 'package:student_readbloom/providers/student_provider.dart';
import 'package:student_readbloom/repositories/student_repository.dart';
import 'package:student_readbloom/services/auth_service.dart';

class ResetPasswordStudentAuthService implements AuthService {
  String? updatedPassword;
  bool signedOut = false;

  @override
  AppRole get requiredRole => AppRole.student;

  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    return const AuthResult.success();
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthResult> updatePassword(String password) async {
    updatedPassword = password;
    return const AuthResult.success();
  }
}

class EmptyQuestionStudentRepository implements StudentRepository {
  ReadingSubmission? uploadedSubmission;
  List<QuizAnswerDraft>? submittedAnswers;
  int? submittedScore;

  @override
  StudentProfile getProfile() {
    return StudentProfile(
      id: 'student-1',
      name: 'Test Student',
      email: 'student@example.com',
      grade: 'Grade 4',
      section: 'Mabini',
      level: 'Reading Explorer',
      progressCurrent: 0,
      progressTotal: 1,
      daysStreak: 0,
      status: 'GROWING',
      badges: const [],
    );
  }

  @override
  List<Story> getAssignedStories() {
    return [
      Story(
        id: 'book-empty',
        title: 'Empty Book',
        bookNumber: 1,
        level: 1,
        text: 'A short passage.',
        questions: const [],
        isLocked: false,
      ),
    ];
  }

  @override
  Future<StudentProfile> getCurrentProfile() async => getProfile();

  @override
  Future<List<Story>> getCurrentAssignedStories() async => getAssignedStories();

  @override
  Future<StudentProfile> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async => getProfile();

  @override
  Future<ReadingSubmission> uploadReadingSubmission({
    required Story story,
    required Uint8List videoBytes,
    required String fileName,
    required int durationSeconds,
    required int timeLimitSeconds,
    required bool isOvertime,
  }) async {
    uploadedSubmission = ReadingSubmission(
      id: 'submission-1',
      studentId: 'student-1',
      bookId: story.id,
      videoPath: 'student-1/submission-1/reading.webm',
      durationSeconds: durationSeconds,
      timeLimitSeconds: timeLimitSeconds,
      isOvertime: isOvertime,
      status: 'uploaded',
    );
    return uploadedSubmission!;
  }

  @override
  Future<void> processReadingSubmission(String submissionId) async {}

  @override
  Future<QuizSubmissionResult> submitQuizAnswers({
    required ReadingSubmission submission,
    required Story story,
    required List<QuizAnswerDraft> answers,
    required int score,
  }) async {
    submittedAnswers = answers;
    submittedScore = score;
    final defaultTier = kAchievementTiers.first;
    return QuizSubmissionResult(
      score: score,
      totalQuestions: answers.length,
      isQuizPassed: score >= answers.length - 1,
      didLevelUp: false,
      newTier: defaultTier,
      previousTier: defaultTier,
      distinctPassedBooksCount: 0,
    );
  }

  @override
  Future<List<StudentMessage>> getCurrentMessages() async => const [];

  @override
  Future<void> markMessageRead(String messageId) async {}

  @override
  Future<bool> hasAcceptedActiveSafetyAgreement() async => false;

  @override
  Future<void> acceptActiveSafetyAgreement() async {}

  @override
  void clearCache() {}
}

class QuizSubmissionStudentRepository extends EmptyQuestionStudentRepository {
  @override
  List<Story> getAssignedStories() {
    return [
      Story(
        id: 'book-1',
        title: 'Quiz Book',
        bookNumber: 1,
        level: 1,
        text: 'A short passage.',
        questions: [
          QuizQuestion(
            id: 'question-1',
            questionText: 'First question?',
            options: const ['Correct', 'Wrong'],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            id: 'question-2',
            questionText: 'Second question?',
            options: const ['Wrong', 'Correct'],
            correctAnswerIndex: 1,
          ),
        ],
        isLocked: false,
      ),
    ];
  }
}

void main() {
  test('mock repository exposes explicit book numbers', () {
    final provider = StudentProvider(
      studentRepository: QuizSubmissionStudentRepository(),
    );

    expect(provider.stories.first.title, 'Quiz Book');
    expect(provider.stories.first.bookNumber, 1);
  });

  test('empty-question stories cannot start and cannot be answered', () {
    final provider = StudentProvider(
      studentRepository: EmptyQuestionStudentRepository(),
    );
    final story = provider.stories.single;

    expect(provider.canStartStory(story), isFalse);
    expect(provider.answerQuizQuestion(0), isFalse);
    expect(provider.score, 0);
    expect(provider.currentQuizQuestionIndex, 0);
  });

  test('quiz answer advances safely and scores correct answers', () {
    final provider = StudentProvider(
      studentRepository: QuizSubmissionStudentRepository(),
    );

    expect(provider.answerQuizQuestion(0), isTrue);
    expect(provider.score, 1);
    expect(provider.currentQuizQuestionIndex, 1);
  });

  test('quiz answer retry on final question does not double count score', () {
    final provider = StudentProvider(
      studentRepository: QuizSubmissionStudentRepository(),
    );

    expect(provider.answerQuizQuestion(0), isTrue);
    expect(provider.score, 1);
    expect(provider.answerQuizQuestion(1), isTrue);
    expect(provider.score, 2);
    expect(provider.answerQuizQuestion(1), isTrue);
    expect(provider.score, 2);
  });

  test('recording remaining time is capped at zero after limit', () {
    final provider = StudentProvider(
      studentRepository: QuizSubmissionStudentRepository(),
    );

    provider.debugSetRecordingElapsedSeconds(
      StudentProvider.readingTimeLimitSeconds + 30,
    );

    expect(
      provider.recordingElapsedSeconds,
      StudentProvider.readingTimeLimitSeconds,
    );
    expect(provider.recordingRemainingSeconds, 0);
    expect(provider.isRecordingOvertime, isFalse);
  });

  test('password reset rejects mismatched confirmation', () async {
    final auth = ResetPasswordStudentAuthService();
    final provider = StudentProvider(authService: auth);

    final result = await provider.completePasswordReset('new-pass', 'wrong');

    expect(result.success, isFalse);
    expect(result.message, 'Passwords do not match.');
    expect(auth.updatedPassword, isNull);
  });

  test('password reset updates password and signs out', () async {
    final auth = ResetPasswordStudentAuthService();
    final provider = StudentProvider(authService: auth);

    final result = await provider.completePasswordReset(
      'new-password',
      'new-password',
    );

    expect(result.success, isTrue);
    expect(auth.updatedPassword, 'new-password');
    expect(auth.signedOut, isTrue);
    expect(provider.isLoggedIn, isFalse);
    expect(provider.isPasswordRecovery, isFalse);
  });

  test('camera recording defaults to low resolution preset and low bitrates', () {
    expect(
      StudentProvider.recordingResolutionPreset,
      ResolutionPreset.low,
    );
    expect(StudentProvider.recordingVideoBitrate, 300000);
    expect(StudentProvider.recordingAudioBitrate, 64000);
    expect(StudentProvider.recordingFps, 24);
  });

  test('disposeCamera safely clears camera state and notifies', () async {
    final provider = StudentProvider(
      studentRepository: QuizSubmissionStudentRepository(),
    );

    var notified = false;
    provider.addListener(() => notified = true);

    await provider.disposeCamera();

    expect(provider.cameraController, isNull);
    expect(notified, isTrue);
  });

  test('cancelReadingRecording clears recording and ensures camera is released', () async {
    final provider = StudentProvider(
      studentRepository: QuizSubmissionStudentRepository(),
    );

    provider.debugSetRecordingElapsedSeconds(45);

    var notified = false;
    provider.addListener(() => notified = true);

    await provider.cancelReadingRecording();

    expect(provider.cameraController, isNull);
    expect(provider.isRecording, isFalse);
    expect(provider.recordingElapsedSeconds, 0);
    expect(notified, isTrue);
  });

  test('logout disposes camera and clears session', () async {
    final auth = ResetPasswordStudentAuthService();
    final provider = StudentProvider(authService: auth);

    await provider.logout();

    expect(provider.cameraController, isNull);
    expect(auth.signedOut, isTrue);
    expect(provider.isLoggedIn, isFalse);
  });

  group('StudentProvider Journey Learning Completed Tests', () {
    test('learning completed count is 0 when no books read, total matches available books', () async {
      final stories = [
        Story(
          id: 'book-1',
          title: 'Book 1',
          bookNumber: 1,
          level: 1,
          text: 'Passage 1',
          questions: [
            QuizQuestion(
              id: 'q1',
              questionText: 'Q1',
              options: ['A', 'B'],
              correctAnswerIndex: 0,
            ),
          ],
          isLocked: false,
        ),
        Story(
          id: 'book-2',
          title: 'Book 2',
          bookNumber: 2,
          level: 1,
          text: 'Passage 2',
          questions: [
            QuizQuestion(
              id: 'q2',
              questionText: 'Q2',
              options: ['A', 'B'],
              correctAnswerIndex: 0,
            ),
          ],
          isLocked: false,
        ),
        Story(
          id: 'book-3',
          title: 'Book 3',
          bookNumber: 3,
          level: 1,
          text: 'Passage 3',
          questions: [
            QuizQuestion(
              id: 'q3',
              questionText: 'Q3',
              options: ['A', 'B'],
              correctAnswerIndex: 0,
            ),
          ],
          isLocked: false,
        ),
      ];

      final profile = StudentProfile(
        id: 'student-1',
        name: 'Student Name',
        email: 'student@example.com',
        grade: 'Grade 4',
        section: 'A',
        level: 'Beginner',
        progressCurrent: 0,
        progressTotal: 3,
        daysStreak: 2,
        status: 'Active',
        badges: const [],
      );

      final repo = MockStudentRepository(
        profile: profile,
        stories: stories,
      );

      final provider = StudentProvider(studentRepository: repo);

      // Student has not read any books yet -> 0
      expect(provider.learningCompletedCount, 0);
      // Total available books -> 3
      expect(provider.totalBooksCount, 3);
    });

    test('learning completed count clamps properly and updates with profile', () async {
      final stories = [
        Story(
          id: 'book-1',
          title: 'Book 1',
          bookNumber: 1,
          level: 1,
          text: 'Passage 1',
          questions: const [],
          isLocked: false,
        ),
        Story(
          id: 'book-2',
          title: 'Book 2',
          bookNumber: 2,
          level: 1,
          text: 'Passage 2',
          questions: const [],
          isLocked: false,
        ),
      ];

      final profile = StudentProfile(
        id: 'student-1',
        name: 'Student Name',
        email: 'student@example.com',
        grade: 'Grade 4',
        section: 'A',
        level: 'Beginner',
        progressCurrent: 1,
        progressTotal: 2,
        daysStreak: 2,
        status: 'Active',
        badges: const [],
      );

      final repo = MockStudentRepository(
        profile: profile,
        stories: stories,
      );

      final provider = StudentProvider(studentRepository: repo);

      // 1 book completed out of 2
      expect(provider.learningCompletedCount, 1);
      expect(provider.totalBooksCount, 2);
    });

    test('unread messages count tracks unread feedback and updates on select', () async {
      final msg1 = StudentMessage(
        id: 'msg-1',
        senderName: 'Teacher Jane',
        title: 'Reading feedback: The Moon',
        body: 'Great pronunciation on this story!',
        createdAtLabel: 'Today',
        isUnread: true,
      );
      final msg2 = StudentMessage(
        id: 'msg-2',
        senderName: 'Teacher Jane',
        title: 'Reading feedback: The Stars',
        body: 'Keep practicing self-correction.',
        createdAtLabel: 'Yesterday',
        isUnread: false,
      );
      final msg3 = StudentMessage(
        id: 'msg-3',
        senderName: 'Teacher Jane',
        title: 'Reading feedback: The Sun',
        body: 'Well done on answering the quiz questions!',
        createdAtLabel: '2 days ago',
        isUnread: true,
      );

      final repo = MockStudentRepository(
        messages: [msg1, msg2, msg3],
      );

      final provider = StudentProvider(studentRepository: repo);
      await provider.loadMessages();

      // Initially 2 unread messages
      expect(provider.unreadMessagesCount, 2);
      expect(provider.hasUnreadFeedback, isTrue);

      // Select and read msg1
      await provider.selectMessage(msg1);
      expect(provider.unreadMessagesCount, 1);
      expect(provider.hasUnreadFeedback, isTrue);

      // Select and read msg3
      await provider.selectMessage(msg3);
      expect(provider.unreadMessagesCount, 0);
      expect(provider.hasUnreadFeedback, isFalse);
    });
  });

  group('Automatic Badge & Achievement Progression Tests', () {
    test('10 achievement tiers are configured in correct order', () {
      expect(kAchievementTiers.length, 10);
      expect(kAchievementTiers[0].title, 'Reading Explorer');
      expect(kAchievementTiers[1].title, 'Reading Star');
      expect(kAchievementTiers[2].title, 'Reading Champion');
      expect(kAchievementTiers[3].title, 'Word Detective');
      expect(kAchievementTiers[4].title, 'Vocabulary Builder');
      expect(kAchievementTiers[5].title, 'Word Master');
      expect(kAchievementTiers[6].title, 'Story Thinker');
      expect(kAchievementTiers[7].title, 'Reading Detective');
      expect(kAchievementTiers[8].title, 'Comprehension Wonderer');
      expect(kAchievementTiers[9].title, 'Word Wizard');

      expect(getTierByPassedBooks(0).title, 'Reading Explorer');
      expect(getTierByPassedBooks(1).title, 'Reading Star');
      expect(getTierByPassedBooks(2).title, 'Reading Champion');
      expect(getTierByPassedBooks(9).title, 'Word Wizard');
      expect(getTierByPassedBooks(100).title, 'Word Wizard');
    });

    test('quiz pass allows at most 1 mistake, advances tier on distinct books, and ignores retakes', () async {
      final story1 = Story(
        id: 'book-1',
        title: 'Story One',
        bookNumber: 1,
        level: 1,
        text: 'Text 1',
        questions: [
          QuizQuestion(id: 'q1', questionText: 'Q1', options: ['A', 'B'], correctAnswerIndex: 0),
          QuizQuestion(id: 'q2', questionText: 'Q2', options: ['A', 'B'], correctAnswerIndex: 0),
          QuizQuestion(id: 'q3', questionText: 'Q3', options: ['A', 'B'], correctAnswerIndex: 0),
        ],
        isLocked: false,
      );
      final story2 = Story(
        id: 'book-2',
        title: 'Story Two',
        bookNumber: 2,
        level: 1,
        text: 'Text 2',
        questions: [
          QuizQuestion(id: 'q4', questionText: 'Q4', options: ['A', 'B'], correctAnswerIndex: 0),
          QuizQuestion(id: 'q5', questionText: 'Q5', options: ['A', 'B'], correctAnswerIndex: 0),
          QuizQuestion(id: 'q6', questionText: 'Q6', options: ['A', 'B'], correctAnswerIndex: 0),
        ],
        isLocked: false,
      );

      final repo = MockStudentRepository(
        stories: [story1, story2],
      );

      final submission1 = ReadingSubmission(
        id: 'sub-1',
        studentId: 'student-1',
        bookId: story1.id,
        videoPath: 'path1',
        durationSeconds: 30,
        timeLimitSeconds: 60,
        isOvertime: false,
        status: 'uploaded',
      );

      final answers3 = [
        QuizAnswerDraft(questionId: 'q1', selectedOptionIndex: 0, isCorrect: true),
        QuizAnswerDraft(questionId: 'q2', selectedOptionIndex: 0, isCorrect: true),
        QuizAnswerDraft(questionId: 'q3', selectedOptionIndex: 1, isCorrect: false),
      ];

      // Initial level is Reading Explorer
      expect(repo.getProfile().level, '📖 Reading Explorer');

      // 1. Pass Story 1 with 1 mistake (2/3 correct) -> Should level up to Reading Star
      final res1 = await repo.submitQuizAnswers(
        submission: submission1,
        story: story1,
        answers: answers3,
        score: 2,
      );
      expect(res1.isQuizPassed, isTrue);
      expect(res1.didLevelUp, isTrue);
      expect(res1.newTier.title, 'Reading Star');
      expect(res1.distinctPassedBooksCount, 1);
      expect(repo.getProfile().level, '🌟 Reading Star');
      expect(repo.getProfile().badges.contains('🌟 Reading Star'), isTrue);

      // 2. Retake Story 1 with perfect score (3/3 correct) -> Should NOT level up again
      final res1Retake = await repo.submitQuizAnswers(
        submission: submission1,
        story: story1,
        answers: answers3,
        score: 3,
      );
      expect(res1Retake.isQuizPassed, isTrue);
      expect(res1Retake.didLevelUp, isFalse);
      expect(res1Retake.distinctPassedBooksCount, 1);
      expect(repo.getProfile().level, '🌟 Reading Star');

      // 3. Fail Story 2 with 2 mistakes (1/3 correct) -> Should NOT pass, should NOT level up
      final submission2 = ReadingSubmission(
        id: 'sub-2',
        studentId: 'student-1',
        bookId: story2.id,
        videoPath: 'path2',
        durationSeconds: 30,
        timeLimitSeconds: 60,
        isOvertime: false,
        status: 'uploaded',
      );
      final res2Fail = await repo.submitQuizAnswers(
        submission: submission2,
        story: story2,
        answers: answers3,
        score: 1,
      );
      expect(res2Fail.isQuizPassed, isFalse);
      expect(res2Fail.didLevelUp, isFalse);
      expect(res2Fail.distinctPassedBooksCount, 1);
      expect(repo.getProfile().level, '🌟 Reading Star');

      // 4. Pass Story 2 with 1 mistake (2/3 correct) -> Should level up to Reading Champion
      final res2Pass = await repo.submitQuizAnswers(
        submission: submission2,
        story: story2,
        answers: answers3,
        score: 2,
      );
      expect(res2Pass.isQuizPassed, isTrue);
      expect(res2Pass.didLevelUp, isTrue);
      expect(res2Pass.newTier.title, 'Reading Champion');
      expect(res2Pass.distinctPassedBooksCount, 2);
      expect(repo.getProfile().level, '🏆 Reading Champion');
      expect(repo.getProfile().badges.contains('🏆 Reading Champion'), isTrue);
    });

    test('skill emojis upgrade every 2 levels and cap at level 10 with no duplicate badge emojis', () {
      // Badge emojis: 📖, 🌟, 🏆, 🔍, 🧠, 👑, 💡, 🔎, 🏅, ✨
      final badgeEmojis = kAchievementTiers.map((t) => t.emoji).toSet();

      final skills = ['Reading', 'Vocabulary', 'Word Master', 'Comprehension'];
      final seenSkillEmojis = <String>{};

      for (final skill in skills) {
        for (var lvl = 1; lvl <= 12; lvl++) {
          final emoji = getSkillTierEmoji(skill, lvl);
          expect(emoji.isNotEmpty, isTrue);
          // Zero overlap with the 10 badge emojis
          expect(
            badgeEmojis.contains(emoji),
            isFalse,
            reason: '$skill at level $lvl used a badge emoji: $emoji',
          );
          seenSkillEmojis.add(emoji);
        }
      }

      // Exactly 20 unique skill emojis (5 stages * 4 skills)
      expect(seenSkillEmojis.length, 20);

      // Verify specific upgrade transitions every 2 levels
      // Reading: 📚 -> 👓 -> 🦅 -> 🚀 -> 🌌
      expect(getSkillTierEmoji('Reading', 1), '📚');
      expect(getSkillTierEmoji('Reading', 2), '📚');
      expect(getSkillTierEmoji('Reading', 3), '👓');
      expect(getSkillTierEmoji('Reading', 4), '👓');
      expect(getSkillTierEmoji('Reading', 5), '🦅');
      expect(getSkillTierEmoji('Reading', 6), '🦅');
      expect(getSkillTierEmoji('Reading', 7), '🚀');
      expect(getSkillTierEmoji('Reading', 8), '🚀');
      expect(getSkillTierEmoji('Reading', 9), '🌌');
      expect(getSkillTierEmoji('Reading', 10), '🌌');
      expect(getSkillTierEmoji('Reading', 25), '🌌'); // Capped above 10

      // Vocabulary: 🌱 -> 🌿 -> 🌳 -> 💎 -> ⚡
      expect(getSkillTierEmoji('Vocabulary', 1), '🌱');
      expect(getSkillTierEmoji('Vocabulary', 2), '🌱');
      expect(getSkillTierEmoji('Vocabulary', 3), '🌿');
      expect(getSkillTierEmoji('Vocabulary', 4), '🌿');
      expect(getSkillTierEmoji('Vocabulary', 5), '🌳');
      expect(getSkillTierEmoji('Vocabulary', 6), '🌳');
      expect(getSkillTierEmoji('Vocabulary', 7), '💎');
      expect(getSkillTierEmoji('Vocabulary', 8), '💎');
      expect(getSkillTierEmoji('Vocabulary', 9), '⚡');
      expect(getSkillTierEmoji('Vocabulary', 10), '⚡');
      expect(getSkillTierEmoji('Vocabulary', 50), '⚡'); // Capped above 10

      // Word Master: ✏️ -> 🧩 -> 🗝️ -> 🛡️ -> 🔮
      expect(getSkillTierEmoji('Word Master', 1), '✏️');
      expect(getSkillTierEmoji('Word Master', 2), '✏️');
      expect(getSkillTierEmoji('Word Master', 3), '🧩');
      expect(getSkillTierEmoji('Word Master', 4), '🧩');
      expect(getSkillTierEmoji('Word Master', 5), '🗝️');
      expect(getSkillTierEmoji('Word Master', 6), '🗝️');
      expect(getSkillTierEmoji('Word Master', 7), '🛡️');
      expect(getSkillTierEmoji('Word Master', 8), '🛡️');
      expect(getSkillTierEmoji('Word Master', 9), '🔮');
      expect(getSkillTierEmoji('Word Master', 10), '🔮');
      expect(getSkillTierEmoji('Word Master', 99), '🔮'); // Capped above 10

      // Comprehension: 👁️ -> 🧭 -> 🎯 -> 🔭 -> 🌠
      expect(getSkillTierEmoji('Comprehension', 1), '👁️');
      expect(getSkillTierEmoji('Comprehension', 2), '👁️');
      expect(getSkillTierEmoji('Comprehension', 3), '🧭');
      expect(getSkillTierEmoji('Comprehension', 4), '🧭');
      expect(getSkillTierEmoji('Comprehension', 5), '🎯');
      expect(getSkillTierEmoji('Comprehension', 6), '🎯');
      expect(getSkillTierEmoji('Comprehension', 7), '🔭');
      expect(getSkillTierEmoji('Comprehension', 8), '🔭');
      expect(getSkillTierEmoji('Comprehension', 9), '🌠');
      expect(getSkillTierEmoji('Comprehension', 10), '🌠');
      expect(getSkillTierEmoji('Comprehension', 100), '🌠'); // Capped above 10
    });
  });
}
