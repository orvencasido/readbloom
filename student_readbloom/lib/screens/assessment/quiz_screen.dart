import 'package:flutter/material.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/guarded_pop_scope.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/quiz_mobile.dart';
import 'web/quiz_web.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 840;
    return Scaffold(
      body: GuardedPopScope(
        onConfirmPop: () => showAppConfirmDialog(
          context,
          title: 'Leave Quiz?',
          message:
              'Your reading was uploaded, but your quiz answers have not been submitted yet.',
          confirmLabel: 'Leave',
          isDanger: true,
        ),
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
              mobileBody: QuizMobileBody(),
              webBody: QuizWebBody(),
            ),
          ),
        ),
      ),
    );
  }
}
