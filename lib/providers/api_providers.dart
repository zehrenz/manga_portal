import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../models/chapter.dart';
import '../models/chapter_pages.dart';
import '../models/manga.dart';
import '../services/download_service.dart';
import '../services/local_progress.dart';
import '../services/mangadex_api.dart';
import 'settings_provider.dart';
import 'library_provider.dart';

part 'api_providers.g.dart';

@riverpod
MangaDexApiService mangaDexApiService(Ref ref) {
  // MOCK_BASE_URL is injected via --dart-define by run_integration_tests.dart.
  // Empty string (the default) means use the real MangaDex API.
  const mockBaseUrl = String.fromEnvironment('MOCK_BASE_URL');
  return MangaDexApiService(
    baseUrl: mockBaseUrl.isEmpty ? null : mockBaseUrl,
  );
}

@riverpod
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@riverpod
Future<LocalProgressService> localProgressService(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  return LocalProgressService.createWithCallback(db, () {
    ref.read(libraryResortTriggerProvider.notifier).update((n) => n + 1);
  });
}

@riverpod
DownloadService downloadService(Ref ref) {
  return DownloadService(
    ref.watch(appDatabaseProvider),
    ref.watch(mangaDexApiServiceProvider),
  );
}

@riverpod
Future<ChapterDownloadStatus> chapterDownloadStatus(
  Ref ref,
  String mangaId,
  String chapterId,
) {
  return ref
      .watch(downloadServiceProvider)
      .getChapterStatus(chapterId, mangaId: mangaId);
}

@riverpod
Stream<ChapterDownloadStatus> chapterDownloadStatusStream(
  Ref ref,
  String mangaId,
  String chapterId,
) {
  return ref
      .watch(downloadServiceProvider)
      .watchChapterStatus(chapterId, mangaId: mangaId);
}

@riverpod
Future<DownloadedChapter?> downloadedChapter(Ref ref, String chapterId) {
  return ref.watch(downloadServiceProvider).getDownloadedChapter(chapterId);
}

@riverpod
Future<Set<String>> downloadedChapterIdsForManga(Ref ref, String mangaId) {
  return ref
      .watch(downloadServiceProvider)
      .getDownloadedChapterIdsForManga(mangaId);
}

@riverpod
Future<int> downloadedBytesForManga(Ref ref, String mangaId) {
  return ref.watch(downloadServiceProvider).getDownloadedBytesForManga(mangaId);
}

@riverpod
Future<Set<String>> mangaIdsWithDownloads(Ref ref) {
  return ref.watch(downloadServiceProvider).getMangaIdsWithDownloads();
}

final downloadedOnlyFilterProvider =
    StateProvider.autoDispose.family<bool, String>((ref, mangaId) => false);

@riverpod
Future<AtHomeServer> atHomeServer(Ref ref, String chapterId) {
  return ref.watch(mangaDexApiServiceProvider).fetchAtHomeServer(chapterId);
}

@riverpod
Future<Manga> manga(Ref ref, String mangaId) async {
  final api = ref.watch(mangaDexApiServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  try {
    final live = await api.fetchManga(mangaId);
    final cached = await db.getCachedManga(mangaId);
    final existingCover = cached?.coverFileName;
    final keepLocalCover = existingCover != null &&
        (existingCover.startsWith('/') || existingCover.startsWith('file:'));
    await db.upsertCachedManga(
      mangaId: live.id,
      title: live.attributes.titleFor('en'),
      coverFileName: keepLocalCover ? existingCover : live.coverArt?.fileName,
    );
    return live;
  } catch (_) {
    final cached = await db.getCachedManga(mangaId);
    if (cached != null) {
      return Manga(
        id: cached.id,
        attributes: MangaAttributes(
          titles: {'en': cached.title},
          descriptions: const {},
        ),
        coverArt: cached.coverFileName == null
            ? null
            : CoverArt(id: '', fileName: cached.coverFileName),
      );
    }
    rethrow;
  }
}

/// Fetches all chapters for [mangaId], paginating internally (max 500/request).
/// Chapters are returned in API order (ascending by chapter number).
@riverpod
Future<List<Chapter>> chapterFeed(Ref ref, String mangaId) async {
  final service = ref.watch(mangaDexApiServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  final allChapters = <Chapter>[];
  var offset = 0;

  try {
    while (true) {
      final batch = await service.fetchChapterFeed(mangaId, offset: offset);
      allChapters.addAll(batch);
      if (batch.length < 500) break; // Received last page.
      offset += batch.length;
      if (offset >= 9500) {
        break; // Stay within API limit (offset + limit ≤ 10000).
      }
    }

    await db.replaceCachedChapters(
      mangaId,
      allChapters
          .map(
            (chapter) => ChaptersTableCompanion.insert(
              id: chapter.id,
              mangaId: mangaId,
              chapterNumber: Value(chapter.attributes.chapterNumber),
              title: Value(chapter.attributes.title),
              language: Value(chapter.attributes.translatedLanguage),
              scanlationGroupId: Value(chapter.scanlationGroup?.id),
              scanlationGroupName: Value(chapter.scanlationGroup?.name),
              updatedAt: DateTime.now(),
            ),
          )
          .toList(),
    );

    return allChapters;
  } catch (_) {
    final cached = await db.getCachedChapters(mangaId);
    if (cached.isNotEmpty) {
      final chapters = cached
          .map(
            (row) => Chapter(
              id: row.id,
              attributes: ChapterAttributes(
                chapterNumber: row.chapterNumber,
                title: row.title,
                translatedLanguage: row.language ?? 'en',
                pages: 0,
              ),
              scanlationGroup: row.scanlationGroupId == null
                  ? null
                  : ScanlationGroup(
                      id: row.scanlationGroupId!,
                      name: row.scanlationGroupName ?? 'Unknown Group',
                    ),
            ),
          )
          .toList();
      chapters.sort((a, b) => _compareChapterNums(
            a.attributes.chapterNumber,
            b.attributes.chapterNumber,
          ));
      return chapters;
    }
    rethrow;
  }
}

int _compareChapterNums(String? a, String? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  final aNum = double.tryParse(a);
  final bNum = double.tryParse(b);
  if (aNum != null && bNum != null) return aNum.compareTo(bNum);
  return a.compareTo(b);
}

/// Search state — holds the query and paginated results.
class MangaSearchState {
  const MangaSearchState({
    this.query = '',
    this.results = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  final String query;
  final List<Manga> results;
  final bool isLoadingMore;
  final bool hasMore;

  MangaSearchState copyWith({
    String? query,
    List<Manga>? results,
    bool? isLoadingMore,
    bool? hasMore,
  }) =>
      MangaSearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
      );
}

@riverpod
class MangaSearch extends _$MangaSearch {
  static const _pageSize = 20;

  @override
  Future<MangaSearchState> build() async => const MangaSearchState();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncData(MangaSearchState());
      return;
    }

    state = const AsyncLoading();

    final settings = ref.read(settingsNotifierProvider);
    try {
      final results = await ref.read(mangaDexApiServiceProvider).searchManga(
            trimmed,
            contentRating: settings.contentRating,
          );
      state = AsyncData(MangaSearchState(
        query: trimmed,
        results: results,
        hasMore: results.length == _pageSize,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final settings = ref.read(settingsNotifierProvider);
    try {
      final more = await ref.read(mangaDexApiServiceProvider).searchManga(
            current.query,
            offset: current.results.length,
            contentRating: settings.contentRating,
          );
      state = AsyncData(current.copyWith(
        results: [...current.results, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}
