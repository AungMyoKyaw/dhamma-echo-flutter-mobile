import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../services/audio_playback_controller.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../ui_ext.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import '../widgets/lucide_icon.dart';
import '../widgets/media_row.dart';

class QueueSleepTimerScreen extends StatelessWidget {
  const QueueSleepTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final audio = context.watch<AudioPlaybackController>();
    final upNext = audio.upNext;
    final remaining = audio.sleepRemaining;
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            BackBar(label: s.nowPlaying, fallback: '/player/audio'),
            TabHeader(title: s.queueAndSleep, serifSize: 22),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: BaganCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BText(
                      s.sleepTimerHeader,
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: c.inkMuted,
                      letterSpacing: s.my ? 0 : 0.8,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterPill(
                          label: s.timerOff,
                          primary: true,
                          selected: audio.sleepMode == SleepMode.off,
                          onTap: audio.cancelSleep,
                        ),
                        for (final mins in AudioPlaybackController.sleepOptions)
                          FilterPill(
                            label: '${mins}m',
                            primary: true,
                            selected:
                                audio.sleepMode == SleepMode.minutes &&
                                audio.sleepMinutes == mins,
                            onTap: () => audio.setSleepMinutes(mins),
                          ),
                        FilterPill(
                          label: s.timerEnd,
                          primary: true,
                          selected: audio.sleepMode == SleepMode.endOfTrack,
                          onTap: audio.setSleepEndOfTrack,
                        ),
                      ],
                    ),
                    if (audio.sleepMode != SleepMode.off) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          LucideIcon('clock-3', size: 16, color: c.lacquer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BText(
                              audio.sleepMode == SleepMode.endOfTrack
                                  ? s.timerEndOfTrack
                                  : s.timerRemaining(
                                      ((remaining?.inSeconds ?? 0) / 60).ceil(),
                                    ),
                              size: 12,
                              color: c.lacquer,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 10, 6),
              child: Row(
                children: [
                  Expanded(
                    child: BText(
                      s.upNext(upNext.length),
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: c.inkMuted,
                      letterSpacing: s.my ? 0 : 0.8,
                    ),
                  ),
                  if (upNext.isNotEmpty)
                    Tappable(
                      semanticLabel: s.clear,
                      onTap: audio.clearUpNext,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: BText(
                          s.clear,
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: c.lacquer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (upNext.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: BText(s.queueEmpty, size: 13, color: c.inkMuted),
                ),
              )
            else
              for (var i = 0; i < upNext.length; i++)
                MediaRow(
                  item: upNext[i],
                  number: i + 1,
                  onTap: () => audio.jumpTo(audio.index + 1 + i),
                ),
          ],
        ),
      ),
    );
  }
}
