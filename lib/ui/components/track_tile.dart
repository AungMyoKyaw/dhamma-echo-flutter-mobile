import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:flutter/material.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    required this.controller,
    required this.track,
    super.key,
    this.showQueueAction = true,
  });

  final AppController controller;
  final AudioTrack track;
  final bool showQueueAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCurrent = controller.playback.current?.id == track.id;
    return ListTile(
      tileColor: isCurrent ? colors.primary.withValues(alpha: 0.06) : null,
      shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: IconButton.filledTonal(
        tooltip: track.playable
            ? 'Play ${track.title}'
            : '${track.format.toUpperCase()} is unavailable',
        onPressed: track.playable ? () => controller.play(track) : null,
        icon: Icon(
          isCurrent && controller.playback.playing
              ? Icons.equalizer
              : Icons.play_arrow_rounded,
        ),
      ),
      title: Text(track.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${track.teacherName} · ${track.language} · ${track.format.toUpperCase()}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      trailing: Wrap(
        spacing: 0,
        children: <Widget>[
          IconButton(
            tooltip: controller.isFavorite(track.id)
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: () => controller.toggleFavorite(track.id),
            icon: Icon(
              controller.isFavorite(track.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
          if (showQueueAction)
            IconButton(
              tooltip: 'Add to queue',
              onPressed: track.playable
                  ? () => controller.enqueue(track)
                  : null,
              icon: const Icon(Icons.playlist_add),
            ),
        ],
      ),
    );
  }
}
