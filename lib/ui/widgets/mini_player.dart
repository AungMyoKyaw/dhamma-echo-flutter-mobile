import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../services/audio_playback_controller.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import 'echo_emblem.dart';
import 'lucide_icon.dart';

/// Persistent 66px floating mini-player docked above the tab bar.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlaybackController>();
    final item = audio.current;
    if (item == null) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Semantics(
        button: true,
        label: item.displayTitle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('/player/audio'),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.rule),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: c.lacquerSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(child: EchoEmblem(size: 28)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BText(
                              item.displayTitle,
                              size: 12,
                              weight: FontWeight.w500,
                              maxLines: 1,
                            ),
                            BText(
                              item.teacherName ?? '',
                              size: 10.5,
                              color: c.inkMuted,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: audio.playing ? 'Pause' : 'Play',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: audio.togglePlay,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.lacquer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: LucideIcon(
                                audio.playing ? 'pause' : 'play',
                                size: 20,
                                color: c.onLacquer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: audio.fraction,
                      minHeight: 2,
                      color: c.lacquer,
                      backgroundColor: c.surfaceSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
