import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schoolwebsite/main.dart';

void main() {
  testWidgets('App launches and shows MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const SchoolPortalApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
