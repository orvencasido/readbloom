import 'dart:convert';
import 'achievement_models.dart';
export 'achievement_models.dart';

class StudentProfile {
  final String id;
  final String name;
  final String email;
  final String grade;
  final String section;
  final String level;
  final int progressCurrent;
  final int progressTotal;
  final int daysStreak;
  final String status;
  final List<String> badges;
  final String avatarUrl;
  final int readingLevel;
  final int vocabularyLevel;
  final int wordMasterLevel;
  final int comprehensionLevel;

  StudentProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.grade,
    required this.section,
    required this.level,
    required this.progressCurrent,
    required this.progressTotal,
    required this.daysStreak,
    required this.status,
    required this.badges,
    this.avatarUrl = '',
    this.readingLevel = 1,
    this.vocabularyLevel = 1,
    this.wordMasterLevel = 1,
    this.comprehensionLevel = 1,
  });

  StudentProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? grade,
    String? section,
    String? level,
    int? progressCurrent,
    int? progressTotal,
    int? daysStreak,
    String? status,
    List<String>? badges,
    String? avatarUrl,
    int? readingLevel,
    int? vocabularyLevel,
    int? wordMasterLevel,
    int? comprehensionLevel,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      level: level ?? this.level,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTotal: progressTotal ?? this.progressTotal,
      daysStreak: daysStreak ?? this.daysStreak,
      status: status ?? this.status,
      badges: badges ?? this.badges,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      readingLevel: readingLevel ?? this.readingLevel,
      vocabularyLevel: vocabularyLevel ?? this.vocabularyLevel,
      wordMasterLevel: wordMasterLevel ?? this.wordMasterLevel,
      comprehensionLevel: comprehensionLevel ?? this.comprehensionLevel,
    );
  }

  String get displayAchievementBadge {
    if (badges.isNotEmpty) {
      final b = badges.first.trim();
      if (b.isNotEmpty &&
          !b.toLowerCase().contains('no badge') &&
          !b.toLowerCase().contains('no achievement')) {
        return b;
      }
    }
    if (level.trim().isNotEmpty) {
      return getTierByNameOrTitle(level).displayName;
    }
    return kAchievementTiers.first.displayName;
  }
}

class Story {
  final String id;
  final String title;
  final int bookNumber;
  final int level;
  final String text;
  final List<QuizQuestion> questions;
  final bool isLocked;

  Story({
    required this.id,
    required this.title,
    required this.bookNumber,
    required this.level,
    required this.text,
    required this.questions,
    required this.isLocked,
  });
}

class QuizQuestion {
  final String? id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class QuizAnswerDraft {
  final String? questionId;
  final int selectedOptionIndex;
  final bool isCorrect;

  QuizAnswerDraft({
    required this.questionId,
    required this.selectedOptionIndex,
    required this.isCorrect,
  });
}

class ReadingSubmission {
  final String id;
  final String studentId;
  final String bookId;
  final String videoPath;
  final int durationSeconds;
  final int timeLimitSeconds;
  final bool isOvertime;
  final String status;

  ReadingSubmission({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.videoPath,
    required this.durationSeconds,
    required this.timeLimitSeconds,
    required this.isOvertime,
    required this.status,
  });
}

class ActivityLog {
  final String name;
  final String activity;
  final int score;
  final String date;

  ActivityLog({
    required this.name,
    required this.activity,
    required this.score,
    required this.date,
  });
}

class StudentMessage {
  final String id;
  final String senderName;
  final String title;
  final String body;
  final String createdAtLabel;
  final bool isUnread;
  final String? relatedSubmissionId;
  final String transcriptText;
  final String passageText;

  StudentMessage({
    required this.id,
    required this.senderName,
    required this.title,
    required this.body,
    required this.createdAtLabel,
    required this.isUnread,
    this.relatedSubmissionId,
    this.transcriptText = '',
    this.passageText = '',
  });
}

class StudentReadingFeedback {
  final String feedback;
  final String transcript;
  final String passage;
  final Map<String, StudentReadingRemark> remarks;
  final bool isStructured;

  const StudentReadingFeedback({
    required this.feedback,
    required this.transcript,
    required this.passage,
    required this.remarks,
    required this.isStructured,
  });

  factory StudentReadingFeedback.fromMessageBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['format'] == 'readbloom_teacher_review_v1') {
        final rawRemarks = decoded['remarks'];
        return StudentReadingFeedback(
          feedback: decoded['feedback']?.toString() ?? '',
          transcript: decoded['transcript']?.toString() ?? '',
          passage: decoded['passage']?.toString() ?? '',
          remarks: rawRemarks is Map
              ? rawRemarks.map((key, value) {
                  final remark = value is Map
                      ? Map<String, dynamic>.from(value)
                      : <String, dynamic>{};
                  return MapEntry(
                    key.toString(),
                    StudentReadingRemark(
                      label: remark['label']?.toString() ?? key.toString(),
                      count: (remark['count'] as num?)?.toInt() ?? 0,
                      indexes: (remark['indexes'] as List<dynamic>? ?? const [])
                          .map((index) => (index as num?)?.toInt())
                          .whereType<int>()
                          .toSet(),
                      words: (remark['words'] as List<dynamic>? ?? const [])
                          .map((word) => word.toString())
                          .toList(),
                    ),
                  );
                })
              : const {},
          isStructured: true,
        );
      }
    } catch (_) {}

    final legacy = _fromLegacyBody(body);
    if (legacy != null) return legacy;

    return StudentReadingFeedback(
      feedback: body,
      transcript: '',
      passage: '',
      remarks: const {},
      isStructured: false,
    );
  }

  factory StudentReadingFeedback.fromMessage(StudentMessage? message) {
    final parsed = StudentReadingFeedback.fromMessageBody(message?.body ?? '');
    final transcript = message?.transcriptText.trim() ?? '';
    final passage = message?.passageText.trim() ?? '';
    if (transcript.isEmpty && passage.isEmpty) return parsed;

    return StudentReadingFeedback(
      feedback: parsed.feedback,
      transcript: transcript.isNotEmpty ? transcript : parsed.transcript,
      passage: passage.isNotEmpty ? passage : parsed.passage,
      remarks: parsed.remarks,
      isStructured: parsed.isStructured,
    );
  }

  static StudentReadingFeedback? _fromLegacyBody(String body) {
    final marker = RegExp(r'\n\s*Reading Remarks\s*\n', caseSensitive: false);
    final match = marker.firstMatch(body);
    if (match == null) return null;

    final rawFeedback = body.substring(0, match.start).trim();
    final remarksText = body.substring(match.end).trim();
    final feedback = rawFeedback
        .replaceFirst(RegExp(r'^Teacher Feedback\s*', caseSensitive: false), '')
        .trim();

    final remarks = <String, StudentReadingRemark>{};
    final remarkHeader = RegExp(
      r'^(Omission|Repetition|Self Correction|Mispronunciation):\s*(\d+)\s*$',
      caseSensitive: false,
    );
    final lines = remarksText.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final header = remarkHeader.firstMatch(lines[i].trim());
      if (header == null) continue;
      final label = header.group(1) ?? '';
      final key = _remarkKeyForLabel(label);
      final wordsLine = i + 1 < lines.length ? lines[i + 1].trim() : '';
      remarks[key] = StudentReadingRemark(
        label: label,
        count: int.tryParse(header.group(2) ?? '') ?? 0,
        indexes: const {},
        words: wordsLine.toLowerCase() == 'none'
            ? const []
            : wordsLine
                  .split(',')
                  .map((word) => word.trim())
                  .where((word) => word.isNotEmpty)
                  .toList(),
      );
    }

    return StudentReadingFeedback(
      feedback: feedback,
      transcript: '',
      passage: '',
      remarks: remarks,
      isStructured: false,
    );
  }

  static String _remarkKeyForLabel(String label) {
    final normalized = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    switch (normalized) {
      case 'omission':
        return 'omission';
      case 'repetition':
        return 'repetition';
      case 'selfcorrection':
        return 'selfCorrection';
      case 'mispronunciation':
        return 'mispronunciation';
      default:
        return normalized;
    }
  }
}

class StudentReadingRemark {
  final String label;
  final int count;
  final Set<int> indexes;
  final List<String> words;

  const StudentReadingRemark({
    required this.label,
    required this.count,
    required this.indexes,
    required this.words,
  });
}
