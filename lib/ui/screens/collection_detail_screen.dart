import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/ui/components/async_message.dart';
import 'package:dhamma_echo/ui/components/track_tile.dart';
import 'package:flutter/material.dart';

class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({required this.controller, required this.collection, super.key});

  final AppController controller;
  final CollectionSummary collection;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Collection')),
        body: FutureBuilder<CollectionDetail>(
          future: controller.getCollection(collection.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AsyncMessage(
                icon: Icons.error_outline,
                title: 'Could not load collection',
                message: snapshot.error.toString(),
              );
            }
            final detail = snapshot.requireData;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                Text(
                  detail.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(detail.teacherName, style: Theme.of(context).textTheme.titleMedium),
                if (detail.description case final description?) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(description),
                ],
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Text('${detail.audioCount} talks'),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await controller.filterByCollection(detail.id);
                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      icon: const Icon(Icons.filter_alt_outlined),
                      label: const Text('Explore filter'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: detail.tracks
                        .map((track) => TrackTile(controller: controller, track: track))
                        .toList(growable: false),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
