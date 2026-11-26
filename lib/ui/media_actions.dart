import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_controller.dart';
import '../services/audio_playback_controller.dart';
import '../services/download_manager.dart';
import '../l10n/app_strings.dart';
import 'widgets/lucide_icon.dart';
import '../theme/bagan_colors.dart';
import '../theme/bagan_theme.dart';

/// Shared "open this item" / "download this item" behaviour.
abstract final class MediaActions {
  static AppStrings _strings(BuildContext context) =>
      AppStrings(context.read<AppController>().language);

  /// Plays audio in place (mini-player appears) or routes to the right viewer.
  static Future<void> open(
    BuildContext context,
    MediaItem item, {
    List<MediaItem> queue = const [],
  }) async {
    if (item.isLegacy) {
      context.push('/legacy/${item.id}');
      return;
    }
    switch (item.kind) {
      case MediaKind.audio:
        final audio = context.read<AudioPlaybackController>();
        final playable = queue
            .where((m) => m.kind == MediaKind.audio && m.isInAppPlayable)
            .toList();
        var index = playable.indexWhere((m) => m.id == item.id);
        if (index < 0) {
          playable
            ..clear()
            ..add(item);
          index = 0;
        }
        await audio.playQueue(playable, index);
      case MediaKind.video:
        context.push('/video/${item.id}');
      case MediaKind.ebook:
        context.push('/reader/${item.id}');
    }
  }

  static Future<void> download(BuildContext context, MediaItem item) async {
    final manager = context.read<DownloadManager>();
    final s = _strings(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await manager.enqueue(item);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            EnqueueResult.started => s.downloadStarted,
            EnqueueResult.alreadyDownloaded => s.readyOffline,
            EnqueueResult.blockedByWifi => s.wifiRequired,
            EnqueueResult.unsupported => s.cannotOpenLink,
          }),
        ),
      );
  }

  static void toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Trailing action reflecting download state (44px target).
class DownloadAction extends StatelessWidget {
  const DownloadAction({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (item.isLegacy) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: LucideIcon('arrow-up-right', size: 20, color: c.inkMuted),
        ),
      );
    }
    final record = context.select<DownloadManager, DownloadRecord?>(
      (m) => m.recordFor(item.id),
    );
    final manager = context.read<DownloadManager>();
    Widget icon;
    VoidCallback? onTap;
    String label;
    final s = AppStrings(context.read<AppController>().language);
    switch (record?.status) {
      case DownloadStatus.completed:
        icon = LucideIcon('check-circle-2', size: 22, color: c.sage);
        onTap = null;
        label = s.offline;
      case DownloadStatus.queued:
      case DownloadStatus.downloading:
        icon = SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            value: record?.progress,
            strokeWidth: 2.4,
            color: c.lacquer,
            backgroundColor: c.surfaceSoft,
          ),
        );
        onTap = () => manager.cancel(item.id);
        label = s.cancel;
      case DownloadStatus.failed:
      case DownloadStatus.canceled:
        icon = LucideIcon('refresh-ccw', size: 20, color: c.danger);
        onTap = () => MediaActions.download(context, item);
        label = s.retry;
      case null:
        icon = LucideIcon('download', size: 22, color: c.inkMuted);
        onTap = () => MediaActions.download(context, item);
        label = s.download;
    }
    return SizedBox(
      width: 44,
      height: 44,
      child: Semantics(
        button: onTap != null,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(child: icon),
        ),
      ),
    );
  }
}

/// "Teacher · MP3 · Offline" style subtitle.
String mediaSubtitle(MediaItem item, AppStrings s, {bool offline = false}) {
  final parts = <String>[
    if ((item.teacherName ?? '').isNotEmpty) item.teacherName!,
    item.formatLabel,
    if (offline) s.offlineBadge,
    if (item.isLegacy) s.browserBadge,
  ];
  return parts.join(' · ');
}

/// Style helper for body copy that may contain Myanmar.
TextStyle bodyStyle(
  BuildContext context,
  String text, {
  double size = 13,
  Color? color,
}) => BaganType.style(text, size: size, color: color ?? context.c.ink);
