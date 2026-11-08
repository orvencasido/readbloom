import 'package:flutter/material.dart';

import 'app_dialogs.dart';
import 'loading_dialog.dart';

Future<void> showForgotPasswordDialog(
  BuildContext context, {
  required Future<void> Function(String email) onSubmit,
}) {
  final emailController = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AppDialogFrame(
        title: 'Forgot Password',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              if (email.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Please enter your email.')),
                );
                return;
              }

              try {
                await runWithLoadingDialog(
                  dialogContext,
                  () => onSubmit(email),
                  message: 'Sending reset email...',
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password reset email sent if the account exists.',
                    ),
                  ),
                );
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Unable to send reset email right now.'),
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
        child: SizedBox(
          width: 360,
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ),
      );
    },
  ).whenComplete(emailController.dispose);
}
