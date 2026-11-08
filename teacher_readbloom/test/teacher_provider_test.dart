import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_readbloom/models/teacher_models.dart';
import 'package:teacher_readbloom/providers/teacher_provider.dart';
import 'package:teacher_readbloom/repositories/teacher_repository.dart';
import 'package:teacher_readbloom/services/auth_service.dart';

class ResetPasswordTeacherAuthService implements AuthService {
  String? updatedPassword;
  bool signedOut = false;

  @override
  AppRole get requiredRole => AppRole.teacher;

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

class BadgeFixtureTeacherRepository extends MockTeacherRepository {
  final List<StudentProgress> _students = [
    StudentProgress(
      id: 'student-1',
      name: 'Student One',
      readingAccuracy: 0,
      vocabularyLevel: 0,
      progressCurrent: 0,
      progressTotal: 0,
      status: '',
      badges: const ['Existing Badge'],
      grade: 'Grade 4',
      section: 'Section A',
    ),
  ];

  @override
  List<StudentProgress> getStudents() => List.unmodifiable(_students);

  @override
  Future<List<StudentProgress>> getCurrentStudents() async => getStudents();
}

class FailingGenerateTeacherRepository extends MockTeacherRepository {
  @override
  Future<GeneratedBookDraft> generateBookDraft({
    required String prompt,
    required String grade,
    required String section,
    required int quizCount,
    required String passageLength,
  }) {
    throw StateError('generation failed');
  }
}

void main() {
  test('addBook appends a valid book through repository boundary', () async {
    final provider = TeacherProvider();
    final initialCount = provider.books.length;

    final error = await provider.addBook(
      title: 'New Passage',
      grade: 'Grade 4',
      section: 'Section A',
      content: 'Passage text',
      questions: const [
        BookQuestionInput(
          questionText: 'What is the title?',
          options: ['New Passage', 'Old Passage'],
          correctOptionIndex: 0,
        ),
        BookQuestionInput(
          questionText: 'What kind of text is this?',
          options: ['Passage', 'Poem'],
          correctOptionIndex: 0,
        ),
      ],
    );

    expect(error, isNull);
    expect(provider.books.length, initialCount + 1);
    expect(provider.books.last.title, 'New Passage');
    expect(provider.books.last.questions, hasLength(2));
  });

  test('addBadgeToStudent does not duplicate badges', () async {
    final provider = TeacherProvider(
      teacherRepository: BadgeFixtureTeacherRepository(),
    );
    final student = provider.students.first;
    final initialBadgeCount = student.badges.length;

    await provider.addBadgeToStudent(student.id, student.badges.first);

    expect(provider.students.first.badges.length, initialBadgeCount);
  });

  test('generateBookDraft rejects empty prompt', () async {
    final provider = TeacherProvider();

    final draft = await provider.generateBookDraft(
      prompt: '   ',
      grade: 'Grade 4',
      section: 'Section A',
      quizCount: 3,
      passageLength: 'short',
    );

    expect(draft, isNull);
    expect(provider.generateBookDraftError, 'Please enter a prompt first.');
  });

  test('generateBookDraft rejects missing section', () async {
    final provider = TeacherProvider();

    final draft = await provider.generateBookDraft(
      prompt: 'Create a story.',
      grade: 'Grade 4',
      section: '',
      quizCount: 3,
      passageLength: 'short',
    );

    expect(draft, isNull);
    expect(
      provider.generateBookDraftError,
      'Please choose a grade and section first.',
    );
  });

  test('generateBookDraft rejects quiz count outside one to three', () async {
    final provider = TeacherProvider();

    final draft = await provider.generateBookDraft(
      prompt: 'Create a story.',
      grade: 'Grade 4',
      section: 'Section A',
      quizCount: 4,
      passageLength: 'short',
    );

    expect(draft, isNull);
    expect(
      provider.generateBookDraftError,
      'Quiz count must be between 1 and 3.',
    );
  });

  test('generateBookDraft returns draft without saving a book', () async {
    final provider = TeacherProvider();
    final initialBookCount = provider.books.length;

    final draft = await provider.generateBookDraft(
      prompt: 'Create a story about teamwork.',
      grade: 'Grade 4',
      section: 'Section A',
      quizCount: 2,
      passageLength: 'short',
    );

    expect(draft, isNotNull);
    expect(draft!.questions, hasLength(2));
    expect(provider.books.length, initialBookCount);
    expect(provider.generateBookDraftError, isNull);
  });

  test('generateBookDraft exposes readable repository failure', () async {
    final provider = TeacherProvider(
      teacherRepository: FailingGenerateTeacherRepository(),
    );

    final draft = await provider.generateBookDraft(
      prompt: 'Create a story.',
      grade: 'Grade 4',
      section: 'Section A',
      quizCount: 1,
      passageLength: 'short',
    );

    expect(draft, isNull);
    expect(
      provider.generateBookDraftError,
      'Unable to generate book content right now.',
    );
  });

  test('password reset rejects mismatched confirmation', () async {
    final auth = ResetPasswordTeacherAuthService();
    final provider = TeacherProvider(authService: auth);

    final result = await provider.completePasswordReset('new-pass', 'wrong');

    expect(result.success, isFalse);
    expect(result.message, 'Passwords do not match.');
    expect(auth.updatedPassword, isNull);
  });

  test('password reset updates password and signs out', () async {
    final auth = ResetPasswordTeacherAuthService();
    final provider = TeacherProvider(authService: auth);

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

  test('lastLoginDate formats account lastSignInAt correctly', () async {
    final account = TeacherAccount(
      name: 'Test Teacher',
      school: 'Test School',
      email: 'test@example.com',
      lastSignInAt: DateTime.utc(2026, 9, 27, 14, 51),
    );
    final repo = _CustomAccountTeacherRepository(account);
    final provider = TeacherProvider(
      teacherRepository: repo,
      authService: ResetPasswordTeacherAuthService(),
    );

    final expectedLocal = account.lastSignInAt!.toLocal();
    final expectedStr =
        '${expectedLocal.month}/${expectedLocal.day}/${expectedLocal.year}';
    expect(provider.lastLoginDate, expectedStr);
  });

  test('lastLoginDate falls back to today on successful login', () async {
    final repo = MockTeacherRepository();
    final provider = TeacherProvider(
      teacherRepository: repo,
      authService: ResetPasswordTeacherAuthService(),
    );

    final loginResult = await provider.login('teacher@test.com', 'pass123');
    expect(loginResult.success, isTrue);

    final now = DateTime.now();
    expect(provider.lastLoginDate, '${now.month}/${now.day}/${now.year}');
  });

  test('updateStudentSkillLevels clamps skill levels to maximum 10 and minimum 1', () async {
    final repo = BadgeFixtureTeacherRepository();
    final provider = TeacherProvider(
      teacherRepository: repo,
      authService: ResetPasswordTeacherAuthService(),
    );

    expect(provider.students.isNotEmpty, isTrue);
    final studentId = provider.students.first.id;

    final error = await provider.updateStudentSkillLevels(
      studentId: studentId,
      readingLevel: 15,
      vocabularyLevel: 11,
      wordMasterLevel: 10,
      comprehensionLevel: 0,
    );

    expect(error, isNull);
    final updated = provider.students.firstWhere((s) => s.id == studentId);
    expect(updated.readingLevel, 10);
    expect(updated.vocabularySkillLevel, 10);
    expect(updated.wordMasterLevel, 10);
    expect(updated.comprehensionLevel, 1);
  });
}

class _CustomAccountTeacherRepository extends MockTeacherRepository {
  final TeacherAccount _customAccount;

  _CustomAccountTeacherRepository(this._customAccount);

  @override
  TeacherAccount getAccount() => _customAccount;

  @override
  Future<TeacherAccount> getCurrentAccount() async => _customAccount;
}

