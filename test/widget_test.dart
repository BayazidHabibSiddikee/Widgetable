// Basic smoke test for WidgetBoardApp.
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetboard/app.dart';

void main() {
  testWidgets('App launches and shows home navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const WidgetBoardApp());
    await tester.pumpAndSettle();
    expect(find.text('Games'), findsOneWidget);
  });
}
