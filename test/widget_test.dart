import 'package:flutter_test/flutter_test.dart';
import 'package:vi_token/main.dart';

void main() {
  testWidgets('ViTokenApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ViTokenApp());
  });
}
