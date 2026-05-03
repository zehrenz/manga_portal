import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/api_providers.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/manga_card.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool _checkedForUpdates = false;
  Set<String> _upMangaIds = const <String>{};

  Future<void> _maybeCheckForUpdates(List<LibraryEntry> entries) async {
    if (_checkedForUpdates) return;
    _checkedForUpdates = true;

    final settings = ref.read(settingsNotifierProvider);
    if (settings.chapterRefreshMode == ChapterRefreshMode.never) return;

    if (settings.chapterRefreshMode == ChapterRefreshMode.wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      final onWifi = connectivity.contains(ConnectivityResult.wifi);
      if (!onWifi) return;
    }

    final progressService = await ref.read(localProgressServiceProvider.future);
    final finishedMangaIds = entries
        .map((entry) => entry.id)
        .where(progressService.isFinished)
        .toList();
    if (finishedMangaIds.isEmpty) return;

    final found = await ref.read(downloadServiceProvider).checkForUpdates(
          finishedMangaIds,
          preferredLanguage: settings.preferredLanguage,
        );
    if (!mounted) return;
    setState(() => _upMangaIds = found);
    if (found.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('New chapters available'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(libraryNotifierProvider);
    ref.watch(libraryResortTriggerProvider); // re-sort on trigger
    final progressService = ref.watch(localProgressServiceProvider).valueOrNull;
    final downloadedMangaIds =
        ref.watch(mangaIdsWithDownloadsProvider).valueOrNull ??
            const <String>{};

    return SafeArea(
      child: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Could not load library.'),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _EmptyLibrary();
          }
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _maybeCheckForUpdates(entries),
          );

          final continueReading = <LibraryEntry>[];
          final shelf = <LibraryEntry>[];

          for (final entry in entries) {
            final isFinished = progressService?.isFinished(entry.id) ?? false;
            final hasProgress =
                (progressService?.getProgress(entry.id).chapterId) != null;
            final isUp = _upMangaIds.contains(entry.id);
            if ((hasProgress && !isFinished) || isUp) {
              continueReading.add(entry);
            } else {
              shelf.add(entry);
            }
          }

          continueReading.sort((a, b) {
            final aAt = progressService?.getLastReadAt(a.id) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bAt = progressService?.getLastReadAt(b.id) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bAt.compareTo(aAt);
          });
          shelf.sort((a, b) => b.savedAt.compareTo(a.savedAt));

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              const _SectionTitle('Continue Reading'),
              if (continueReading.isEmpty)
                const _SectionEmpty('No in-progress manga right now.')
              else
                _MangaGrid(
                  entries: continueReading,
                  downloadedMangaIds: downloadedMangaIds,
                  upMangaIds: _upMangaIds,
                ),
              const SizedBox(height: 12),
              const _SectionTitle('The Shelf'),
              if (shelf.isEmpty)
                const _SectionEmpty('No bookmarked manga on the shelf yet.')
              else
                _MangaGrid(
                  entries: shelf,
                  downloadedMangaIds: downloadedMangaIds,
                  upMangaIds: _upMangaIds,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MangaGrid extends StatelessWidget {
  const _MangaGrid({
    required this.entries,
    required this.downloadedMangaIds,
    required this.upMangaIds,
  });

  final List<LibraryEntry> entries;
  final Set<String> downloadedMangaIds;
  final Set<String> upMangaIds;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return MangaCard(
          manga: entry.toManga(),
          hasDownloadedChapters: downloadedMangaIds.contains(entry.id),
          isUp: upMangaIds.contains(entry.id),
          onTap: () => context.push('/manga/${entry.id}'),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: outline),
          const SizedBox(height: 16),
          Text(
            'Your library is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Search for manga to add them here.',
            style: TextStyle(color: outline),
          ),
        ],
      ),
    );
  }
}
