import 'dart:async';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_models.dart';
import '../repositories/student_repository.dart';
import '../services/auth_service.dart';
import '../services/profile_image_picker.dart';
import '../services/supabase_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentRepository _studentRepository;
  final AuthService _authService;
  late StudentProfile _profile;
  late List<Story> _stories;
  List<StudentMessage> _messages = const [];

  Story? _selectedStory;
  StudentMessage? _selectedMessage;
  bool _isLoggedIn = false;
  bool _isAuthLoading = true;
  bool _isPasswordRecovery = false;
  bool _hasAcceptedPrivacy = false;
  bool _isSplashDone = false;
  bool _isUploadingAvatar = false;
  bool _isStoriesLoading = false;
  bool _isMessagesLoading = false;
  bool _isCameraInitializing = false;
  bool _isRecording = false;
  bool _isStoppingRecording = false;
  bool _isRecordingOvertime = false;
  bool _hasReachedRecordingTimeLimit = false;
  bool _isUploadingReading = false;
  bool _isSubmittingQuiz = false;
  bool _isRefreshingData = false;
  String? _storiesError;
  String? _messagesError;
  String? _recordingError;
  String? _readingUploadError;
  String? _quizSubmissionError;
  int _currentQuizQuestionIndex = 0;
  int _score = 0;
  int _recordingElapsedSeconds = 0;
  double _readingUploadProgress = 0;
  Timer? _recordingTimer;
  StreamSubscription<AuthState>? _authStateSubscription;
  CameraController? _cameraController;
  XFile? _recordedVideo;
  ReadingSubmission? _lastReadingSubmission;
  List<int?> _quizSelectedOptionIndices = const [];

  static const int readingTimeLimitSeconds = 300;
  static const ResolutionPreset recordingResolutionPreset =
      ResolutionPreset.low;
  static const int recordingVideoBitrate = 300000;
  static const int recordingAudioBitrate = 64000;
  static const int recordingFps = 24;

  // Audio calibration level (0.0 to 1.0)
  double _micLevel = 0.5;

  StudentProvider({
    StudentRepository? studentRepository,
    AuthService? authService,
  }) : _studentRepository = studentRepository ?? SupabaseStudentRepository(),
       _authService = authService ?? SupabaseRoleAuthService(AppRole.student) {
    _profile = _studentRepository.getProfile();
    _stories = _studentRepository.getAssignedStories();
    _isPasswordRecovery = _isPasswordRecoveryRedirect();
    _listenForPasswordRecovery();
    restoreSession();
  }

  StudentProfile get profile => _profile;
  List<Story> get stories => _stories;
  int get totalBooksCount {
    if (_stories.isNotEmpty) return _stories.length;
    return _profile.progressTotal;
  }

  int get learningCompletedCount {
    final total = totalBooksCount;
    if (total == 0) return 0;
    return _profile.progressCurrent.clamp(0, total);
  }

  List<StudentMessage> get messages => _messages;
  int get unreadMessagesCount => _messages.where((m) => m.isUnread).length;
  bool get hasUnreadFeedback => _messages.any((m) => m.isUnread);
  Story? get selectedStory =>
      _selectedStory ?? (_stories.isNotEmpty ? _stories[0] : null);
  StudentMessage? get selectedMessage => _selectedMessage;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthLoading => _isAuthLoading;
  bool get isPasswordRecovery => _isPasswordRecovery;
  bool get hasAcceptedPrivacy => _hasAcceptedPrivacy;
  bool get isSplashDone => _isSplashDone;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isStoriesLoading => _isStoriesLoading;
  bool get isMessagesLoading => _isMessagesLoading;
  bool get isCameraInitializing => _isCameraInitializing;
  bool get isRecording => _isRecording;
  bool get isStoppingRecording => _isStoppingRecording;
  bool get isRecordingOvertime => _isRecordingOvertime;
  bool get hasReachedRecordingTimeLimit => _hasReachedRecordingTimeLimit;
  bool get isUploadingReading => _isUploadingReading;
  bool get isSubmittingQuiz => _isSubmittingQuiz;
  bool get isRefreshingData => _isRefreshingData;
  String? get storiesError => _storiesError;
  String? get messagesError => _messagesError;
  String? get recordingError => _recordingError;
  String? get readingUploadError => _readingUploadError;
  QuizSubmissionResult? _lastQuizResult;
  QuizSubmissionResult? get lastQuizResult => _lastQuizResult;
  String? get quizSubmissionError => _quizSubmissionError;
  int get currentQuizQuestionIndex => _currentQuizQuestionIndex;
  int get score => _score;
  int get recordingElapsedSeconds => _recordingElapsedSeconds;
  int get recordingRemainingSeconds =>
      readingTimeLimitSeconds - _recordingElapsedSeconds;
  CameraController? get cameraController => _cameraController;
  XFile? get recordedVideo => _recordedVideo;
  double get readingUploadProgress => _readingUploadProgress;
  ReadingSubmission? get lastReadingSubmission => _lastReadingSubmission;
  double get micLevel => _micLevel;

  void selectStory(Story story) {
    _selectedStory = story;
    resetQuiz(notify: false);
    notifyListeners();
  }

  void markSplashDone() {
    _isSplashDone = true;
    notifyListeners();
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
      try {
        await _loadAccountState();
      } catch (_) {
        await _authService.signOut();
        return const AuthResult.failure(
          'Unable to load this student profile right now.',
        );
      }
      _isLoggedIn = true;
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    await _disposeCamera();
    await _authService.signOut();
    _isLoggedIn = false;
    _isPasswordRecovery = false;
    _hasAcceptedPrivacy = false;
    _selectedStory = null;
    _selectedMessage = null;
    _messages = const [];
    resetQuiz(notify: false);
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

  Future<void> acceptPrivacy() async {
    await _studentRepository.acceptActiveSafetyAgreement();
    _hasAcceptedPrivacy = true;
    notifyListeners();
  }

  Future<String?> updateProfilePicture() async {
    if (_isUploadingAvatar) return null;

    final image = await pickProfileImage();
    if (image == null) return null;
    if (image.bytes.isEmpty) {
      return 'Unable to read the selected image.';
    }

    _isUploadingAvatar = true;
    notifyListeners();
    try {
      _profile = await _studentRepository.updateCurrentProfileAvatar(
        bytes: image.bytes,
        fileName: image.fileName,
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
      return null;
    } catch (_) {
      return 'Unable to refresh student data right now.';
    } finally {
      _isRefreshingData = false;
      notifyListeners();
    }
  }

  Future<String?> prepareRecordingSession() async {
    if (_cameraController?.value.isInitialized == true) return null;

    _isCameraInitializing = true;
    _recordingError = null;
    notifyListeners();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _recordingError = 'No camera was found on this device.';
        return _recordingError;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      CameraController controller = CameraController(
        camera,
        recordingResolutionPreset,
        enableAudio: true,
        fps: recordingFps,
        videoBitrate: recordingVideoBitrate,
        audioBitrate: recordingAudioBitrate,
      );
      try {
        await controller.initialize();
      } catch (_) {
        controller = CameraController(
          camera,
          recordingResolutionPreset,
          enableAudio: true,
          videoBitrate: recordingVideoBitrate,
          audioBitrate: recordingAudioBitrate,
        );
        await controller.initialize();
      }
      _cameraController = controller;
      return null;
    } catch (_) {
      await _disposeCamera();
      _recordingError =
          'Camera or microphone permission is needed before reading.';
      return _recordingError;
    } finally {
      _isCameraInitializing = false;
      notifyListeners();
    }
  }

  Future<String?> startReadingRecording() async {
    final prepareError = await prepareRecordingSession();
    if (prepareError != null) return prepareError;

    final controller = _cameraController;
    if (controller == null || controller.value.isRecordingVideo) return null;

    _recordedVideo = null;
    _lastReadingSubmission = null;
    _readingUploadProgress = 0;
    _readingUploadError = null;
    resetQuiz(notify: false);
    _recordingElapsedSeconds = 0;
    _isRecordingOvertime = false;
    _hasReachedRecordingTimeLimit = false;
    _isRecording = true;
    _recordingError = null;
    notifyListeners();

    try {
      await controller.startVideoRecording();
      try {
        await CameraPlatform.instance.resumePreview(controller.cameraId);
      } catch (_) {
        // Best-effort: Some camera platforms do not require or support explicit resumePreview calls.
      }
      _startRecordingTimer();
      return null;
    } catch (_) {
      _isRecording = false;
      _recordingError = 'Unable to start recording right now.';
      notifyListeners();
      return _recordingError;
    }
  }

  Future<void> resumeCameraPreview() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await CameraPlatform.instance.resumePreview(controller.cameraId);
    } catch (_) {
      // Best-effort preview resume.
    }
  }

  Future<String?> stopReadingRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isRecordingVideo) {
      if (_recordedVideo != null) return null;
      return 'No active recording was found.';
    }

    _isStoppingRecording = true;
    notifyListeners();
    try {
      _recordedVideo = await controller.stopVideoRecording();
      _isRecording = false;
      _hasReachedRecordingTimeLimit = false;
      _stopRecordingTimer();
      return null;
    } catch (_) {
      _recordingError = 'Unable to stop recording right now.';
      return _recordingError;
    } finally {
      _isStoppingRecording = false;
      notifyListeners();
    }
  }

  Future<void> cancelReadingRecording() async {
    final controller = _cameraController;
    if (controller?.value.isRecordingVideo == true) {
      try {
        await controller!.stopVideoRecording();
      } catch (_) {}
    }
    await discardRecordedVideo();
    await _disposeCamera();
    notifyListeners();
  }

  Future<void> discardRecordedVideo() async {
    _recordedVideo = null;
    _lastReadingSubmission = null;
    _readingUploadProgress = 0;
    _readingUploadError = null;
    resetQuiz(notify: false);
    _isRecording = false;
    _isStoppingRecording = false;
    _isRecordingOvertime = false;
    _hasReachedRecordingTimeLimit = false;
    _recordingElapsedSeconds = 0;
    _recordingError = null;
    _stopRecordingTimer();
    notifyListeners();
  }

  Future<void> finishPreviewForUpload() async {
    _stopRecordingTimer();
    await _disposeCamera();
  }

  Future<String?> uploadRecordedReading() async {
    if (_isUploadingReading) return null;

    final story = selectedStory;
    final video = _recordedVideo;
    if (story == null) return 'No selected book was found.';
    if (video == null) return 'No recorded video was found.';

    _isUploadingReading = true;
    _readingUploadError = null;
    _readingUploadProgress = _lastReadingSubmission == null ? 0.05 : 0.75;
    notifyListeners();

    try {
      if (_lastReadingSubmission == null) {
        final videoBytes = await video.readAsBytes();
        if (videoBytes.isEmpty) {
          throw StateError('Recorded video file is empty.');
        }

        _readingUploadProgress = 0.25;
        notifyListeners();

        final fileName = video.name.trim().isNotEmpty ? video.name : video.path;
        _lastReadingSubmission = await _studentRepository
            .uploadReadingSubmission(
              story: story,
              videoBytes: videoBytes,
              fileName: fileName,
              durationSeconds: _recordingElapsedSeconds,
              timeLimitSeconds: readingTimeLimitSeconds,
              isOvertime: _isRecordingOvertime,
            );

        _readingUploadProgress = 0.75;
        notifyListeners();
      }

      await _studentRepository.processReadingSubmission(
        _lastReadingSubmission!.id,
      );

      _readingUploadProgress = 1;
      notifyListeners();
      return null;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      _readingUploadError = message.isEmpty
          ? 'Unable to process your reading video right now.'
          : 'Unable to process your reading video right now. $message';
      return _readingUploadError;
    } finally {
      _isUploadingReading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAccountState() async {
    _studentRepository.clearCache();
    _profile = await _studentRepository.getCurrentProfile();
    _hasAcceptedPrivacy = await _studentRepository
        .hasAcceptedActiveSafetyAgreement();
    await loadAssignedStories();
    await loadMessages();
  }

  Future<void> loadAssignedStories() async {
    _isStoriesLoading = true;
    _storiesError = null;
    notifyListeners();
    try {
      _stories = await _studentRepository.getCurrentAssignedStories();
      if (_stories.isNotEmpty && _profile.progressTotal != _stories.length) {
        _profile = _profile.copyWith(progressTotal: _stories.length);
      }
      if (_selectedStory != null &&
          !_stories.any((story) => story.id == _selectedStory!.id)) {
        _selectedStory = null;
      }
    } catch (_) {
      _storiesError = 'Unable to load assigned books right now.';
    } finally {
      _isStoriesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages() async {
    _isMessagesLoading = true;
    _messagesError = null;
    notifyListeners();
    try {
      _messages = await _studentRepository.getCurrentMessages();
      if (_selectedMessage != null &&
          !_messages.any((message) => message.id == _selectedMessage!.id)) {
        _selectedMessage = null;
      }
    } catch (_) {
      _messagesError = 'Unable to load messages right now.';
    } finally {
      _isMessagesLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectMessage(StudentMessage message) async {
    _selectedMessage = message;
    notifyListeners();
    if (!message.isUnread) return;
    try {
      await _studentRepository.markMessageRead(message.id);
      _messages = _messages.map((current) {
        if (current.id != message.id) return current;
        return StudentMessage(
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
      }).toList();
      _selectedMessage = _messages.firstWhere(
        (current) => current.id == message.id,
        orElse: () => message,
      );
      notifyListeners();
    } catch (_) {}
  }

  void clearSelectedMessage() {
    _selectedMessage = null;
    notifyListeners();
  }

  void setMicLevel(double val) {
    _micLevel = val;
    notifyListeners();
  }

  bool canStartStory(Story story) =>
      !story.isLocked &&
      story.text.trim().isNotEmpty &&
      story.questions.isNotEmpty;

  bool answerQuizQuestion(int optionIndex) {
    final story = selectedStory;
    if (story == null ||
        story.questions.isEmpty ||
        _currentQuizQuestionIndex < 0 ||
        _currentQuizQuestionIndex >= story.questions.length) {
      return false;
    }

    _ensureQuizAnswerSlots(story.questions.length);
    final question = story.questions[_currentQuizQuestionIndex];
    final previousOption =
        _quizSelectedOptionIndices[_currentQuizQuestionIndex];
    final wasCorrect = previousOption == question.correctAnswerIndex;
    final isCorrect = optionIndex == question.correctAnswerIndex;
    _quizSelectedOptionIndices[_currentQuizQuestionIndex] = optionIndex;

    if (!wasCorrect && isCorrect) {
      _score++;
    } else if (wasCorrect && !isCorrect) {
      _score--;
    }
    if (_currentQuizQuestionIndex < story.questions.length - 1) {
      _currentQuizQuestionIndex++;
    }
    notifyListeners();
    return true;
  }

  Future<String?> submitQuizAnswers() async {
    if (_isSubmittingQuiz) return null;

    final story = selectedStory;
    final submission = _lastReadingSubmission;
    if (story == null || story.questions.isEmpty) {
      return 'No quiz was found for this book.';
    }
    if (submission == null) {
      return 'No uploaded reading submission was found.';
    }

    _ensureQuizAnswerSlots(story.questions.length);
    if (_quizSelectedOptionIndices.any((answer) => answer == null)) {
      return 'Please answer all quiz questions before finishing.';
    }

    final answers = <QuizAnswerDraft>[];
    for (var index = 0; index < story.questions.length; index++) {
      final selectedIndex = _quizSelectedOptionIndices[index]!;
      final question = story.questions[index];
      answers.add(
        QuizAnswerDraft(
          questionId: question.id,
          selectedOptionIndex: selectedIndex,
          isCorrect: selectedIndex == question.correctAnswerIndex,
        ),
      );
    }

    _isSubmittingQuiz = true;
    _quizSubmissionError = null;
    notifyListeners();
    try {
      _lastQuizResult = await _studentRepository.submitQuizAnswers(
        submission: submission,
        story: story,
        answers: answers,
        score: _score,
      );
      try {
        _profile = await _studentRepository.getCurrentProfile();
      } catch (_) {}
      return null;
    } catch (_) {
      _quizSubmissionError =
          'Unable to submit your quiz answers right now. Please try again.';
      return _quizSubmissionError;
    } finally {
      _isSubmittingQuiz = false;
      notifyListeners();
    }
  }

  void resetQuiz({bool notify = true}) {
    _currentQuizQuestionIndex = 0;
    _score = 0;
    _quizSelectedOptionIndices = const [];
    _quizSubmissionError = null;
    _isSubmittingQuiz = false;
    _lastQuizResult = null;
    if (notify) notifyListeners();
  }

  void _ensureQuizAnswerSlots(int questionCount) {
    if (_quizSelectedOptionIndices.length == questionCount) return;
    _quizSelectedOptionIndices = List<int?>.filled(questionCount, null);
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingElapsedSeconds >= readingTimeLimitSeconds) {
        _recordingElapsedSeconds = readingTimeLimitSeconds;
        _isRecordingOvertime = false;
        _stopRecordingTimer();
        unawaited(_stopRecordingAtTimeLimit());
        notifyListeners();
        return;
      }

      _recordingElapsedSeconds++;
      if (_recordingElapsedSeconds >= readingTimeLimitSeconds) {
        _recordingElapsedSeconds = readingTimeLimitSeconds;
        _isRecordingOvertime = false;
        _stopRecordingTimer();
        unawaited(_stopRecordingAtTimeLimit());
      }
      notifyListeners();
    });
  }

  Future<void> _stopRecordingAtTimeLimit() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isRecordingVideo) return;

    _isStoppingRecording = true;
    notifyListeners();
    try {
      _recordedVideo = await controller.stopVideoRecording();
      _isRecording = false;
      _recordingElapsedSeconds = readingTimeLimitSeconds;
      _isRecordingOvertime = false;
      _hasReachedRecordingTimeLimit = true;
      _recordingError =
          'The 5-minute reading limit was reached. Review your recording before uploading.';
    } catch (_) {
      _recordingError = 'Unable to stop recording at the time limit.';
    } finally {
      _isStoppingRecording = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void debugSetRecordingElapsedSeconds(int seconds) {
    _recordingElapsedSeconds = seconds < 0 ? 0 : seconds;
    if (_recordingElapsedSeconds > readingTimeLimitSeconds) {
      _recordingElapsedSeconds = readingTimeLimitSeconds;
    }
    _isRecordingOvertime = false;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetCameraController(CameraController? controller) {
    _cameraController = controller;
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
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

  Future<void> disposeCamera() async {
    await _disposeCamera();
    notifyListeners();
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _stopRecordingTimer();
    _cameraController?.dispose();
    super.dispose();
  }
}
