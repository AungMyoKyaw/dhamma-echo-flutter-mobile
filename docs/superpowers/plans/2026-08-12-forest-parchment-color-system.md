# Forest and Parchment Color System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply one accessible forest-and-parchment color system consistently across Dhamma Echo and certify its contrast and responsive rendering.

**Architecture:** Keep the app-level `ThemeData` as the single source of truth and expose the canonical palette as testable constants in the same app theme module. Configure Material component themes for consistent selected, unselected, disabled, and focus states; existing screens continue consuming semantic `ColorScheme` roles.

**Tech Stack:** Flutter, Material 3, Dart widget tests, iOS Simulator

---

### Task 1: Lock the canonical semantic palette

**Files:**

- Modify: `lib/app/dhamma_echo_app.dart`
- Create: `test/ui/theme_regression_test.dart`

- [ ] **Step 1: Write the failing palette test**

Create a widget test that pumps `DhammaEchoApp`, reads `Theme.of(context).colorScheme`, and expects the canonical roles: forest `#245C45`, white on-primary, sage `#D6E8DC`, dark forest `#123A2A`, parchment `#FAF7F0`, warm white `#FFFEFA`, charcoal `#20231F`, gray-brown `#5C625C`, warm outline `#837F76`, and brick red `#9B3D35`.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/ui/theme_regression_test.dart`

Expected: FAIL because the current theme uses burnt orange and olive role values.

- [ ] **Step 3: Implement the semantic palette**

Add a `DhammaEchoColors` constants class and replace the `ColorScheme.copyWith` values in `DhammaEchoApp._theme()` with the canonical colors. Set supporting surface containers and outlines to warm-neutral values derived from parchment rather than unrelated hues.

- [ ] **Step 4: Run the palette test**

Run: `flutter test test/ui/theme_regression_test.dart`

Expected: PASS.

### Task 2: Unify Material control states

**Files:**

- Modify: `lib/app/dhamma_echo_app.dart`
- Modify: `test/ui/theme_regression_test.dart`

- [ ] **Step 1: Write failing component-state assertions**

Assert that selected choice chips use `primary`/`onPrimary`, unselected chips use warm-white/charcoal with a visible outline, sliders use forest active color and warm-neutral inactive color, navigation selection uses sage/dark forest, and progress indicators use forest.

- [ ] **Step 2: Run the focused test and confirm it fails**

Run: `flutter test test/ui/theme_regression_test.dart`

Expected: FAIL for component themes not yet configured.

- [ ] **Step 3: Configure the global component themes**

Add `chipTheme`, `sliderTheme`, `progressIndicatorTheme`, `iconButtonTheme`, and consistent state resolution for navigation. Preserve existing card, app-bar, input, and search shapes while replacing their colors with semantic scheme roles.

- [ ] **Step 4: Run the focused test**

Run: `flutter test test/ui/theme_regression_test.dart`

Expected: PASS.

### Task 3: Remove inconsistent local visual states

**Files:**

- Modify: `lib/ui/components/track_tile.dart`
- Modify: `lib/ui/components/mini_player.dart`
- Modify: `lib/ui/screens/player_screen.dart`
- Modify: `test/ui/theme_regression_test.dart`

- [ ] **Step 1: Write failing widget assertions**

Pump representative active-track and player states. Assert active rows use `primaryContainer`, mini-player artwork uses sage/dark forest, and now-playing artwork uses the same pair rather than a solid primary container.

- [ ] **Step 2: Run the focused test and confirm it fails**

Run: `flutter test test/ui/theme_regression_test.dart`

Expected: FAIL where local component styling still uses inconsistent roles or opacity.

- [ ] **Step 3: Replace local styling with shared semantic roles**

Use `primaryContainer`/`onPrimaryContainer` for supporting selected surfaces and reserve `primary`/`onPrimary` for direct actions. Remove translucent active-row styling that produces unpredictable contrast.

- [ ] **Step 4: Run focused theme and existing playback tests**

Run: `flutter test test/ui/theme_regression_test.dart test/player/playback_controller_test.dart test/ui/detail_settings_regression_test.dart`

Expected: PASS.

### Task 4: Certify contrast and reflow

**Files:**

- Create: `docs/reports/2026-08-12-color-system-certification.md`

- [ ] **Step 1: Calculate contrast ratios**

Use the WCAG relative-luminance formula to calculate primary/on-primary, primary-container/on-primary-container, surface/on-surface, surface/on-surface-variant, lowest-surface/outline, and error/on-error pairs. Require at least 4.5:1 for normal text and 3:1 for large text and graphical controls.

- [ ] **Step 2: Run automated verification**

Run: `flutter test test/ui/theme_regression_test.dart test/player/playback_controller_test.dart test/ui/detail_settings_regression_test.dart`

Run: `flutter analyze lib/app/dhamma_echo_app.dart lib/ui/components/track_tile.dart lib/ui/components/mini_player.dart lib/ui/screens/player_screen.dart test/ui/theme_regression_test.dart`

Expected: all focused tests pass and analysis reports no issues.

- [ ] **Step 3: Render representative flows at multiple widths**

Capture Explore and Now Playing at an iPhone viewport and a narrow accessibility/reflow viewport. Verify no clipping, overlap, unreadable state, or old accent colors remain in the rendered screens.

- [ ] **Step 4: Write the certification report**

Record exact palette values, contrast ratios, test and analysis commands, rendered viewport sizes, inspected flows, findings, and any repository-wide failures unrelated to this change.

