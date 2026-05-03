import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class LibraryEntriesTable extends Table {
  TextColumn get mangaId => text()();
  TextColumn get title => text()();
  TextColumn get coverFileName => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mangaId};
}

class MangaProgressTable extends Table {
  TextColumn get mangaId => text()();
  TextColumn get chapterId => text().nullable()();
  TextColumn get finishedChapterId => text().nullable()();
  IntColumn get pageIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mangaId};
}

class ReadChaptersTable extends Table {
  TextColumn get mangaId => text()();
  TextColumn get chapterId => text()();
  DateTimeColumn get readAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mangaId, chapterId};
}

class ReadingModesTable extends Table {
  TextColumn get mangaId => text()();
  TextColumn get mode => text()(); // ltr | rtl | scroll
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mangaId};
}

class MangaTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get coverFileName => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChaptersTable extends Table {
  TextColumn get id => text()();
  TextColumn get mangaId => text()();
  TextColumn get chapterNumber => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get language => text().nullable()();
  TextColumn get scanlationGroupId => text().nullable()();
  TextColumn get scanlationGroupName => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DownloadJobsTable extends Table {
  TextColumn get chapterId => text()();
  TextColumn get mangaId => text()();
  TextColumn get status =>
      text()(); // queued | downloading | completed | failed
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {chapterId};
}

class DownloadedPagesTable extends Table {
  TextColumn get chapterId => text()();
  IntColumn get pageIndex => integer()();
  TextColumn get localPath => text()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get checksum => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {chapterId, pageIndex};
}

@DriftDatabase(
  tables: [
    SettingsTable,
    LibraryEntriesTable,
    MangaProgressTable,
    ReadChaptersTable,
    ReadingModesTable,
    MangaTable,
    ChaptersTable,
    DownloadJobsTable,
    DownloadedPagesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test constructor for in-memory database.
  ///
  /// Each test creates its own isolated in-memory database, so Drift warnings
  /// about multiple database instances can be safely ignored in test contexts.
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(
                mangaProgressTable, mangaProgressTable.finishedChapterId);
          }
        },
      );

  Future<void> upsertSetting(String key, String value) {
    return into(settingsTable).insertOnConflictUpdate(
      SettingsTableCompanion.insert(key: key, value: value),
    );
  }

  Future<String?> getSetting(String key) async {
    final row = await (select(settingsTable)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> upsertLibraryEntry({
    required String mangaId,
    required String title,
    String? coverFileName,
  }) {
    return into(libraryEntriesTable).insertOnConflictUpdate(
      LibraryEntriesTableCompanion.insert(
        mangaId: mangaId,
        title: title,
        coverFileName: Value(coverFileName),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<List<LibraryEntriesTableData>> allLibraryEntries() {
    return (select(libraryEntriesTable)
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  Future<void> removeLibraryEntry(String mangaId) {
    return (delete(libraryEntriesTable)
          ..where((t) => t.mangaId.equals(mangaId)))
        .go();
  }

  Future<void> saveProgress(
      String mangaId, String chapterId, int pageIndex) async {
    await into(mangaProgressTable).insertOnConflictUpdate(
      MangaProgressTableCompanion.insert(
        mangaId: mangaId,
        chapterId: Value(chapterId),
        pageIndex: Value(pageIndex),
        finishedChapterId: const Value.absent(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<({String? chapterId, int pageIndex})> getProgress(
      String mangaId) async {
    final row = await (select(mangaProgressTable)
          ..where((t) => t.mangaId.equals(mangaId)))
        .getSingleOrNull();
    return (chapterId: row?.chapterId, pageIndex: row?.pageIndex ?? 0);
  }

  Future<void> setFinishedChapter(String mangaId, String chapterId) async {
    final existing = await (select(mangaProgressTable)
          ..where((t) => t.mangaId.equals(mangaId)))
        .getSingleOrNull();
    if (existing == null) {
      await into(mangaProgressTable).insert(
        MangaProgressTableCompanion.insert(
          mangaId: mangaId,
          chapterId: Value(chapterId),
          finishedChapterId: Value(chapterId),
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    await (update(mangaProgressTable)..where((t) => t.mangaId.equals(mangaId)))
        .write(
      MangaProgressTableCompanion(
        finishedChapterId: Value(chapterId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> getFinishedChapter(String mangaId) async {
    final row = await (select(mangaProgressTable)
          ..where((t) => t.mangaId.equals(mangaId)))
        .getSingleOrNull();
    return row?.finishedChapterId;
  }

  Future<List<MangaProgressTableData>> allProgressRows() {
    return select(mangaProgressTable).get();
  }

  Future<Map<String, DateTime>> allProgressUpdatedAt() async {
    final rows = await select(mangaProgressTable).get();
    return {
      for (final row in rows) row.mangaId: row.updatedAt,
    };
  }

  Future<void> markChapterRead(String mangaId, String chapterId) {
    return into(readChaptersTable).insertOnConflictUpdate(
      ReadChaptersTableCompanion.insert(
        mangaId: mangaId,
        chapterId: chapterId,
        readAt: DateTime.now(),
      ),
    );
  }

  Future<Set<String>> getReadChapterIds(String mangaId) async {
    final rows = await (select(readChaptersTable)
          ..where((t) => t.mangaId.equals(mangaId)))
        .get();
    return rows.map((r) => r.chapterId).toSet();
  }

  Future<List<ReadChaptersTableData>> allReadChaptersRows() {
    return select(readChaptersTable).get();
  }

  Future<void> saveReadingMode(String mangaId, String mode) {
    return into(readingModesTable).insertOnConflictUpdate(
      ReadingModesTableCompanion.insert(
        mangaId: mangaId,
        mode: mode,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<String> getReadingMode(String mangaId) async {
    final row = await (select(readingModesTable)
          ..where((t) => t.mangaId.equals(mangaId)))
        .getSingleOrNull();
    final mode = row?.mode;
    if (mode == 'paged') return 'ltr';
    if (mode == 'ltr' || mode == 'rtl' || mode == 'scroll') return mode!;
    return 'ltr';
  }

  Future<List<ReadingModesTableData>> allReadingModesRows() {
    return select(readingModesTable).get();
  }

  Future<void> upsertCachedManga({
    required String mangaId,
    required String title,
    String? coverFileName,
  }) {
    return into(mangaTable).insertOnConflictUpdate(
      MangaTableCompanion.insert(
        id: mangaId,
        title: title,
        coverFileName: Value(coverFileName),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<MangaTableData?> getCachedManga(String mangaId) {
    return (select(mangaTable)..where((t) => t.id.equals(mangaId)))
        .getSingleOrNull();
  }

  Future<void> replaceCachedChapters(
    String mangaId,
    List<ChaptersTableCompanion> chapters,
  ) async {
    await transaction(() async {
      await (delete(chaptersTable)..where((t) => t.mangaId.equals(mangaId)))
          .go();
      if (chapters.isNotEmpty) {
        await batch((batch) => batch.insertAll(chaptersTable, chapters));
      }
    });
  }

  Future<List<ChaptersTableData>> getCachedChapters(String mangaId) {
    return (select(chaptersTable)..where((t) => t.mangaId.equals(mangaId)))
        .get();
  }

  Future<void> upsertDownloadJob({
    required String chapterId,
    required String mangaId,
    required String status,
    int progress = 0,
    int downloadedBytes = 0,
    int? totalBytes,
    String? errorMessage,
  }) {
    return into(downloadJobsTable).insertOnConflictUpdate(
      DownloadJobsTableCompanion.insert(
        chapterId: chapterId,
        mangaId: mangaId,
        status: status,
        progress: Value(progress),
        downloadedBytes: Value(downloadedBytes),
        totalBytes: Value(totalBytes),
        errorMessage: Value(errorMessage),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<DownloadJobsTableData?> getDownloadJob(String chapterId) {
    return (select(downloadJobsTable)
          ..where((t) => t.chapterId.equals(chapterId)))
        .getSingleOrNull();
  }

  Stream<DownloadJobsTableData?> watchDownloadJob(String chapterId) {
    return (select(downloadJobsTable)
          ..where((t) => t.chapterId.equals(chapterId)))
        .watchSingleOrNull();
  }

  Stream<List<DownloadJobsTableData>> watchDownloadJobsForManga(
      String mangaId) {
    return (select(downloadJobsTable)..where((t) => t.mangaId.equals(mangaId)))
        .watch();
  }

  Future<List<DownloadJobsTableData>> getDownloadJobsForManga(String mangaId) {
    return (select(downloadJobsTable)..where((t) => t.mangaId.equals(mangaId)))
        .get();
  }

  Future<Set<String>> getMangaIdsWithCompletedDownloads() async {
    final rows = await (select(downloadJobsTable)
          ..where((t) => t.status.equals('completed')))
        .get();
    return rows.map((row) => row.mangaId).toSet();
  }

  Future<void> replaceDownloadedPages(
    String chapterId,
    List<DownloadedPagesTableCompanion> pages,
  ) async {
    await transaction(() async {
      await (delete(downloadedPagesTable)
            ..where((t) => t.chapterId.equals(chapterId)))
          .go();
      if (pages.isNotEmpty) {
        await batch((batch) => batch.insertAll(downloadedPagesTable, pages));
      }
    });
  }

  Future<List<DownloadedPagesTableData>> getDownloadedPages(String chapterId) {
    return (select(downloadedPagesTable)
          ..where((t) => t.chapterId.equals(chapterId))
          ..orderBy([(t) => OrderingTerm.asc(t.pageIndex)]))
        .get();
  }

  Future<bool> hasDownloadedChapter(String chapterId) async {
    final count = downloadedPagesTable.pageIndex.count();
    final query = selectOnly(downloadedPagesTable)
      ..addColumns([count])
      ..where(downloadedPagesTable.chapterId.equals(chapterId));
    final row = await query.getSingleOrNull();
    return (row?.read(count) ?? 0) > 0;
  }

  Future<void> deleteDownload(String chapterId) async {
    await transaction(() async {
      await (delete(downloadedPagesTable)
            ..where((t) => t.chapterId.equals(chapterId)))
          .go();
      await (delete(downloadJobsTable)
            ..where((t) => t.chapterId.equals(chapterId)))
          .go();
    });
  }

  Future<void> clearProgressData() async {
    await delete(mangaProgressTable).go();
    await delete(readChaptersTable).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'manga_portal.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
