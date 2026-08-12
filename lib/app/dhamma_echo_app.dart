import 'dart:async';

import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/ui/components/async_message.dart';
import 'package:dhamma_echo/ui/components/mini_player.dart';
import 'package:dhamma_echo/ui/screens/collections_screen.dart';
import 'package:dhamma_echo/ui/screens/explore_screen.dart';
import 'package:dhamma_echo/ui/screens/home_screen.dart';
import 'package:dhamma_echo/ui/screens/library_screen.dart';
import 'package:dhamma_echo/ui/screens/settings_screen.dart';
import 'package:dhamma_echo/ui/screens/teachers_screen.dart';
import 'package:flutter/material.dart';

class DhammaEchoApp extends StatefulWidget {
  const DhammaEchoApp({required this.controller, super.key});
  final AppController controller;

  @override
  State<DhammaEchoApp> createState() => _DhammaEchoAppState();
}

class _DhammaEchoAppState extends State<DhammaEchoApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dhamma Echo',
      themeMode: ThemeMode.light,
      theme: _theme(),
      home: MainShell(controller: widget.controller),
    );
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8C3F08),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF8C3F08),
      onPrimary: const Color(0xFFFFE3D5),
      primaryContainer: const Color(0xFF9B4B15),
      onPrimaryContainer: const Color(0xFFFFFCFF),
      secondary: const Color(0xFF485B37),
      onSecondary: const Color(0xFFD9F0C1),
      secondaryContainer: const Color(0xFF546742),
      onSecondaryContainer: const Color(0xFFFAFFEF),
      tertiary: const Color(0xFF6E5014),
      onTertiary: const Color(0xFFFFE4BC),
      tertiaryContainer: const Color(0xFF7B5C1F),
      onTertiaryContainer: const Color(0xFFFFFCFF),
      error: const Color(0xFF8D3531),
      onError: const Color(0xFFFFF7F6),
      surface: const Color(0xFFFCF9F2),
      onSurface: const Color(0xFF2E2E2A),
      onSurfaceVariant: const Color(0xFF565550),
      outline: const Color(0xFFD5D1C8),
      outlineVariant: const Color(0xFFD5D1C8),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF6F3EC),
      surfaceContainer: const Color(0xFFF0EEE7),
      surfaceContainerHigh: const Color(0xFFEBE8E1),
      surfaceContainerHighest: const Color(0xFFE5E2DB),
    );
    final outline = scheme.outlineVariant;
    const cardRadius = BorderRadius.all(Radius.circular(18));
    const inputRadius = BorderRadius.all(Radius.circular(16));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: const OutlineInputBorder(borderRadius: inputRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll<double?>(0.0),
        backgroundColor: WidgetStatePropertyAll<Color?>(
          scheme.surfaceContainerLowest,
        ),
        surfaceTintColor: const WidgetStatePropertyAll<Color?>(
          Colors.transparent,
        ),
        side: WidgetStatePropertyAll<BorderSide?>(
          BorderSide(color: outline),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder?>(
          RoundedRectangleBorder(borderRadius: cardRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onSecondaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({required this.controller, super.key});
  final AppController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(controller.saveCurrentResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.initializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.initializationError.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dhamma Echo')),
            body: AsyncMessage(
              icon: Icons.error_outline,
              title: 'Could not open Dhamma Echo',
              message: controller.initializationError,
              actionLabel: 'Retry',
              onAction: controller.initialize,
            ),
          );
        }
        final screens = <Widget>[
          HomeScreen(controller: controller),
          ExploreScreen(controller: controller),
          CollectionsScreen(controller: controller),
          TeachersScreen(controller: controller),
          LibraryScreen(controller: controller),
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.spa_outlined),
                SizedBox(width: 10),
                Text('Dhamma Echo'),
              ],
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(controller: controller),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(index: controller.selectedTab, children: screens),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MiniPlayer(controller: controller, safeBottom: false),
              NavigationBar(
                selectedIndex: controller.selectedTab,
                onDestinationSelected: controller.selectTab,
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search),
                    label: 'Explore',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music),
                    label: 'Collections',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: 'Teachers',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.favorite_border),
                    selectedIcon: Icon(Icons.favorite),
                    label: 'Library',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
