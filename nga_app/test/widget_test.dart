// Basic smoke test for NGA app.

import 'package:flutter_test/flutter_test.dart';

import 'package:nga_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NgaApp());

    // Verify that the app title is present.
    expect(find.text('NGA Forum'), findsOneWidget);
  });
}
