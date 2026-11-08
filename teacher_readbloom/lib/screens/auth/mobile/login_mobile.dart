import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_dialogs.dart';
// import '../../../widgets/forgot_password_dialog.dart';
import '../../../widgets/loading_dialog.dart';

class LoginMobileBody extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginMobileBody({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('lib/assets/teacher-bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.22),
            BlendMode.srcATop,
          ),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: TeacherTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24.0,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Icon
                Image.asset(
                  'lib/assets/logo-icon.png',
                  height: 72,
                  width: 72,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome back, Teacher',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: TeacherTheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review student progress and reading assessments.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: TeacherTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 28),

                // Email field
                _buildFieldLabel('EMAIL'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: emailController,
                  hintText: 'Enter your email',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

                // Password field
                _buildFieldLabel('PASSWORD'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: passwordController,
                  hintText: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await runWithLoadingDialog(
                        context,
                        () => context.read<TeacherProvider>().login(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        ),
                        message: 'Signing in...',
                      );
                      if (result.success || !context.mounted) return;
                      showAppMessageDialog(
                        context,
                        title: 'Cannot login',
                        message:
                            result.message ??
                            'Credentials not found or incorrect.',
                        isDanger: true,
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Log in'),
                  ),
                ),
                // const SizedBox(height: 16),
                // TextButton(
                //   onPressed: () => showForgotPasswordDialog(
                //     context,
                //     onSubmit: (email) => context
                //         .read<TeacherProvider>()
                //         .sendPasswordResetEmail(email),
                //   ),
                //   child: const Text('Forgot password?'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: TeacherTheme.text,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.inter(fontSize: 14, color: TeacherTheme.text),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: TeacherTheme.mutedText),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: TeacherTheme.mutedText,
        ),
      ),
    );
  }
}
