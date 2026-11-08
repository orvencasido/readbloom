import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_models.dart';
import '../services/supabase_service.dart';

abstract class AdminRepository {
  AdminAccount getAccount();
  Future<AdminAccount> getCurrentAccount();
  Future<AdminAccount> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  });
  Future<List<AdminUser>> getCurrentUsers();
  Future<List<AdminSection>> getCurrentSections();
  Future<List<AdminBook>> getCurrentBooks();
  Future<List<AdminReadingHistory>> getCurrentReadingHistories();
  Future<List<SystemActivity>> getCurrentActivities();
  double getStorageUsage();
  List<SystemStatus> getStatuses();
  List<SystemActivity> getActivities();
  List<AdminUser> getUsers();
  List<AdminUser> getActiveSessions();
  Future<AdminUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? gradeLevel,
    String? sectionId,
    List<String> teacherSectionIds = const [],
  });
  Future<void> disableUser(String userId);
  Future<void> deleteAccount(String userId);
  Future<AdminSection> addSection({
    required String gradeLevel,
    required String name,
  });
  Future<void> deleteSection(String sectionId);
  Future<void> deleteBook(String bookId);
  Future<void> deleteReadingHistory(String submissionId);
  void deleteUser(String userId);
  void forceLogoutUser(String userId);
}

class MockAdminRepository implements AdminRepository {
  final AdminAccount _account = const AdminAccount(id: '', name: '', email: '');

  final double _storageUsage = 0;

  final List<SystemStatus> _statuses = [
    SystemStatus(name: 'Frontend', status: 'Operational'),
    SystemStatus(name: 'Authentication', status: 'Operational'),
    SystemStatus(name: 'Database', status: 'Operational'),
    SystemStatus(name: 'Storage Used', status: 'Operational'),
  ];

  final List<AdminSection> _sections = [];

  @override
  AdminAccount getAccount() => _account;

  @override
  Future<AdminAccount> getCurrentAccount() async => _account;

  @override
  Future<AdminAccount> updateCurrentProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async => _account;

  @override
  Future<List<AdminUser>> getCurrentUsers() async => getUsers();

  @override
  Future<List<AdminSection>> getCurrentSections() async =>
      List.unmodifiable(_sections);

  @override
  Future<List<SystemActivity>> getCurrentActivities() async => getActivities();

  @override
  Future<List<AdminBook>> getCurrentBooks() async => const [];

  @override
  Future<List<AdminReadingHistory>> getCurrentReadingHistories() async =>
      const [];

  final List<SystemActivity> _activities = [];

  final List<AdminUser> _users = [];

  late final List<AdminUser> _activeSessions = List.of(_users);

  @override
  double getStorageUsage() => _storageUsage;

  @override
  List<SystemStatus> getStatuses() => List.unmodifiable(_statuses);

  @override
  List<SystemActivity> getActivities() => List.unmodifiable(_activities);

  @override
  List<AdminUser> getUsers() => List.unmodifiable(_users);

  @override
  List<AdminUser> getActiveSessions() => List.unmodifiable(_activeSessions);

  @override
  Future<AdminUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? gradeLevel,
    String? sectionId,
    List<String> teacherSectionIds = const [],
  }) async {
    final newId = (_users.length + 1).toString();
    final sections = await getCurrentSections();
    AdminSection? selectedSection;
    for (final section in sections) {
      if (section.id == sectionId) {
        selectedSection = section;
        break;
      }
    }
    final user = AdminUser(
      id: newId,
      name: name,
      email: email,
      role: role,
      status: 'Active',
      gradeSection: selectedSection?.label,
    );
    _users.add(user);
    return user;
  }

  @override
  Future<void> disableUser(String userId) async {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) return;
    final user = _users[index];
    _users[index] = AdminUser(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      status: 'Disabled',
      gradeSection: user.gradeSection,
    );
    _activeSessions.removeWhere((session) => session.id == userId);
  }

  @override
  Future<void> deleteAccount(String userId) async {
    deleteUser(userId);
  }

  @override
  Future<AdminSection> addSection({
    required String gradeLevel,
    required String name,
  }) async {
    final section = AdminSection(
      id: '${gradeLevel.toLowerCase()}-${name.toLowerCase()}'.replaceAll(
        ' ',
        '-',
      ),
      gradeLevel: gradeLevel,
      name: name,
    );
    _sections.add(section);
    return section;
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    _sections.removeWhere((section) => section.id == sectionId);
  }

  @override
  Future<void> deleteBook(String bookId) async {}

  @override
  Future<void> deleteReadingHistory(String submissionId) async {}

  @override
  void deleteUser(String userId) {
    _users.removeWhere((user) => user.id == userId);
    _activeSessions.removeWhere((user) => user.id == userId);
  }

  @override
  void forceLogoutUser(String userId) {
    _activeSessions.removeWhere((user) => user.id == userId);
  }
}

class SupabaseAdminRepository extends MockAdminRepository {
  @override
  Future<AdminAccount> getCurrentAccount() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return super.getCurrentAccount();

    final base = getAccount();
    final profile = await client
        .from('profiles')
        .select('email,full_name,avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    var avatarUrl = '';
    try {
      avatarUrl = await _getSignedAvatarUrl(profile?['avatar_url'] as String?);
    } catch (_) {
      avatarUrl = '';
    }

    return AdminAccount(
      id: user.id,
      name: profile?['full_name'] as String? ?? base.name,
      email: profile?['email'] as String? ?? user.email ?? base.email,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<AdminAccount> updateCurrentProfileAvatar({
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
  Future<List<AdminUser>> getCurrentUsers() async {
    final client = SupabaseService.client;
    if (client == null) return super.getCurrentUsers();

    try {
      final rows = await client
          .from('profiles')
          .select(
            'id,email,full_name,role,status,student_profiles(grade_level,sections(name)),teacher_sections(sections(grade_level,name))',
          )
          .order('full_name');

      return rows.map<AdminUser>((row) {
        final role = row['role'] as String? ?? 'student';
        final status = row['status'] as String? ?? 'active';
        return AdminUser(
          id: row['id'] as String,
          name: row['full_name'] as String? ?? 'Unnamed User',
          email: row['email'] as String? ?? '',
          role: role.isEmpty
              ? role
              : '${role[0].toUpperCase()}${role.substring(1)}',
          status: status.isEmpty
              ? status
              : '${status[0].toUpperCase()}${status.substring(1)}',
          gradeSection: _gradeSectionLabel(row, role),
        );
      }).toList();
    } catch (_) {
      return super.getCurrentUsers();
    }
  }

  @override
  Future<List<AdminSection>> getCurrentSections() async {
    final client = SupabaseService.client;
    if (client == null) return super.getCurrentSections();

    try {
      final rows = await client
          .from('sections')
          .select('id,grade_level,name')
          .order('grade_level')
          .order('name');

      return rows.map<AdminSection>((row) {
        return AdminSection(
          id: row['id'] as String,
          gradeLevel: row['grade_level'] as String? ?? '',
          name: row['name'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<AdminBook>> getCurrentBooks() async {
    final client = SupabaseService.client;
    if (client == null) return super.getCurrentBooks();

    try {
      final rows = await client
          .from('books')
          .select('id,title,grade_level,sections(name)')
          .order('created_at', ascending: false);

      return rows.map<AdminBook>((row) {
        final section = _embeddedMap(row['sections']);
        return AdminBook(
          id: row['id'] as String,
          title: row['title'] as String? ?? 'Untitled Book',
          gradeSection:
              _joinLabel(
                row['grade_level']?.toString(),
                section['name']?.toString(),
              ) ??
              '',
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<AdminReadingHistory>> getCurrentReadingHistories() async {
    final client = SupabaseService.client;
    if (client == null) return super.getCurrentReadingHistories();

    try {
      final rows = await client
          .from('reading_submissions')
          .select(
            'id,book_title_snapshot,status,submitted_at,created_at,profiles(full_name)',
          )
          .order('created_at', ascending: false);

      return rows.map<AdminReadingHistory>((row) {
        final student = _embeddedMap(row['profiles']);
        return AdminReadingHistory(
          id: row['id'] as String,
          studentName: student['full_name']?.toString() ?? 'Unknown Student',
          bookTitle: row['book_title_snapshot']?.toString() ?? 'Untitled Book',
          startedAt: _dateTimeLabel(row['created_at']),
          submittedAt: row['submitted_at'] != null
              ? _dateTimeLabel(row['submitted_at'])
              : '—',
          status: _titleCase(row['status']?.toString() ?? ''),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<AdminUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? gradeLevel,
    String? sectionId,
    List<String> teacherSectionIds = const [],
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      return super.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        gradeLevel: gradeLevel,
        sectionId: sectionId,
        teacherSectionIds: teacherSectionIds,
      );
    }

    final normalizedRole = role.toLowerCase();
    final body = <String, dynamic>{
      'full_name': name,
      'email': email,
      'password': password,
      'role': normalizedRole,
    };
    if (gradeLevel != null) body['grade_level'] = gradeLevel;
    if (sectionId != null) body['section_id'] = sectionId;
    if (teacherSectionIds.isNotEmpty) {
      body['teacher_section_ids'] = teacherSectionIds;
    }

    final response = await client.functions.invoke(
      'admin-create-user',
      body: body,
    );

    final data = _metadataMap(response.data);
    final error = data['error']?.toString();
    if (error != null && error.isNotEmpty) {
      throw Exception(error);
    }

    return AdminUser(
      id: data['id']?.toString() ?? '',
      name: data['full_name']?.toString() ?? name,
      email: data['email']?.toString() ?? email,
      role: _titleCase(data['role']?.toString() ?? normalizedRole),
      status: _titleCase(data['status']?.toString() ?? 'active'),
    );
  }

  @override
  Future<void> disableUser(String userId) async {
    final client = SupabaseService.client;
    if (client == null) return super.disableUser(userId);

    final admin = client.auth.currentUser;
    final existing = await client
        .from('profiles')
        .select('full_name,email,role')
        .eq('id', userId)
        .maybeSingle();

    await client
        .from('profiles')
        .update({'status': 'disabled'})
        .eq('id', userId);

    try {
      await client.from('activity_logs').insert({
        'actor_id': admin?.id,
        'actor_role': 'admin',
        'action': 'admin_disabled_user',
        'entity_type': 'profile',
        'entity_id': userId,
        'metadata': {
          'disabled_user_name': existing?['full_name'],
          'disabled_user_email': existing?['email'],
          'disabled_user_role': existing?['role'],
        },
      });
    } catch (_) {
      // Activity logging should not block the admin action.
    }
  }

  @override
  Future<void> deleteAccount(String userId) async {
    final client = SupabaseService.client;
    if (client == null) return super.deleteAccount(userId);

    final response = await client.functions.invoke(
      'admin-delete-user',
      body: {'user_id': userId},
    );
    final data = _metadataMap(response.data);
    final error = data['error']?.toString();
    if (error != null && error.isNotEmpty) {
      throw Exception(error);
    }
  }

  @override
  Future<AdminSection> addSection({
    required String gradeLevel,
    required String name,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      return super.addSection(gradeLevel: gradeLevel, name: name);
    }

    final row = await client
        .from('sections')
        .insert({'grade_level': gradeLevel, 'name': name})
        .select('id,grade_level,name')
        .single();
    await _logAdminAction(
      action: 'admin_created_section',
      entityType: 'section',
      entityId: row['id'] as String?,
      metadata: {'grade_level': gradeLevel, 'section_name': name},
    );
    return AdminSection(
      id: row['id'] as String,
      gradeLevel: row['grade_level'] as String? ?? gradeLevel,
      name: row['name'] as String? ?? name,
    );
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    final client = SupabaseService.client;
    if (client == null) return super.deleteSection(sectionId);

    final existing = await client
        .from('sections')
        .select('grade_level,name')
        .eq('id', sectionId)
        .maybeSingle();
    await client.from('sections').delete().eq('id', sectionId);
    await _logAdminAction(
      action: 'admin_deleted_section',
      entityType: 'section',
      entityId: sectionId,
      metadata: {
        'grade_level': existing?['grade_level'],
        'section_name': existing?['name'],
      },
    );
  }

  @override
  Future<void> deleteBook(String bookId) async {
    final client = SupabaseService.client;
    if (client == null) return super.deleteBook(bookId);

    final existing = await client
        .from('books')
        .select('title')
        .eq('id', bookId)
        .maybeSingle();
    await client.from('books').delete().eq('id', bookId);
    await _logAdminAction(
      action: 'admin_deleted_book',
      entityType: 'book',
      entityId: bookId,
      metadata: {'book_title': existing?['title']},
    );
  }

  @override
  Future<void> deleteReadingHistory(String submissionId) async {
    final client = SupabaseService.client;
    if (client == null) return super.deleteReadingHistory(submissionId);

    final existing = await client
        .from('reading_submissions')
        .select('book_title_snapshot')
        .eq('id', submissionId)
        .maybeSingle();
    await client.from('reading_submissions').delete().eq('id', submissionId);
    await _logAdminAction(
      action: 'admin_deleted_reading_history',
      entityType: 'reading_submission',
      entityId: submissionId,
      metadata: {'book_title': existing?['book_title_snapshot']},
    );
  }

  @override
  Future<List<SystemActivity>> getCurrentActivities() async {
    final client = SupabaseService.client;
    if (client == null) return super.getCurrentActivities();

    try {
      final rows = await client
          .from('activity_logs')
          .select('actor_role,action,metadata,created_at,profiles(full_name)')
          .order('created_at', ascending: false)
          .limit(1000);

      return rows.map<SystemActivity>((row) {
        final role = row['actor_role'] as String? ?? 'system';
        final metadata = _metadataMap(row['metadata']);
        final profile = _embeddedMap(row['profiles']);
        final profileName = profile['full_name']?.toString();
        return SystemActivity(
          dateTime: _dateTimeLabel(row['created_at']),
          activity: _activityTitle(row['action'] as String? ?? '', metadata),
          userType: _titleCase(role),
          name: _actorName(role, metadata, profileName),
          status: 'Success',
        );
      }).toList();
    } catch (_) {
      return super.getCurrentActivities();
    }
  }

  Map<String, dynamic> _metadataMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _activityTitle(String action, Map<String, dynamic> metadata) {
    final bookTitle = metadata['book_title']?.toString();
    final badgeName = metadata['badge_name']?.toString();
    switch (action) {
      case 'submitted_reading_quiz':
        return 'Submitted reading quiz${bookTitle == null ? '' : ': $bookTitle'}';
      case 'sent_teacher_feedback':
        return 'Sent teacher feedback${bookTitle == null ? '' : ': $bookTitle'}';
      case 'awarded_badge':
        return 'Awarded badge${badgeName == null ? '' : ': $badgeName'}';
      case 'admin_created_user':
        return 'Created account${metadata['created_user_email'] == null ? '' : ': ${metadata['created_user_email']}'}';
      case 'admin_disabled_user':
        return 'Disabled account${metadata['disabled_user_email'] == null ? '' : ': ${metadata['disabled_user_email']}'}';
      case 'admin_deleted_user':
        return 'Deleted account${metadata['deleted_user_email'] == null ? '' : ': ${metadata['deleted_user_email']}'}';
      case 'admin_created_section':
        return 'Created section${metadata['section_name'] == null ? '' : ': ${metadata['section_name']}'}';
      case 'admin_deleted_section':
        return 'Deleted section${metadata['section_name'] == null ? '' : ': ${metadata['section_name']}'}';
      case 'admin_deleted_book':
        return 'Deleted book${metadata['book_title'] == null ? '' : ': ${metadata['book_title']}'}';
      case 'admin_deleted_reading_history':
        return 'Deleted reading history${metadata['book_title'] == null ? '' : ': ${metadata['book_title']}'}';
      default:
        return action
            .split('_')
            .where((part) => part.isNotEmpty)
            .map(_titleCase)
            .join(' ');
    }
  }

  String _actorName(
    String role,
    Map<String, dynamic> metadata,
    String? profileName,
  ) {
    final name = metadata['actor_name']?.toString();
    if (name != null && name.trim().isNotEmpty) return name;
    if (profileName != null && profileName.trim().isNotEmpty) {
      return profileName;
    }
    return _titleCase(role);
  }

  String? _gradeSectionLabel(Map<String, dynamic> row, String role) {
    if (role == 'student') {
      final profile = _embeddedMap(row['student_profiles']);
      final section = _embeddedMap(profile['sections']);
      final grade = profile['grade_level']?.toString();
      final sectionName = section['name']?.toString();
      return _joinLabel(grade, sectionName);
    }

    if (role == 'teacher') {
      final assignments = row['teacher_sections'];
      if (assignments is List) {
        final labels = assignments
            .map((assignment) {
              final section = _embeddedMap(
                _embeddedMap(assignment)['sections'],
              );
              return _joinLabel(
                section['grade_level']?.toString(),
                section['name']?.toString(),
              );
            })
            .where((label) => label != null && label.isNotEmpty)
            .cast<String>()
            .toList();
        return labels.join(', ');
      }
    }

    return null;
  }

  Map<String, dynamic> _embeddedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) return _embeddedMap(value.first);
    return <String, dynamic>{};
  }

  String? _joinLabel(String? grade, String? section) {
    final cleanGrade = grade?.trim() ?? '';
    final cleanSection = section?.trim() ?? '';
    if (cleanGrade.isEmpty && cleanSection.isEmpty) return null;
    if (cleanGrade.isEmpty) return cleanSection;
    if (cleanSection.isEmpty) return cleanGrade;
    return '$cleanGrade - $cleanSection';
  }

  Future<void> _logAdminAction({
    required String action,
    required String entityType,
    required String? entityId,
    required Map<String, dynamic> metadata,
  }) async {
    final client = SupabaseService.client;
    final admin = client?.auth.currentUser;
    if (client == null) return;

    try {
      await client.from('activity_logs').insert({
        'actor_id': admin?.id,
        'actor_role': 'admin',
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'metadata': metadata,
      });
    } catch (_) {
      // Activity logging should not block the admin action.
    }
  }

  String _dateTimeLabel(dynamic rawDate) {
    if (rawDate == null) return '';
    final str = rawDate.toString().trim();
    if (str.isEmpty) return '';
    final date = DateTime.tryParse(str);
    if (date == null) return str;

    // Convert to Philippine Standard Time (UTC+8)
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

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  Future<String> _getSignedAvatarUrl(String? avatarPath) async {
    if (avatarPath == null || avatarPath.trim().isEmpty) return '';
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }

    final client = SupabaseService.client;
    if (client == null) return '';
    return client.storage.from('avatars').createSignedUrl(avatarPath, 3600);
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
