import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/login_mobile.dart';
import 'web/login_web.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
