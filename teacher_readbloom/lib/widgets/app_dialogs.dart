import 'dart:ui';

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
    this.maxWidth = 460,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 1.2,
                ),
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
                        color: Colors.white,
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
            backgroundColor: isDanger
                ? TeacherTheme.danger
                : const Color(0xFFF7DD68),
            foregroundColor: isDanger ? Colors.white : const Color(0xFF1F2937),
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
          color: Colors.white.withValues(alpha: 0.78),
        ),
      ),
    ),
  );
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Keep Editing',
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
            backgroundColor: isDanger
                ? TeacherTheme.danger
                : const Color(0xFFF7DD68),
            foregroundColor: isDanger ? Colors.white : const Color(0xFF1F2937),
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
          color: Colors.white.withValues(alpha: 0.78),
        ),
      ),
    ),
  );
  return result ?? false;
}
