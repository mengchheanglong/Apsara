import 'package:flutter_test/flutter_test.dart';

import 'package:artkh_app/main.dart';

void main() {
  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ArtKhApp());

    expect(find.text('ArtKh'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
