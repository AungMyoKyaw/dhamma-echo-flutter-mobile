# Forest and Parchment Color System

## Goal

Give Dhamma Echo one calm, recognizable visual identity with consistent color roles and accessible contrast across every screen. Replace the current burnt-orange and muted-olive mixture with a forest-green accent grounded in warm parchment surfaces.

## Palette

- Primary: deep forest green for primary actions, playback controls, focus, and active indicators.
- On-primary: white for readable content on solid forest surfaces.
- Primary container: pale sage for selected rows, chips, navigation indicators, avatars, and supporting emphasis.
- On-primary container: dark forest for content on pale sage.
- Surface: warm parchment for page backgrounds.
- Lowest surface container: warm white for cards, fields, search, and bottom navigation.
- Higher surface containers: progressively darker warm neutrals for grouping and disabled states.
- On-surface: near-black charcoal for primary content.
- On-surface variant: neutral gray-brown for metadata and secondary content.
- Outline: a warm neutral dark enough to distinguish controls from parchment and white surfaces.
- Error: brick red, reserved for destructive and error states.

Every foreground/background pair must meet WCAG AA contrast for its text or icon size. Selected controls must not rely on color alone: existing checks, indicator shapes, and state icons remain visible.

## Theme Architecture

The app-level `ThemeData` and `ColorScheme` are the single source of truth. Components consume semantic roles such as `primary`, `primaryContainer`, `surface`, and `outlineVariant`; they do not introduce screen-specific brand colors.

Global component themes will define consistent states for:

- Choice chips and other filters
- Filled, tonal, outlined, and icon buttons
- Sliders and progress indicators
- Navigation bar selection
- Cards and list rows
- Search, dropdown, and text-field surfaces
- App bars and page backgrounds

The now-playing artwork, mini-player, teacher avatars, active track rows, and offline indicators will use the same forest/sage roles.

## Interaction States

- Default controls use warm-white surfaces, charcoal content, and visible warm-neutral outlines.
- Selected controls use deep forest with white content when emphasis is primary.
- Supporting selected surfaces use pale sage with dark-forest content.
- Pressed, hovered, focused, and disabled states derive from the same semantic roles and remain visibly distinct.
- Disabled controls retain readable content without appearing active.

## Scope

This change updates color and component-state styling only. It does not alter navigation, layout, typography, content, playback behavior, or data flow.

## Verification

- Add theme tests for the canonical palette and key selected/unselected component states.
- Run focused widget tests for Explore filters, navigation, track rows, and the player.
- Run static analysis on changed files.
- Render representative screens and visually check that no burnt-orange or unrelated olive accent remains.
- Check contrast for the semantic foreground/background pairs and document the ratios used.

