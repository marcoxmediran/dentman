import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentman/main.dart';

void main() {
  testWidgets('DentMan login screen smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DentManApp()));

    // Verify that the login screen elements render correctly
    expect(find.text('DentMan'), findsOneWidget);
    expect(find.text('Staff Sign In'), findsOneWidget);
    expect(find.text('Clinic Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
