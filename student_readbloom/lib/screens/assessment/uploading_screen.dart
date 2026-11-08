import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/uploading_mobile.dart';
import 'web/uploading_web.dart';
import 'preview_screen.dart';
import 'quiz_screen.dart';

class UploadingScreen extends StatefulWidget {
  const UploadingScreen({super.key});

  @override
  State<UploadingScreen> createState() => _UploadingScreenState();
}

class _UploadingScreenState extends State<UploadingScreen> {
  bool _hasStartedUpload = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startUpload();
    });
  }

  Future<void> _startUpload() async {
    if (_hasStartedUpload) return;
    _hasStartedUpload = true;

    final provider = context.read<StudentProvider>();
    final error = await provider.uploadRecordedReading();
    if (!mounted || error != null) return;

    provider.resetQuiz();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const QuizScreen()),
    );
  }

  Future<void> _retryUpload() async {
    _hasStartedUpload = false;
    await _startUpload();
  }

  Future<void> _goBackToPreview() async {
    if (context.read<StudentProvider>().isUploadingReading) {
      await showAppMessageDialog(
        context,
        title: 'Upload In Progress',
        message:
            'Please wait until your reading finishes uploading and processing.',
      );
      return;
    }
    final shouldLeave = await showAppConfirmDialog(
      context,
      title: 'Return To Preview?',
      message:
          'Your recorded video will stay available so you can try uploading again.',
      confirmLabel: 'Back To Preview',
    );
    if (!shouldLeave || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 840;
    final pct = context.select<StudentProvider, double>(
      (prov) => prov.readingUploadProgress,
    );
    final isUploading = context.select<StudentProvider, bool>(
      (prov) => prov.isUploadingReading,
    );
    final error = context.select<StudentProvider, String?>(
      (prov) => prov.readingUploadError,
    );

    return Scaffold(
      body: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _goBackToPreview();
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                isMobile
                    ? 'lib/assets/main-bg-2.png'
                    : 'lib/assets/website/bg-website.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: ResponsiveLayout(
            mobileBody: UploadingMobileBody(
              pct: pct,
              isUploading: isUploading,
              error: error,
              onRetry: _retryUpload,
              onBack: _goBackToPreview,
            ),
            webBody: UploadingWebBody(
              pct: pct,
              isUploading: isUploading,
              error: error,
              onRetry: _retryUpload,
              onBack: _goBackToPreview,
            ),
          ),
        ),
      ),
    );
  }
}
