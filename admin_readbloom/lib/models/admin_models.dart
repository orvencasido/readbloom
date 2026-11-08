class AdminAccount {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  const AdminAccount({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
  });
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? gradeSection;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.gradeSection,
  });
}

class AdminSection {
  final String id;
  final String gradeLevel;
  final String name;

  const AdminSection({
    required this.id,
    required this.gradeLevel,
    required this.name,
  });

  String get label => '$gradeLevel - $name';
}

class AdminBook {
  final String id;
  final String title;
  final String gradeSection;

  const AdminBook({
    required this.id,
    required this.title,
    required this.gradeSection,
  });
}

class AdminReadingHistory {
  final String id;
  final String studentName;
  final String bookTitle;
  final String startedAt;
  final String submittedAt;
  final String status;

  const AdminReadingHistory({
    required this.id,
    required this.studentName,
    required this.bookTitle,
    this.startedAt = '',
    required this.submittedAt,
    required this.status,
  });
}

class SystemActivity {
  final String dateTime;
  final String activity;
  final String userType;
  final String name;
  final String status;

  SystemActivity({
    required this.dateTime,
    required this.activity,
    this.userType = 'System',
    this.name = 'ReadBloom',
    this.status = 'Success',
  });
}

class SystemStatus {
  final String name;
  final String status;

  SystemStatus({required this.name, required this.status});
}
