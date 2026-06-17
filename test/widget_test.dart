import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tasker/app.dart';
import 'package:tasker/core/providers/settings_provider.dart';

void main() {
  testWidgets('App boots to the lists shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TaskerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Bottom navigation should be present.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
