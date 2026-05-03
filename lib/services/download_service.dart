import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/chapter.dart';
import '../models/manga.dart';
import 'mangadex_api.dart';

class ChapterDownloadStatus {
  const ChapterDownloadStatus({
    required this.chapterId,
    required this.mangaId,
    required this.status,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes,
    this.errorMessage,
  });

  final String chapterId;
  final String mangaId;
  final String status;
  final int progress;
  final int downloadedBytes;
  final int? totalBytes;
  final String? errorMessage;

  bool get isDownloaded => status == 'completed';
  bool get isDownloading => status == 'downloading' || status == 'queued';

  static const none = ChapterDownloadStatus(
    chapterId: '',
    mangaId: '',
    status: 'not-downloaded',
  );

  factory ChapterDownloadStatus.fromRow(DownloadJobsTableData row) {
    return ChapterDownloadStatus(
      chapterId: row.chapterId,
      mangaId: row.mangaId,
      status: row.status,
      progress: row.progress,
      downloadedBytes: row.downloadedBytes,
      totalBytes: row.totalBytes,
      errorMessage: row.errorMessage,
    );
  }
}

class DownloadedChapter {
  const DownloadedChapter({
    required this.chapterId,
    required this.pages,
  });

  final String chapterId;
  final List<String> pages;
}

class DownloadService {
  DownloadService(this._db, this._apiService);

  final AppDatabase _db;
  final MangaDexApiService _apiService;
  final HttpClient _httpClient = HttpClient();
  static const _libraryPrefsKey = 'library_entries';
  final Set<String> _upMangaIds = <String>{};

  Set<String> getUpMangaIds() => Set.unmodifiable(_upMangaIds);

  Stream<ChapterDownloadStatus> watchChapterStatus(
    String chapterId, {
    String mangaId = '',
  }) {
    return _db.watchDownloadJob(chapterId).map(
          (row) => row == null
              ? ChapterDownloadStatus(
                  chapterId: chapterId,
                  mangaId: mangaId,
                  status: 'not-downloaded',
                )
              : ChapterDownloadStatus.fromRow(row),
        );
  }

  Future<ChapterDownloadStatus> getChapterStatus(
    String chapterId, {
    String mangaId = '',
  }) async {
    final row = await _db.getDownloadJob(chapterId);
    if (row == null) {
      return ChapterDownloadStatus(
        chapterId: chapterId,
        mangaId: mangaId,
        status: 'not-downloaded',
      );
    }
    return ChapterDownloadStatus.fromRow(row);
  }

  Future<DownloadedChapter?> getDownloadedChapter(String chapterId) async {
    final pages = await _db.getDownloadedPages(chapterId);
    if (pages.isEmpty) return null;
    return DownloadedChapter(
      chapterId: chapterId,
      pages: pages.map((page) => page.localPath).toList(growable: false),
    );
  }

  Future<Set<String>> getDownloadedChapterIdsForManga(String mangaId) async {
    final jobs = await _db.getDownloadJobsForManga(mangaId);
    return jobs
        .where((job) => job.status == 'completed')
        .map((job) => job.chapterId)
        .toSet();
  }

  Future<int> getDownloadedBytesForManga(String mangaId) async {
    final ids = await getDownloadedChapterIdsForManga(mangaId);
    var total = 0;
    for (final chapterId in ids) {
      final pages = await _db.getDownloadedPages(chapterId);
      for (final page in pages) {
        total += page.sizeBytes ?? 0;
      }
    }
    return total;
  }

  Future<void> removeAllDownloadsForManga(String mangaId) async {
    final ids = await getDownloadedChapterIdsForManga(mangaId);
    for (final chapterId in ids) {
      await removeChapterDownload(chapterId);
    }
  }

  Future<Set<String>> getMangaIdsWithDownloads() {
    return _db.getMangaIdsWithCompletedDownloads();
  }

  Future<Set<String>> checkForUpdates(
    List<String> mangaIds, {
    required String preferredLanguage,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final updated = <String>{};
    final started = DateTime.now();

    for (final mangaId in mangaIds) {
      if (DateTime.now().difference(started) > timeout) {
        break;
      }

      final finishedChapterId = await _db.getFinishedChapter(mangaId);
      if (finishedChapterId == null) continue;

      try {
        final chapters = await _fetchAllChapters(mangaId);
        final preferred = chapters
            .where((c) => c.attributes.translatedLanguage == preferredLanguage)
            .toList();
        if (preferred.isEmpty) continue;

        preferred.sort((a, b) {
          final aNum = double.tryParse(a.attributes.chapterNumber ?? '');
          final bNum = double.tryParse(b.attributes.chapterNumber ?? '');
          if (aNum != null && bNum != null) return aNum.compareTo(bNum);
          if (a.attributes.chapterNumber == null) return -1;
          if (b.attributes.chapterNumber == null) return 1;
          return (a.attributes.chapterNumber ?? '')
              .compareTo(b.attributes.chapterNumber ?? '');
        });

        final latest = preferred.last;
        if (latest.id != finishedChapterId) {
          updated.add(mangaId);
        }
      } catch (_) {
        // Best-effort background refresh: ignore failures per manga.
      }
    }

    _upMangaIds
      ..clear()
      ..addAll(updated);
    return updated;
  }

  Future<void> downloadChapter({
    required String mangaId,
    required String chapterId,
    bool dataSaver = false,
  }) async {
    await _db.upsertDownloadJob(
      chapterId: chapterId,
      mangaId: mangaId,
      status: 'queued',
    );

    try {
      await _db.upsertDownloadJob(
        chapterId: chapterId,
        mangaId: mangaId,
        status: 'downloading',
      );

      // Cache metadata and cover while online so the detail page/library can
      // render offline for manga with downloaded chapters.
      await _cacheMangaOfflineAssets(mangaId);

      final server = await _apiService.fetchAtHomeServer(chapterId);
      final fileNames =
          dataSaver ? server.chapter.dataSaver : server.chapter.data;
      final chapterDir = await _chapterDirectory(chapterId);
      if (chapterDir.existsSync()) {
        await chapterDir.delete(recursive: true);
      }
      await chapterDir.create(recursive: true);

      final downloadedPages = <DownloadedPagesTableCompanion>[];
      var downloadedBytes = 0;
      final totalCount = fileNames.length;

      for (var index = 0; index < fileNames.length; index++) {
        final fileName = fileNames[index];
        final targetFile = File(p.join(chapterDir.path, fileName));
        final bytes = await _downloadFile(
          server.pageUrl(fileName, dataSaver: dataSaver),
        );
        await targetFile.writeAsBytes(bytes, flush: true);
        downloadedBytes += bytes.length;
        downloadedPages.add(
          DownloadedPagesTableCompanion.insert(
            chapterId: chapterId,
            pageIndex: index,
            localPath: targetFile.path,
            sizeBytes: Value(bytes.length),
            updatedAt: DateTime.now(),
          ),
        );
        await _db.upsertDownloadJob(
          chapterId: chapterId,
          mangaId: mangaId,
          status: 'downloading',
          progress: (((index + 1) / totalCount) * 100).round(),
          downloadedBytes: downloadedBytes,
        );
      }

      await _db.replaceDownloadedPages(chapterId, downloadedPages);
      await _db.upsertDownloadJob(
        chapterId: chapterId,
        mangaId: mangaId,
        status: 'completed',
        progress: 100,
        downloadedBytes: downloadedBytes,
      );
    } catch (error) {
      await _db.upsertDownloadJob(
        chapterId: chapterId,
        mangaId: mangaId,
        status: 'failed',
        errorMessage: 'Could not download chapter.',
      );
      rethrow;
    }
  }

  Future<void> removeChapterDownload(String chapterId) async {
    final pages = await _db.getDownloadedPages(chapterId);
    for (final page in pages) {
      final file = File(page.localPath);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    final dir = await _chapterDirectory(chapterId);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    await _db.deleteDownload(chapterId);
  }

  Future<Directory> _chapterDirectory(String chapterId) async {
    final root = await getApplicationDocumentsDirectory();
    return Directory(p.join(root.path, 'downloads', chapterId));
  }

  Future<List<int>> _downloadFile(String url) async {
    final request = await _httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Download failed: ${response.statusCode}',
          uri: Uri.parse(url));
    }
    return consolidateHttpClientResponseBytes(response);
  }

  Future<void> _cacheMangaOfflineAssets(String mangaId) async {
    try {
      final manga = await _apiService.fetchManga(mangaId);
      final chapters = await _fetchAllChapters(mangaId);
      final localCoverPath = await _cacheCoverImage(manga);

      await _db.upsertCachedManga(
        mangaId: manga.id,
        title: manga.attributes.titleFor('en'),
        coverFileName: localCoverPath ?? manga.coverArt?.fileName,
      );

      await _db.replaceCachedChapters(
        mangaId,
        chapters
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

      await _autoAddToLibrary(
        mangaId: manga.id,
        title: manga.attributes.titleFor('en'),
        coverPathOrName: localCoverPath ?? manga.coverArt?.fileName,
      );
    } catch (_) {
      // Download should not fail just because metadata prefetch fails.
    }
  }

  Future<List<Chapter>> _fetchAllChapters(String mangaId) async {
    final all = <Chapter>[];
    var offset = 0;
    while (true) {
      final batch = await _apiService.fetchChapterFeed(mangaId, offset: offset);
      all.addAll(batch);
      if (batch.length < 500) break;
      offset += batch.length;
      if (offset >= 9500) break;
    }
    return all;
  }

  Future<String?> _cacheCoverImage(Manga manga) async {
    final coverUrl = manga.coverUrl(256);
    if (coverUrl == null) return null;

    final bytes = await _downloadFile(coverUrl);
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'downloads', 'covers'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final ext = p.extension(Uri.parse(coverUrl).path);
    final file =
        File(p.join(dir.path, '${manga.id}${ext.isEmpty ? '.jpg' : ext}'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _autoAddToLibrary({
    required String mangaId,
    required String title,
    String? coverPathOrName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_libraryPrefsKey) ?? const <String>[];
    final entries = raw
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => _decodeJson(s))
        .whereType<Map<String, dynamic>>()
        .toList();

    final exists = entries.any((e) => e['id'] == mangaId);
    if (exists) return;

    entries.insert(0, {
      'id': mangaId,
      'title': title,
      'coverFileName': coverPathOrName,
      'savedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setStringList(
      _libraryPrefsKey,
      entries.map((e) => _encodeJson(e)).toList(),
    );
  }

  Map<String, dynamic>? _decodeJson(String raw) {
    try {
      final obj = jsonDecode(raw);
      return obj is Map<String, dynamic> ? obj : null;
    } catch (_) {
      return null;
    }
  }

  String _encodeJson(Map<String, dynamic> value) => jsonEncode(value);
}
