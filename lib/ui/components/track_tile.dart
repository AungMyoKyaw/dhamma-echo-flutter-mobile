import 'dart:async';

import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:flutter/material.dart';

enum _TrackAction { download, favorite, queue }

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
    final playback = controller.playback;
    final isCurrent = playback.current?.id == track.id;
    final isPlaying = isCurrent && playback.playing;
    final isLoading = isCurrent && playback.loading;
    final isDownloaded = controller.isDownloaded(track.id);
    final isDownloading = controller.isDownloading(track.id);
    final progress = controller.downloadProgress(track.id);

    return ListTile(
      onTap: track.playable && !isLoading
          ? () => unawaited(_activateTrack())
          : null,
      tileColor: isCurrent ? colors.primaryContainer : null,
      shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: IconButton.filledTonal(
        tooltip: _playbackTooltip(
          isCurrent: isCurrent,
          isPlaying: isPlaying,
          isLoading: isLoading,
        ),
        onPressed: track.playable && !isLoading
            ? () => unawaited(_activateTrack())
            : null,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
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
      trailing: PopupMenuButton<_TrackAction>(
        tooltip: 'More actions for ${track.title}',
        onSelected: (action) {
          unawaited(_handleAction(context, action, isDownloaded));
        },
        itemBuilder: (context) => <PopupMenuEntry<_TrackAction>>[
          if (controller.downloadManager != null)
            PopupMenuItem<_TrackAction>(
              value: _TrackAction.download,
              enabled: !isDownloading && (isDownloaded || track.playable),
              child: _menuItem(
                icon: isDownloading
                    ? SizedBox.square(
                        dimension: 20,
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
                label: isDownloading
                    ? 'Downloading'
                    : isDownloaded
                    ? 'Remove download'
                    : track.playable
                    ? 'Download for offline listening'
                    : 'Download unavailable',
              ),
            ),
          PopupMenuItem<_TrackAction>(
            value: _TrackAction.favorite,
            child: _menuItem(
              icon: Icon(
                controller.isFavorite(track.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              label: controller.isFavorite(track.id)
                  ? 'Remove from favorites'
                  : 'Add to favorites',
            ),
          ),
          if (showQueueAction)
            PopupMenuItem<_TrackAction>(
              value: _TrackAction.queue,
              enabled: track.playable,
              child: _menuItem(
                icon: const Icon(Icons.playlist_add),
                label: track.playable ? 'Add to queue' : 'Queue unavailable',
              ),
            ),
        ],
      ),
    );
  }

  String _playbackTooltip({
    required bool isCurrent,
    required bool isPlaying,
    required bool isLoading,
  }) {
    if (!track.playable) return '${track.format.toUpperCase()} is unavailable';
    if (isLoading) return 'Loading ${track.title}';
    if (isPlaying) return 'Pause ${track.title}';
    if (isCurrent) return 'Resume ${track.title}';
    return 'Play ${track.title}';
  }

  Widget _menuItem({required Widget icon, required String label}) {
    return Row(
      children: <Widget>[
        SizedBox(width: 24, child: Center(child: icon)),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }

  Future<void> _activateTrack() async {
    if (!track.playable) return;
    if (controller.playback.current?.id == track.id) {
      await controller.playback.toggle();
      return;
    }
    await controller.play(track);
  }

  Future<void> _handleAction(
    BuildContext context,
    _TrackAction action,
    bool isDownloaded,
  ) async {
    switch (action) {
      case _TrackAction.download:
        await _toggleDownload(context, isDownloaded);
        return;
      case _TrackAction.favorite:
        await controller.toggleFavorite(track.id);
        return;
      case _TrackAction.queue:
        controller.enqueue(track);
        return;
    }
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
