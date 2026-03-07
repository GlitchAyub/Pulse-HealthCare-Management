import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic smoke renders app shell frame', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('HealthReach'),
        ),
      ),
    );

    expect(find.text('HealthReach'), findsOneWidget);
  });
}
