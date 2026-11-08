import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/admin_provider.dart';
import '../../../theme/app_theme.dart';

class ActivityLogWebBody extends StatelessWidget {
  const ActivityLogWebBody({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Activity History & Logins',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminTheme.border),
              ),
              child: Column(
                children: prov.activities
                    .map(
                      (act) => ListTile(
                        leading: const Icon(Icons.login, color: Colors.blue),
                        title: Text(
                          act.activity,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Timestamp: ${act.dateTime}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
