import 'package:flutter_test/flutter_test.dart';
import 'package:billingadmin/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const BillingAdminApp());
    await tester.pump();
  });
}
