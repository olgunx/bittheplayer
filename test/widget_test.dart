import 'package:flutter_test/flutter_test.dart';
import 'package:bittheplayer/main.dart';

void main() {
  testWidgets('App boots and displays title test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BitThePlayerApp());

    // Verify that the splash/title text is displayed.
    expect(find.text('BIT THE PLAYER'), findsOneWidget);
  });
}
