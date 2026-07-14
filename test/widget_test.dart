import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentman/main.dart';
import 'package:dentman/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('DentMan login screen smoke test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'use_mock_db': true,
    });
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const DentManApp(),
      ),
    );

    // Verify that the login screen elements render correctly
    expect(find.text('DentMan'), findsOneWidget);
    expect(find.text('Staff Sign In'), findsOneWidget);
    expect(find.text('Clinic Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
