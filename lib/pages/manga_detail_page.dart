import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/chapter.dart';
import '../models/manga.dart';
import '../providers/api_providers.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chapter_list_tile.dart';

class MangaDetailPage extends ConsumerWidget {
  const MangaDetailPage({super.key, required this.mangaId});

  final String mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangaAsync = ref.watch(mangaProvider(mangaId));
    final chaptersAsync = ref.watch(chapterFeedProvider(mangaId));
    final settings = ref.watch(settingsNotifierProvider);
    final progressAsync = ref.watch(localProgressServiceProvider);
    final downloadedOnly = ref.watch(downloadedOnlyFilterProvider(mangaId));
    final downloadedIdsAsync =
        ref.watch(downloadedChapterIdsForMangaProvider(mangaId));
    final downloadedBytesAsync =
        ref.watch(downloadedBytesForMangaProvider(mangaId));

    // Current chapter the user is partway through (null when progress unknown).
    final currentChapterId = progressAsync.maybeWhen(
      data: (service) => service.getProgress(mangaId).chapterId,
      orElse: () => null,
    );
    // Set of chapter IDs the user has explicitly finished.
    final readChapterIds = progressAsync.maybeWhen(
      data: (service) => service.getReadChapterIds(mangaId),
      orElse: () => const <String>{},
    );

    // Chapter to open when the user taps the action button.
    // • Has progress → resume that chapter.
    // • No progress  → start from the lowest available chapter in their language.
    final actionChapter = chaptersAsync.maybeWhen(
      data: (chapters) => _resolveActionChapter(
        chapters,
        currentChapterId,
        settings.preferredLanguage,
      ),
      orElse: () => null,
    );

    final downloadedChapterIds =
        downloadedIdsAsync.valueOrNull ?? const <String>{};
    final downloadedBytes = downloadedBytesAsync.valueOrNull ?? 0;

    // Library state — watched here so the bookmark button in the AppBar rebuilds.
    final manga = mangaAsync.valueOrNull;
    final inLibrary = ref.watch(
      libraryNotifierProvider.select(
        (s) => s.valueOrNull?.any((e) => e.id == mangaId) ?? false,
      ),
    );
    final notifier = ref.read(libraryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (manga != null)
            IconButton(
              icon: Icon(inLibrary ? Icons.bookmark : Icons.bookmark_border),
              tooltip: inLibrary ? 'Remove from library' : 'Add to library',
              onPressed: () async {
                if (inLibrary) {
                  await notifier.removeManga(mangaId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(content: Text('Removed from library.')),
                      );
                  }
                } else {
                  await notifier.addManga(manga);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(content: Text('Added to library.')),
                      );
                  }
                }
              },
            ),
        ],
      ),
      body: mangaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          message: 'Could not load manga.\nPlease check your connection.',
          onRetry: () {
            ref.invalidate(mangaProvider(mangaId));
            ref.invalidate(chapterFeedProvider(mangaId));
          },
        ),
        data: (manga) => CustomScrollView(
          slivers: [
            _MangaCover(manga: manga),
            _MangaInfo(manga: manga, locale: settings.preferredLanguage),
            if (actionChapter != null)
              _ReadingButton(
                chapter: actionChapter,
                isResuming: currentChapterId != null,
                onTap: () => context
                    .push('/reader/${actionChapter.id}?mangaId=$mangaId'),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Downloaded only'),
                      selected: downloadedOnly,
                      onSelected: (selected) => ref
                          .read(downloadedOnlyFilterProvider(mangaId).notifier)
                          .state = selected,
                    ),
                    Text(
                      '${downloadedChapterIds.length} downloaded • ${_formatBytes(downloadedBytes)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (downloadedChapterIds.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Remove all downloads'),
                        onPressed: () async {
                          await ref
                              .read(downloadServiceProvider)
                              .removeAllDownloadsForManga(mangaId);
                          ref.invalidate(
                              downloadedChapterIdsForMangaProvider(mangaId));
                          ref.invalidate(
                              downloadedBytesForMangaProvider(mangaId));
                          final chapters =
                              chaptersAsync.valueOrNull ?? const <Chapter>[];
                          for (final chapter in chapters) {
                            ref.invalidate(
                              chapterDownloadStatusProvider(
                                  mangaId, chapter.id),
                            );
                            ref.invalidate(
                                downloadedChapterProvider(chapter.id));
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Removed all downloads for this manga.')),
                            );
                        },
                      ),
                  ],
                ),
              ),
            ),
            chaptersAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: _ErrorBody(
                  message: 'Could not load chapters.',
                  onRetry: () => ref.invalidate(chapterFeedProvider(mangaId)),
                ),
              ),
              data: (chapters) => _ChapterList(
                mangaId: mangaId,
                chapters: chapters,
                preferredLanguage: settings.preferredLanguage,
                currentChapterId: currentChapterId,
                readChapterIds: readChapterIds,
                downloadedOnly: downloadedOnly,
                downloadedChapterIds: downloadedChapterIds,
                onChapterSelected: (chapterId) =>
                    context.push('/reader/$chapterId?mangaId=$mangaId'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cover image ───────────────────────────────────────────────────────────────

class _MangaCover extends StatelessWidget {
  const _MangaCover({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context) {
    final coverFile = manga.coverArt?.fileName;
    final hasLocalCover = coverFile != null &&
        (coverFile.startsWith('/') || coverFile.startsWith('file:'));
    final coverUrl = hasLocalCover ? null : manga.coverUrl(512);
    final localCoverPath = hasLocalCover
        ? (coverFile.startsWith('file:')
            ? Uri.parse(coverFile).toFilePath()
            : coverFile)
        : null;
    final title = manga.attributes.titleFor('en');

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover art.
            if (localCoverPath != null)
              Image(
                image: FileImage(File(localCoverPath)),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.expand(),
              )
            else if (coverUrl != null)
              Image(
                image: CachedNetworkImageProvider(coverUrl),
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, sync) =>
                    sync || frame != null ? child : const SizedBox.expand(),
                errorBuilder: (_, __, ___) => const SizedBox.expand(),
              ),
            // Frosted-glass title strip at the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withAlpha(30),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Description section ──────────────────────────────────────────────────────

class _MangaInfo extends StatefulWidget {
  const _MangaInfo({required this.manga, required this.locale});

  final Manga manga;
  final String locale;

  @override
  State<_MangaInfo> createState() => _MangaInfoState();
}

class _MangaInfoState extends State<_MangaInfo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.manga.attributes.descriptionFor(widget.locale);
    final style = Theme.of(context).textTheme.bodyMedium!;
    final lineHeight = (style.fontSize ?? 14) * (style.height ?? 1.43);
    final collapsedHeight = lineHeight * 2;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? MarkdownBody(
                          data: description,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(Theme.of(context)),
                          shrinkWrap: true,
                        )
                      : SizedBox(
                          height: collapsedHeight,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              maxHeight: double.infinity,
                              child: MarkdownBody(
                                data: description,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context)),
                                shrinkWrap: true,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  const Divider(),
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 28,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    tooltip: _expanded ? 'Collapse' : 'Expand',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Chapter list ─────────────────────────────────────────────────────────────

class _ChapterList extends StatelessWidget {
  const _ChapterList({
    required this.mangaId,
    required this.chapters,
    required this.preferredLanguage,
    required this.onChapterSelected,
    this.currentChapterId,
    this.readChapterIds = const {},
    this.downloadedOnly = false,
    this.downloadedChapterIds = const <String>{},
  });

  final String mangaId;
  final List<Chapter> chapters;
  final String preferredLanguage;
  final void Function(String chapterId) onChapterSelected;

  /// The ID of the chapter the user is currently partway through, if any.
  final String? currentChapterId;

  /// Chapter IDs the user has explicitly finished (swiped past the last page).
  final Set<String> readChapterIds;

  final bool downloadedOnly;
  final Set<String> downloadedChapterIds;

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No chapters available.')),
        ),
      );
    }

    var groups = _groupAndSort(chapters);
    final latestPreferredChapterNumber = _latestPreferredChapterNumber(
      chapters,
      preferredLanguage,
    );
    if (downloadedOnly) {
      groups = groups
          .where((entry) => entry.value
              .any((chapter) => downloadedChapterIds.contains(chapter.id)))
          .toList();
      if (groups.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No downloaded chapters.')),
          ),
        );
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = groups[index];
          return ChapterListTile(
            key: ValueKey(entry.key),
            mangaId: mangaId,
            chapters: entry.value,
            preferredLanguage: preferredLanguage,
            isLatest: latestPreferredChapterNumber == entry.key,
            readState:
                _readStateFor(entry.value, currentChapterId, readChapterIds),
            onChapterSelected: onChapterSelected,
          );
        },
        childCount: groups.length,
      ),
    );
  }

  /// Determines the read state for a chapter group.
  ///
  /// - [reading]: any version in the group is the user's current chapter.
  /// - [read]:    at least one version has been explicitly completed.
  /// - [unread]:  none of the above.
  static ChapterReadState _readStateFor(
    List<Chapter> groupChapters,
    String? currentChapterId,
    Set<String> readChapterIds,
  ) {
    if (groupChapters.any((c) => c.id == currentChapterId)) {
      return ChapterReadState.reading;
    }
    if (groupChapters.any((c) => readChapterIds.contains(c.id))) {
      return ChapterReadState.read;
    }
    return ChapterReadState.unread;
  }

  /// Groups chapters by their chapter number and sorts descending.
  /// Oneshots (null chapter number) sort to the top.
  static List<MapEntry<String?, List<Chapter>>> _groupAndSort(
    List<Chapter> chapters,
  ) {
    final groups = <String?, List<Chapter>>{};
    for (final c in chapters) {
      groups.putIfAbsent(c.attributes.chapterNumber, () => []).add(c);
    }

    final entries = groups.entries.toList()
      ..sort((a, b) {
        if (a.key == null && b.key == null) return 0;
        if (a.key == null) return -1; // Oneshots → top
        if (b.key == null) return 1;
        final aNum = double.tryParse(a.key!);
        final bNum = double.tryParse(b.key!);
        if (aNum != null && bNum != null) return bNum.compareTo(aNum);
        return b.key!.compareTo(a.key!);
      });

    return entries;
  }

  static String? _latestPreferredChapterNumber(
    List<Chapter> chapters,
    String preferredLanguage,
  ) {
    final preferred = chapters
        .where((c) => c.attributes.translatedLanguage == preferredLanguage)
        .toList();
    if (preferred.isEmpty) return null;

    preferred.sort((a, b) {
      final aNum = double.tryParse(a.attributes.chapterNumber ?? '');
      final bNum = double.tryParse(b.attributes.chapterNumber ?? '');
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      if (a.attributes.chapterNumber == null) return -1;
      if (b.attributes.chapterNumber == null) return 1;
      return (a.attributes.chapterNumber ?? '')
          .compareTo(b.attributes.chapterNumber ?? '');
    });

    return preferred.last.attributes.chapterNumber;
  }
}

// ── Action chapter resolution ─────────────────────────────────────────────────

/// Returns the chapter to open when the user taps the read button.
///
/// If [currentChapterId] is set and found in [chapters], returns that chapter
/// (resume). Otherwise returns the lowest-numbered chapter available in
/// [preferredLanguage] (start from beginning). Returns null if no chapters in
/// the preferred language exist.
Chapter? _resolveActionChapter(
  List<Chapter> chapters,
  String? currentChapterId,
  String preferredLanguage,
) {
  final available = chapters
      .where((c) => c.attributes.translatedLanguage == preferredLanguage)
      .toList();
  if (available.isEmpty) return null;

  if (currentChapterId != null) {
    final current =
        available.where((c) => c.id == currentChapterId).firstOrNull;
    if (current != null) return current;
  }

  // Sort ascending to find the lowest chapter number.
  available.sort((a, b) {
    final aNum = double.tryParse(a.attributes.chapterNumber ?? '');
    final bNum = double.tryParse(b.attributes.chapterNumber ?? '');
    if (aNum != null && bNum != null) return aNum.compareTo(bNum);
    if (a.attributes.chapterNumber == null) return -1;
    if (b.attributes.chapterNumber == null) return 1;
    return a.attributes.chapterNumber!.compareTo(b.attributes.chapterNumber!);
  });
  return available.first;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(2)} GB';
}

// ── Read / Continue button ────────────────────────────────────────────────────

class _ReadingButton extends StatelessWidget {
  const _ReadingButton({
    required this.chapter,
    required this.isResuming,
    required this.onTap,
  });

  final Chapter chapter;

  /// true → "Continue Ch. X", false → "Start Ch. X"
  final bool isResuming;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final num = chapter.attributes.chapterNumber;
    final chapterLabel = num != null ? 'Ch. $num' : 'Oneshot';
    final label = isResuming ? 'Continue $chapterLabel' : 'Start $chapterLabel';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: FilledButton.icon(
          icon: Icon(isResuming ? Icons.play_arrow : Icons.play_arrow_outlined),
          label: Text(label),
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
    );
  }
}

// ── Shared error widget ───────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
