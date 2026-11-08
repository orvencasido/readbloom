import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher_models.dart';
import '../repositories/teacher_repository.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class TeacherProvider extends ChangeNotifier {
  final TeacherRepository _teacherRepository;
  final AuthService _authService;
  late TeacherAccount _account;
  late List<ClassStats> _classes;
  late List<StudentActivity> _activities;
  late Map<String, EvaluationMetrics> _evaluations;
  late List<Book> _books;
  late List<StudentProgress> _students;
  late Map<String, List<ReadingSubmissionReview>> _readingReviewsByStudent;
  List<String> _assignedSections = const [];
  Set<String> _viewedSubmissionIds = {};

  bool _isLoggedIn = false;
  bool _isAuthLoading = true;
  bool _isPasswordRecovery = false;
  bool _isUploadingAvatar = false;
  bool _isBooksLoading = false;
  bool _isGeneratingBookDraft = false;
  bool _isTeacherDataLoading = false;
  bool _isRefreshingData = false;
  bool _isSavingFeedback = false;
  bool _isUpdatingSkillLevel = false;
  DateTime? _lastLoginDateFallback;
  String? _booksError;
  String? _generateBookDraftError;
  String? _teacherDataError;
  StudentProgress? _selectedStudentForEvaluation;
  StreamSubscription<AuthState>? _authStateSubscription;
  RealtimeChannel? _submissionsChannel;
  Timer? _periodicRefreshTimer;

  TeacherProvider({
    TeacherRepository? teacherRepository,
    AuthService? authService,
  }) : _teacherRepository = teacherRepository ?? SupabaseTeacherRepository(),
       _authService = authService ?? SupabaseRoleAuthService(AppRole.teacher) {
    _account = _teacherRepository.getAccount();
    _classes = _teacherRepository.getClasses();
    _students = List<StudentProgress>.from(_teacherRepository.getStudents());
    _activities = _teacherRepository.getActivities();
    _evaluations = _teacherRepository.getEvaluations();
    _books = List<Book>.from(_teacherRepository.getBooks());
    _readingReviewsByStudent = const {};
    _isPasswordRecovery = _isPasswordRecoveryRedirect();
    _listenForPasswordRecovery();
    restoreSession();
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthLoading => _isAuthLoading;
  bool get isPasswordRecovery => _isPasswordRecovery;
  String get teacherName => _account.name;
  String get school => _account.school;
  String get email => _account.email;
  String get avatarUrl => _account.avatarUrl;
  DateTime? get lastSignInAt => _account.lastSignInAt;

  String get lastLoginDate {
    final date = _account.lastSignInAt?.toLocal() ?? _lastLoginDateFallback;
    if (date == null) {
      if (_isLoggedIn) {
        final now = DateTime.now();
        return '${now.month}/${now.day}/${now.year}';
      }
      return '';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  List<String> get assignedSections => _assignedSections;
  bool get isUploadingAvatar => _isUploadingAvatar;
  List<ClassStats> get classes => _classes;
  List<StudentProgress> get students => _students;
  List<StudentActivity> get activities => _activities;
  bool get isTeacherDataLoading => _isTeacherDataLoading;
  bool get isRefreshingData => _isRefreshingData;
  bool get isSavingFeedback => _isSavingFeedback;
  bool get isUpdatingSkillLevel => _isUpdatingSkillLevel;
  String? get teacherDataError => _teacherDataError;
  StudentProgress? get selectedStudentForEvaluation =>
      _selectedStudentForEvaluation ??
      (_students.isNotEmpty ? _students[0] : null);
  List<Book> get books => _books;
  bool get isBooksLoading => _isBooksLoading;
  bool get isGeneratingBookDraft => _isGeneratingBookDraft;
  String? get booksError => _booksError;
  String? get generateBookDraftError => _generateBookDraftError;
  List<String> get availableGrades {
    final grades = _students.map((student) => student.grade).toSet().toList()
      ..sort();
    return ['All Grades', ...grades.where((grade) => grade.isNotEmpty)];
  }

  List<String> get availableSections {
    final sections =
        _students.map((student) => student.section).toSet().toList()..sort();
    return ['All Sections', ...sections.where((section) => section.isNotEmpty)];
  }

  List<ReadingSubmissionReview> getReadingReviewsForStudent(String studentId) {
    return List.unmodifiable(_readingReviewsByStudent[studentId] ?? const []);
  }

  bool isSubmissionViewed(String submissionId) {
    return _viewedSubmissionIds.contains(submissionId);
  }

  int get newReadingSubmissionsCount {
    int count = 0;
    for (final reviews in _readingReviewsByStudent.values) {
      for (final review in reviews) {
        if (review.isPendingReview && !_viewedSubmissionIds.contains(review.id)) {
          count++;
        }
      }
    }
    return count;
  }

  int getNewReadingSubmissionsCountForStudent(String studentId) {
    final reviews = _readingReviewsByStudent[studentId];
    if (reviews == null || reviews.isEmpty) return 0;
    return reviews
        .where((r) => r.isPendingReview && !_viewedSubmissionIds.contains(r.id))
        .length;
  }

  Future<void> markSubmissionAsViewed(String submissionId) async {
    final cleanId = submissionId.trim();
    if (cleanId.isEmpty || _viewedSubmissionIds.contains(cleanId)) return;
    _viewedSubmissionIds.add(cleanId);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'teacher_viewed_submissions_${_account.email}';
      await prefs.setStringList(key, _viewedSubmissionIds.toList());
    } catch (_) {}
  }

  Future<void> markStudentSubmissionsAsViewed(String studentId) async {
    final reviews = _readingReviewsByStudent[studentId];
    if (reviews == null || reviews.isEmpty) return;
    bool changed = false;
    for (final r in reviews) {
      if (r.id.isNotEmpty && !_viewedSubmissionIds.contains(r.id)) {
        _viewedSubmissionIds.add(r.id);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = 'teacher_viewed_submissions_${_account.email}';
        await prefs.setStringList(key, _viewedSubmissionIds.toList());
      } catch (_) {}
    }
  }

  void selectStudentForEvaluation(StudentProgress student) {
    _selectedStudentForEvaluation = student;
    notifyListeners();
  }

  EvaluationMetrics _extractEvaluationFromSubmission(
    ReadingSubmissionReview submission,
  ) {
    int omissions = submission.suggestedRemarks?.omission.count ?? 0;
    int repetitions = submission.suggestedRemarks?.repetition.count ?? 0;
    int selfCorrections = submission.suggestedRemarks?.selfCorrection.count ?? 0;
    int mispronunciations =
        submission.suggestedRemarks?.mispronunciation.count ?? 0;
    String feedback = '';

    final feedbackText = submission.feedbackText?.trim();
    if (feedbackText != null && feedbackText.isNotEmpty) {
      try {
        final decoded = jsonDecode(feedbackText);
        if (decoded is Map<String, dynamic> &&
            decoded['format'] == 'readbloom_teacher_review_v1') {
          feedback = decoded['feedback']?.toString() ?? '';
          final remarks = decoded['remarks'];
          if (remarks is Map) {
            final oMap = remarks['omission'];
            if (oMap is Map && oMap['count'] != null) {
              omissions = (oMap['count'] as num).toInt();
            }
            final rMap = remarks['repetition'];
            if (rMap is Map && rMap['count'] != null) {
              repetitions = (rMap['count'] as num).toInt();
            }
            final sMap = remarks['selfCorrection'];
            if (sMap is Map && sMap['count'] != null) {
              selfCorrections = (sMap['count'] as num).toInt();
            }
            final mMap = remarks['mispronunciation'];
            if (mMap is Map && mMap['count'] != null) {
              mispronunciations = (mMap['count'] as num).toInt();
            }
          }
        } else {
          feedback = feedbackText;
        }
      } catch (_) {
        feedback = feedbackText;
      }
    }

    return EvaluationMetrics(
      omissions: omissions,
      repetitions: repetitions,
      selfCorrections: selfCorrections,
      mispronunciations: mispronunciations,
      feedback: feedback,
    );
  }

  EvaluationMetrics getEvaluationForStudent(String studentId) {
    if (_evaluations.containsKey(studentId)) {
      return _evaluations[studentId]!;
    }
    final reviews = _readingReviewsByStudent[studentId];
    if (reviews != null && reviews.isNotEmpty) {
      final eval = _extractEvaluationFromSubmission(reviews.first);
      _evaluations[studentId] = eval;
      return eval;
    }
    return EvaluationMetrics(
      omissions: 0,
      repetitions: 0,
      selfCorrections: 0,
      mispronunciations: 0,
      feedback: '',
    );
  }

  void updateEvaluation(
    String studentId,
    int o,
    int r,
    int s,
    int m,
    String f,
  ) {
    _evaluations[studentId] = EvaluationMetrics(
      omissions: o,
      repetitions: r,
      selfCorrections: s,
      mispronunciations: m,
      feedback: f,
    );
    notifyListeners();
  }

  Future<String?> addBadgeToStudent(String studentId, String badge) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    final cleanedBadge = badge.trim();
    if (cleanedBadge.isEmpty) return 'Please enter a badge name first.';
    if (index == -1) return 'Student was not found.';

    final currentStudent = _students[index];
    if (currentStudent.badges.contains(cleanedBadge)) {
      return '${currentStudent.name} already has this badge.';
    }

    try {
      await _teacherRepository.awardBadgeToStudent(
        studentId: studentId,
        badgeName: cleanedBadge,
      );
    } catch (_) {
      return 'Unable to award badge right now.';
    }

    final updatedBadges = List<String>.from(currentStudent.badges)
      ..add(cleanedBadge);
    _students = List<StudentProgress>.from(_students)
      ..[index] = _copyStudent(currentStudent, badges: updatedBadges);
    notifyListeners();
    return null;
  }

  Future<String?> updateStudentSkillLevels({
    required String studentId,
    required int readingLevel,
    required int vocabularyLevel,
    required int wordMasterLevel,
    required int comprehensionLevel,
  }) async {
    final index = _students.indexWhere((student) => student.id == studentId);
    if (index == -1) return null;

    final safeReadingLevel = readingLevel.clamp(1, 10);
    final safeVocabularyLevel = vocabularyLevel.clamp(1, 10);
    final safeWordMasterLevel = wordMasterLevel.clamp(1, 10);
    final safeComprehensionLevel = comprehensionLevel.clamp(1, 10);

    try {
      await _teacherRepository.updateStudentSkillLevels(
        studentId: studentId,
        readingLevel: safeReadingLevel,
        vocabularyLevel: safeVocabularyLevel,
        wordMasterLevel: safeWordMasterLevel,
        comprehensionLevel: safeComprehensionLevel,
      );
    } catch (_) {
      return 'Unable to update skill levels right now.';
    }

    final student = _students[index];
    _students = List<StudentProgress>.from(_students)
      ..[index] = _copyStudent(
        student,
        readingLevel: safeReadingLevel,
        vocabularySkillLevel: safeVocabularyLevel,
        wordMasterLevel: safeWordMasterLevel,
        comprehensionLevel: safeComprehensionLevel,
      );
    notifyListeners();
    return null;
  }

  Future<String?> sendFeedbackForSubmission({
    required ReadingSubmissionReview submission,
    required String studentId,
    required String feedback,
  }) async {
    final cleanedFeedback = feedback.trim();
    if (cleanedFeedback.isEmpty) return 'Please enter feedback first.';

    _isSavingFeedback = true;
    notifyListeners();
    try {
      await _teacherRepository.sendFeedback(
        submission: submission,
        studentId: studentId,
        feedback: cleanedFeedback,
      );

      final updatedSubmission =
          submission.copyWith(feedbackText: cleanedFeedback);
      final currentList = _readingReviewsByStudent[studentId];
      if (currentList != null) {
        final index = currentList.indexWhere((s) => s.id == submission.id);
        if (index != -1) {
          final updatedList = List<ReadingSubmissionReview>.from(currentList);
          updatedList[index] = updatedSubmission;
          _readingReviewsByStudent =
              Map<String, List<ReadingSubmissionReview>>.from(
                _readingReviewsByStudent,
              )..[studentId] = updatedList;
        }
      }

      final eval = _extractEvaluationFromSubmission(updatedSubmission);
      _evaluations[studentId] = eval;
      return null;
    } catch (_) {
      return 'Unable to send feedback right now.';
    } finally {
      _isSavingFeedback = false;
      notifyListeners();
    }
  }

  Future<String?> updateStudentSkillLevel({
    required String studentId,
    required String skillLevel,
  }) async {
    final cleanedSkillLevel = skillLevel.trim();
    if (cleanedSkillLevel.isEmpty) return 'Please enter a skill level.';

    _isUpdatingSkillLevel = true;
    notifyListeners();
    try {
      await _teacherRepository.updateStudentSkillLevel(
        studentId: studentId,
        skillLevel: cleanedSkillLevel,
      );
      _students = _students.map((student) {
        if (student.id != studentId) return student;
        return _copyStudent(student, skillLevel: cleanedSkillLevel);
      }).toList();
      return null;
    } catch (_) {
      return 'Unable to update skill level right now.';
    } finally {
      _isUpdatingSkillLevel = false;
      notifyListeners();
    }
  }

  Future<String?> addBook({
    required String title,
    required String grade,
    required String section,
    required String content,
    required List<BookQuestionInput> questions,
  }) async {
    final cleanedQuestions = <BookQuestionInput>[];
    for (final question in questions) {
      final cleanedQuestion = _cleanQuestion(question);
      if (cleanedQuestion != null) cleanedQuestions.add(cleanedQuestion);
    }

    if (title.trim().isEmpty ||
        content.trim().isEmpty ||
        cleanedQuestions.isEmpty) {
      return 'Please complete the book and quiz fields.';
    }

    _isBooksLoading = true;
    _booksError = null;
    notifyListeners();
    try {
      final newBook = await _teacherRepository.addBook(
        title: title.trim(),
        grade: grade.trim(),
        section: section.trim(),
        content: content.trim(),
        questions: cleanedQuestions,
      );
      _books = List<Book>.from(_books)..add(newBook);
      return null;
    } catch (_) {
      _booksError = 'Unable to save this book right now.';
      return _booksError;
    } finally {
      _isBooksLoading = false;
      notifyListeners();
    }
  }

  Future<GeneratedBookDraft?> generateBookDraft({
    required String prompt,
    required String grade,
    required String section,
    required int quizCount,
    required String passageLength,
  }) async {
    final cleanedPrompt = prompt.trim();
    final cleanedGrade = grade.trim();
    final cleanedSection = section.trim();
    final cleanedPassageLength = passageLength.trim();

    if (cleanedPrompt.isEmpty) {
      _generateBookDraftError = 'Please enter a prompt first.';
      notifyListeners();
      return null;
    }
    if (cleanedGrade.isEmpty || cleanedSection.isEmpty) {
      _generateBookDraftError = 'Please choose a grade and section first.';
      notifyListeners();
      return null;
    }
    if (quizCount < 1 || quizCount > 3) {
      _generateBookDraftError = 'Quiz count must be between 1 and 3.';
      notifyListeners();
      return null;
    }
    if (!const ['short', 'medium', 'long'].contains(cleanedPassageLength)) {
      _generateBookDraftError = 'Please choose a passage length.';
      notifyListeners();
      return null;
    }

    _isGeneratingBookDraft = true;
    _generateBookDraftError = null;
    notifyListeners();
    try {
      return await _teacherRepository.generateBookDraft(
        prompt: cleanedPrompt,
        grade: cleanedGrade,
        section: cleanedSection,
        quizCount: quizCount,
        passageLength: cleanedPassageLength,
      );
    } catch (_) {
      _generateBookDraftError = 'Unable to generate book content right now.';
      return null;
    } finally {
      _isGeneratingBookDraft = false;
      notifyListeners();
    }
  }

  BookQuestionInput? _cleanQuestion(BookQuestionInput question) {
    final questionText = question.questionText.trim();
    final trimmedOptions = question.options
        .map((option) => option.trim())
        .toList();
    final selectedAnswer =
        question.correctOptionIndex >= 0 &&
            question.correctOptionIndex < trimmedOptions.length
        ? trimmedOptions[question.correctOptionIndex]
        : '';
    final cleanedOptions = trimmedOptions
        .where((option) => option.isNotEmpty)
        .toList();
    final normalizedCorrectOptionIndex = trimmedOptions
        .take(question.correctOptionIndex)
        .where((option) => option.isNotEmpty)
        .length;

    if (questionText.isEmpty ||
        selectedAnswer.isEmpty ||
        cleanedOptions.length < 2 ||
        normalizedCorrectOptionIndex >= cleanedOptions.length) {
      return null;
    }

    return BookQuestionInput(
      questionText: questionText,
      options: cleanedOptions,
      correctOptionIndex: normalizedCorrectOptionIndex,
    );
  }

  Future<void> restoreSession() async {
    _isAuthLoading = true;
    notifyListeners();
    if (_isPasswordRecovery) {
      _isLoggedIn = false;
      _isAuthLoading = false;
      notifyListeners();
      return;
    }
    _isLoggedIn = await _authService.hasValidSession();
    if (_isLoggedIn) {
      try {
        await _loadAccountState();
      } catch (_) {
        await _authService.signOut();
        _isLoggedIn = false;
      }
    }
    _isAuthLoading = false;
    notifyListeners();
  }

  Future<AuthResult> login(String email, String password) async {
    final result = await _authService.signIn(
      email: email.trim(),
      password: password,
    );
    if (result.success) {
      _lastLoginDateFallback = DateTime.now();
      try {
        await _loadAccountState();
      } catch (_) {
        await _authService.signOut();
        return const AuthResult.failure(
          'Unable to load this teacher profile right now.',
        );
      }
      _isLoggedIn = true;
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    _submissionsChannel?.unsubscribe();
    _submissionsChannel = null;
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
    await _authService.signOut();
    _isLoggedIn = false;
    _isPasswordRecovery = false;
    _selectedStudentForEvaluation = null;
    _viewedSubmissionIds.clear();
    _lastLoginDateFallback = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<AuthResult> updatePassword(String password) {
    return _authService.updatePassword(password);
  }

  Future<AuthResult> completePasswordReset(
    String password,
    String confirmPassword,
  ) async {
    if (password != confirmPassword) {
      return const AuthResult.failure('Passwords do not match.');
    }
    final result = await _authService.updatePassword(password);
    if (result.success) {
      _isPasswordRecovery = false;
      _isLoggedIn = false;
      await _authService.signOut();
      notifyListeners();
    }
    return result;
  }

  Future<String?> updateProfilePicture() async {
    if (_isUploadingAvatar) return null;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return null;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return 'Unable to read the selected image.';
    }

    _isUploadingAvatar = true;
    notifyListeners();
    try {
      _account = await _teacherRepository.updateCurrentProfileAvatar(
        bytes: bytes,
        fileName: file.name,
      );
      return null;
    } catch (_) {
      return 'Unable to update profile picture right now.';
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  Future<String?> refreshData() async {
    if (_isRefreshingData || !_isLoggedIn) return null;

    _isRefreshingData = true;
    notifyListeners();
    try {
      await _loadAccountState();
      return _teacherDataError;
    } catch (_) {
      return 'Unable to refresh teacher data right now.';
    } finally {
      _isRefreshingData = false;
      notifyListeners();
    }
  }

  Future<void> _loadViewedSubmissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'teacher_viewed_submissions_${_account.email}';
      final list = prefs.getStringList(key);
      if (list != null) {
        _viewedSubmissionIds = list.toSet();
      }
    } catch (_) {}
  }

  Future<void> _loadLastLoginDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'teacher_last_login_${_account.email}';
      if (_account.lastSignInAt != null) {
        await prefs.setString(key, _account.lastSignInAt!.toIso8601String());
      } else {
        final cached = prefs.getString(key);
        if (cached != null && cached.isNotEmpty) {
          final parsed = DateTime.tryParse(cached);
          if (parsed != null) {
            _lastLoginDateFallback = parsed;
          }
        }
      }
    } catch (_) {}
  }

  Future<String> getSignedVideoUrl(String videoPath) {
    return _teacherRepository.getSignedVideoUrl(videoPath);
  }

  Future<void> _loadAccountState() async {
    _teacherRepository.clearCache();
    _account = await _teacherRepository.getCurrentAccount();
    await _loadViewedSubmissions();
    await _loadLastLoginDate();
    _isTeacherDataLoading = true;
    _teacherDataError = null;
    notifyListeners();
    try {
      _assignedSections = await _teacherRepository.getAssignedSections();
      _books = await _teacherRepository.getCurrentBooks();
      _readingReviewsByStudent = await _teacherRepository
          .getCurrentReadingReviews();
      _evaluations = {};
      for (final entry in _readingReviewsByStudent.entries) {
        if (entry.value.isNotEmpty) {
          _evaluations[entry.key] =
              _extractEvaluationFromSubmission(entry.value.first);
        }
      }
      _students = await _teacherRepository.getCurrentStudents();
      _classes = await _teacherRepository.getCurrentClasses();
      _activities = await _teacherRepository.getCurrentActivities();
      if (_selectedStudentForEvaluation != null &&
          !_students.any(
            (student) => student.id == _selectedStudentForEvaluation!.id,
          )) {
        _selectedStudentForEvaluation = null;
      }
      _subscribeToSubmissionsRealtime();
    } catch (error) {
      _teacherDataError =
          'Unable to load teacher dashboard data right now. ${error.toString()}';
    } finally {
      _isTeacherDataLoading = false;
      notifyListeners();
    }
  }

  StudentProgress _copyStudent(
    StudentProgress student, {
    List<String>? badges,
    String? skillLevel,
    int? readingLevel,
    int? vocabularySkillLevel,
    int? wordMasterLevel,
    int? comprehensionLevel,
  }) {
    return StudentProgress(
      id: student.id,
      name: student.name,
      readingAccuracy: student.readingAccuracy,
      vocabularyLevel: student.vocabularyLevel,
      progressCurrent: student.progressCurrent,
      progressTotal: student.progressTotal,
      status: student.status,
      badges: badges ?? student.badges,
      grade: student.grade,
      section: student.section,
      avatarUrl: student.avatarUrl,
      skillLevel: skillLevel ?? student.skillLevel,
      readingLevel: readingLevel ?? student.readingLevel,
      vocabularySkillLevel:
          vocabularySkillLevel ?? student.vocabularySkillLevel,
      wordMasterLevel: wordMasterLevel ?? student.wordMasterLevel,
      comprehensionLevel: comprehensionLevel ?? student.comprehensionLevel,
    );
  }

  void _listenForPasswordRecovery() {
    final client = SupabaseService.client;
    if (client == null) return;
    _authStateSubscription = client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        _isLoggedIn = false;
        _isAuthLoading = false;
        notifyListeners();
      }
    });
  }

  bool _isPasswordRecoveryRedirect() {
    final uri = Uri.base;
    return uri.queryParameters['type'] == 'recovery' ||
        uri.fragment.contains('type=recovery') ||
        uri.toString().contains('type=recovery');
  }

  Future<void> refreshReadingReviews() async {
    try {
      _readingReviewsByStudent =
          await _teacherRepository.getCurrentReadingReviews();
      _evaluations = {};
      for (final entry in _readingReviewsByStudent.entries) {
        if (entry.value.isNotEmpty) {
          _evaluations[entry.key] =
              _extractEvaluationFromSubmission(entry.value.first);
        }
      }
      _activities = await _teacherRepository.getCurrentActivities();
      notifyListeners();
    } catch (_) {
      // Best-effort background refresh
    }
  }

  void _subscribeToSubmissionsRealtime() {
    final client = SupabaseService.client;
    if (client == null) return;
    _submissionsChannel?.unsubscribe();
    _submissionsChannel = client
        .channel('public:reading_submissions_teacher')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reading_submissions',
          callback: (_) {
            unawaited(refreshReadingReviews());
          },
        )
        .subscribe();

    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isLoggedIn && !_isTeacherDataLoading) {
        unawaited(refreshReadingReviews());
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _submissionsChannel?.unsubscribe();
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }
}
