import 'package:dual_capture_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const DualCaptureExampleApp());
    expect(find.text('dual_capture demos'), findsOneWidget);
  });
}
