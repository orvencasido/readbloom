import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/login_mobile.dart';
import 'web/login_web.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: LoginMobileBody(
          emailController: _emailController,
          passwordController: _passwordController,
        ),
        webBody: LoginWebBody(
          emailController: _emailController,
          passwordController: _passwordController,
        ),
      ),
    );
  }
}
