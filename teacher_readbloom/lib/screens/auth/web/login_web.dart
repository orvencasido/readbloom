import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../widgets/app_dialogs.dart';
// import '../../../widgets/forgot_password_dialog.dart';
import '../../../widgets/loading_dialog.dart';

class LoginWebBody extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginWebBody({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/bg-web.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Image (Directly on Gradient)
                Image.asset(
                  'lib/assets/logo-icon.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),

                // Welcome Header
                Text(
                  'WELCOME TEACHER!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'WHERE WORDS BLOOM, MINDS GROW',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Email field
                _buildFieldLabel('EMAIL'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: emailController,
                  hintText: 'Enter your email',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),

                // Password field
                _buildFieldLabel('PASSWORD'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: passwordController,
                  hintText: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 36),

                // Log In Button (Yellow Plain Capsule)
                InkWell(
                  onTap: () async {
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
                  child: Container(
                    width: 180,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7DD68),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'LOG IN',
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
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
                //   child: Text(
                //     'Forgot password?',
                //     style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                //   ),
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
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
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
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.black38, size: 20),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.black38,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
