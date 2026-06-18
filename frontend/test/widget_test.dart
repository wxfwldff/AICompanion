import 'package:flutter_test/flutter_test.dart';
import 'package:ai_social_app/app.dart';

void main() {
  testWidgets('HomePage renders character list', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('AI 社交世界'), findsOneWidget);
  });
}
