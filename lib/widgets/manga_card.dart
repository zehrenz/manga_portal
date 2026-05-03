import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/manga.dart';

/// A card showing a manga's cover thumbnail and title.
/// Used in the library grid and search results.
class MangaCard extends StatelessWidget {
  const MangaCard({
    super.key,
    required this.manga,
    this.onTap,
    this.hasDownloadedChapters = false,
    this.isUp = false,
  });

  final Manga manga;
  final VoidCallback? onTap;
  final bool hasDownloadedChapters;
  final bool isUp;

  @override
  Widget build(BuildContext context) {
    final localCoverPath = manga.coverArt?.fileName;
    final hasLocalCover = localCoverPath != null &&
        (localCoverPath.startsWith('/') || localCoverPath.startsWith('file:'));
    final coverUrl = manga.coverUrl(256);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasLocalCover
                      ? Image(
                          image: FileImage(
                            File(
                              localCoverPath.startsWith('file:')
                                  ? Uri.parse(localCoverPath).toFilePath()
                                  : localCoverPath,
                            ),
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _PlaceholderCover(),
                        )
                      : coverUrl != null
                          ? Image(
                              image: CachedNetworkImageProvider(coverUrl),
                              fit: BoxFit.cover,
                              frameBuilder: (context, child, frame, sync) {
                                if (sync || frame != null) return child;
                                return const ColoredBox(
                                  color: Colors.black26,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (_, __, ___) =>
                                  const _PlaceholderCover(),
                            )
                          : const _PlaceholderCover(),
                  if (isUp)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: _CornerBadge(
                        icon: Icons.arrow_upward,
                        iconColor: Colors.green,
                      ),
                    ),
                  if (hasDownloadedChapters)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: _CornerBadge(
                        icon: Icons.arrow_downward,
                        iconColor: Colors.lightBlue,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                manga.attributes.titleFor('en'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black26,
      child: Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.icon, required this.iconColor});

  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}
