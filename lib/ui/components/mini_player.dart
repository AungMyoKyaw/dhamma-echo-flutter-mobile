import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/ui/screens/player_screen.dart';
import 'package:flutter/material.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final track = controller.playback.current;
    if (track == null) return const SizedBox.shrink();
    return Material(
      key: const Key('mini-player'),
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => PlayerScreen(controller: controller)),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(Icons.spa_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(track.teacherName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: controller.playback.playing ? 'Pause' : 'Play',
                  onPressed: controller.playback.loading ? null : controller.playback.toggle,
                  icon: controller.playback.loading
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(controller.playback.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                IconButton(
                  tooltip: 'Play next',
                  onPressed: controller.playback.queue.isEmpty ? null : controller.playback.playNext,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
