import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reillo_mobile/main.dart';

void main() {
  testWidgets('app launches with the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ReilloAdvMobProg());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
