import 'package:material_ui/material_ui.dart';

/// "Monastic Lacquer & Raw Cotton" palette from DESIGN.md.
@immutable
class BaganColors extends ThemeExtension<BaganColors> {
  const BaganColors({
    required this.brightness,
    required this.paper,
    required this.surface,
    required this.surfaceSoft,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.lacquer,
    required this.lacquerStrong,
    required this.lacquerSoft,
    required this.onLacquer,
    required this.gold,
    required this.goldSoft,
    required this.sage,
    required this.sageSoft,
    required this.rule,
    required this.danger,
    required this.dangerSoft,
  });

  static const light = BaganColors(
    brightness: Brightness.light,
    paper: Color(0xFFFAF8F3),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF2EFE7),
    ink: Color(0xFF1A1918),
    inkMuted: Color(0xFF635E57),
    inkSubtle: Color(0xFF8A8378),
    lacquer: Color(0xFFB24A2B),
    lacquerStrong: Color(0xFF8F371D),
    lacquerSoft: Color(0xFFF5E4DC),
    onLacquer: Color(0xFFFAF8F3),
    gold: Color(0xFF9A742B),
    goldSoft: Color(0xFFF4ECDB),
    sage: Color(0xFF4E6E58),
    sageSoft: Color(0xFFE4EFE7),
    rule: Color(0xFFE3DDD2),
    danger: Color(0xFFA63329),
    dangerSoft: Color(0xFFF8E2DF),
  );

  static const dark = BaganColors(
    brightness: Brightness.dark,
    paper: Color(0xFF141210),
    surface: Color(0xFF1D1A17),
    surfaceSoft: Color(0xFF26221E),
    ink: Color(0xFFF3EFE8),
    inkMuted: Color(0xFFA69E92),
    inkSubtle: Color(0xFF7A7368),
    lacquer: Color(0xFFE38A6B),
    lacquerStrong: Color(0xFFF0A58B),
    lacquerSoft: Color(0xFF3A241C),
    onLacquer: Color(0xFF141210),
    gold: Color(0xFFD4B06A),
    goldSoft: Color(0xFF332B1B),
    sage: Color(0xFF86B394),
    sageSoft: Color(0xFF1F3025),
    rule: Color(0xFF332E28),
    danger: Color(0xFFF28B82),
    dangerSoft: Color(0xFF3B1E1C),
  );

  final Brightness brightness;
  final Color paper;
  final Color surface;
  final Color surfaceSoft;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color lacquer;
  final Color lacquerStrong;
  final Color lacquerSoft;
  final Color onLacquer;
  final Color gold;
  final Color goldSoft;
  final Color sage;
  final Color sageSoft;
  final Color rule;
  final Color danger;
  final Color dangerSoft;

  bool get isDark => brightness == Brightness.dark;

  /// Deterministic monogram-seal tints (background, foreground).
  List<(Color, Color)> get sealTints => isDark
      ? const [
          (Color(0xFF3A241C), Color(0xFFE38A6B)),
          (Color(0xFF332B1B), Color(0xFFD4B06A)),
          (Color(0xFF1F3025), Color(0xFF86B394)),
          (Color(0xFF2A2433), Color(0xFFB7A6D6)),
          (Color(0xFF1F2A31), Color(0xFF8FB4CC)),
          (Color(0xFF2E221D), Color(0xFFD1A08A)),
        ]
      : const [
          (Color(0xFFF5E4DC), Color(0xFFB24A2B)),
          (Color(0xFFF4ECDB), Color(0xFF8C6522)),
          (Color(0xFFE4EFE7), Color(0xFF43634D)),
          (Color(0xFFEAE6F0), Color(0xFF5C4D73)),
          (Color(0xFFE6ECF0), Color(0xFF3E5C70)),
          (Color(0xFFF2E8E2), Color(0xFF7A4B3A)),
        ];

  @override
  BaganColors copyWith() => this;

  @override
  BaganColors lerp(ThemeExtension<BaganColors>? other, double t) =>
      t < 0.5 ? this : (other as BaganColors? ?? this);
}

/// Sepia reading palette used by the PDF reader chrome.
abstract final class PdfSepia {
  static const canvas = Color(0xFFF4ECD8);
  static const sheet = Color(0xFFFAF4E4);
  static const chrome = Color(0xFFEFE4CB);
  static const border = Color(0xFFDDD0B3);
  static const ink = Color(0xFF2B251B);
}

extension BaganContext on BuildContext {
  BaganColors get c => Theme.of(this).extension<BaganColors>()!;
}
