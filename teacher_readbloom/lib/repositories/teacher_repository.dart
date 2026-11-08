import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/teacher_models.dart';
import '../services/supabase_service.dart';

class TeacherAccount {
  final String name;
  final String school;
  final String email;
  final String avatarUrl;
  final DateTime? lastSignInAt;

  const TeacherAccount({
    required this.name,
    required this.school,
    required this.email,
    this.avatarUrl = '',
    this.lastSignInAt,
  });
}

abstract class TeacherRepository {
  TeacherAccount getAccount();
  Future<TeacherAccount> getCurrentAccount();
  Future<TeacherAccount> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  });
  Future<List<String>> getAssignedSections();
  List<ClassStats> getClasses();
  List<StudentProgress> getStudents();
  List<StudentActivity> getActivities();
  Map<String, EvaluationMetrics> getEvaluations();
  List<Book> getBooks();
  Future<List<ClassStats>> getCurrentClasses();
  Future<List<StudentProgress>> getCurrentStudents();
  Future<List<StudentActivity>> getCurrentActivities();
  Future<Map<String, List<ReadingSubmissionReview>>> getCurrentReadingReviews();
  Future<List<Book>> getCurrentBooks();
  Future<void> sendFeedback({
    required ReadingSubmissionReview submission,
    required String studentId,
    required String feedback,
  });
  Future<void> updateStudentSkillLevel({
    required String studentId,
    required String skillLevel,
  });
  Future<void> updateStudentSkillLevels({
    required String studentId,
    required int readingLevel,
    required int vocabularyLevel,
    required int wordMasterLevel,
    required int comprehensionLevel,
  });
  Future<void> awardBadgeToStudent({
    required String studentId,
    required String badgeName,
  });
  Future<GeneratedBookDraft> generateBookDraft({
    required String prompt,
    required String grade,
    required String section,
    required int quizCount,
    required String passageLength,
  });
  Future<Book> addBook({
    required String title,
    required String grade,
    required String section,
    required String content,
    required List<BookQuestionInput> questions,
  });
  Future<String> getSignedVideoUrl(String videoPath);
  void clearCache();
}

class MockTeacherRepository implements TeacherRepository {
  final TeacherAccount _account = const TeacherAccount(
    name: '',
    school: '',
    email: '',
  );

  final List<ClassStats> _classes = [];

  final List<StudentProgress> _students = [];

  final List<StudentActivity> _activities = [];

  final Map<String, EvaluationMetrics> _evaluations = {};

  final List<Book> _books = [];

  @override
  TeacherAccount getAccount() => _account;

  @override
  Future<TeacherAccount> getCurrentAccount() async => _account;

  @override
  Future<TeacherAccount> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async => _account;

  @override
  Future<List<String>> getAssignedSections() async => const [];

  @override
  List<ClassStats> getClasses() => List.unmodifiable(_classes);

  @override
  List<StudentProgress> getStudents() => List.unmodifiable(_students);

  @override
  List<StudentActivity> getActivities() => List.unmodifiable(_activities);

  @override
  Map<String, EvaluationMetrics> getEvaluations() => Map.of(_evaluations);

  @override
  List<Book> getBooks() => List.unmodifiable(_books);

  @override
  Future<List<Book>> getCurrentBooks() async => getBooks();

  @override
  Future<List<ClassStats>> getCurrentClasses() async => getClasses();

  @override
  Future<List<StudentProgress>> getCurrentStudents() async => getStudents();

  @override
  Future<List<StudentActivity>> getCurrentActivities() async => getActivities();

  @override
  Future<Map<String, List<ReadingSubmissionReview>>>
  getCurrentReadingReviews() async {
    return const {};
  }

  @override
  Future<void> sendFeedback({
    required ReadingSubmissionReview submission,
    required String studentId,
    required String feedback,
  }) async {}

  @override
  Future<void> updateStudentSkillLevel({
    required String studentId,
    required String skillLevel,
  }) async {}

  @override
  Future<void> updateStudentSkillLevels({
    required String studentId,
    required int readingLevel,
    required int vocabularyLevel,
    required int wordMasterLevel,
    required int comprehensionLevel,
  }) async {}

  @override
  Future<void> awardBadgeToStudent({
    required String studentId,
    required String badgeName,
  }) async {}

  @override
  Future<GeneratedBookDraft> generateBookDraft({
    required String prompt,
    required String grade,
    required String section,
    required int quizCount,
    required String passageLength,
  }) async {
    final count = quizCount.clamp(1, 3);
    return GeneratedBookDraft(
      title: 'Generated $grade Reading',
      passageText:
          'Maya helped her classmates read a short story about ${prompt.trim()}. '
          'They talked about the lesson and shared what they learned.',
      questions: List.generate(
        count,
        (index) => BookQuestionInput(
          questionText: 'Generated question ${index + 1}?',
          options: const [
            'First choice',
            'Second choice',
            'Third choice',
            'Fourth choice',
          ],
          correctOptionIndex: 0,
        ),
      ),
    );
  }

  @override
  Future<Book> addBook({
    required String title,
    required String grade,
    required String section,
    required String content,
    required List<BookQuestionInput> questions,
  }) async {
    final newBook = Book(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      grade: grade,
      section: section,
      content: content,
      questions: questions
          .asMap()
          .entries
          .map(
            (entry) => BookQuestion(
              id: 'question_${DateTime.now().microsecondsSinceEpoch}_${entry.key}',
              questionText: entry.value.questionText,
              options: entry.value.options,
              correctOptionIndex: entry.value.correctOptionIndex,
            ),
          )
          .toList(),
    );
    _books.add(newBook);
    return newBook;
  }

  @override
  Future<String> getSignedVideoUrl(String videoPath) async =>
      'https://example.com/mock_video.mp4';

  @override
  void clearCache() {}
}

class SupabaseTeacherRepository extends MockTeacherRepository {
  Map<String, List<ReadingSubmissionReview>>? _cachedReviews;
  List<StudentProgress>? _cachedStudents;
  List<Book>? _cachedBooks;
  final Map<String, String> _signedVideoUrls = {};

  @override
  void clearCache() {
    _cachedReviews = null;
    _cachedStudents = null;
    _cachedBooks = null;
    _signedVideoUrls.clear();
  }
  @override
  Future<TeacherAccount> getCurrentAccount() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentAccount();

    final base = getAccount();
    final profile = await client
        .from('profiles')
        .select('email,full_name,avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    final teacherProfile = await client
        .from('teacher_profiles')
        .select('school_id')
        .eq('profile_id', user.id)
        .maybeSingle();

    String school = base.school;
    final schoolId = teacherProfile?['school_id'] as String?;
    if (schoolId != null) {
      final schoolRow = await client
          .from('schools')
          .select('name')
          .eq('id', schoolId)
          .maybeSingle();
      school = schoolRow?['name'] as String? ?? school;
    }

    final avatarUrl = await _getSignedAvatarUrl(
      profile?['avatar_url'] as String?,
    );

    DateTime? lastSignInAt;
    final rawLastSignIn = user.lastSignInAt;
    if (rawLastSignIn != null && rawLastSignIn.trim().isNotEmpty) {
      lastSignInAt = DateTime.tryParse(rawLastSignIn.trim());
    }

    return TeacherAccount(
      name: profile?['full_name'] as String? ?? base.name,
      school: school,
      email: profile?['email'] as String? ?? user.email ?? base.email,
      avatarUrl: avatarUrl,
      lastSignInAt: lastSignInAt,
    );
  }

  @override
  Future<TeacherAccount> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentAccount();

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

    return getCurrentAccount();
  }

  @override
  Future<List<String>> getAssignedSections() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const [];

    final rows = await client
        .from('teacher_sections')
        .select('sections(grade_level,name)')
        .eq('teacher_id', user.id);

    return rows
        .map<String>((row) {
          final section = row['sections'] as Map<String, dynamic>?;
          if (section == null) return '';
          final grade = section['grade_level'] as String? ?? '';
          final name = section['name'] as String? ?? '';
          return '$grade - $name'.trim();
        })
        .where((label) => label.isNotEmpty)
        .toList();
  }

  @override
  Future<List<StudentProgress>> getCurrentStudents() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentStudents();

    final rows = await client
        .from('student_profiles')
        .select(
          'profile_id,grade_level,current_skill_level,reading_level,vocabulary_level,word_master_level,comprehension_level,profiles(full_name,email,avatar_url,status),sections(name)',
        )
        .order('grade_level');

    final submissionsByStudent =
        _cachedReviews ?? await getCurrentReadingReviews();
    _cachedReviews = submissionsByStudent;

    final allBadgesMap = <String, List<String>>{};
    try {
      final badgeRows = await client
          .from('student_badges')
          .select('student_id,badges(name)');
      for (final b in (badgeRows as List<dynamic>? ?? const [])) {
        final bMap = b as Map<String, dynamic>;
        final sId = bMap['student_id']?.toString() ?? '';
        final badgeInfo = bMap['badges'] as Map<String, dynamic>?;
        final badgeName = badgeInfo?['name'] as String?;
        if (sId.isNotEmpty && badgeName != null && badgeName.isNotEmpty) {
          allBadgesMap.putIfAbsent(sId, () => []).add(badgeName);
        }
      }
    } catch (_) {}

    final students = <StudentProgress>[];
    for (final row in rows) {
      final profile = _embeddedMap(row['profiles']);
      final section = _embeddedMap(row['sections']);
      final id = row['profile_id'] as String? ?? '';
      if (id.isEmpty) continue;
      final reviews = submissionsByStudent[id] ?? const [];
      final submittedCount = reviews
          .where((review) => review.status == 'submitted')
          .length;
      final accuracyValues = reviews
          .map((review) => review.readingAccuracy)
          .whereType<double>()
          .toList();
      final avgAccuracy = accuracyValues.isEmpty
          ? 0.0
          : accuracyValues.reduce((a, b) => a + b) / accuracyValues.length;
      final status = _statusForAccuracy(avgAccuracy, submittedCount);

      final badges = allBadgesMap[id] ?? const [];

      final avatarPath = profile['avatar_url'] as String?;
      final avatarUrl = (avatarPath != null && avatarPath.trim().isNotEmpty)
          ? await _getSignedAvatarUrl(avatarPath)
          : '';

      students.add(
        StudentProgress(
          id: id,
          name: profile['full_name'] as String? ?? 'Unnamed Student',
          readingAccuracy: avgAccuracy,
          vocabularyLevel: avgAccuracy,
          progressCurrent: submittedCount,
          progressTotal: reviews.length > submittedCount
              ? reviews.length
              : submittedCount,
          status: status,
          badges: badges,
          grade: row['grade_level'] as String? ?? '',
          section: section['name'] as String? ?? '',
          avatarUrl: avatarUrl,
          skillLevel:
              row['current_skill_level'] as String? ?? 'Reading Explorer',
          readingLevel: (row['reading_level'] as num?)?.toInt() ?? 1,
          vocabularySkillLevel: (row['vocabulary_level'] as num?)?.toInt() ?? 1,
          wordMasterLevel: (row['word_master_level'] as num?)?.toInt() ?? 1,
          comprehensionLevel:
              (row['comprehension_level'] as num?)?.toInt() ?? 1,
        ),
      );
    }
    _cachedStudents = students;
    return students;
  }

  @override
  Future<List<ClassStats>> getCurrentClasses() async {
    final students = _cachedStudents ?? await getCurrentStudents();
    final books = _cachedBooks ?? await getCurrentBooks();
    final byGrade = <String, List<StudentProgress>>{};
    for (final student in students) {
      byGrade.putIfAbsent(student.grade, () => []).add(student);
    }

    return byGrade.entries.map((entry) {
      final gradeStudents = entry.value;
      final completed = gradeStudents
          .where((student) => student.progressCurrent > 0)
          .length;
      final lessons = books.where((book) => book.grade == entry.key).length;
      return ClassStats(
        grade: entry.key,
        totalStudents: gradeStudents.length,
        completionRate: gradeStudents.isEmpty
            ? 0
            : completed / gradeStudents.length,
        totalLessons: lessons,
      );
    }).toList()..sort((a, b) => a.grade.compareTo(b.grade));
  }

  @override
  Future<List<StudentActivity>> getCurrentActivities() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentActivities();

    final rows = await client
        .from('reading_submissions')
        .select(
          'id,student_id,book_title_snapshot,status,submitted_at,created_at,profiles(full_name)',
        )
        .inFilter('status', ['submitted', 'processed'])
        .order('created_at', ascending: false)
        .limit(50);

    return rows.map<StudentActivity>((row) {
      final profile = _embeddedMap(row['profiles']);
      return StudentActivity(
        id: row['id'] as String? ?? '',
        studentName: profile['full_name'] as String? ?? 'Student',
        activityTitle: 'Read: ${row['book_title_snapshot'] ?? 'Untitled Book'}',
        score: row['status'] == 'submitted' ? 1 : 0,
        date: _dateLabel(row['submitted_at'] ?? row['created_at']),
      );
    }).toList();
  }

  @override
  Future<Map<String, List<ReadingSubmissionReview>>>
  getCurrentReadingReviews() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.getCurrentReadingReviews();
    }

    final rows = await client
        .from('reading_submissions')
        .select(
          'id,student_id,book_title_snapshot,passage_text_snapshot,video_path,duration_seconds,status,submitted_at,created_at,'
          'transcript_results(raw_transcript,alignment_json,overall_accuracy,suggested_remarks_json,suggested_omission_count,suggested_repetition_count,suggested_self_correction_count,suggested_mispronunciation_count),'
          'quiz_answers(is_correct),'
          'teacher_feedback(feedback_text,created_at)',
        )
        .inFilter('status', ['submitted', 'processed'])
        .order('created_at', ascending: false);

    final result = <String, List<ReadingSubmissionReview>>{};
    for (final row in rows) {
      final studentId = row['student_id'] as String? ?? '';
      if (studentId.isEmpty) continue;
      final videoPath = row['video_path'] as String? ?? '';
      final transcript = _embeddedMap(row['transcript_results']);
      final quizRows = _embeddedList(row['quiz_answers']);
      final quizTotal = quizRows.length;
      final quizScore = quizRows.where((answer) {
        final answerRow = answer as Map<String, dynamic>;
        return answerRow['is_correct'] == true;
      }).length;
      final feedbackRows = _embeddedList(row['teacher_feedback']);
      String? latestFeedbackText;
      if (feedbackRows.isNotEmpty) {
        final sortedFeedback = List.from(feedbackRows);
        sortedFeedback.sort((a, b) {
          final aCreated =
              (a as Map<String, dynamic>)['created_at']?.toString() ?? '';
          final bCreated =
              (b as Map<String, dynamic>)['created_at']?.toString() ?? '';
          return bCreated.compareTo(aCreated);
        });
        latestFeedbackText =
            (sortedFeedback.first as Map<String, dynamic>)['feedback_text']
                ?.toString();
      }

      final review = ReadingSubmissionReview(
        id: row['id'] as String? ?? '',
        studentId: studentId,
        bookTitle: row['book_title_snapshot'] as String? ?? 'Untitled Book',
        passageText: row['passage_text_snapshot'] as String? ?? '',
        status: row['status'] as String? ?? '',
        submittedAtLabel: _dateLabel(row['submitted_at'] ?? row['created_at']),
        videoPath: videoPath,
        videoUrl: _signedVideoUrls[videoPath] ?? '',
        durationSeconds: (row['duration_seconds'] as num?)?.toInt() ?? 0,
        rawTranscript: transcript['raw_transcript'] as String? ?? '',
        alignment: _alignmentFromJson(transcript['alignment_json']),
        readingAccuracy: _toDouble(transcript['overall_accuracy']),
        quizScore: quizScore,
        quizTotal: quizTotal,
        suggestedRemarks: _suggestedRemarksFromJson(
          transcript['suggested_remarks_json'],
          omissionCount: (transcript['suggested_omission_count'] as num?)
              ?.toInt(),
          repetitionCount: (transcript['suggested_repetition_count'] as num?)
              ?.toInt(),
          selfCorrectionCount:
              (transcript['suggested_self_correction_count'] as num?)?.toInt(),
          mispronunciationCount:
              (transcript['suggested_mispronunciation_count'] as num?)?.toInt(),
        ),
        feedbackText: latestFeedbackText,
      );
      result.putIfAbsent(studentId, () => []).add(review);
    }
    _cachedReviews = result;
    return result;
  }

  @override
  Future<void> sendFeedback({
    required ReadingSubmissionReview submission,
    required String studentId,
    required String feedback,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.sendFeedback(
        submission: submission,
        studentId: studentId,
        feedback: feedback,
      );
    }

    await client.from('teacher_feedback').insert({
      'submission_id': submission.id,
      'teacher_id': user.id,
      'student_id': studentId,
      'feedback_text': feedback,
    });
    await client.from('messages').insert({
      'recipient_id': studentId,
      'sender_id': user.id,
      'type': 'teacher_feedback',
      'title': 'Reading feedback: ${submission.bookTitle}',
      'body': feedback,
      'related_submission_id': submission.id,
    });
    try {
      await client.from('activity_logs').insert({
        'actor_id': user.id,
        'actor_role': 'teacher',
        'action': 'sent_teacher_feedback',
        'entity_type': 'reading_submission',
        'entity_id': submission.id,
        'metadata': {
          'student_id': studentId,
          'book_title': submission.bookTitle,
        },
      });
    } catch (_) {}
  }

  @override
  Future<void> updateStudentSkillLevel({
    required String studentId,
    required String skillLevel,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.updateStudentSkillLevel(
        studentId: studentId,
        skillLevel: skillLevel,
      );
    }

    await client
        .from('student_profiles')
        .update({'current_skill_level': skillLevel})
        .eq('profile_id', studentId);
  }

  @override
  Future<void> updateStudentSkillLevels({
    required String studentId,
    required int readingLevel,
    required int vocabularyLevel,
    required int wordMasterLevel,
    required int comprehensionLevel,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.updateStudentSkillLevels(
        studentId: studentId,
        readingLevel: readingLevel,
        vocabularyLevel: vocabularyLevel,
        wordMasterLevel: wordMasterLevel,
        comprehensionLevel: comprehensionLevel,
      );
    }

    await client
        .from('student_profiles')
        .update({
          'reading_level': readingLevel,
          'vocabulary_level': vocabularyLevel,
          'word_master_level': wordMasterLevel,
          'comprehension_level': comprehensionLevel,
        })
        .eq('profile_id', studentId);

    try {
      await client.from('activity_logs').insert({
        'actor_id': user.id,
        'actor_role': 'teacher',
        'action': 'updated_student_skill_levels',
        'entity_type': 'student_profile',
        'entity_id': studentId,
        'metadata': {
          'student_id': studentId,
          'reading_level': readingLevel,
          'vocabulary_level': vocabularyLevel,
          'word_master_level': wordMasterLevel,
          'comprehension_level': comprehensionLevel,
        },
      });
    } catch (_) {}
  }

  @override
  Future<void> awardBadgeToStudent({
    required String studentId,
    required String badgeName,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.awardBadgeToStudent(
        studentId: studentId,
        badgeName: badgeName,
      );
    }

    final existingBadge = await client
        .from('badges')
        .select('id')
        .eq('name', badgeName)
        .maybeSingle();
    final badgeRow =
        existingBadge ??
        await client
            .from('badges')
            .insert({'name': badgeName, 'created_by': user.id})
            .select('id')
            .single();
    final badgeId = badgeRow['id'] as String;

    final existingAward = await client
        .from('student_badges')
        .select('student_id')
        .eq('student_id', studentId)
        .eq('badge_id', badgeId)
        .maybeSingle();
    if (existingAward == null) {
      await client.from('student_badges').insert({
        'student_id': studentId,
        'badge_id': badgeId,
        'awarded_by': user.id,
      });
    }

    try {
      await client.from('activity_logs').insert({
        'actor_id': user.id,
        'actor_role': 'teacher',
        'action': 'awarded_badge',
        'entity_type': 'badge',
        'entity_id': badgeId,
        'metadata': {'student_id': studentId, 'badge_name': badgeName},
      });
    } catch (_) {}
  }

  @override
  Future<List<Book>> getCurrentBooks() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentBooks();

    final rows = await client
        .from('books')
        .select(
          'id,title,grade_level,passage_text,status,sections(name),'
          'book_questions(id,question_text,options,correct_option_index,sort_order)',
        )
        .eq('created_by', user.id)
        .order('grade_level')
        .order('title');

    final books = rows.map<Book>(_bookFromRow).toList();
    _cachedBooks = books;
    return books;
  }

  @override
  Future<Book> addBook({
    required String title,
    required String grade,
    required String section,
    required String content,
    required List<BookQuestionInput> questions,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.addBook(
        title: title,
        grade: grade,
        section: section,
        content: content,
        questions: questions,
      );
    }

    final teacherSectionRow = await client
        .from('teacher_sections')
        .select('sections!inner(id,grade_level,name)')
        .eq('teacher_id', user.id)
        .eq('sections.grade_level', grade)
        .eq('sections.name', section)
        .maybeSingle();
    final sectionRow = teacherSectionRow?['sections'] as Map<String, dynamic>?;
    final sectionId = sectionRow?['id'] as String?;
    if (sectionId == null) {
      throw StateError('Selected section was not found.');
    }

    final bookRow = await client
        .from('books')
        .insert({
          'created_by': user.id,
          'section_id': sectionId,
          'grade_level': grade,
          'title': title,
          'passage_text': content,
          'status': 'published',
        })
        .select('id,title,grade_level,passage_text,status,sections(name)')
        .single();

    await client
        .from('book_questions')
        .insert(
          questions.asMap().entries.map((entry) {
            final question = entry.value;
            return {
              'book_id': bookRow['id'],
              'question_text': question.questionText,
              'options': question.options,
              'correct_option_index': question.correctOptionIndex,
              'sort_order': entry.key,
            };
          }).toList(),
        );

    return _bookFromRow({
      ...bookRow,
      'book_questions': questions.asMap().entries.map((entry) {
        final question = entry.value;
        return {
          'id': 'new_${entry.key}',
          'question_text': question.questionText,
          'options': question.options,
          'correct_option_index': question.correctOptionIndex,
          'sort_order': entry.key,
        };
      }).toList(),
    });
  }

  @override
  Future<GeneratedBookDraft> generateBookDraft({
    required String prompt,
    required String grade,
    required String section,
    required int quizCount,
    required String passageLength,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return super.generateBookDraft(
        prompt: prompt,
        grade: grade,
        section: section,
        quizCount: quizCount,
        passageLength: passageLength,
      );
    }

    final teacherSectionRow = await client
        .from('teacher_sections')
        .select('sections!inner(id,grade_level,name)')
        .eq('teacher_id', user.id)
        .eq('sections.grade_level', grade)
        .eq('sections.name', section)
        .maybeSingle();
    final sectionRow = teacherSectionRow?['sections'] as Map<String, dynamic>?;
    final sectionId = sectionRow?['id'] as String?;
    if (sectionId == null) {
      throw StateError('Selected section was not found.');
    }

    final response = await client.functions.invoke(
      'generate-book-content',
      body: {
        'prompt': prompt,
        'gradeLevel': grade,
        'sectionId': sectionId,
        'quizCount': quizCount,
        'passageLength': passageLength,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return GeneratedBookDraft.fromJson(data);
    }
    if (data is Map) {
      return GeneratedBookDraft.fromJson(Map<String, dynamic>.from(data));
    }
    throw const FormatException('Generated book response is malformed.');
  }

  Book _bookFromRow(Map<String, dynamic> row) {
    final section = row['sections'] as Map<String, dynamic>?;
    final rawQuestions = row['book_questions'] as List<dynamic>? ?? const [];
    final questionRows =
        rawQuestions
            .map((question) => question as Map<String, dynamic>)
            .toList()
          ..sort((a, b) {
            final aOrder = (a['sort_order'] as num?)?.toInt() ?? 0;
            final bOrder = (b['sort_order'] as num?)?.toInt() ?? 0;
            return aOrder.compareTo(bOrder);
          });
    final questions = questionRows.map<BookQuestion>((questionRow) {
      final rawOptions = questionRow['options'] as List<dynamic>? ?? const [];
      return BookQuestion(
        id: questionRow['id'] as String? ?? '',
        questionText: questionRow['question_text'] as String? ?? '',
        options: rawOptions.map((option) => option.toString()).toList(),
        correctOptionIndex:
            (questionRow['correct_option_index'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return Book(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Untitled Book',
      grade: row['grade_level'] as String? ?? '',
      section: section?['name'] as String? ?? '',
      content: row['passage_text'] as String? ?? '',
      questions: questions,
    );
  }

  String _statusForAccuracy(double accuracy, int submittedCount) {
    if (submittedCount == 0) return 'NO SUBMISSIONS';
    if (accuracy >= 0.9) return 'OUTSTANDING';
    if (accuracy >= 0.75) return 'GROWING';
    if (accuracy >= 0.5) return 'EXPLORER';
    return 'NEEDS SUPPORT';
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

  List<TranscriptWordDiff> _alignmentFromJson(dynamic rawAlignment) {
    final alignment = rawAlignment is Map
        ? rawAlignment['tokens']
        : rawAlignment;
    if (alignment is! List) return const [];
    return alignment
        .map<TranscriptWordDiff>((item) {
          if (item is! Map) {
            return TranscriptWordDiff(word: item.toString(), status: 'matched');
          }
          final word = item['expected']?.toString().trim().isNotEmpty == true
              ? item['expected'].toString()
              : item['word']?.toString().trim().isNotEmpty == true
              ? item['word'].toString()
              : item['actual']?.toString() ?? '';
          return TranscriptWordDiff(
            word: word,
            status: item['status']?.toString() ?? 'matched',
          );
        })
        .where((diff) => diff.word.trim().isNotEmpty)
        .toList();
  }

  SuggestedReadingRemarks? _suggestedRemarksFromJson(
    dynamic raw, {
    int? omissionCount,
    int? repetitionCount,
    int? selfCorrectionCount,
    int? mispronunciationCount,
  }) {
    try {
      if (raw is! Map) {
        final hasCounts =
            (omissionCount ?? 0) > 0 ||
            (repetitionCount ?? 0) > 0 ||
            (selfCorrectionCount ?? 0) > 0 ||
            (mispronunciationCount ?? 0) > 0;
        if (!hasCounts) return null;
        return SuggestedReadingRemarks(
          version: 1,
          source: 'deterministic_alignment',
          omission: _emptyRemark('Omission', omissionCount ?? 0),
          repetition: _emptyRemark('Repetition', repetitionCount ?? 0),
          selfCorrection: _emptyRemark(
            'Self-Correction',
            selfCorrectionCount ?? 0,
          ),
          mispronunciation: _emptyRemark(
            'Possible Mispronunciation',
            mispronunciationCount ?? 0,
          ),
        );
      }

      final remarks = raw['remarks'];
      if (remarks is! Map) return null;
      return SuggestedReadingRemarks(
        version: (raw['version'] as num?)?.toInt() ?? 1,
        source: raw['source'] as String? ?? 'deterministic_alignment',
        omission: _remarkSuggestionFromJson(
          remarks['omission'],
          fallbackLabel: 'Omission',
          fallbackCount: omissionCount,
        ),
        repetition: _remarkSuggestionFromJson(
          remarks['repetition'],
          fallbackLabel: 'Repetition',
          fallbackCount: repetitionCount,
        ),
        selfCorrection: _remarkSuggestionFromJson(
          remarks['selfCorrection'],
          fallbackLabel: 'Self-Correction',
          fallbackCount: selfCorrectionCount,
        ),
        mispronunciation: _remarkSuggestionFromJson(
          remarks['mispronunciation'],
          fallbackLabel: 'Possible Mispronunciation',
          fallbackCount: mispronunciationCount,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  ReadingRemarkSuggestion _remarkSuggestionFromJson(
    dynamic raw, {
    required String fallbackLabel,
    int? fallbackCount,
  }) {
    if (raw is! Map) return _emptyRemark(fallbackLabel, fallbackCount ?? 0);
    return ReadingRemarkSuggestion(
      label: raw['label'] as String? ?? fallbackLabel,
      count: (raw['count'] as num?)?.toInt() ?? fallbackCount ?? 0,
      transcriptIndexes: _intList(raw['transcriptIndexes'] ?? raw['indexes']),
      expectedIndexes: _intList(raw['expectedIndexes']),
      words: _stringList(raw['words']),
      confidence: raw['confidence'] as String? ?? '',
    );
  }

  ReadingRemarkSuggestion _emptyRemark(String label, int count) {
    return ReadingRemarkSuggestion(
      label: label,
      count: count,
      transcriptIndexes: const [],
      expectedIndexes: const [],
      words: const [],
      confidence: '',
    );
  }

  List<int> _intList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item is num ? item.toInt() : int.tryParse('$item'))
        .whereType<int>()
        .toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _embeddedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return <String, dynamic>{};
  }

  List<dynamic> _embeddedList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) return [value];
    return const [];
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<String> _getSignedAvatarUrl(String? avatarPath) async {
    if (avatarPath == null || avatarPath.trim().isEmpty) return '';
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }

    final client = SupabaseService.client;
    if (client == null) return '';
    try {
      return await client.storage.from('avatars').createSignedUrl(avatarPath, 3600);
    } catch (_) {
      return '';
    }
  }

  Future<String> _getSignedVideoUrl(SupabaseClient client, String videoPath) async {
    try {
      return await client.storage
          .from('reading-videos')
          .createSignedUrl(videoPath, 3600);
    } catch (_) {
      return '';
    }
  }

  @override
  Future<String> getSignedVideoUrl(String videoPath) async {
    final client = SupabaseService.client;
    if (client == null || videoPath.trim().isEmpty) return '';
    final cached = _signedVideoUrls[videoPath];
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final url = await _getSignedVideoUrl(client, videoPath);
      if (url.isNotEmpty) {
        _signedVideoUrls[videoPath] = url;
      }
      return url;
    } catch (_) {
      return '';
    }
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
}
