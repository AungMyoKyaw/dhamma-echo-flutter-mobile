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
    const scheme = ColorScheme.light(
      primary: Color(0xFF8C3F08),
      onPrimary: Color(0xFFFFE9E0),
      primaryContainer: Color(0xFF9B4B15),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFF485B37),
      onSecondary: Color(0xFFDEF5C6),
      secondaryContainer: Color(0xFF546742),
      onSecondaryContainer: Colors.white,
      tertiary: Color(0xFF6E5014),
      onTertiary: Color(0xFFFFEACD),
      error: Color(0xFF913834),
      surface: Color(0xFFFCF9F2),
      onSurface: Color(0xFF2E2E2A),
      onSurfaceVariant: Color(0xFF565550),
      outline: Color(0xFF72716B),
      outlineVariant: Color(0xFF9D9B96),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFFFCF9F2),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFFD5D1C8)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFF0EEE7),
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
              MiniPlayer(controller: controller),
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
