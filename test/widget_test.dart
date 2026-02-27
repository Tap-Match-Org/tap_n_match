import 'package:flutter_test/flutter_test.dart';
import 'package:tap_n_match/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const TapAndMatchApp());

    expect(find.text('Tap & Match'), findsWidgets);
    expect(find.text('The Color game'), findsOneWidget);
  });
}