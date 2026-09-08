import 'package:flutter_test/flutter_test.dart';

import 'package:last_time_i/main.dart';

void main() {
  testWidgets('App launches and shows the title', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const LastTimeIApp());

    // The title appears at least once (in the app bar).
    expect(find.text('Last Time I...'), findsWidgets);
  });
}
