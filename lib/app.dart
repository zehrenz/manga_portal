import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/library_page.dart';
import 'providers/library_provider.dart';
import 'pages/manga_detail_page.dart';
import 'pages/reader_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'library',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LibraryPage(),
          ),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
      ],
    ),
    // Detail and reader routes sit outside the shell so the nav bar is hidden.
    GoRoute(
      path: '/manga/:mangaId',
      name: 'mangaDetail',
      builder: (context, state) {
        final mangaId = state.pathParameters['mangaId']!;
        return MangaDetailPage(mangaId: mangaId);
      },
    ),
    GoRoute(
      path: '/reader/:chapterId',
      name: 'reader',
      builder: (context, state) {
        final chapterId = state.pathParameters['chapterId']!;
        final mangaId = state.uri.queryParameters['mangaId'];
        return ReaderPage(chapterId: chapterId, mangaId: mangaId);
      },
    ),
  ],
);

class _ScaffoldWithNavBar extends ConsumerWidget {
  const _ScaffoldWithNavBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, ref, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, WidgetRef ref, int index) {
    if (index == 0) {
      ref.read(libraryResortTriggerProvider.notifier).update((n) => n + 1);
    }
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/search');
      case 2:
        context.go('/settings');
    }
  }
}
