import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';
import '../repositories/admin_repository.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository;
  final AuthService _authService;
  late final double _storageUsage;
  late final List<SystemStatus> _statuses;
  late List<SystemActivity> _activities;
  late AdminAccount _account;
  late List<AdminUser> _users;
  late List<AdminUser> _activeSessions;
  List<AdminSection> _sections = const [];
  List<AdminBook> _books = const [];
  List<AdminReadingHistory> _readingHistories = const [];

  bool _isLoggedIn = false;
  bool _isAuthLoading = true;
  bool _isPasswordRecovery = false;
  bool _isUploadingAvatar = false;
  bool _isUserActionLoading = false;
  bool _isRefreshingData = false;
  String? _adminDataError;
  StreamSubscription<AuthState>? _authStateSubscription;

  AdminProvider({AdminRepository? adminRepository, AuthService? authService})
    : _adminRepository = adminRepository ?? SupabaseAdminRepository(),
      _authService = authService ?? SupabaseRoleAuthService(AppRole.admin) {
    _storageUsage = _adminRepository.getStorageUsage();
    _statuses = _adminRepository.getStatuses();
    _activities = _adminRepository.getActivities();
    _account = _adminRepository.getAccount();
    _users = _adminRepository.getUsers();
    _activeSessions = _adminRepository.getActiveSessions();
    _isPasswordRecovery = _isPasswordRecoveryRedirect();
    _listenForPasswordRecovery();
    restoreSession();
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthLoading => _isAuthLoading;
  bool get isPasswordRecovery => _isPasswordRecovery;
  double get storageUsage => _storageUsage;
  List<SystemStatus> get statuses => _statuses;
  List<SystemActivity> get activities => _activities;
  AdminAccount get account => _account;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isUserActionLoading => _isUserActionLoading;
  bool get isRefreshingData => _isRefreshingData;
  String? get adminDataError => _adminDataError;
  List<AdminUser> get users => _users;
  List<AdminUser> get activeSessions => _activeSessions;
  List<AdminSection> get sections => _sections;
  List<AdminBook> get books => _books;
  List<AdminReadingHistory> get readingHistories => _readingHistories;

  void forceLogoutUser(String userId) {
    _adminRepository.forceLogoutUser(userId);
    _activeSessions = _adminRepository.getActiveSessions();
    notifyListeners();
  }

  Future<String?> createUser(
    String name,
    String email,
    String password,
    String role,
    String sectionId, {
    String? gradeLevel,
    List<String> teacherSectionIds = const [],
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      return 'Full name, email, and password are required.';
    }

    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'student' && sectionId.trim().isEmpty) {
      return 'Student accounts require a section.';
    }
    if (normalizedRole == 'teacher' && teacherSectionIds.isEmpty) {
      return 'Teacher accounts require at least one assigned section.';
    }

    _isUserActionLoading = true;
    notifyListeners();
    try {
      await _adminRepository.createUser(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role,
        gradeLevel: gradeLevel?.trim(),
        sectionId: sectionId.trim().isEmpty ? null : sectionId.trim(),
        teacherSectionIds: teacherSectionIds,
      );
      await _refreshManagementData();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUserActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> disableUser(String userId) async {
    _isUserActionLoading = true;
    notifyListeners();
    try {
      await _adminRepository.disableUser(userId);
      await _refreshManagementData();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUserActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    _adminRepository.deleteUser(userId);
    await _refreshManagementData();
    notifyListeners();
  }

  Future<String?> deleteAccount(String userId) async {
    _isUserActionLoading = true;
    notifyListeners();
    try {
      await _adminRepository.deleteAccount(userId);
      await _refreshManagementData();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUserActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addSection(String gradeLevel, String sectionName) async {
    if (gradeLevel.trim().isEmpty || sectionName.trim().isEmpty) {
      return 'Grade and section name are required.';
    }
    final normalizedGrade = gradeLevel.trim().toLowerCase();
    final normalizedSection = sectionName.trim().toLowerCase();
    final alreadyExists = _sections.any(
      (section) =>
          section.gradeLevel.trim().toLowerCase() == normalizedGrade &&
          section.name.trim().toLowerCase() == normalizedSection,
    );
    if (alreadyExists) {
      return 'This grade and section already exists.';
    }

    _isUserActionLoading = true;
    notifyListeners();
    try {
      await _adminRepository.addSection(
        gradeLevel: gradeLevel.trim(),
        name: sectionName.trim(),
      );
      await _refreshManagementData();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUserActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteSection(String sectionId) async {
    _isUserActionLoading = true;
    notifyListeners();
    try {
      await _adminRepository.deleteSection(sectionId);
      await _refreshManagementData();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUserActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteBook(String bookId) async {
    _isUserActionLoading = true;
    notifyListeners();
    try {
      await _adminRepository.deleteBook(bookId);
      await _refreshManagementData();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUserActionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteReadingHistory(String submissionId) async {
    _isUserActionLoading = true;
    notifyListeners();
    try {
      await _adminRepository.deleteReadingHistory(submissionId);
      await _refreshManagementData();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUserActionLoading = false;
      notifyListeners();
    }
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
          'Unable to load this admin profile right now.',
        );
      }
      _isLoggedIn = true;
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    await _authService.signOut();
    _isLoggedIn = false;
    _isPasswordRecovery = false;
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
      _account = await _adminRepository.updateCurrentProfileAvatar(
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
      _account = await _adminRepository.getCurrentAccount();
      await _refreshManagementData();
      notifyListeners();
      return _adminDataError;
    } catch (_) {
      return 'Unable to refresh admin data right now.';
    } finally {
      _isRefreshingData = false;
      notifyListeners();
    }
  }

  Future<void> _loadAccountState() async {
    _account = await _adminRepository.getCurrentAccount();
    await _refreshManagementData();
  }

  Future<void> _refreshManagementData() async {
    _adminDataError = null;
    try {
      _users = await _adminRepository.getCurrentUsers();
      _sections = await _adminRepository.getCurrentSections();
      _books = await _adminRepository.getCurrentBooks();
      _readingHistories = await _adminRepository.getCurrentReadingHistories();
      _activeSessions = _adminRepository.getActiveSessions();
      _activities = await _adminRepository.getCurrentActivities();
    } catch (error) {
      _users = const [];
      _sections = const [];
      _books = const [];
      _readingHistories = const [];
      _activeSessions = const [];
      _activities = const [];
      _adminDataError =
          'Unable to load admin dashboard data right now. ${error.toString()}';
    }
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

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
