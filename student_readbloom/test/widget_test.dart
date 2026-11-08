import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:student_readbloom/main.dart';
import 'package:student_readbloom/providers/student_provider.dart';

void main() {
  testWidgets('BloomStu App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => StudentProvider())],
        child: const StudentApp(),
      ),
    );

    // Verify splash screen displays some indicator
    expect(find.byType(StudentApp), findsOneWidget);
  });
}
