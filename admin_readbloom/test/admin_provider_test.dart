import 'package:flutter_test/flutter_test.dart';
import 'package:admin_readbloom/providers/admin_provider.dart';
import 'package:admin_readbloom/services/auth_service.dart';

class ResetPasswordAdminAuthService implements AuthService {
  String? updatedPassword;
  bool signedOut = false;

  @override
  AppRole get requiredRole => AppRole.admin;

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

void main() {
  test('createUser adds a user through repository boundary', () async {
    final provider = AdminProvider();
    final initialCount = provider.users.length;

    final error = await provider.createUser(
      'New Student',
      'new.student@example.com',
      'temporary-password',
      'Student',
      'grade-4-mabini',
      gradeLevel: 'Grade 4',
    );

    expect(error, isNull);
    expect(provider.users.length, initialCount + 1);
    expect(provider.users.last.email, 'new.student@example.com');
  });

  test('deleteUser removes user and active session', () async {
    final provider = AdminProvider();
    await provider.createUser(
      'Delete Me',
      'delete.me@example.com',
      'temporary-password',
      'Student',
      'section-1',
      gradeLevel: 'Grade 4',
    );
    final userId = provider.users.first.id;

    await provider.deleteUser(userId);

    expect(provider.users.any((user) => user.id == userId), isFalse);
    expect(provider.activeSessions.any((user) => user.id == userId), isFalse);
  });

  test('deleteAccount removes student or teacher account', () async {
    final provider = AdminProvider();
    await provider.createUser(
      'Delete Account',
      'delete.account@example.com',
      'temporary-password',
      'Student',
      'section-1',
      gradeLevel: 'Grade 4',
    );
    final userId = provider.users.first.id;

    final error = await provider.deleteAccount(userId);

    expect(error, isNull);
    expect(provider.users.any((user) => user.id == userId), isFalse);
  });

  test('disableUser marks the account disabled', () async {
    final provider = AdminProvider();
    await provider.createUser(
      'Disable Me',
      'disable.me@example.com',
      'temporary-password',
      'Student',
      'section-1',
      gradeLevel: 'Grade 4',
    );
    final userId = provider.users.first.id;

    final error = await provider.disableUser(userId);

    expect(error, isNull);
    expect(
      provider.users.firstWhere((user) => user.id == userId).status,
      'Disabled',
    );
  });

  test('addSection and deleteSection update section choices', () async {
    final provider = AdminProvider();

    final addError = await provider.addSection('Grade 7', 'Luna');
    final section = provider.sections.firstWhere(
      (section) => section.label == 'Grade 7 - Luna',
    );
    final deleteError = await provider.deleteSection(section.id);

    expect(addError, isNull);
    expect(deleteError, isNull);
    expect(
      provider.sections.any((section) => section.label == 'Grade 7 - Luna'),
      isFalse,
    );
  });

  test('password reset rejects mismatched confirmation', () async {
    final auth = ResetPasswordAdminAuthService();
    final provider = AdminProvider(authService: auth);

    final result = await provider.completePasswordReset('new-pass', 'wrong');

    expect(result.success, isFalse);
    expect(result.message, 'Passwords do not match.');
    expect(auth.updatedPassword, isNull);
  });

  test('password reset updates password and signs out', () async {
    final auth = ResetPasswordAdminAuthService();
    final provider = AdminProvider(authService: auth);

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
}
