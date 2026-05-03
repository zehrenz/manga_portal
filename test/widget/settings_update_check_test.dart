import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manga_portal/pages/settings_page.dart';
import 'package:manga_portal/providers/settings_provider.dart';

void main() {
  testWidgets('chapter refresh mode defaults to WiFi only and can change',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Check for new chapters on launch'), findsOneWidget);
    expect(find.text('WiFi only'), findsOneWidget);

    await tester.tap(find.text('Always'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPage)),
    );
    final mode = container.read(settingsNotifierProvider).chapterRefreshMode;
    expect(mode, ChapterRefreshMode.always);
  });
}
