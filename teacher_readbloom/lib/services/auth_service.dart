import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum AppRole { student, teacher, admin }

class AuthResult {
  final bool success;
  final String? message;

  const AuthResult.success() : success = true, message = null;
  const AuthResult.failure(this.message) : success = false;
}

abstract class AuthService {
  AppRole get requiredRole;

  Future<bool> hasValidSession();

  Future<AuthResult> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<AuthResult> updatePassword(String password);
}

class MockTeacherAuthService implements AuthService {
  @override
  AppRole get requiredRole => AppRole.teacher;

  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const AuthResult.failure('Email and password are required.');
    }
    return const AuthResult.success();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthResult> updatePassword(String password) async {
    if (password.length < 6) {
      return const AuthResult.failure(
        'Password must be at least 6 characters.',
      );
    }
    return const AuthResult.success();
  }
}

class SupabaseRoleAuthService implements AuthService {
  SupabaseRoleAuthService(this.requiredRole);

  @override
  final AppRole requiredRole;

  String get _requiredRoleName => requiredRole.name;

  SupabaseClient? get _client => SupabaseService.client;

  @override
  Future<bool> hasValidSession() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return false;

    final result = await _validateCurrentUserRole();
    if (!result.success) {
      await signOut();
      return false;
    }
    return true;
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return const AuthResult.failure(
        'Supabase is not configured. Add the project URL and publishable key.',
      );
    }
    if (email.trim().isEmpty || password.isEmpty) {
      return const AuthResult.failure('Email and password are required.');
    }

    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final result = await _validateCurrentUserRole();
      if (!result.success) {
        await signOut();
      }
      return result;
    } on AuthException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return const AuthResult.failure('Unable to sign in right now.');
    }
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    await client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<AuthResult> updatePassword(String password) async {
    final client = _client;
    if (client == null) {
      return const AuthResult.failure('Supabase is not configured.');
    }
    if (password.length < 6) {
      return const AuthResult.failure(
        'Password must be at least 6 characters.',
      );
    }

    try {
      await client.auth.updateUser(UserAttributes(password: password));
      return const AuthResult.success();
    } on AuthException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return const AuthResult.failure('Unable to update password right now.');
    }
  }

  Future<AuthResult> _validateCurrentUserRole() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return const AuthResult.failure('No active session.');
    }

    final profile = await client
        .from('profiles')
        .select('role,status')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      return const AuthResult.failure('No profile is linked to this account.');
    }

    final role = profile['role'] as String?;
    final status = profile['status'] as String?;
    if (status != 'active') {
      return const AuthResult.failure('This account is disabled.');
    }
    if (role != _requiredRoleName) {
      return AuthResult.failure(
        'This account is not allowed in the $_requiredRoleName app.',
      );
    }
    return const AuthResult.success();
  }
}
