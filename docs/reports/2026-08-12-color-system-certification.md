# Dhamma Echo Color System Certification

Date: 2026-08-12

## Result

The forest-and-parchment color system is implemented consistently across the app theme, filters, navigation, progress controls, active track rows, mini-player, and Now Playing artwork. The inspected semantic color pairs meet WCAG AA contrast requirements. Standard iPhone rendering passed visual inspection, and accessibility text reflow passed after adapting bottom-navigation label behavior.

## Canonical Palette

| Role | Value |
| --- | --- |
| Primary forest | `#245C45` |
| On primary | `#FFFFFF` |
| Selected sage | `#D6E8DC` |
| On selected sage | `#123A2A` |
| Parchment surface | `#FAF7F0` |
| Warm-white container | `#FFFEFA` |
| Charcoal text | `#20231F` |
| Secondary gray-brown text | `#5C625C` |
| Warm outline | `#837F76` |
| Brick error | `#9B3D35` |

## Contrast Certification

Ratios use the WCAG relative-luminance formula.

| Pair | Ratio | Requirement | Result |
| --- | ---: | ---: | --- |
| Forest / white | 7.80:1 | 4.5:1 | Pass |
| Sage / dark forest | 9.87:1 | 4.5:1 | Pass |
| Parchment / charcoal | 14.85:1 | 4.5:1 | Pass |
| Parchment / secondary text | 5.85:1 | 4.5:1 | Pass |
| Warm white / outline | 3.95:1 | 3:1 graphical control | Pass |
| Brick error / white | 6.75:1 | 4.5:1 | Pass |

## Rendered Flow

1. Explore, iPhone 17, iOS 26.5, standard text: selected filters use forest/white; unselected filters and inputs use warm white with visible warm outlines; track actions and metadata remain legible.
2. Active track and mini-player, iPhone 17: the active row uses deterministic sage rather than a translucent overlay; the mini-player uses the same sage/dark-forest supporting state.
3. Now Playing, iPhone 17: artwork, playback controls, slider, and supporting actions share the forest/sage system. Runtime metadata showed `0:17 / 58:13`, confirming duration and progress presentation.
4. Home, iPhone 17, Accessibility Medium text: content reflows vertically; bottom navigation changes from five persistent labels to only the selected label and increases in height, eliminating the observed label collision and clipping.

## Render Evidence

- `docs/reports/assets/forest-parchment-explore-iphone17.png`
- `docs/reports/assets/forest-parchment-now-playing-iphone17.png`
- `docs/reports/assets/forest-parchment-home-accessibility-text.png`

## Automated Verification

- `flutter test test/ui/theme_regression_test.dart`: passed 3 tests.
- `flutter test test/player/playback_controller_test.dart`: passed 7 tests.
- Focused row-play and active-row widget regressions: passed.
- Focused `flutter analyze` across the theme, player surfaces, and relevant tests: no issues.

## Known Baseline Limitation

The existing `track row downloads and removes offline media` widget test hangs in `pumpAndSettle`; this occurred before the palette work and remains unrelated to color-system behavior. Repository-wide analysis also previously reported an unrelated stale `CollectionSearchRequest` reference in `test/data/production_catalogue_regression_test.dart`. Neither issue was changed as part of this visual-system scope.

