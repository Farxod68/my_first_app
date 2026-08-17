import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('TopBuy Deals ishga tushadi', (WidgetTester tester) async {
    await tester.pumpWidget(const TopBuyDealsApp());

    expect(find.text('TopBuy Deals'), findsOneWidget);
  });
}