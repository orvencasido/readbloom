import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/calibration_mobile.dart';
import 'web/calibration_web.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  bool _isNavigatingToReadAloud = false;

  void _onStartReading() {
    _isNavigatingToReadAloud = true;
  }

  Future<void> _onCancel() async {
    final navigator = Navigator.of(context);
    await context.read<StudentProvider>().disposeCamera();
    if (mounted) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final error = await context
          .read<StudentProvider>()
          .prepareRecordingSession();
      if (error != null && mounted) {
        await showAppMessageDialog(
          context,
          title: 'Camera Not Ready',
          message: error,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 840;
    return Scaffold(
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && !_isNavigatingToReadAloud) {
            context.read<StudentProvider>().disposeCamera();
          }
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
            mobileBody: CalibrationMobileBody(
              onStart: _onStartReading,
              onCancel: _onCancel,
            ),
            webBody: CalibrationWebBody(
              onStart: _onStartReading,
              onCancel: _onCancel,
            ),
          ),
        ),
      ),
    );
  }
}
