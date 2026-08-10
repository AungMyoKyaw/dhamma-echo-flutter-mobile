import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/core/text_utils.dart';
import 'package:dhamma_echo/ui/components/track_tile.dart';
import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final player = controller.playback;
        final track = player.current;
        if (track == null) return const Scaffold(body: Center(child: Text('Nothing is playing.')));
        final durationMs = player.duration.inMilliseconds;
        final maximum = durationMs <= 0 ? 1.0 : durationMs.toDouble();
        final position = player.position.inMilliseconds.clamp(0, maximum.toInt()).toDouble();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Now playing'),
            actions: <Widget>[
              IconButton(
                tooltip: controller.isFavorite(track.id) ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () => controller.toggleFavorite(track.id),
                icon: Icon(controller.isFavorite(track.id) ? Icons.favorite : Icons.favorite_border),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(28)),
                  child: Icon(Icons.spa_outlined, size: 112, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 24),
              Text(track.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(track.teacherName, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Slider(
                value: position,
                max: maximum,
                onChanged: (value) => player.seek(Duration(milliseconds: value.round())),
              ),
              Row(children: <Widget>[Text(formatDuration(player.position.inSeconds)), const Spacer(), Text(formatDuration(player.duration.inSeconds))]),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(iconSize: 32, tooltip: 'Back 15 seconds', onPressed: () => player.jump(-15), icon: const Icon(Icons.replay_10)),
                  IconButton.filled(iconSize: 38, tooltip: player.playing ? 'Pause' : 'Play', onPressed: player.loading ? null : player.toggle, icon: Icon(player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                  IconButton(iconSize: 32, tooltip: 'Forward 15 seconds', onPressed: () => player.jump(15), icon: const Icon(Icons.forward_10)),
                ],
              ),
              if (player.error.isNotEmpty) ...<Widget>[const SizedBox(height: 10), Text(player.error, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center)],
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  const Icon(Icons.speed),
                  const SizedBox(width: 12),
                  Expanded(child: Slider(value: player.rate, min: 0.75, max: 2, divisions: 5, label: '${player.rate}×', onChanged: controller.setPlaybackRate)),
                  Text('${player.rate}×'),
                ],
              ),
              Row(
                children: <Widget>[
                  const Icon(Icons.volume_up_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Slider(value: player.volume, onChanged: controller.setVolume)),
                ],
              ),
              const SizedBox(height: 18),
              Row(children: <Widget>[Text('Queue', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), TextButton(onPressed: player.queue.isEmpty ? null : player.clearQueue, child: const Text('Clear'))]),
              if (player.queue.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Your queue is empty.'))
              else
                Card(clipBehavior: Clip.antiAlias, child: Column(children: player.queue.map((queued) => TrackTile(controller: controller, track: queued, showQueueAction: false)).toList(growable: false))),
            ],
          ),
        );
      },
    );
  }
}
