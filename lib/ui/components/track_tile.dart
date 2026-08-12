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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => AnimatedBuilder(
        animation: controller.playback.controls,
        builder: (context, _) {
          final manager = controller.downloadManager;
          if (manager == null) return _buildTile(context);
          return AnimatedBuilder(
            animation: manager,
            builder: (context, _) => _buildTile(context),
          );
        },
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCurrent = controller.playback.current?.id == track.id;
    final isDownloaded = controller.isDownloaded(track.id);
    final isDownloading = controller.isDownloading(track.id);
    final progress = controller.downloadProgress(track.id);

    return ListTile(
      onTap: track.playable && !(isCurrent && controller.playback.playing)
          ? () => controller.play(track)
          : null,
      tileColor: isCurrent ? colors.primary.withValues(alpha: 0.06) : null,
      shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          if (controller.downloadManager != null)
            IconButton(
              tooltip: isDownloading
                  ? 'Downloading'
                  : isDownloaded
                  ? 'Remove download'
                  : track.playable
                  ? 'Download for offline listening'
                  : 'Download unavailable',
              onPressed: isDownloading || !track.playable
                  ? null
                  : () => _toggleDownload(context, isDownloaded),
              icon: isDownloading
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress != null && progress > 0
                            ? progress
                            : null,
                      ),
                    )
                  : Icon(
                      isDownloaded
                          ? Icons.download_done_rounded
                          : Icons.download_rounded,
                    ),
            ),
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

  Future<void> _toggleDownload(BuildContext context, bool isDownloaded) async {
    final succeeded = isDownloaded
        ? await controller.removeDownload(track.id)
        : await controller.downloadTrack(track);
    if (!context.mounted || succeeded) return;
    final message = controller.downloadError(track.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.isEmpty ? 'Could not update this download.' : message,
        ),
      ),
    );
  }
}
