import 'package:dhamma_echo/app/app_controller.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});
  final AppController controller;

  static const List<double> rates = <double>[0.75, 1, 1.25, 1.5, 1.75, 2];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'Make listening yours',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Playback speed',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<double>(
                        isExpanded: true,
                        value: controller.settings.playbackRate,
                        items: rates
                            .map(
                              (rate) => DropdownMenuItem<double>(
                                value: rate,
                                child: Text('$rate×'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) controller.setPlaybackRate(value);
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Volume',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Slider(
                        value: controller.settings.volume,
                        onChanged: controller.setVolume,
                      ),
                      Text('${(controller.settings.volume * 100).round()}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dhamma Echo uses a light-only interface and keeps favorites, history, resume positions, and settings on this device.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}
