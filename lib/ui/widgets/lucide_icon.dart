import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/bagan_colors.dart';

/// Renders a bundled Lucide SVG tinted with [color].
class LucideIcon extends StatelessWidget {
  const LucideIcon(this.name, {super.key, this.size = 24, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/lucide/$name.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
    colorFilter: ColorFilter.mode(color ?? context.c.ink, BlendMode.srcIn),
  );
}
