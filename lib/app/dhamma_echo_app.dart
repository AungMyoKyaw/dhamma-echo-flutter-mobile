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
      theme: buildDhammaEchoTheme(),
      home: MainShell(controller: widget.controller),
    );
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}

abstract final class DhammaEchoColors {
  static const forest = Color(0xFF245C45);
  static const onForest = Color(0xFFFFFFFF);
  static const sage = Color(0xFFD6E8DC);
  static const onSage = Color(0xFF123A2A);
  static const parchment = Color(0xFFFAF7F0);
  static const warmWhite = Color(0xFFFFFEFA);
  static const charcoal = Color(0xFF20231F);
  static const secondaryText = Color(0xFF5C625C);
  static const outline = Color(0xFF837F76);
  static const outlineVariant = Color(0xFFC9C5BB);
  static const error = Color(0xFF9B3D35);
  static const onError = Color(0xFFFFFFFF);
}

ThemeData buildDhammaEchoTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: DhammaEchoColors.forest,
        brightness: Brightness.light,
      ).copyWith(
        primary: DhammaEchoColors.forest,
        onPrimary: DhammaEchoColors.onForest,
        primaryContainer: DhammaEchoColors.sage,
        onPrimaryContainer: DhammaEchoColors.onSage,
        secondary: DhammaEchoColors.forest,
        onSecondary: DhammaEchoColors.onForest,
        secondaryContainer: DhammaEchoColors.sage,
        onSecondaryContainer: DhammaEchoColors.onSage,
        tertiary: const Color(0xFF536A5B),
        onTertiary: DhammaEchoColors.onForest,
        tertiaryContainer: const Color(0xFFDCE7DF),
        onTertiaryContainer: DhammaEchoColors.onSage,
        error: DhammaEchoColors.error,
        onError: DhammaEchoColors.onError,
        surface: DhammaEchoColors.parchment,
        onSurface: DhammaEchoColors.charcoal,
        onSurfaceVariant: DhammaEchoColors.secondaryText,
        outline: DhammaEchoColors.outline,
        outlineVariant: DhammaEchoColors.outlineVariant,
        surfaceContainerLowest: DhammaEchoColors.warmWhite,
        surfaceContainerLow: const Color(0xFFF6F2EA),
        surfaceContainer: const Color(0xFFF0ECE3),
        surfaceContainerHigh: const Color(0xFFEAE6DD),
        surfaceContainerHighest: const Color(0xFFE3DED4),
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
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primary,
      disabledColor: scheme.surfaceContainerHigh,
      labelStyle: TextStyle(color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
      checkmarkColor: scheme.onPrimary,
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.outlineVariant,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: scheme.primary,
      valueIndicatorTextStyle: TextStyle(color: scheme.onPrimary),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
      circularTrackColor: scheme.outlineVariant,
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
      side: WidgetStatePropertyAll<BorderSide?>(BorderSide(color: outline)),
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

NavigationDestinationLabelBehavior navigationLabelBehaviorFor(
  double textScale,
) => textScale > 1.3
    ? NavigationDestinationLabelBehavior.onlyShowSelected
    : NavigationDestinationLabelBehavior.alwaysShow;

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
        final textScale = MediaQuery.textScalerOf(context).scale(1);
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
                height: textScale > 1.3 ? 88 : 72,
                labelBehavior: navigationLabelBehaviorFor(textScale),
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
