import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_controller.dart';
import '../../services/audio_playback_controller.dart';
import '../../services/download_manager.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../media_actions.dart';
import '../ui_ext.dart';
import '../widgets/common.dart';
import '../widgets/echo_emblem.dart';
import '../widgets/lucide_icon.dart';

class AudioNowPlayingScreen extends StatefulWidget {
  const AudioNowPlayingScreen({super.key});

  @override
  State<AudioNowPlayingScreen> createState() => _AudioNowPlayingScreenState();
}

class _AudioNowPlayingScreenState extends State<AudioNowPlayingScreen> {
  double? _scrubValue;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final audio = context.watch<AudioPlaybackController>();
    final item = audio.current;
    if (item == null) {
      return Scaffold(
        backgroundColor: c.paper,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  Tappable(
                    semanticLabel: s.back,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    child: LucideIcon('chevron-down', size: 24, color: c.ink),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: BText(s.nothingToResume, size: 16, serif: true),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final saved = context.select<AppController, bool>(
      (a) => a.isSaved(item.id),
    );
    final dlRecord = context.select<DownloadManager, DownloadRecord?>(
      (m) => m.recordFor(item.id),
    );
    final dlStatus = dlRecord?.status;
    final offline = dlStatus == DownloadStatus.completed;
    final downloading =
        dlStatus == DownloadStatus.downloading ||
        dlStatus == DownloadStatus.queued;

    final durationMs = audio.duration.inMilliseconds;
    final sliderMax = durationMs > 0 ? durationMs.toDouble() : 1.0;
    final currentPos =
        _scrubValue ??
        audio.position.inMilliseconds.toDouble().clamp(0.0, sliderMax);

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 6),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.rule,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Tappable(
                              semanticLabel: s.back,
                              onTap: () => context.canPop()
                                  ? context.pop()
                                  : context.go('/home'),
                              child: LucideIcon(
                                'chevron-down',
                                size: 24,
                                color: c.ink,
                              ),
                            ),
                            Expanded(
                              child: BText(
                                s.nowPlayingMp3,
                                size: 11,
                                weight: FontWeight.w600,
                                color: c.inkMuted,
                                align: TextAlign.center,
                                letterSpacing: s.my ? 0 : 0.8,
                              ),
                            ),
                            Tappable(
                              semanticLabel: s.queue,
                              onTap: () => context.push('/player/queue'),
                              child: LucideIcon(
                                'more-horizontal',
                                size: 24,
                                color: c.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 45,
                      vertical: 14,
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.symmetric(vertical: 34),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: c.rule),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const EchoEmblem(size: 156),
                          if (offline) ...[
                            const SizedBox(height: 22),
                            SmallBadge(
                              label: s.offlineReady,
                              background: c.sageSoft,
                              foreground: c.sage,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            BText(
                              item.displayTitle,
                              size: 15.5,
                              serif: true,
                              weight: FontWeight.w700,
                              align: TextAlign.center,
                            ),
                            if ((item.teacherName ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: item.teacherId == null
                                    ? null
                                    : () => context.push(
                                        '/teacher/${item.teacherId}',
                                      ),
                                child: BText(
                                  item.teacherName!,
                                  size: 12,
                                  color: c.inkMuted,
                                  align: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (audio.hasError)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                          child: SmallBadge(
                            label: s.playbackError,
                            background: c.dangerSoft,
                            foreground: c.danger,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            activeTrackColor: c.lacquer,
                            inactiveTrackColor: c.surfaceSoft,
                            thumbColor: c.lacquer,
                            overlayColor: c.lacquerSoft,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: sliderMax,
                            value: currentPos,
                            onChangeStart: (v) =>
                                setState(() => _scrubValue = v),
                            onChanged: (v) => setState(() => _scrubValue = v),
                            onChangeEnd: (v) async {
                              setState(() => _scrubValue = null);
                              await audio.seekTo(
                                Duration(milliseconds: v.round()),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BText(
                              formatDuration(
                                Duration(milliseconds: currentPos.round()),
                              ),
                              size: 11.5,
                              color: c.inkMuted,
                            ),
                            BText(
                              formatDuration(audio.duration),
                              size: 11.5,
                              color: c.inkMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Tappable(
                            semanticLabel: 'Previous',
                            onTap: audio.previous,
                            child: LucideIcon(
                              'skip-back',
                              size: 24,
                              color: c.ink,
                            ),
                          ),
                          Tappable(
                            semanticLabel: 'Back 15s',
                            onTap: audio.skipBack,
                            child: LucideIcon(
                              'rotate-ccw',
                              size: 24,
                              color: c.ink,
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: audio.playing ? 'Pause' : 'Play',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: audio.togglePlay,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: c.lacquer,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: audio.loading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: c.onLacquer,
                                          ),
                                        )
                                      : LucideIcon(
                                          audio.playing ? 'pause' : 'play',
                                          size: 26,
                                          color: c.onLacquer,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          Tappable(
                            semanticLabel: 'Forward 15s',
                            onTap: audio.skipForward,
                            child: LucideIcon(
                              'refresh-ccw',
                              size: 24,
                              color: c.ink,
                            ),
                          ),
                          Tappable(
                            semanticLabel: 'Next',
                            onTap: audio.hasNext ? audio.next : null,
                            child: LucideIcon(
                              'skip-forward',
                              size: 24,
                              color: audio.hasNext ? c.ink : c.inkSubtle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BaganCard(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              _UtilityTile(
                                top: BText(
                                  '${audio.speed}×',
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                                label: s.speed,
                                onTap: () => _pickSpeed(context, audio),
                              ),
                              _UtilityTile(
                                top: LucideIcon(
                                  'clock-3',
                                  size: 22,
                                  color: audio.sleepLabel != null
                                      ? c.lacquer
                                      : c.ink,
                                ),
                                label: s.sleepLabel(audio.sleepLabel),
                                active: audio.sleepLabel != null,
                                onTap: () => context.push('/player/queue'),
                              ),
                              _UtilityTile(
                                top: LucideIcon(
                                  'list-music',
                                  size: 22,
                                  color: c.ink,
                                ),
                                label: s.queue,
                                onTap: () => context.push('/player/queue'),
                              ),
                              _UtilityTile(
                                top: LucideIcon(
                                  'heart',
                                  size: 22,
                                  color: saved ? c.lacquer : c.ink,
                                ),
                                label: s.saved,
                                active: saved,
                                onTap: () => context
                                    .read<AppController>()
                                    .toggleSaved(item.id),
                              ),
                              _UtilityTile(
                                top: downloading
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          value: dlRecord?.progress,
                                          strokeWidth: 2.2,
                                          color: c.lacquer,
                                          backgroundColor: c.surfaceSoft,
                                        ),
                                      )
                                    : LucideIcon(
                                        offline ? 'check-circle-2' : 'download',
                                        size: 22,
                                        color: offline ? c.sage : c.ink,
                                      ),
                                label: downloading && dlRecord?.progress != null
                                    ? '${(dlRecord!.progress! * 100).round()}%'
                                    : s.offline,
                                active: offline,
                                onTap: offline
                                    ? null
                                    : downloading
                                    ? () => context
                                          .read<DownloadManager>()
                                          .cancel(item.id)
                                    : () =>
                                          MediaActions.download(context, item),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickSpeed(
    BuildContext context,
    AudioPlaybackController audio,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BText(
                context.s.speed,
                size: 18,
                serif: true,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final spd in AudioPlaybackController.speeds)
                    FilterPill(
                      label: '$spd×',
                      primary: true,
                      selected: (audio.speed - spd).abs() < 0.01,
                      onTap: () {
                        audio.setSpeed(spd);
                        Navigator.of(ctx).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UtilityTile extends StatelessWidget {
  const _UtilityTile({
    required this.top,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final Widget top;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Tappable(
        semanticLabel: label,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 26, child: Center(child: top)),
              const SizedBox(height: 4),
              BText(
                label,
                size: 10,
                color: active ? c.lacquer : c.inkMuted,
                maxLines: 1,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
