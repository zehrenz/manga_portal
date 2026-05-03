import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:manga_portal/app.dart' show goRouter;
import 'package:manga_portal/database/app_database.dart';
import 'package:manga_portal/widgets/manga_card.dart';
import 'package:manga_portal/main.dart' as app;

Future<void> _clearTestStorage() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  final dir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(dir.path, 'manga_portal.sqlite'));
  if (await dbFile.exists()) {
    await dbFile.delete();
  }
}

Future<void> _seedLibraryEntry({
  required String mangaId,
  required String title,
  String? coverFileName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('library_entries', [
    jsonEncode({
      'id': mangaId,
      'title': title,
      'coverFileName': coverFileName,
      'savedAt': DateTime.now().toIso8601String(),
    }),
  ]);
}

Future<void> _seedCompletedDownload({
  required String mangaId,
  required String chapterId,
}) async {
  final db = AppDatabase();
  await db.upsertDownloadJob(
    chapterId: chapterId,
    mangaId: mangaId,
    status: 'completed',
    progress: 100,
    downloadedBytes: 123,
    totalBytes: 123,
  );
  await db.close();
}

Future<void> _seedFinishedAtOlderChapter({
  required String mangaId,
  required String finishedChapterId,
}) async {
  final db = AppDatabase();
  await db.setFinishedChapter(mangaId, finishedChapterId);
  await db.close();
}

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for ${finder.description}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const mockBaseUrl = String.fromEnvironment('MOCK_BASE_URL');
  if (mockBaseUrl.isEmpty) {
    throw StateError(
      'MOCK_BASE_URL is not set. '
      'Run integration tests via: dart run tool/run_integration_tests.dart',
    );
  }

  setUp(() async {
    await _clearTestStorage();
  });

  testWidgets('add manga from detail page then tap card in library',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();
    goRouter.go('/');
    await tester.pumpAndSettle();

    // Library tab is empty at start.
    expect(find.text('Your library is empty'), findsOneWidget);

    // Navigate to Search tab.
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    // Search for a manga.
    await tester.enterText(find.byType(SearchBar), 'mock');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Tap the first result to open its detail page.
    await tester.tap(find.text('Mock Manga One'));
    await tester.pumpAndSettle();

    // The bookmark icon should be unfilled (not in library yet).
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    // Tap the bookmark icon to add to library.
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    // Icon should now be filled (confirmed as in-library).
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    // Go back to the shell (search page) then tap Library tab.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    // The added manga appears as a card in the grid.
    expect(find.byType(MangaCard), findsOneWidget);
    expect(find.text('Mock Manga Title'), findsOneWidget);

    // Tap the card to navigate to the detail page.
    await tester.tap(find.byType(MangaCard));
    await tester.pumpAndSettle();

    // We're on the detail page — bookmark is filled and title is present.
    expect(find.text('Mock Manga Title'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('remove manga from library via detail page bookmark',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();
    goRouter.go('/');
    await tester.pumpAndSettle();

    // Add manga via search → detail.
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'mock');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mock Manga One'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    // Bookmark should be filled after adding.
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    // Now remove it.
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    // Bookmark should be unfilled again.
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    // Navigate to Library tab — should be empty again.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.byType(MangaCard), findsNothing);
    expect(find.text('Your library is empty'), findsOneWidget);
  });

  testWidgets('series moves into Continue Reading after reading starts',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();
    goRouter.go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'mock');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mock Manga One'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ch. 1'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();

    goRouter.go('/');
    await tester.pumpAndSettle();

    expect(find.text('Continue Reading'), findsOneWidget);
    expect(find.text('Mock Manga Title'), findsOneWidget);
    expect(find.text('No bookmarked manga on the shelf yet.'), findsOneWidget);
  });

  testWidgets('download badge appears when a library manga has downloads',
      (tester) async {
    await _seedLibraryEntry(mangaId: 'mock-manga-1', title: 'Mock Manga Title');
    await _seedCompletedDownload(
      mangaId: 'mock-manga-1',
      chapterId: 'test-chapter-1',
    );

    app.main();
    await tester.pumpAndSettle();
    goRouter.go('/');
    await tester.pumpAndSettle();

    expect(find.text('Mock Manga Title'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('up badge appears on first library load when new chapter exists',
      (tester) async {
    await _seedLibraryEntry(mangaId: 'mock-manga-1', title: 'Mock Manga Title');

    // Force update checks even when emulator connectivity is not WiFi.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_chapter_refresh_mode', 'always');

    // Stage a finished older chapter before first app load.
    await _seedFinishedAtOlderChapter(
      mangaId: 'mock-manga-1',
      finishedChapterId: 'test-chapter-1',
    );

    app.main();
    await tester.pumpAndSettle();
    goRouter.go('/');
    await tester.pumpAndSettle();

    await _waitForFinder(tester, find.byIcon(Icons.arrow_upward));
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });
}
