import 'package:material_ui/material_ui.dart';

import 'bagan_colors.dart';

final RegExp _myanmarScript = RegExp(
  r'[\u1000-\u109F\uA9E0-\uA9FF\uAA60-\uAA7F]',
);

bool hasMyanmar(String text) => _myanmarScript.hasMatch(text);

/// Script-aware type system: PT Serif / Noto Serif Myanmar for display,
/// Avenir Next / Noto Sans Myanmar for UI. Myanmar gets a taller line box so
/// stacked consonants and medials never clip.
abstract final class BaganType {
  static const _latinSansFallback = ['NotoSansMyanmar'];

  static TextStyle style(
    String text, {
    required double size,
    required Color color,
    bool serif = false,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    double? height,
  }) {
    final mm = hasMyanmar(text);
    final family = mm
        ? (serif ? 'NotoSerifMyanmar' : 'NotoSansMyanmar')
        : (serif ? 'PTSerif' : 'Avenir Next');
    final fallback = mm
        ? (serif ? const ['PTSerif'] : const ['Avenir Next'])
        : (serif ? const ['NotoSerifMyanmar'] : _latinSansFallback);
    // The bundled Myanmar fonts only ship Regular + Bold (serif) or
    // Regular/Medium/Bold (sans); clamp to the available weights.
    final resolved = (serif && mm)
        ? (weight.value >= FontWeight.w600.value
              ? FontWeight.w700
              : FontWeight.w400)
        : weight;
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      color: color,
      fontWeight: resolved,
      height: height ?? (mm ? 1.7 : 1.35),
      letterSpacing: letterSpacing,
    );
  }
}

/// Text that selects the right family/leading for its own content.
class BText extends StatelessWidget {
  const BText(
    this.text, {
    super.key,
    this.size = 13,
    this.color,
    this.serif = false,
    this.weight = FontWeight.w400,
    this.maxLines,
    this.align,
    this.letterSpacing,
    this.height,
  });

  final String text;
  final double size;
  final Color? color;
  final bool serif;
  final FontWeight weight;
  final int? maxLines;
  final TextAlign? align;
  final double? letterSpacing;
  final double? height;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: maxLines,
    textAlign: align,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: BaganType.style(
      text,
      size: size,
      color: color ?? context.c.ink,
      serif: serif,
      weight: weight,
      letterSpacing: letterSpacing,
      height: height,
    ),
  );
}

abstract final class BaganTheme {
  static ThemeData build(BaganColors c) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: c.brightness,
        primary: c.lacquer,
        onPrimary: c.onLacquer,
        secondary: c.gold,
        onSecondary: c.onLacquer,
        error: c.danger,
        onError: c.onLacquer,
        surface: c.surface,
        onSurface: c.ink,
      ),
      dividerColor: c.rule,
      fontFamily: 'Avenir Next',
      fontFamilyFallback: const ['NotoSansMyanmar'],
      extensions: [c],
    );
    return base.copyWith(
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(
          color: c.paper,
          fontFamily: 'Avenir Next',
          fontFamilyFallback: const ['NotoSansMyanmar'],
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get light => build(BaganColors.light);
  static ThemeData get dark => build(BaganColors.dark);
}
