import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/app_dialogs.dart';
// import '../../../widgets/forgot_password_dialog.dart';
import '../../../widgets/loading_dialog.dart';
import '../../../theme/app_theme.dart';

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
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/main-bg-2.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Icon
                Image.asset(
                  'lib/assets/logo-icon.png',
                  height: 90,
                  width: 90,
                ),
                const SizedBox(height: 24),

                // Welcome Text
                Text(
                  'welcome little one!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2E3A),
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  'WHERE WORDS BLOOM, MINDS GROW',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: const Color(0xFF0F2E3A),
                  ),
                ),
                const SizedBox(height: 32),

                // Inputs Group constrained to 320px
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      // Email field
                      _buildFieldLabel('EMAIL'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: emailController,
                        hintText: 'Enter your email',
                        icon: Icons.alternate_email,
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

                      // Forgot Password Link (commented out)
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: TextButton(
                      //     onPressed: () => showForgotPasswordDialog(
                      //       context,
                      //       onSubmit: (email) => context
                      //           .read<StudentProvider>()
                      //           .sendPasswordResetEmail(email),
                      //     ),
                      //     child: Text(
                      //       'Forgot password?',
                      //       style: GoogleFonts.inter(
                      //         fontSize: 13,
                      //         fontWeight: FontWeight.w800,
                      //         color: const Color(0xFF0F2E3A),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Log In Button
                Container(
                  width: 200,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFDE69C), Color(0xFFE5C158)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFC39F3F),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await runWithLoadingDialog(
                        context,
                        () => context.read<StudentProvider>().login(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF4A3414),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'LOG IN',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
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
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: const Color(0xFF0F2E3A),
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
    return SizedBox(
      width: 320,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: StudentTheme.text,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEBF9D5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: Icon(icon, color: const Color(0xFF9CB88F), size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF9CB88F),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: StudentTheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
