import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/download_manager.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../ui_ext.dart';
import 'common.dart';

/// Editorial spine-cover card for an eBook (2-column shelf).
class EbookSpineCard extends StatelessWidget {
  const EbookSpineCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  final MediaItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final offline = context.select<DownloadManager, bool>(
      (m) => m.recordFor(item.id)?.status == DownloadStatus.completed,
    );
    final spine = [c.lacquer, c.gold, c.sage, c.inkMuted][index % 4];
    final legacy = item.isLegacy;
    return Semantics(
      button: true,
      label: item.displayTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.rule),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 12, color: spine),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SmallBadge(
                            label: item.formatLabel,
                            background: offline || !legacy
                                ? c.sageSoft
                                : c.dangerSoft,
                            foreground: legacy ? c.danger : c.sage,
                          ),
                          const Spacer(),
                          if (offline)
                            BText(
                              s.offlineBadge,
                              size: 10.5,
                              weight: FontWeight.w600,
                              color: c.sage,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ClipRect(
                          child: BText(
                            item.displayTitle,
                            size: 12,
                            serif: true,
                            weight: FontWeight.w700,
                            maxLines: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Hairline(),
                      const SizedBox(height: 8),
                      BText(
                        item.teacherName ?? '',
                        size: 10,
                        color: c.inkMuted,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
