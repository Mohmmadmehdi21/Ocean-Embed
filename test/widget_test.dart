import 'package:flutter_test/flutter_test.dart';
import 'package:oceanembed/main.dart';

void main() {
  testWidgets('OceanEmbed smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OceanEmbedApp());
    await tester.pump();

    // Verify OceanEmbed title on splash screen
    expect(find.text('OceanEmbed'), findsOneWidget);

    // Fast forward splash timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify Ocean Dashboard renders
    expect(find.text('Ocean Dashboard'), findsOneWidget);
  });
}
