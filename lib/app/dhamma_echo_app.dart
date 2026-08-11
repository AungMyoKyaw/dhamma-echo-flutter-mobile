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
      seedColor: const Color(0xFF2F5D50),
      brightness: Brightness.light,
    ).copyWith(surface: const Color(0xFFF8FAF7));
    final outline = scheme.outlineVariant;
    const cardRadius = BorderRadius.all(Radius.circular(18));
    const inputRadius = BorderRadius.all(Radius.circular(16));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAF7),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8FAF7),
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
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
        fillColor: Colors.white,
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
        backgroundColor: const WidgetStatePropertyAll<Color?>(Colors.white),
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
        backgroundColor: Colors.white,
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
