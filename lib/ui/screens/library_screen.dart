import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/ui/components/async_message.dart';
import 'package:dhamma_echo/ui/components/track_tile.dart';
import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final favorites = controller.favoriteTracks;
    final recent = controller.recentTracks;
    final downloads = controller.downloadedTracks;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text(
          'Your library',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        Text(
          'Favorites',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (favorites.isEmpty)
          const Card(
            child: AsyncMessage(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              message: 'Favorite a talk and it will appear here.',
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: favorites
                  .map(
                    (track) => TrackTile(controller: controller, track: track),
                  )
                  .toList(growable: false),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Downloads',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (downloads.isEmpty)
          const Card(
            child: AsyncMessage(
              icon: Icons.download_for_offline_outlined,
              title: 'No downloads yet',
              message: 'Download a playable MP3 to listen without a network connection.',
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: downloads
                  .map(
                    (track) => TrackTile(controller: controller, track: track),
                  )
                  .toList(growable: false),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Recent',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const Card(
            child: AsyncMessage(
              icon: Icons.history,
              title: 'Nothing played yet',
              message: 'Your recent listening history will stay on this device.',
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: recent
                  .map(
                    (track) => TrackTile(controller: controller, track: track),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }
}
