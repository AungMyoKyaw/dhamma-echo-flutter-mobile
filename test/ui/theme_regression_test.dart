import 'package:dhamma_echo/app/dhamma_echo_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme exposes the forest and parchment semantic palette', () {
    final scheme = buildDhammaEchoTheme().colorScheme;

    expect(scheme.primary, const Color(0xFF245C45));
    expect(scheme.onPrimary, const Color(0xFFFFFFFF));
    expect(scheme.primaryContainer, const Color(0xFFD6E8DC));
    expect(scheme.onPrimaryContainer, const Color(0xFF123A2A));
    expect(scheme.surface, const Color(0xFFFAF7F0));
    expect(scheme.surfaceContainerLowest, const Color(0xFFFFFEFA));
    expect(scheme.onSurface, const Color(0xFF20231F));
    expect(scheme.onSurfaceVariant, const Color(0xFF5C625C));
    expect(scheme.outline, const Color(0xFF837F76));
    expect(scheme.error, const Color(0xFF9B3D35));
  });

  test('theme gives controls consistent forest selection states', () {
    final theme = buildDhammaEchoTheme();
    final scheme = theme.colorScheme;

    expect(theme.chipTheme.selectedColor, scheme.primary);
    expect(theme.chipTheme.backgroundColor, scheme.surfaceContainerLowest);
    expect(theme.chipTheme.secondaryLabelStyle?.color, scheme.onPrimary);
    expect(theme.sliderTheme.activeTrackColor, scheme.primary);
    expect(theme.sliderTheme.thumbColor, scheme.primary);
    expect(theme.sliderTheme.inactiveTrackColor, scheme.outlineVariant);
    expect(theme.progressIndicatorTheme.color, scheme.primary);
    expect(theme.navigationBarTheme.indicatorColor, scheme.primaryContainer);
  });

  test('navigation reduces labels when accessibility text needs reflow', () {
    expect(
      navigationLabelBehaviorFor(1),
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    expect(
      navigationLabelBehaviorFor(2),
      NavigationDestinationLabelBehavior.onlyShowSelected,
    );
  });
}
