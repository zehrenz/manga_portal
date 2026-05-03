import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chapter.dart';
import '../providers/api_providers.dart';

/// Reading state for a chapter group, used to style the corresponding tile.
enum ChapterReadState {
  /// No progress recorded — user hasn't started this chapter.
  unread,

  /// This is the chapter the user is currently partway through.
  reading,

  /// User has read past this chapter.
  read,
}

/// Displays all versions of a single chapter number.
///
/// Receives [chapters] — all [Chapter] objects that share the same chapter
/// number — and [preferredLanguage] to decide how to present them:
///
/// - **One group in preferred language**: single tappable row.
/// - **Multiple groups in preferred language**: collapsed row with an expand
///   toggle that reveals all groups inline.
/// - **No groups in preferred language**: subdued, non-interactive row with a
///   note indicating the chapter is unavailable in the preferred language.
class ChapterListTile extends StatefulWidget {
  const ChapterListTile({
    super.key,
    required this.mangaId,
    required this.chapters,
    required this.preferredLanguage,
    required this.onChapterSelected,
    this.readState = ChapterReadState.unread,
    this.isLatest = false,
  });

  final String mangaId;
  final List<Chapter> chapters;
  final String preferredLanguage;
  final void Function(String chapterId) onChapterSelected;
  final ChapterReadState readState;
  final bool isLatest;

  @override
  State<ChapterListTile> createState() => _ChapterListTileState();
}

class _ChapterListTileState extends State<ChapterListTile> {
  bool _expanded = false;

  List<Chapter> get _preferred => widget.chapters
      .where((c) => c.attributes.translatedLanguage == widget.preferredLanguage)
      .toList();

  @override
  Widget build(BuildContext context) {
    final preferred = _preferred;
    final chapterNumber = widget.chapters.first.attributes.chapterNumber;
    final title = _chapterLabel(chapterNumber);

    if (preferred.isEmpty) {
      return _UnavailableTile(
        label: title,
        preferredLanguage: widget.preferredLanguage,
      );
    }

    if (preferred.length == 1) {
      return _SingleGroupTile(
        mangaId: widget.mangaId,
        label: title,
        chapter: preferred.first,
        readState: widget.readState,
        isLatest: widget.isLatest,
        onTap: () => widget.onChapterSelected(preferred.first.id),
      );
    }

    return _MultiGroupTile(
      mangaId: widget.mangaId,
      label: title,
      chapters: preferred,
      readState: widget.readState,
      isLatest: widget.isLatest,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      onChapterSelected: widget.onChapterSelected,
    );
  }
}

String _chapterLabel(String? chapterNumber) =>
    chapterNumber != null ? 'Ch. $chapterNumber' : 'Oneshot';

String _formatDate(String? isoDate) {
  if (isoDate == null) return '';
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return '';
  }
}

// ── Single group ─────────────────────────────────────────────────────────────

class _SingleGroupTile extends StatelessWidget {
  const _SingleGroupTile({
    required this.mangaId,
    required this.label,
    required this.chapter,
    required this.onTap,
    this.readState = ChapterReadState.unread,
    this.isLatest = false,
  });

  final String mangaId;
  final String label;
  final Chapter chapter;
  final VoidCallback onTap;
  final ChapterReadState readState;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final groupName = chapter.scanlationGroup?.name;
    final date = _formatDate(chapter.attributes.publishAt);
    final subtitle = [
      if (groupName != null) groupName,
      if (date.isNotEmpty) date,
    ].join(' · ');

    final isRead = readState == ChapterReadState.read;
    final isReading = readState == ChapterReadState.reading;
    final dimColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    final tile = ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: isRead ? TextStyle(color: dimColor) : null,
            ),
          ),
          if (isLatest) ...[
            const SizedBox(width: 8),
            const _LatestBadge(),
          ],
          if (isRead) ...[
            const SizedBox(width: 6),
            Icon(Icons.check_circle_outline, size: 16, color: dimColor),
          ],
        ],
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: isRead ? TextStyle(color: dimColor) : null,
            )
          : null,
      trailing: _ChapterDownloadAction(
        mangaId: mangaId,
        chapter: chapter,
        dimColor: dimColor,
        readState: readState,
      ),
      onTap: onTap,
    );

    if (isReading) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        child: tile,
      );
    }

    return tile;
  }
}

// ── Multiple groups ───────────────────────────────────────────────────────────

class _MultiGroupTile extends StatelessWidget {
  const _MultiGroupTile({
    required this.mangaId,
    required this.label,
    required this.chapters,
    required this.expanded,
    required this.onToggle,
    required this.onChapterSelected,
    this.readState = ChapterReadState.unread,
    this.isLatest = false,
  });

  final String mangaId;
  final String label;
  final List<Chapter> chapters;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(String chapterId) onChapterSelected;
  final ChapterReadState readState;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final isRead = readState == ChapterReadState.read;
    final isReading = readState == ChapterReadState.reading;
    final dimColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    final header = ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: isRead ? TextStyle(color: dimColor) : null,
            ),
          ),
          if (isLatest) ...[
            const SizedBox(width: 8),
            const _LatestBadge(),
          ],
        ],
      ),
      subtitle: Text(
        '${chapters.length} translations',
        style: isRead ? TextStyle(color: dimColor) : null,
      ),
      trailing: Icon(
        expanded ? Icons.expand_less : Icons.expand_more,
        color: isRead ? dimColor : null,
      ),
      onTap: onToggle,
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isReading
            ? DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: header,
              )
            : header,
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final chapter in chapters)
                      ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 32, right: 16),
                        title: Text(
                          chapter.scanlationGroup?.name ?? 'Unknown Group',
                        ),
                        subtitle:
                            Text(_formatDate(chapter.attributes.publishAt)),
                        trailing: _ChapterDownloadAction(
                          mangaId: mangaId,
                          chapter: chapter,
                          dimColor: dimColor,
                          readState: readState,
                        ),
                        onTap: () => onChapterSelected(chapter.id),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const Divider(height: 1),
      ],
    );

    return column;
  }
}

// ── Not available in preferred language ──────────────────────────────────────

class _UnavailableTile extends StatelessWidget {
  const _UnavailableTile({
    required this.label,
    required this.preferredLanguage,
  });

  final String label;
  final String preferredLanguage;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
      subtitle: Text(
        'Not available in $preferredLanguage',
        style: TextStyle(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
      enabled: false,
    );
  }
}

class _ChapterDownloadAction extends ConsumerStatefulWidget {
  const _ChapterDownloadAction({
    required this.mangaId,
    required this.chapter,
    required this.dimColor,
    required this.readState,
  });

  final String mangaId;
  final Chapter chapter;
  final Color dimColor;
  final ChapterReadState readState;

  @override
  ConsumerState<_ChapterDownloadAction> createState() =>
      _ChapterDownloadActionState();
}

class _LatestBadge extends StatelessWidget {
  const _LatestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Latest',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

class _ChapterDownloadActionState
    extends ConsumerState<_ChapterDownloadAction> {
  bool _isStartingDownload = false;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(
      chapterDownloadStatusProvider(widget.mangaId, widget.chapter.id),
    );

    return statusAsync.when(
      loading: () => _buildSpinner(),
      error: (_, __) => _buildCircleButton(
        tooltip: 'Download chapter',
        icon: Icons.download_outlined,
        onPressed: () => _download(context),
      ),
      data: (status) {
        if (_isStartingDownload) return _buildSpinner();
        return switch (status.status) {
          'completed' => _buildCircleButton(
              tooltip: 'Remove download',
              icon: Icons.check,
              onPressed: () => _remove(context),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              iconColor: Theme.of(context).colorScheme.primary,
            ),
          'downloading' || 'queued' => _buildSpinner(
              value: status.progress <= 0 ? null : status.progress / 100,
            ),
          _ => _buildCircleButton(
              tooltip: 'Download chapter',
              icon: Icons.download_outlined,
              onPressed: () => _download(context),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
        };
      },
    );
  }

  Widget _buildSpinner({double? value}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: value,
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          shape: const CircleBorder(),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    setState(() => _isStartingDownload = true);
    try {
      await ref.read(downloadServiceProvider).downloadChapter(
            mangaId: widget.mangaId,
            chapterId: widget.chapter.id,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Chapter downloaded.')),
        );
      ref.invalidate(
          chapterDownloadStatusProvider(widget.mangaId, widget.chapter.id));
      ref.invalidate(downloadedChapterProvider(widget.chapter.id));
      ref.invalidate(downloadedChapterIdsForMangaProvider(widget.mangaId));
      ref.invalidate(downloadedBytesForMangaProvider(widget.mangaId));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Could not download chapter.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isStartingDownload = false);
      }
    }
  }

  Future<void> _remove(BuildContext context) async {
    await ref
        .read(downloadServiceProvider)
        .removeChapterDownload(widget.chapter.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Download removed.')),
      );
    ref.invalidate(
        chapterDownloadStatusProvider(widget.mangaId, widget.chapter.id));
    ref.invalidate(downloadedChapterProvider(widget.chapter.id));
    ref.invalidate(downloadedChapterIdsForMangaProvider(widget.mangaId));
    ref.invalidate(downloadedBytesForMangaProvider(widget.mangaId));
  }
}
