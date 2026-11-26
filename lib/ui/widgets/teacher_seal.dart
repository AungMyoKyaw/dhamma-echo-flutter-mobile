import 'package:material_ui/material_ui.dart';

import '../../data/catalogue_repository.dart';
import '../../models/models.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';

/// Deterministic geometric monogram seal for a teacher (no photos in the DB).
class TeacherSeal extends StatelessWidget {
  const TeacherSeal({super.key, required this.teacher, this.size = 58});

  final Teacher teacher;
  final double size;

  static int tintIndex(int teacherId) {
    final featured = CatalogueRepository.featuredTeacherIds.indexOf(teacherId);
    return featured >= 0 ? featured % 6 : teacherId % 6;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = c.sealTints[tintIndex(teacher.id)];
    final glyph = teacher.monogram;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(color: c.rule),
        ),
        child: Container(
          width: size - size * 0.138,
          height: size - size * 0.138,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.24),
            border: Border.all(color: fg, width: 0.8),
          ),
          child: Transform.translate(
            offset: Offset(0, hasMyanmar(glyph) ? -size * 0.05 : 0),
            child: Text(
              glyph,
              textAlign: TextAlign.center,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
                leadingDistribution: TextLeadingDistribution.even,
              ),
              style: BaganType.style(
                glyph,
                size: size * 0.4,
                color: fg,
                serif: true,
                weight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
