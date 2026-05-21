import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apsara_app/main.dart';

void main() {
  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Apsara'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
