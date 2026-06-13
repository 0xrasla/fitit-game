import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App loads blank screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Container), findsOneWidget);
  });
}
