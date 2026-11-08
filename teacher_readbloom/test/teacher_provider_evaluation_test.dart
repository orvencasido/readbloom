import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_readbloom/models/teacher_models.dart';
import 'package:teacher_readbloom/providers/teacher_provider.dart';
import 'package:teacher_readbloom/repositories/teacher_repository.dart';

class MockReviewsTeacherRepository extends MockTeacherRepository {
  Map<String, List<ReadingSubmissionReview>> reviews;
  MockReviewsTeacherRepository({required this.reviews});

  @override
  Future<Map<String, List<ReadingSubmissionReview>>> getCurrentReadingReviews() async => reviews;
}

void main() {
  group('TeacherProvider Pending Submissions Notification Badge Tests', () {
    test('initial pending count is 0', () {
      final provider = TeacherProvider();
      expect(provider.newReadingSubmissionsCount, 0);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-1'), 0);
    });

    test('counts unreviewed submissions and updates when feedback is sent', () async {
      const sub1 = ReadingSubmissionReview(
        id: 'sub-1',
        studentId: 'student-1',
        bookTitle: 'Book 1',
        passageText: 'Passage 1',
        status: 'completed',
        submittedAtLabel: '10m ago',
        videoPath: '',
        videoUrl: '',
        rawTranscript: 'hello',
        readingAccuracy: 90,
        quizScore: 5,
        quizTotal: 5,
        alignment: [],
        feedbackText: null, // Pending review
      );

      const sub2 = ReadingSubmissionReview(
        id: 'sub-2',
        studentId: 'student-1',
        bookTitle: 'Book 2',
        passageText: 'Passage 2',
        status: 'completed',
        submittedAtLabel: '20m ago',
        videoPath: '',
        videoUrl: '',
        rawTranscript: 'world',
        readingAccuracy: 92,
        quizScore: 4,
        quizTotal: 5,
        alignment: [],
        feedbackText: '   ', // Whitespace only, treated as pending review
      );

      const sub3 = ReadingSubmissionReview(
        id: 'sub-3',
        studentId: 'student-2',
        bookTitle: 'Book 3',
        passageText: 'Passage 3',
        status: 'completed',
        submittedAtLabel: '1h ago',
        videoPath: '',
        videoUrl: '',
        rawTranscript: 'reading',
        readingAccuracy: 95,
        quizScore: 5,
        quizTotal: 5,
        alignment: [],
        feedbackText: 'Great work!', // Already reviewed
      );

      const sub4 = ReadingSubmissionReview(
        id: 'sub-4',
        studentId: 'student-2',
        bookTitle: 'Book 4',
        passageText: 'Passage 4',
        status: 'completed',
        submittedAtLabel: '5m ago',
        videoPath: '',
        videoUrl: '',
        rawTranscript: 'read bloom',
        readingAccuracy: 88,
        quizScore: 3,
        quizTotal: 5,
        alignment: [],
        feedbackText: null, // Pending review
      );

      final repo = MockReviewsTeacherRepository(
        reviews: {
          'student-1': [sub1, sub2],
          'student-2': [sub3, sub4],
        },
      );

      final provider = TeacherProvider(teacherRepository: repo);
      await provider.refreshReadingReviews();

      // Total pending: sub1 (student-1), sub2 (student-1), sub4 (student-2) -> 3 total
      expect(provider.newReadingSubmissionsCount, 3);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-1'), 2);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-2'), 1);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-3'), 0);

      // Now send feedback for sub1
      await provider.sendFeedbackForSubmission(
        submission: sub1,
        studentId: 'student-1',
        feedback: 'Good job on the passage!',
      );

      // Total pending should now be 2, and student-1 pending should be 1
      expect(provider.newReadingSubmissionsCount, 2);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-1'), 1);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-2'), 1);

      // Now viewing sub2 without sending feedback should also decrement pending count
      await provider.markSubmissionAsViewed('sub-2');
      expect(provider.isSubmissionViewed('sub-2'), isTrue);
      expect(provider.newReadingSubmissionsCount, 1);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-1'), 0);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-2'), 1);

      // Viewing sub4 clears all remaining notifications
      await provider.markSubmissionAsViewed('sub-4');
      expect(provider.newReadingSubmissionsCount, 0);
      expect(provider.getNewReadingSubmissionsCountForStudent('student-2'), 0);
    });
  });
  group('TeacherProvider Evaluation Metrics Tests', () {
    test('getEvaluationForStudent returns 0s when no submissions exist', () {
      final provider = TeacherProvider();
      final eval = provider.getEvaluationForStudent('student-123');

      expect(eval.omissions, 0);
      expect(eval.repetitions, 0);
      expect(eval.selfCorrections, 0);
      expect(eval.mispronunciations, 0);
      expect(eval.feedback, '');
    });

    test('updateEvaluation updates metrics correctly', () {
      final provider = TeacherProvider();
      provider.updateEvaluation('student-123', 1, 2, 3, 4, 'Great job!');

      final eval = provider.getEvaluationForStudent('student-123');
      expect(eval.omissions, 1);
      expect(eval.repetitions, 2);
      expect(eval.selfCorrections, 3);
      expect(eval.mispronunciations, 4);
      expect(eval.feedback, 'Great job!');
    });

    test('sendFeedbackForSubmission updates evaluation counts and feedback text', () async {
      final provider = TeacherProvider();
      const submission = ReadingSubmissionReview(
        id: 'sub-1',
        studentId: 'student-456',
        bookTitle: 'Test Book',
        passageText: 'Sample passage',
        status: 'submitted',
        submittedAtLabel: 'Today',
        videoPath: '',
        videoUrl: '',
        rawTranscript: 'sample words',
        alignment: [],
        readingAccuracy: 95.0,
        quizScore: 5,
        quizTotal: 5,
        suggestedRemarks: SuggestedReadingRemarks(
          omission: ReadingRemarkSuggestion(
            label: 'Omission',
            count: 3,
            transcriptIndexes: [],
            expectedIndexes: [],
            words: [],
            confidence: 'high',
          ),
          repetition: ReadingRemarkSuggestion(
            label: 'Repetition',
            count: 2,
            transcriptIndexes: [],
            expectedIndexes: [],
            words: [],
            confidence: 'high',
          ),
          selfCorrection: ReadingRemarkSuggestion(
            label: 'Self Correction',
            count: 1,
            transcriptIndexes: [],
            expectedIndexes: [],
            words: [],
            confidence: 'high',
          ),
          mispronunciation: ReadingRemarkSuggestion(
            label: 'Mispronunciation',
            count: 4,
            transcriptIndexes: [],
            expectedIndexes: [],
            words: [],
            confidence: 'high',
          ),
        ),
      );

      final reviewJson = jsonEncode({
        'format': 'readbloom_teacher_review_v1',
        'feedback': 'Good effort! Practice word pronunciation.',
        'transcript': 'sample words',
        'passage': 'Sample passage',
        'remarks': {
          'omission': {'label': 'Omission', 'count': 5, 'indexes': [0]},
          'repetition': {'label': 'Repetition', 'count': 1, 'indexes': [1]},
          'selfCorrection': {'label': 'Self Correction', 'count': 2, 'indexes': []},
          'mispronunciation': {'label': 'Mispronunciation', 'count': 3, 'indexes': []},
        },
      });

      await provider.sendFeedbackForSubmission(
        submission: submission,
        studentId: 'student-456',
        feedback: reviewJson,
      );

      final eval = provider.getEvaluationForStudent('student-456');
      expect(eval.omissions, 5);
      expect(eval.repetitions, 1);
      expect(eval.selfCorrections, 2);
      expect(eval.mispronunciations, 3);
      expect(eval.feedback, 'Good effort! Practice word pronunciation.');
    });
  });
}
