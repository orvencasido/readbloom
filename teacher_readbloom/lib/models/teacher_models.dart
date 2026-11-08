class ClassStats {
  final String grade;
  final int totalStudents;
  final double completionRate;
  final int totalLessons;

  ClassStats({
    required this.grade,
    required this.totalStudents,
    required this.completionRate,
    required this.totalLessons,
  });
}

class StudentProgress {
  final String id;
  final String name;
  final double readingAccuracy;
  final double vocabularyLevel;
  final int progressCurrent;
  final int progressTotal;
  final String status;
  final List<String> badges;
  final String grade;
  final String section;
  final String avatarUrl;
  final String skillLevel;
  final int readingLevel;
  final int vocabularySkillLevel;
  final int wordMasterLevel;
  final int comprehensionLevel;

  StudentProgress({
    required this.id,
    required this.name,
    required this.readingAccuracy,
    required this.vocabularyLevel,
    required this.progressCurrent,
    required this.progressTotal,
    required this.status,
    required this.badges,
    required this.grade,
    required this.section,
    this.avatarUrl = '',
    this.skillLevel = 'Reading Explorer',
    this.readingLevel = 1,
    this.vocabularySkillLevel = 1,
    this.wordMasterLevel = 1,
    this.comprehensionLevel = 1,
  });
}

class StudentActivity {
  final String id;
  final String studentName;
  final String activityTitle;
  final double score;
  final String date;

  StudentActivity({
    required this.id,
    required this.studentName,
    required this.activityTitle,
    required this.score,
    required this.date,
  });
}

class ReadingSubmissionReview {
  final String id;
  final String studentId;
  final String bookTitle;
  final String passageText;
  final String status;
  final String submittedAtLabel;
  final String videoPath;
  final String videoUrl;
  final int durationSeconds;
  final String rawTranscript;
  final List<TranscriptWordDiff> alignment;
  final double? readingAccuracy;
  final int quizScore;
  final int quizTotal;
  final SuggestedReadingRemarks? suggestedRemarks;
  final String? feedbackText;

  const ReadingSubmissionReview({
    required this.id,
    required this.studentId,
    required this.bookTitle,
    required this.passageText,
    required this.status,
    required this.submittedAtLabel,
    required this.videoPath,
    required this.videoUrl,
    this.durationSeconds = 0,
    required this.rawTranscript,
    required this.alignment,
    required this.readingAccuracy,
    required this.quizScore,
    required this.quizTotal,
    this.suggestedRemarks,
    this.feedbackText,
  });

  bool get isPendingReview =>
      feedbackText == null || feedbackText!.trim().isEmpty;

  ReadingSubmissionReview copyWith({
    String? id,
    String? studentId,
    String? bookTitle,
    String? passageText,
    String? status,
    String? submittedAtLabel,
    String? videoPath,
    String? videoUrl,
    int? durationSeconds,
    String? rawTranscript,
    List<TranscriptWordDiff>? alignment,
    double? readingAccuracy,
    int? quizScore,
    int? quizTotal,
    SuggestedReadingRemarks? suggestedRemarks,
    String? feedbackText,
  }) {
    return ReadingSubmissionReview(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      bookTitle: bookTitle ?? this.bookTitle,
      passageText: passageText ?? this.passageText,
      status: status ?? this.status,
      submittedAtLabel: submittedAtLabel ?? this.submittedAtLabel,
      videoPath: videoPath ?? this.videoPath,
      videoUrl: videoUrl ?? this.videoUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      alignment: alignment ?? this.alignment,
      readingAccuracy: readingAccuracy ?? this.readingAccuracy,
      quizScore: quizScore ?? this.quizScore,
      quizTotal: quizTotal ?? this.quizTotal,
      suggestedRemarks: suggestedRemarks ?? this.suggestedRemarks,
      feedbackText: feedbackText ?? this.feedbackText,
    );
  }
}

class TranscriptWordDiff {
  final String word;
  final String status;

  const TranscriptWordDiff({required this.word, required this.status});
}

class SuggestedReadingRemarks {
  final int version;
  final String source;
  final ReadingRemarkSuggestion omission;
  final ReadingRemarkSuggestion repetition;
  final ReadingRemarkSuggestion selfCorrection;
  final ReadingRemarkSuggestion mispronunciation;

  const SuggestedReadingRemarks({
    this.version = 1,
    this.source = 'deterministic_alignment',
    required this.omission,
    required this.repetition,
    required this.selfCorrection,
    required this.mispronunciation,
  });

  bool get hasSuggestions =>
      omission.count > 0 ||
      repetition.count > 0 ||
      selfCorrection.count > 0 ||
      mispronunciation.count > 0;
}

class ReadingRemarkSuggestion {
  final String label;
  final int count;
  final List<int> transcriptIndexes;
  final List<int> expectedIndexes;
  final List<String> words;
  final String confidence;

  const ReadingRemarkSuggestion({
    required this.label,
    required this.count,
    required this.transcriptIndexes,
    required this.expectedIndexes,
    required this.words,
    required this.confidence,
  });
}

class EvaluationMetrics {
  int omissions;
  int repetitions;
  int selfCorrections;
  int mispronunciations;
  String feedback;

  EvaluationMetrics({
    required this.omissions,
    required this.repetitions,
    required this.selfCorrections,
    required this.mispronunciations,
    required this.feedback,
  });
}

class Book {
  final String id;
  final String title;
  final String grade;
  final String section;
  final String content;
  final List<BookQuestion> questions;

  Book({
    required this.id,
    required this.title,
    required this.grade,
    required this.section,
    required this.content,
    this.questions = const [],
  });
}

class BookQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  const BookQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });
}

class BookQuestionInput {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  const BookQuestionInput({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });
}

class GenerateBookRequest {
  final String prompt;
  final String gradeLevel;
  final String sectionId;
  final int quizCount;
  final String passageLength;

  const GenerateBookRequest({
    required this.prompt,
    required this.gradeLevel,
    required this.sectionId,
    required this.quizCount,
    required this.passageLength,
  });
}

class GeneratedBookDraft {
  final String title;
  final String passageText;
  final List<BookQuestionInput> questions;

  const GeneratedBookDraft({
    required this.title,
    required this.passageText,
    required this.questions,
  });

  factory GeneratedBookDraft.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String? ?? '').trim();
    final passageText = (json['passageText'] as String? ?? '').trim();
    final rawQuestions = json['questions'];
    if (title.isEmpty || passageText.isEmpty || rawQuestions is! List) {
      throw const FormatException('Generated book content is incomplete.');
    }

    final questions = rawQuestions.map<BookQuestionInput>((rawQuestion) {
      if (rawQuestion is! Map) {
        throw const FormatException('Generated quiz question is malformed.');
      }
      final question = Map<String, dynamic>.from(rawQuestion);
      final questionText = (question['questionText'] as String? ?? '').trim();
      final rawOptions = question['options'];
      final correctOptionIndex =
          (question['correctOptionIndex'] as num?)?.toInt() ?? -1;
      if (questionText.isEmpty || rawOptions is! List) {
        throw const FormatException('Generated quiz question is incomplete.');
      }
      final options = rawOptions
          .map((option) => option.toString().trim())
          .where((option) => option.isNotEmpty)
          .toList();
      if (options.length < 2 ||
          correctOptionIndex < 0 ||
          correctOptionIndex >= options.length) {
        throw const FormatException('Generated quiz options are invalid.');
      }
      return BookQuestionInput(
        questionText: questionText,
        options: options,
        correctOptionIndex: correctOptionIndex,
      );
    }).toList();

    if (questions.isEmpty || questions.length > 3) {
      throw const FormatException('Generated quiz count is invalid.');
    }

    return GeneratedBookDraft(
      title: title,
      passageText: passageText,
      questions: questions,
    );
  }
}
