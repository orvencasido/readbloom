import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/student_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/privacy/privacy_screen.dart';
import 'screens/dashboard/main_scaffold.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => StudentProvider())],
      child: const StudentApp(),
    ),
  );
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloomStu',
      debugShowCheckedModeBanner: false,
      theme: StudentTheme.theme,
      home: const StudentStateWrapper(),
    );
  }
}

class StudentStateWrapper extends StatelessWidget {
  const StudentStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();

    // Dynamically direct the user if their login/privacy consent states change
    if (prov.isAuthLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (prov.isPasswordRecovery) {
      return const StudentResetPasswordScreen();
    }
    if (!prov.isSplashDone) {
      return const StudentSplashScreen();
    }
    if (!prov.isLoggedIn) {
      return const StudentLoginScreen();
    }
    if (!prov.hasAcceptedPrivacy) {
      return const StudentPrivacyScreen();
    }
    return const StudentMainScaffold();
  }
}
