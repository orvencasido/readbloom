import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin_readbloom/main.dart';
import 'package:admin_readbloom/providers/admin_provider.dart';
import 'package:admin_readbloom/screens/dashboard/management_body.dart';

void main() {
  testWidgets('BloomAdmin App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AdminProvider())],
        child: const AdminApp(),
      ),
    );

    expect(find.byType(AdminApp), findsOneWidget);
  });

  testWidgets('Admin dedicated management pages render table content', (
    WidgetTester tester,
  ) async {
    Future<void> pumpPage(AdminManagementView view) {
      return tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AdminProvider())],
          child: MaterialApp(home: AdminManagementBody(view: view)),
        ),
      );
    }

    await pumpPage(AdminManagementView.sections);
    expect(find.text('Grade'), findsWidgets);
    expect(find.text('Section'), findsWidgets);

    await pumpPage(AdminManagementView.books);
    expect(find.text('Book Title'), findsWidgets);

    await pumpPage(AdminManagementView.readingHistory);
    expect(find.text('Student'), findsWidgets);
    expect(find.text('Submitted'), findsWidgets);
  });
}
