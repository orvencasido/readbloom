import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class AppDialogFrame extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  const AppDialogFrame({
    super.key,
    this.title,
    required this.child,
    this.actions = const [],
    this.maxWidth = 440,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AdminTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AdminTheme.text,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              child,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAppMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'OK',
  bool isDanger = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AppDialogFrame(
      title: title,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDanger ? AdminTheme.danger : AdminTheme.primary,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(buttonLabel),
        ),
      ],
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.45,
          color: AdminTheme.mutedText,
        ),
      ),
    ),
  );
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Continue',
  bool isDanger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialogFrame(
      title: title,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDanger ? AdminTheme.danger : AdminTheme.primary,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.45,
          color: AdminTheme.mutedText,
        ),
      ),
    ),
  );
  return result ?? false;
}

Future<bool> showTypedConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmationText,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Delete Permanently',
}) async {
  final controller = TextEditingController();
  var typedValue = '';

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final normalizedConfirmation = confirmationText.toUpperCase();
          final canConfirm = typedValue == normalizedConfirmation;
          return AppDialogFrame(
            title: title,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.danger,
                ),
                onPressed: canConfirm
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: Text(confirmLabel),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: AdminTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Type $normalizedConfirmation to confirm.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'DELETE'),
                  onChanged: (value) {
                    setDialogState(() {
                      typedValue = value.trim().toUpperCase();
                    });
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );

  controller.dispose();
  return result ?? false;
}
