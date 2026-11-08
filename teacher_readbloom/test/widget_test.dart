import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:teacher_readbloom/main.dart';
import 'package:teacher_readbloom/providers/teacher_provider.dart';

void main() {
  testWidgets('BloomTeach App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => TeacherProvider())],
        child: const TeacherApp(),
      ),
    );

    expect(find.byType(TeacherApp), findsOneWidget);
  });
}
