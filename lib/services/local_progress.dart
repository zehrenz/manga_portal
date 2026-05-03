import 'dart:async';

import '../database/app_database.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

/// Persists and retrieves per-manga reading progress.
///
/// Backed by [AppDatabase], with an in-memory cache to preserve the existing
/// synchronous read API used by providers/widgets.
class LocalProgressService {
  LocalProgressService._(
    this._db,
    this._progressByManga,
    this._readByManga,
    this._modeByManga,
    this._finishedChapterByManga,
    this._lastReadAtByManga,
    this._onProgressChanged,
  );

  final AppDatabase _db;
  final VoidCallback? _onProgressChanged;

  final Map<String, ({String? chapterId, int pageIndex})> _progressByManga;
  final Map<String, Set<String>> _readByManga;
  final Map<String, String> _modeByManga;
  final Map<String, String> _finishedChapterByManga;
  final Map<String, DateTime> _lastReadAtByManga;

  static Future<LocalProgressService> create(AppDatabase db) async {
    final progressRows = await db.allProgressRows();
    final readRows = await db.allReadChaptersRows();
    final modeRows = await db.allReadingModesRows();

    final progress = <String, ({String? chapterId, int pageIndex})>{
      for (final row in progressRows)
        row.mangaId: (chapterId: row.chapterId, pageIndex: row.pageIndex),
    };
    final finished = <String, String>{
      for (final row in progressRows)
        if (row.finishedChapterId != null) row.mangaId: row.finishedChapterId!,
    };
    final lastRead = <String, DateTime>{
      for (final row in progressRows) row.mangaId: row.updatedAt,
    };

    final read = <String, Set<String>>{};
    for (final row in readRows) {
      (read[row.mangaId] ??= <String>{}).add(row.chapterId);
    }

    final modes = <String, String>{
      for (final row in modeRows)
        row.mangaId: (row.mode == 'paged') ? 'ltr' : row.mode,
    };

    return LocalProgressService._(
        db, progress, read, modes, finished, lastRead, null);
  }

  /// Creates a [LocalProgressService] with an [onProgressChanged] callback
  /// that fires whenever [saveProgress] is called.
  static Future<LocalProgressService> createWithCallback(
      AppDatabase db, VoidCallback onProgressChanged) async {
    final s = await create(db);
    return LocalProgressService._(
        s._db,
        s._progressByManga,
        s._readByManga,
        s._modeByManga,
        s._finishedChapterByManga,
        s._lastReadAtByManga,
        onProgressChanged);
  }

  /// Saves the current reading position for [mangaId].
  void saveProgress(String mangaId, String chapterId, int pageIndex) {
    _progressByManga[mangaId] = (chapterId: chapterId, pageIndex: pageIndex);
    _lastReadAtByManga[mangaId] = DateTime.now();
    unawaited(_db.saveProgress(mangaId, chapterId, pageIndex));
    _onProgressChanged?.call();
  }

  /// Returns the saved reading position for [mangaId].
  /// Returns `(chapterId: null, pageIndex: 0)` if nothing has been saved.
  ({String? chapterId, int pageIndex}) getProgress(String mangaId) {
    return _progressByManga[mangaId] ?? (chapterId: null, pageIndex: 0);
  }

  /// Records [chapterId] as fully read for [mangaId].
  /// Safe to call multiple times for the same chapter.
  void markChapterRead(String mangaId, String chapterId) {
    final read = (_readByManga[mangaId] ??= <String>{});
    if (read.add(chapterId)) {
      unawaited(_db.markChapterRead(mangaId, chapterId));
    }
  }

  /// Marks [mangaId] as finished at [lastChapterId].
  void finishManga(String mangaId, String lastChapterId) {
    _finishedChapterByManga[mangaId] = lastChapterId;
    _lastReadAtByManga[mangaId] = DateTime.now();
    unawaited(_db.setFinishedChapter(mangaId, lastChapterId));
  }

  bool isFinished(String mangaId) =>
      _finishedChapterByManga.containsKey(mangaId);

  String? getFinishedChapter(String mangaId) =>
      _finishedChapterByManga[mangaId];

  DateTime? getLastReadAt(String mangaId) => _lastReadAtByManga[mangaId];

  /// Returns the set of chapter IDs the user has explicitly completed for
  /// [mangaId]. An empty set means no chapters have been fully read yet.
  Set<String> getReadChapterIds(String mangaId) {
    return {...(_readByManga[mangaId] ?? const <String>{})};
  }

  /// Saves the preferred reading mode for [mangaId].
  /// [mode] must be one of: 'ltr', 'rtl', or 'scroll'.
  void saveReadingMode(String mangaId, String mode) {
    _modeByManga[mangaId] = mode;
    unawaited(_db.saveReadingMode(mangaId, mode));
  }

  /// Returns the saved reading mode for [mangaId], defaulting to 'ltr'.
  ///
  /// Also migrates legacy values:
  ///   'paged' -> 'ltr'
  String getReadingMode(String mangaId) {
    final mode = _modeByManga[mangaId];
    if (mode == 'paged') return 'ltr';
    if (mode == 'ltr' || mode == 'rtl' || mode == 'scroll') return mode!;
    return 'ltr';
  }

  /// Removes all reading progress and read-chapter history from the device.
  /// Reading modes are intentionally preserved (they are a preference, not history).
  Future<void> clearAllProgress() async {
    _progressByManga.clear();
    _readByManga.clear();
    _finishedChapterByManga.clear();
    _lastReadAtByManga.clear();
    await _db.clearProgressData();
  }
}
