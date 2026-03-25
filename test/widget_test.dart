import 'package:flutter_test/flutter_test.dart';

import 'package:telemedicine/app/app.dart';

void main() {
  testWidgets('Account type screen appears', (WidgetTester tester) async {
    await tester.pumpWidget(const TelemedicineApp());

    expect(find.text('Telemedicine Portal'), findsOneWidget);
    expect(find.text('اختر نوع الحساب'), findsOneWidget);
  });
}
