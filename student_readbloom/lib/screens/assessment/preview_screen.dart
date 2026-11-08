import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/guarded_pop_scope.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/preview_mobile.dart';
import 'web/preview_web.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 840;
    return Scaffold(
      body: GuardedPopScope(
        onConfirmPop: () => showAppConfirmDialog(
          context,
          title: 'Leave Preview?',
          message: 'Your recorded video will be discarded if you leave.',
          confirmLabel: 'Discard',
          isDanger: true,
        ),
        onConfirmedPop: () async {
          final prov = context.read<StudentProvider>();
          await prov.discardRecordedVideo();
          await prov.disposeCamera();
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
          child: const SafeArea(
            child: ResponsiveLayout(
              mobileBody: PreviewMobileBody(),
              webBody: PreviewWebBody(),
            ),
          ),
        ),
      ),
    );
  }
}
