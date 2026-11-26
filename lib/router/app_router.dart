import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../ui/screens/audio_now_playing_screen.dart';
import '../ui/screens/browse_screen.dart';
import '../ui/screens/collection_detail_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/legacy_media_detail_screen.dart';
import '../ui/screens/library_screen.dart';
import '../ui/screens/pdf_reader_screen.dart';
import '../ui/screens/queue_sleep_timer_screen.dart';
import '../ui/screens/search_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/teacher_detail_screen.dart';
import '../ui/screens/video_player_screen.dart';
import '../ui/widgets/chrome.dart';

GoRouter createRouter({GlobalKey<NavigatorState>? navigatorKey}) {
  final rootKey = navigatorKey ?? GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ChromeScaffold(
          currentTab: shell.currentIndex,
          onTab: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          body: shell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                builder: (context, state) {
                  final kindParam = state.uri.queryParameters['kind'];
                  final kind = switch (kindParam) {
                    'video' => BrowseKind.video,
                    'ebook' => BrowseKind.ebook,
                    'teachers' => BrowseKind.teachers,
                    _ => BrowseKind.audio,
                  };
                  final abhidhamma =
                      state.uri.queryParameters['abhidhamma'] == '1';
                  return BrowseScreen(
                    key: ValueKey('$kindParam-$abhidhamma'),
                    initialKind: kind,
                    abhidhamma: abhidhamma,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/teacher/:id',
        builder: (context, state) => TeacherDetailScreen(
          teacherId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/collection/:id',
        builder: (context, state) => CollectionDetailScreen(
          collectionId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/player/audio',
        builder: (context, state) => const AudioNowPlayingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/player/queue',
        builder: (context, state) => const QueueSleepTimerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/video/:id',
        builder: (context, state) => VideoPlayerScreen(
          mediaId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/reader/:id',
        builder: (context, state) => PdfReaderScreen(
          mediaId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/legacy/:id',
        builder: (context, state) => LegacyMediaDetailScreen(
          mediaId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
