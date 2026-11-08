import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/loading_dialog.dart';
import 'login_screen.dart';

class AdminResetPasswordScreen extends StatefulWidget {
  const AdminResetPasswordScreen({super.key});

  @override
  State<AdminResetPasswordScreen> createState() =>
      _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState extends State<AdminResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final result = await runWithLoadingDialog<AuthResult>(
      context,
      () => context.read<AdminProvider>().completePasswordReset(
        _passwordController.text,
        _confirmController.text,
      ),
      message: 'Updating password...',
    );
    if (!mounted) return;
    if (!result.success) {
      await showAppMessageDialog(
        context,
        title: 'Password Not Updated',
        message: result.message ?? 'Unable to update password.',
        isDanger: true,
      );
      return;
    }
    await showAppMessageDialog(
      context,
      title: 'Password Updated',
      message: 'Please log in again with your new password.',
      buttonLabel: 'Go To Login',
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('lib/assets/logo-icon.png', height: 84),
                const SizedBox(height: 24),
                Text(
                  'Create New Password',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a new password for your BloomAdmin account.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.black54),
                ),
                const SizedBox(height: 28),
                _passwordField(_passwordController, 'New password'),
                const SizedBox(height: 14),
                _passwordField(_confirmController, 'Confirm new password'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savePassword,
                    child: const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
        ),
      ),
    );
  }
}
