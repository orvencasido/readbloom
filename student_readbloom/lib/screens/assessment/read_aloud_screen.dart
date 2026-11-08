import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/guarded_pop_scope.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/read_aloud_mobile.dart';
import 'preview_screen.dart';
import 'web/read_aloud_web.dart';

class ReadAloudScreen extends StatefulWidget {
  const ReadAloudScreen({super.key});

  @override
  State<ReadAloudScreen> createState() => _ReadAloudScreenState();
}

class _ReadAloudScreenState extends State<ReadAloudScreen> {
  StudentProvider? _provider;
  bool _isHandlingTimeLimit = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<StudentProvider>();
    _provider?.addListener(_handleProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final error = await _provider?.startReadingRecording();
      if (mounted) {
        await _provider?.resumeCameraPreview();
      }
      if (error != null && mounted) {
        await showAppMessageDialog(
          context,
          title: 'Recording Not Started',
          message: error,
          isDanger: true,
        );
      }
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderChanged);
    super.dispose();
  }

  void _handleProviderChanged() {
    if (_isHandlingTimeLimit || !mounted) return;

    final provider = _provider;
    if (provider == null) return;
    if (!provider.hasReachedRecordingTimeLimit ||
        provider.isRecording ||
        provider.isStoppingRecording ||
        provider.recordedVideo == null) {
      return;
    }

    _isHandlingTimeLimit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showAppMessageDialog(
        context,
        title: 'Time Limit Reached',
        message:
            '5 minutes have already passed. Your recording will now move to preview.',
        buttonLabel: 'Go To Preview',
        autoDismissAfter: const Duration(seconds: 2),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PreviewScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 840;
    return Scaffold(
      body: GuardedPopScope(
        onConfirmPop: () => showAppConfirmDialog(
          context,
          title: 'Leave Reading?',
          message:
              'Your current recording will be discarded if you leave this screen.',
          confirmLabel: 'Discard',
          isDanger: true,
        ),
        onConfirmedPop: () =>
            context.read<StudentProvider>().cancelReadingRecording(),
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
          child: const SafeArea(
            child: ResponsiveLayout(
              mobileBody: ReadAloudMobileBody(),
              webBody: ReadAloudWebBody(),
            ),
          ),
        ),
      ),
    );
  }
}
