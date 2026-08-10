import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/ui/components/teacher_card.dart';
import 'package:dhamma_echo/ui/components/track_tile.dart';
import 'package:dhamma_echo/ui/screens/teacher_detail_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text('Discover the Dhamma', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('A quiet library for listening and returning to trusted teachings.', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(child: _MetricCard(label: 'Audio talks', value: controller.summary.totalAudio)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(label: 'Teachers', value: controller.summary.totalTeachers)),
          ],
        ),
        const SizedBox(height: 24),
        if (controller.recentTracks.isNotEmpty) ...<Widget>[
          _SectionTitle(title: 'Continue listening', onSeeAll: () => controller.selectTab(4)),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: controller.recentTracks.take(3).map((track) => TrackTile(controller: controller, track: track)).toList(growable: false),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _SectionTitle(title: 'Featured teachers', onSeeAll: () => controller.selectTab(3)),
        const SizedBox(height: 8),
        for (final teacher in controller.homeFeaturedTeachers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TeacherCard(
              teacher: teacher,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => TeacherDetailScreen(controller: controller, teacher: teacher)),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(value.toString(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}
