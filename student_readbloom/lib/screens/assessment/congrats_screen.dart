import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import 'mobile/congrats_mobile.dart';
import 'web/congrats_web.dart';

class CongratsScreen extends StatelessWidget {
  const CongratsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 840;
    return Scaffold(
      body: Container(
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
            mobileBody: CongratsMobileBody(),
            webBody: CongratsWebBody(),
          ),
        ),
      ),
    );
  }
}
