import 'package:material_ui/material_ui.dart';

import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import 'lucide_icon.dart';

/// Minimum comfortable touch target (design spec: 44px+).
const double kTouch = 44;

/// Tappable area with a guaranteed 44px target and button semantics.
class Tappable extends StatelessWidget {
  const Tappable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.minSize = kTouch,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double minSize;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: semanticLabel,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        child: Align(
          alignment: alignment,
          widthFactor: 1,
          heightFactor: 1,
          child: child,
        ),
      ),
    ),
  );
}

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(start: indent),
    child: SizedBox(
      height: 1,
      width: double.infinity,
      child: ColoredBox(color: context.c.rule),
    ),
  );
}

/// Uppercase muted section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: BText(
      text,
      size: 10.5,
      weight: FontWeight.w600,
      color: context.c.inkMuted,
      letterSpacing: hasMyanmar(text) ? 0 : 0.9,
    ),
  );
}

class BaganCard extends StatelessWidget {
  const BaganCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? context.c.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? context.c.rule),
    ),
    child: child,
  );
}

/// Filter chip. [primary] = 34px segmented tab; otherwise 30px filter pill.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final height = primary ? 34.0 : 30.0;
    final bg = selected ? (primary ? c.lacquer : c.lacquerSoft) : c.surface;
    final fg = selected ? (primary ? c.onLacquer : c.lacquer) : c.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kTouch),
          child: Center(
            widthFactor: 1,
            child: Container(
              height: height,
              padding: EdgeInsets.symmetric(horizontal: primary ? 13 : 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(height / 2),
                border: selected && primary
                    ? null
                    : Border.all(color: selected ? Colors.transparent : c.rule),
              ),
              child: BText(
                label,
                size: primary ? 11.5 : 11,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: fg,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling row of pills with consistent gutters.
class PillRow extends StatelessWidget {
  const PillRow({super.key, required this.children, this.gap = 8});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: kTouch,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(width: gap),
      itemBuilder: (_, i) => children[i],
    ),
  );
}

class SmallBadge extends StatelessWidget {
  const SmallBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: BText(
      label,
      size: 10,
      weight: FontWeight.w600,
      color: foreground,
      letterSpacing: hasMyanmar(label) ? 0 : 0.5,
      height: 1.3,
    ),
  );
}

class BaganButton extends StatelessWidget {
  const BaganButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = true,
    this.expand = true,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final bool primary;
  final bool expand;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = primary ? c.onLacquer : (danger ? c.danger : c.ink);
    final bg = primary ? c.lacquer : c.surface;
    final child = Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: onTap == null ? c.surfaceSoft : bg,
        borderRadius: BorderRadius.circular(14),
        border: primary ? null : Border.all(color: c.rule),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            LucideIcon(icon!, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: BText(
              label,
              size: 13,
              weight: FontWeight.w600,
              color: fg,
              align: TextAlign.center,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
