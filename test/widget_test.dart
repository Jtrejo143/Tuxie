// test/widget_test.dart
// Basic smoke test — verifies the app launches without crashing

import 'package:flutter_test/flutter_test.dart';
import 'package:tuxie/main.dart';

void main() {
  testWidgets('Tuxie app smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const TuxieApp());

    // Verify it renders without throwing
    expect(find.byType(TuxieApp), findsOneWidget);
  });
}
