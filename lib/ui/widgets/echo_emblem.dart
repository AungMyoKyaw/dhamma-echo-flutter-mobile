import 'package:material_ui/material_ui.dart';

import '../../theme/bagan_colors.dart';

/// Concentric acoustic-resonance emblem (ratio 28 : 19 : 11 : 4).
class EchoEmblem extends StatelessWidget {
  const EchoEmblem({super.key, this.size = 28, this.mono});

  final double size;

  /// When set, every ring uses this single colour (e.g. monochrome contexts).
  final Color? mono;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EchoPainter(outer: mono ?? c.gold, inner: mono ?? c.lacquer),
      ),
    );
  }
}

class _EchoPainter extends CustomPainter {
  const _EchoPainter({required this.outer, required this.inner});

  final Color outer;
  final Color inner;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    void ring(double diameter, double stroke, Color color) {
      canvas.drawCircle(
        center,
        (diameter - stroke) / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color
          ..isAntiAlias = true,
      );
    }

    ring(s, s * 1.2 / 28, outer);
    ring(s * 19 / 28, s * 1.54 / 28, inner);
    ring(s * 11 / 28, s * 1.68 / 28, inner);
    canvas.drawCircle(center, s * 2 / 28, Paint()..color = inner);
  }

  @override
  bool shouldRepaint(_EchoPainter old) =>
      old.outer != outer || old.inner != inner;
}
