import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_models.dart';
import '../services/supabase_service.dart';

abstract class StudentRepository {
  StudentProfile getProfile();
  List<Story> getAssignedStories();
  Future<StudentProfile> getCurrentProfile();
  Future<List<Story>> getCurrentAssignedStories();
  Future<StudentProfile> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  });
  Future<ReadingSubmission> uploadReadingSubmission({
    required Story story,
    required Uint8List videoBytes,
    required String fileName,
    required int durationSeconds,
    required int timeLimitSeconds,
    required bool isOvertime,
  });
  Future<void> processReadingSubmission(String submissionId);
  Future<QuizSubmissionResult> submitQuizAnswers({
    required ReadingSubmission submission,
    required Story story,
    required List<QuizAnswerDraft> answers,
    required int score,
  });
  Future<List<StudentMessage>> getCurrentMessages();
  Future<void> markMessageRead(String messageId);
  Future<bool> hasAcceptedActiveSafetyAgreement();
  Future<void> acceptActiveSafetyAgreement();
  void clearCache();
}

class MockStudentRepository implements StudentRepository {
  StudentProfile _profile;
  final List<Story> _stories;
  final List<StudentMessage> _messages;
  final Set<String> _passedStoryIds = <String>{};

  MockStudentRepository({
    StudentProfile? profile,
    List<Story>? stories,
    List<StudentMessage>? messages,
  })  : _profile = profile ??
            StudentProfile(
              id: '',
              name: '',
              email: '',
              grade: '',
              section: '',
              level: kAchievementTiers.first.displayName,
              progressCurrent: 0,
              progressTotal: 0,
              daysStreak: 0,
              status: '',
              badges: [kAchievementTiers.first.displayName],
            ),
        _stories = stories ?? [],
        _messages = messages != null ? List.from(messages) : [];

  @override
  StudentProfile getProfile() => _profile;

  @override
  List<Story> getAssignedStories() => List.unmodifiable(_stories);

  @override
  Future<StudentProfile> getCurrentProfile() async => _profile;

  @override
  Future<List<Story>> getCurrentAssignedStories() async => getAssignedStories();

  @override
  Future<StudentProfile> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async => _profile;

  @override
  Future<ReadingSubmission> uploadReadingSubmission({
    required Story story,
    required Uint8List videoBytes,
    required String fileName,
    required int durationSeconds,
    required int timeLimitSeconds,
    required bool isOvertime,
  }) async {
    return ReadingSubmission(
      id: 'mock-submission',
      studentId: _profile.id,
      bookId: story.id,
      videoPath: 'mock/${story.id}/reading.webm',
      durationSeconds: durationSeconds,
      timeLimitSeconds: timeLimitSeconds,
      isOvertime: isOvertime,
      status: 'uploaded',
    );
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
    final mistakes = answers.length - score;
    final isQuizPassed = answers.isNotEmpty && mistakes <= 1;
    final currentTier = getTierByNameOrTitle(_profile.level);

    if (isQuizPassed) {
      _passedStoryIds.add(story.id);
    }

    final targetTier = getTierByPassedBooks(_passedStoryIds.length);
    final didLevelUp = isQuizPassed && targetTier.level > currentTier.level;

    if (didLevelUp || _profile.badges.isEmpty) {
      final updatedBadges = List<String>.from(_profile.badges);
      for (final tier in kAchievementTiers) {
        if (tier.level <= targetTier.level && !updatedBadges.contains(tier.displayName)) {
          updatedBadges.add(tier.displayName);
        }
      }
      _profile = _profile.copyWith(
        level: targetTier.displayName,
        badges: updatedBadges,
        progressCurrent: _passedStoryIds.length,
      );
    }

    return QuizSubmissionResult(
      didLevelUp: didLevelUp,
      newTier: didLevelUp ? targetTier : currentTier,
      previousTier: currentTier,
      isQuizPassed: isQuizPassed,
      score: score,
      totalQuestions: answers.length,
      distinctPassedBooksCount: _passedStoryIds.length,
    );
  }

  @override
  Future<List<StudentMessage>> getCurrentMessages() async {
    return List.unmodifiable(_messages);
  }

  @override
  Future<void> markMessageRead(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final current = _messages[index];
      _messages[index] = StudentMessage(
        id: current.id,
        senderName: current.senderName,
        title: current.title,
        body: current.body,
        createdAtLabel: current.createdAtLabel,
        isUnread: false,
        relatedSubmissionId: current.relatedSubmissionId,
        transcriptText: current.transcriptText,
        passageText: current.passageText,
      );
    }
  }

  @override
  Future<bool> hasAcceptedActiveSafetyAgreement() async => false;

  @override
  Future<void> acceptActiveSafetyAgreement() async {}

  @override
  void clearCache() {}
}

class SupabaseStudentRepository extends MockStudentRepository {
  List<Story>? _cachedStories;

  @override
  void clearCache() {
    _cachedStories = null;
  }
  @override
  Future<List<Story>> getCurrentAssignedStories() async {
    if (_cachedStories != null) return _cachedStories!;
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.getCurrentAssignedStories();
    }

    final studentProfile = await client
        .from('student_profiles')
        .select('grade_level,section_id')
        .eq('profile_id', user.id)
        .maybeSingle();
    final gradeLevel = studentProfile?['grade_level'] as String?;
    final sectionId = studentProfile?['section_id'] as String?;
    if (gradeLevel == null) return const [];

    var query = client
        .from('books')
        .select(
          'id,title,grade_level,passage_text,created_at,'
          'book_questions(id,question_text,options,correct_option_index,sort_order)',
        )
        .eq('status', 'published')
        .eq('grade_level', gradeLevel);

    if (sectionId != null) {
      query = query.or('section_id.eq.$sectionId,section_id.is.null');
    }

    final rows = await query.order('created_at');

    final stories = <Story>[];
    for (final row in rows) {
      List<QuizQuestion> questions = const [];
      final embeddedQuestions = row['book_questions'] as List<dynamic>?;
      if (embeddedQuestions != null && embeddedQuestions.isNotEmpty) {
        final sorted = embeddedQuestions
            .map((q) => q as Map<String, dynamic>)
            .toList()
          ..sort((a, b) {
            final aOrder = (a['sort_order'] as num?)?.toInt() ?? 0;
            final bOrder = (b['sort_order'] as num?)?.toInt() ?? 0;
            return aOrder.compareTo(bOrder);
          });
        questions = sorted
            .map<QuizQuestion>((qRow) {
              final rawOptions = qRow['options'] as List<dynamic>? ?? const [];
              return QuizQuestion(
                id: qRow['id']?.toString() ?? '',
                questionText: qRow['question_text'] as String? ?? '',
                options: rawOptions.map((o) => o.toString()).toList(),
                correctAnswerIndex:
                    (qRow['correct_option_index'] as num?)?.toInt() ?? 0,
              );
            })
            .where((q) =>
                q.questionText.trim().isNotEmpty &&
                q.options.length >= 2 &&
                q.correctAnswerIndex >= 0 &&
                q.correctAnswerIndex < q.options.length)
            .toList();
      } else {
        try {
          questions = await _getQuestionsForBook(row['id'] as String);
        } catch (_) {}
      }

      stories.add(
        Story(
          id: row['id'] as String,
          title: row['title'] as String? ?? 'Untitled Book',
          bookNumber: stories.length + 1,
          level: _levelFromGrade(row['grade_level'] as String?),
          text: row['passage_text'] as String? ?? '',
          questions: questions,
          isLocked: questions.isEmpty,
        ),
      );
    }

    _cachedStories = stories;
    return stories;
  }

  @override
  Future<StudentProfile> getCurrentProfile() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentProfile();

    final base = getProfile();
    final profile = await client
        .from('profiles')
        .select('email,full_name,avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    final studentProfile = await client
        .from('student_profiles')
        .select(
          'grade_level,current_skill_level,days_streak,section_id,reading_level,vocabulary_level,word_master_level,comprehension_level',
        )
        .eq('profile_id', user.id)
        .maybeSingle();

    String section = base.section;
    final sectionId = studentProfile?['section_id'] as String?;
    if (sectionId != null) {
      final sectionRow = await client
          .from('sections')
          .select('name')
          .eq('id', sectionId)
          .maybeSingle();
      section = sectionRow?['name'] as String? ?? section;
    }

    final avatarUrl = await _getSignedAvatarUrl(
      profile?['avatar_url'] as String?,
    );
    final stats = await _getStudentJourneyStats(user.id);

    return StudentProfile(
      id: user.id,
      name: profile?['full_name'] as String? ?? base.name,
      email: profile?['email'] as String? ?? user.email ?? base.email,
      grade: studentProfile?['grade_level'] as String? ?? base.grade,
      section: section,
      level: (studentProfile?['current_skill_level'] as String?)?.trim().isNotEmpty == true
          ? studentProfile!['current_skill_level'] as String
          : (base.level.isNotEmpty ? base.level : kAchievementTiers.first.displayName),
      progressCurrent: stats.completedBooks,
      progressTotal: stats.totalAssignedBooks,
      daysStreak:
          (studentProfile?['days_streak'] as num?)?.toInt() ?? base.daysStreak,
      status: base.status,
      badges: stats.badges.isNotEmpty
          ? stats.badges
          : [kAchievementTiers.first.displayName],
      avatarUrl: avatarUrl,
      readingLevel:
          (studentProfile?['reading_level'] as num?)?.toInt() ??
          base.readingLevel,
      vocabularyLevel:
          (studentProfile?['vocabulary_level'] as num?)?.toInt() ??
          base.vocabularyLevel,
      wordMasterLevel:
          (studentProfile?['word_master_level'] as num?)?.toInt() ??
          base.wordMasterLevel,
      comprehensionLevel:
          (studentProfile?['comprehension_level'] as num?)?.toInt() ??
          base.comprehensionLevel,
    );
  }

  @override
  Future<StudentProfile> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentProfile();

    final extension = _extensionFor(fileName);
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _contentTypeFor(extension)),
        );
    await client
        .from('profiles')
        .update({'avatar_url': path})
        .eq('id', user.id);

    return getCurrentProfile();
  }

  @override
  Future<ReadingSubmission> uploadReadingSubmission({
    required Story story,
    required Uint8List videoBytes,
    required String fileName,
    required int durationSeconds,
    required int timeLimitSeconds,
    required bool isOvertime,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.uploadReadingSubmission(
        story: story,
        videoBytes: videoBytes,
        fileName: fileName,
        durationSeconds: durationSeconds,
        timeLimitSeconds: timeLimitSeconds,
        isOvertime: isOvertime,
      );
    }

    String? submissionId;
    try {
      final inserted = await client
          .from('reading_submissions')
          .insert({
            'student_id': user.id,
            'book_id': story.id,
            'book_title_snapshot': story.title,
            'passage_text_snapshot': story.text,
            'duration_seconds': durationSeconds,
            'time_limit_seconds': timeLimitSeconds,
            'is_overtime': isOvertime,
            'status': 'uploading',
          })
          .select('id')
          .single();

      submissionId = inserted['id'] as String;
      final extension = _videoExtensionFor(fileName);
      final videoPath = '${user.id}/$submissionId/reading.$extension';

      await client.storage
          .from('reading-videos')
          .uploadBinary(
            videoPath,
            videoBytes,
            fileOptions: FileOptions(
              contentType: _videoContentTypeFor(extension),
              upsert: true,
            ),
          );

      await client
          .from('reading_submissions')
          .update({'video_path': videoPath, 'status': 'uploaded'})
          .eq('id', submissionId)
          .eq('student_id', user.id);

      return ReadingSubmission(
        id: submissionId,
        studentId: user.id,
        bookId: story.id,
        videoPath: videoPath,
        durationSeconds: durationSeconds,
        timeLimitSeconds: timeLimitSeconds,
        isOvertime: isOvertime,
        status: 'uploaded',
      );
    } catch (_) {
      if (submissionId != null) {
        try {
          await client
              .from('reading_submissions')
              .update({'status': 'failed'})
              .eq('id', submissionId)
              .eq('student_id', user.id);
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<void> processReadingSubmission(String submissionId) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.processReadingSubmission(submissionId);
    }

    try {
      await client.functions.invoke(
        'process-reading-submission',
        body: {'submission_id': submissionId},
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error'].toString());
      }
      throw Exception(error.toString());
    }
  }

  @override
  Future<QuizSubmissionResult> submitQuizAnswers({
    required ReadingSubmission submission,
    required Story story,
    required List<QuizAnswerDraft> answers,
    required int score,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.submitQuizAnswers(
        submission: submission,
        story: story,
        answers: answers,
        score: score,
      );
    }

    final row = await client
        .from('reading_submissions')
        .select('status')
        .eq('id', submission.id)
        .eq('student_id', user.id)
        .maybeSingle();
    if (row == null) {
      throw Exception('No matching reading submission was found.');
    }

    // If not already submitted, record answers & mark submitted
    if (row['status'] != 'submitted') {
      await client
          .from('quiz_answers')
          .delete()
          .eq('submission_id', submission.id);

      final answerRows = answers.map((answer) {
        final questionId = answer.questionId?.trim();
        return {
          'submission_id': submission.id,
          if (questionId != null && questionId.isNotEmpty)
            'question_id': questionId,
          'selected_option_index': answer.selectedOptionIndex,
          'is_correct': answer.isCorrect,
        };
      }).toList();

      if (answerRows.isNotEmpty) {
        await client.from('quiz_answers').insert(answerRows);
      }

      await client
          .from('reading_submissions')
          .update({
            'status': 'submitted',
            'submitted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', submission.id)
          .eq('student_id', user.id);

      try {
        await client.from('activity_logs').insert({
          'actor_id': user.id,
          'actor_role': 'student',
          'action': 'submitted_reading_quiz',
          'entity_type': 'reading_submission',
          'entity_id': submission.id,
          'metadata': {
            'book_id': story.id,
            'book_title': story.title,
            'score': score,
            'total_questions': answers.length,
          },
        });
      } catch (_) {}
    }

    // 1. Calculate if the current quiz is passed (at most 1 mistake)
    final mistakes = answers.length - score;
    final isCurrentQuizPassed = answers.isNotEmpty && mistakes <= 1;

    // 2. Fetch current student profile skill level
    final studentProfileRow = await client
        .from('student_profiles')
        .select('current_skill_level')
        .eq('profile_id', user.id)
        .maybeSingle();
    final currentSkillLevelName =
        studentProfileRow?['current_skill_level'] as String? ?? 'Reading Explorer';
    final previousTier = getTierByNameOrTitle(currentSkillLevelName);

    // 3. Find distinct books the student has passed with <= 1 mistake
    final distinctPassedBookIds = <String>{};
    if (isCurrentQuizPassed) {
      distinctPassedBookIds.add(story.id);
    }

    try {
      final pastSubmissions = await client
          .from('reading_submissions')
          .select('id,book_id')
          .eq('student_id', user.id)
          .inFilter('status', ['submitted', 'processed']);

      final pastSubList = (pastSubmissions as List<dynamic>? ?? const []);
      final subIds = pastSubList
          .map((s) => s['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty && id != submission.id)
          .toList();

      if (subIds.isNotEmpty) {
        final pastAnswers = await client
            .from('quiz_answers')
            .select('submission_id,is_correct')
            .inFilter('submission_id', subIds);

        final answersMap = <String, List<bool>>{};
        for (final item in (pastAnswers as List<dynamic>? ?? const [])) {
          final sId = item['submission_id']?.toString() ?? '';
          final isCorr = item['is_correct'] == true;
          if (sId.isNotEmpty) {
            answersMap.putIfAbsent(sId, () => []).add(isCorr);
          }
        }

        final subToBookMap = <String, String>{};
        for (final s in pastSubList) {
          final sId = s['id']?.toString() ?? '';
          final bId = s['book_id']?.toString() ?? '';
          if (sId.isNotEmpty && bId.isNotEmpty) {
            subToBookMap[sId] = bId;
          }
        }

        for (final entry in answersMap.entries) {
          final list = entry.value;
          final total = list.length;
          final correct = list.where((c) => c).length;
          if (total > 0 && (total - correct <= 1)) {
            final bookId = subToBookMap[entry.key];
            if (bookId != null && bookId.isNotEmpty) {
              distinctPassedBookIds.add(bookId);
            }
          }
        }
      }
    } catch (_) {}

    // 4. Determine target tier based on total distinct passed books
    final targetTier = getTierByPassedBooks(distinctPassedBookIds.length);
    final didLevelUp = isCurrentQuizPassed && targetTier.level > previousTier.level;

    if (didLevelUp) {
      try {
        await client
            .from('student_profiles')
            .update({'current_skill_level': targetTier.displayName})
            .eq('profile_id', user.id);
      } catch (_) {}

      // Ensure all unlocked tier badges exist and are assigned to the student
      try {
        for (final tier in kAchievementTiers) {
          if (tier.level <= targetTier.level) {
            final existingBadge = await client
                .from('badges')
                .select('id')
                .eq('name', tier.displayName)
                .maybeSingle();

            String badgeId;
            if (existingBadge != null) {
              badgeId = existingBadge['id'] as String;
            } else {
              final insertedBadge = await client
                  .from('badges')
                  .insert({
                    'name': tier.displayName,
                    'description': 'Passed ${tier.requiredBooksPassed} books with passing quiz score.',
                  })
                  .select('id')
                  .single();
              badgeId = insertedBadge['id'] as String;
            }

            final existingAward = await client
                .from('student_badges')
                .select('student_id')
                .eq('student_id', user.id)
                .eq('badge_id', badgeId)
                .maybeSingle();

            if (existingAward == null) {
              await client.from('student_badges').insert({
                'student_id': user.id,
                'badge_id': badgeId,
              });
            }
          }
        }

        await client.from('activity_logs').insert({
          'actor_id': user.id,
          'actor_role': 'student',
          'action': 'student_unlocked_achievement',
          'entity_type': 'badge',
          'metadata': {
            'level': targetTier.level,
            'achievement': targetTier.displayName,
            'passed_books_count': distinctPassedBookIds.length,
          },
        });
      } catch (_) {}
    }

    return QuizSubmissionResult(
      didLevelUp: didLevelUp,
      newTier: didLevelUp ? targetTier : previousTier,
      previousTier: previousTier,
      isQuizPassed: isCurrentQuizPassed,
      score: score,
      totalQuestions: answers.length,
      distinctPassedBooksCount: distinctPassedBookIds.length,
    );
  }

  @override
  Future<List<StudentMessage>> getCurrentMessages() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentMessages();

    final rows = await client
        .from('messages')
        .select(
          'id,title,body,created_at,read_at,related_submission_id,profiles!messages_sender_id_fkey(full_name)',
        )
        .eq('recipient_id', user.id)
        .order('created_at', ascending: false);

    final messages = <StudentMessage>[];
    for (final row in rows) {
      final sender = _embeddedMap(row['profiles']);
      final relatedSubmissionId = row['related_submission_id'] as String?;
      final submissionText = await _getSubmissionTextForMessage(
        relatedSubmissionId,
      );
      messages.add(
        StudentMessage(
          id: row['id'] as String? ?? '',
          senderName: sender['full_name'] as String? ?? 'ReadBloom',
          title: row['title'] as String? ?? 'Message',
          body: row['body'] as String? ?? '',
          createdAtLabel: _dateLabel(row['created_at']),
          isUnread: row['read_at'] == null,
          relatedSubmissionId: relatedSubmissionId,
          transcriptText: submissionText.transcript,
          passageText: submissionText.passage,
        ),
      );
    }
    return messages;
  }

  Future<_MessageSubmissionText> _getSubmissionTextForMessage(
    String? submissionId,
  ) async {
    final client = SupabaseService.client;
    if (client == null || submissionId == null || submissionId.isEmpty) {
      return const _MessageSubmissionText(transcript: '', passage: '');
    }

    try {
      final row = await client
          .from('reading_submissions')
          .select('passage_text_snapshot,transcript_results(raw_transcript)')
          .eq('id', submissionId)
          .maybeSingle();
      if (row == null) {
        return const _MessageSubmissionText(transcript: '', passage: '');
      }
      final transcript = _embeddedMap(row['transcript_results']);
      return _MessageSubmissionText(
        transcript: transcript['raw_transcript'] as String? ?? '',
        passage: row['passage_text_snapshot'] as String? ?? '',
      );
    } catch (_) {
      return const _MessageSubmissionText(transcript: '', passage: '');
    }
  }

  @override
  Future<void> markMessageRead(String messageId) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.markMessageRead(messageId);
    }
    await client
        .from('messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', messageId)
        .eq('recipient_id', user.id);
  }

  @override
  Future<bool> hasAcceptedActiveSafetyAgreement() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return false;

    final agreement = await client
        .from('safety_agreements')
        .select('id')
        .eq('is_active', true)
        .maybeSingle();
    final agreementId = agreement?['id'] as String?;
    if (agreementId == null) return true;

    final acceptance = await client
        .from('profile_safety_acceptances')
        .select('profile_id')
        .eq('profile_id', user.id)
        .eq('agreement_id', agreementId)
        .maybeSingle();

    return acceptance != null;
  }

  @override
  Future<void> acceptActiveSafetyAgreement() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    final agreement = await client
        .from('safety_agreements')
        .select('id')
        .eq('is_active', true)
        .maybeSingle();
    final agreementId = agreement?['id'] as String?;
    if (agreementId == null) return;

    await client.from('profile_safety_acceptances').upsert({
      'profile_id': user.id,
      'agreement_id': agreementId,
      'accepted_from': 'readbloom_student_app',
    });
  }

  Future<List<QuizQuestion>> _getQuestionsForBook(String bookId) async {
    final client = SupabaseService.client;
    if (client == null) return const [];

    final rows = await client
        .from('book_questions')
        .select('id,question_text,options,correct_option_index,sort_order')
        .eq('book_id', bookId)
        .order('sort_order');

    return rows
        .map<QuizQuestion>((row) {
          final rawOptions = row['options'] as List<dynamic>? ?? const [];
          return QuizQuestion(
            id: row['id'] as String?,
            questionText: row['question_text'] as String? ?? '',
            options: rawOptions.map((option) => option.toString()).toList(),
            correctAnswerIndex:
                (row['correct_option_index'] as num?)?.toInt() ?? 0,
          );
        })
        .where((question) {
          return question.questionText.trim().isNotEmpty &&
              question.options.length >= 2 &&
              question.correctAnswerIndex >= 0 &&
              question.correctAnswerIndex < question.options.length;
        })
        .toList();
  }

  Future<_StudentJourneyStats> _getStudentJourneyStats(String userId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return const _StudentJourneyStats(
        completedBooks: 0,
        totalAssignedBooks: 0,
        badges: [],
      );
    }

    try {
      final assigned = await getCurrentAssignedStories();
      final rows = await client
          .from('reading_submissions')
          .select('book_id')
          .eq('student_id', userId)
          .inFilter('status', ['submitted', 'processed']);
      final completedBooks = rows
          .map<String>((row) => row['book_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .length;

      final badgeRows = await client
          .from('student_badges')
          .select('badges(name)')
          .eq('student_id', userId)
          .order('awarded_at', ascending: false);
      final badges = badgeRows
          .map<String>((row) {
            final badge = _embeddedMap(row['badges']);
            return badge['name'] as String? ?? '';
          })
          .where((badge) => badge.isNotEmpty)
          .toList();

      final totalBooks = assigned.length;
      final finalCompleted = totalBooks > 0
          ? completedBooks.clamp(0, totalBooks)
          : completedBooks;

      final finalBadges = badges.isNotEmpty
          ? badges
          : [kAchievementTiers.first.displayName];

      return _StudentJourneyStats(
        completedBooks: finalCompleted,
        totalAssignedBooks: totalBooks,
        badges: finalBadges,
      );
    } catch (_) {
      return _StudentJourneyStats(
        completedBooks: 0,
        totalAssignedBooks: 0,
        badges: [kAchievementTiers.first.displayName],
      );
    }
  }

  Map<String, dynamic> _embeddedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return <String, dynamic>{};
  }

  String _dateLabel(dynamic rawDate) {
    if (rawDate == null) return '';
    final str = rawDate.toString().trim();
    if (str.isEmpty) return '';
    final date = DateTime.tryParse(str);
    if (date == null) return str;

    // Convert UTC timestamps to Philippine Standard Time (UTC+8)
    final phTime = (str.contains('T') || str.contains(':') || date.isUtc)
        ? date.toUtc().add(const Duration(hours: 8))
        : date.toLocal();

    final year = phTime.year.toString().padLeft(4, '0');
    final month = phTime.month.toString().padLeft(2, '0');
    final day = phTime.day.toString().padLeft(2, '0');

    if (str.contains('T') || str.contains(':')) {
      final hour12 = phTime.hour == 0
          ? 12
          : (phTime.hour > 12 ? phTime.hour - 12 : phTime.hour);
      final hourStr = hour12.toString().padLeft(2, '0');
      final minuteStr = phTime.minute.toString().padLeft(2, '0');
      final period = phTime.hour >= 12 ? 'PM' : 'AM';
      return '$year-$month-$day $hourStr:$minuteStr $period';
    }

    return '$year-$month-$day';
  }

  int _levelFromGrade(String? grade) {
    final match = RegExp(r'\d+').firstMatch(grade ?? '');
    return int.tryParse(match?.group(0) ?? '') ?? 1;
  }

  Future<String> _getSignedAvatarUrl(String? avatarPath) async {
    if (avatarPath == null || avatarPath.trim().isEmpty) return '';
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }

    final client = SupabaseService.client;
    if (client == null) return '';
    return client.storage.from('avatars').createSignedUrl(avatarPath, 3600);
  }

  String _extensionFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'png' || extension == 'webp') return extension;
    return 'jpg';
  }

  String _contentTypeFor(String extension) {
    if (extension == 'png') return 'image/png';
    if (extension == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  String _videoExtensionFor(String fileName) {
    final cleanName = fileName.split('?').first;
    final extension = cleanName.contains('.')
        ? cleanName.split('.').last.toLowerCase()
        : '';
    if (extension == 'mp4' ||
        extension == 'webm' ||
        extension == 'mov' ||
        extension == 'm4v') {
      return extension;
    }
    return 'webm';
  }

  String _videoContentTypeFor(String extension) {
    if (extension == 'mp4' || extension == 'm4v') return 'video/mp4';
    if (extension == 'mov') return 'video/quicktime';
    return 'video/webm';
  }
}

class _StudentJourneyStats {
  final int completedBooks;
  final int totalAssignedBooks;
  final List<String> badges;

  const _StudentJourneyStats({
    required this.completedBooks,
    required this.totalAssignedBooks,
    required this.badges,
  });
}

class _MessageSubmissionText {
  final String transcript;
  final String passage;

  const _MessageSubmissionText({
    required this.transcript,
    required this.passage,
  });
}
