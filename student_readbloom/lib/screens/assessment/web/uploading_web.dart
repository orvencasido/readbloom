import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadingWebBody extends StatelessWidget {
  final double pct;
  final bool isUploading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const UploadingWebBody({
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                error == null
                    ? Icons.cloud_upload_outlined
                    : Icons.error_outline,
                color: error == null
                    ? const Color(0xFF5C8DF6)
                    : Colors.red.shade700,
                size: 54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              error == null
                  ? pct >= 0.75
                        ? 'Processing your reading'
                        : 'Uploading your reading'
                  : 'Processing failed',
              style: GoogleFonts.outfit(
                color: error == null ? Colors.black : Colors.red.shade700,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(10, (index) {
                      final active = index < (pct * 10).toInt();
                      return Container(
                        width: 10,
                        height: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF5C8DF6)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${(pct * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading && error == null) ...[
              const SizedBox(height: 18),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(retryLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C8DF6),
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
    );
  }
}
