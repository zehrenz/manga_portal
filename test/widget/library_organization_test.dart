import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manga_portal/database/app_database.dart';
import 'package:manga_portal/pages/library_page.dart';
import 'package:manga_portal/providers/api_providers.dart';
import 'package:manga_portal/providers/library_provider.dart';
import 'package:manga_portal/providers/settings_provider.dart';
import 'package:manga_portal/services/local_progress.dart';

class _FakeLibraryNotifier extends LibraryNotifier {
  _FakeLibraryNotifier(this._entries);

  final List<LibraryEntry> _entries;

  @override
  Future<List<LibraryEntry>> build() async => _entries;
}

class _NeverRefreshSettingsNotifier extends SettingsNotifier {
  @override
  Settings build() {
    return const Settings(chapterRefreshMode: ChapterRefreshMode.never);
  }
}

void main() {
  testWidgets('shows Continue Reading and The Shelf sections', (tester) async {
    final db = AppDatabase.forTesting();
    final progress = await LocalProgressService.create(db);
    progress.saveProgress('manga-reading', 'ch-1', 3);
    progress.finishManga('manga-shelf', 'ch-9');

    final entries = [
      LibraryEntry(
        id: 'manga-reading',
        title: 'Reading Manga',
        savedAt: DateTime(2026, 1, 1),
      ),
      LibraryEntry(
        id: 'manga-shelf',
        title: 'Shelf Manga',
        savedAt: DateTime(2026, 1, 2),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryNotifierProvider.overrideWith(
            () => _FakeLibraryNotifier(entries),
          ),
          localProgressServiceProvider.overrideWith((ref) async => progress),
          mangaIdsWithDownloadsProvider
              .overrideWith((ref) async => {'manga-shelf'}),
          settingsNotifierProvider.overrideWith(
            _NeverRefreshSettingsNotifier.new,
          ),
        ],
        child: const MaterialApp(home: LibraryPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Continue Reading'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('The Shelf'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('The Shelf'), findsOneWidget);
    expect(find.text('Reading Manga'), findsOneWidget);
    expect(find.text('Shelf Manga'), findsOneWidget);

    await db.close();
  });
}
