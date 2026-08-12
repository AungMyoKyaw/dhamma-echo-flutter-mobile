import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/ui/screens/player_screen.dart';
import 'package:flutter/material.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    required this.controller,
    super.key,
    this.safeBottom = true,
  });

  final AppController controller;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.playback,
      builder: (context, _) {
        final player = controller.playback;
        final track = player.current;
        if (track == null) return const SizedBox.shrink();
        final durationMs = player.duration.inMilliseconds;
        final progress = durationMs <= 0
            ? 0.0
            : (player.position.inMilliseconds / durationMs)
                  .clamp(0.0, 1.0)
                  .toDouble();

        return Material(
          key: const Key('mini-player'),
          elevation: 8,
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: InkWell(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => PlayerScreen(controller: controller),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: safeBottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 4),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.spa_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                track.teacherName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: player.playing ? 'Pause' : 'Play',
                          onPressed: player.loading ? null : player.toggle,
                          icon: player.loading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  player.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                        ),
                        IconButton(
                          tooltip: 'Play next',
                          onPressed: player.queue.isEmpty
                              ? null
                              : controller.playNext,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
