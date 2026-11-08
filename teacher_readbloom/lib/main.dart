import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/teacher_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard/main_scaffold.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TeacherProvider())],
      child: const TeacherApp(),
    ),
  );
}

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloomTeach',
      debugShowCheckedModeBanner: false,
      theme: TeacherTheme.theme,
      home: const TeacherStateWrapper(),
    );
  }
}

class TeacherStateWrapper extends StatelessWidget {
  const TeacherStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();
    if (prov.isAuthLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (prov.isPasswordRecovery) {
      return const TeacherResetPasswordScreen();
    }
    if (!prov.isLoggedIn) {
      return const TeacherLoginScreen();
    }
    return const TeacherMainScaffold();
  }
}
