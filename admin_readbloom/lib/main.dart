import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
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
      providers: [ChangeNotifierProvider(create: (_) => AdminProvider())],
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloomAdmin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.theme,
      home: const AdminStateWrapper(),
    );
  }
}

class AdminStateWrapper extends StatelessWidget {
  const AdminStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    if (prov.isAuthLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (prov.isPasswordRecovery) {
      return const AdminResetPasswordScreen();
    }
    if (!prov.isLoggedIn) {
      return const AdminLoginScreen();
    }
    return const AdminMainScaffold();
  }
}
