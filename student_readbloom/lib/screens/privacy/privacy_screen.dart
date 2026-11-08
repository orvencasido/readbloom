import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/privacy_mobile.dart';
import 'web/privacy_web.dart';

class StudentPrivacyScreen extends StatelessWidget {
  const StudentPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ResponsiveLayout(
        mobileBody: PrivacyMobileBody(),
        webBody: PrivacyWebBody(),
      ),
    );
  }
}
