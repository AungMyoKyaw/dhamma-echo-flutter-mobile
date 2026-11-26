import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/audio_playback_controller.dart';
import '../../services/download_manager.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../media_actions.dart';
import '../ui_ext.dart';
import 'common.dart';
import 'lucide_icon.dart';

/// Standard list row for any catalogue entry.
class MediaRow extends StatelessWidget {
  const MediaRow({
    super.key,
    required this.item,
    required this.onTap,
    this.number,
    this.showDivider = true,
  });

  final MediaItem item;
  final VoidCallback onTap;

  /// Track number shown instead of the icon tile (collection detail).
  final int? number;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final nowPlaying = context.select<AudioPlaybackController, (int?, bool)>(
      (a) => (a.current?.id, a.playing),
    );
    final isCurrent = item.kind == MediaKind.audio && nowPlaying.$1 == item.id;
    final isPlaying = isCurrent && nowPlaying.$2;
    final offline = context.select<DownloadManager, bool>(
      (m) => m.recordFor(item.id)?.status == DownloadStatus.completed,
    );

    final tileColor = isCurrent ? c.lacquer : c.surfaceSoft;
    final (iconName, iconColor) = item.isLegacy
        ? ('external-link', c.danger)
        : switch (item.kind) {
            MediaKind.ebook => ('book-open', c.sage),
            MediaKind.video => ('play', c.gold),
            MediaKind.audio => (
              isPlaying ? 'pause' : 'play',
              isCurrent ? c.onLacquer : c.lacquer,
            ),
          };

    final leading = number != null
        ? SizedBox(
            width: 28,
            child: BText(
              number!.toString().padLeft(2, '0'),
              size: 12,
              color: isCurrent ? c.lacquer : c.inkSubtle,
              weight: FontWeight.w600,
            ),
          )
        : Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: LucideIcon(iconName, size: 20, color: iconColor),
            ),
          );

    final row = Container(
      constraints: const BoxConstraints(minHeight: 70),
      margin: EdgeInsets.symmetric(horizontal: isCurrent ? 10 : 0),
      padding: EdgeInsets.symmetric(
        horizontal: isCurrent ? 6 : 16,
        vertical: 8,
      ),
      decoration: isCurrent
          ? BoxDecoration(
              color: c.lacquerSoft,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                BText(
                  item.displayTitle,
                  size: 12.5,
                  weight: FontWeight.w500,
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                BText(
                  mediaSubtitle(item, s, offline: offline),
                  size: 10.5,
                  color: c.inkMuted,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          DownloadAction(item: item),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: item.displayTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row,
            if (showDivider && !isCurrent)
              Hairline(indent: number != null ? 56 : 70),
          ],
        ),
      ),
    );
  }
}
