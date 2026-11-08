import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class UploadingMobileBody extends StatelessWidget {
  final double pct;
  final bool isUploading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const UploadingMobileBody({
    super.key,
    required this.pct,
    required this.isUploading,
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final retryLabel = pct >= 0.75 ? 'Retry Processing' : 'Retry Upload';

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 104,
                width: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  error == null
                      ? Icons.cloud_upload_outlined
                      : Icons.error_outline,
                  size: 52,
                  color: error == null
                      ? StudentTheme.primary
                      : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                error == null
                    ? pct >= 0.75
                          ? 'Processing your reading'
                          : 'Uploading your reading'
                    : 'Processing Failed',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Segmented progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(10, (index) {
                  final active = index < (pct * 10).toInt();
                  return Container(
                    width: 14,
                    height: 25,
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    decoration: BoxDecoration(
                      color: active
                          ? StudentTheme.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '${(pct * 100).toInt()}% Done',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              if (error != null) ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isUploading ? null : onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(retryLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StudentTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isUploading ? null : onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
