import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../services/app_controller.dart';
import '../../services/audio_playback_controller.dart';
import '../../theme/bagan_colors.dart';
import '../../theme/bagan_theme.dart';
import '../ui_ext.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    final app = context.watch<AppController>();
    final settings = app.settings;
    final counts = app.counts;

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            BackBar(label: s.back),
            TabHeader(title: s.settings),
            SectionLabel(s.languageAndAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BaganCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    _SettingRow(
                      label: s.appLanguage,
                      control: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilterPill(
                            label: 'English',
                            primary: true,
                            selected: settings.language == 'en',
                            onTap: () => app.setLanguage('en'),
                          ),
                          const SizedBox(width: 6),
                          FilterPill(
                            label: 'မြန်မာ',
                            primary: true,
                            selected: settings.language == 'my',
                            onTap: () => app.setLanguage('my'),
                          ),
                        ],
                      ),
                    ),
                    const Hairline(),
                    _SettingRow(
                      label: s.theme,
                      control: Wrap(
                        spacing: 6,
                        children: [
                          for (final (mode, label) in [
                            (ThemeMode.system, s.themeSystem),
                            (ThemeMode.light, s.themeLight),
                            (ThemeMode.dark, s.themeDark),
                          ])
                            FilterPill(
                              label: label,
                              selected: settings.themeMode == mode,
                              onTap: () => app.setThemeMode(mode),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SectionLabel(s.playbackAndOffline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BaganCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    _SettingRow(
                      label: s.defaultSpeed,
                      control: Tappable(
                        semanticLabel: s.defaultSpeed,
                        onTap: () => _pickSpeed(context, app),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: BText(
                            '${settings.playbackSpeed}×',
                            size: 13,
                            weight: FontWeight.w600,
                            color: c.lacquer,
                          ),
                        ),
                      ),
                    ),
                    const Hairline(),
                    _SettingRow(
                      label: s.wifiOnly,
                      control: Switch.adaptive(
                        value: settings.wifiOnly,
                        activeTrackColor: c.lacquer,
                        onChanged: (v) => app.setWifiOnly(value: v),
                      ),
                    ),
                    const Hairline(),
                    _SettingRow(
                      label: s.showLegacy,
                      control: Switch.adaptive(
                        value: settings.showLegacy,
                        activeTrackColor: c.lacquer,
                        onChanged: (v) => app.setShowLegacy(value: v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SectionLabel(s.aboutAndPrivacy),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BaganCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SmallBadge(
                      label: s.privacyBadge,
                      background: c.sageSoft,
                      foreground: c.sage,
                    ),
                    const SizedBox(height: 12),
                    BText(
                      s.bundledCatalogue(counts.total),
                      size: 13.5,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 6),
                    BText(
                      s.privacyBody(counts.teachers, counts.collections),
                      size: 12,
                      color: c.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSpeed(BuildContext context, AppController app) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BText(
                context.s.defaultSpeed,
                size: 18,
                serif: true,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final spd in AudioPlaybackController.speeds)
                    FilterPill(
                      label: '$spd×',
                      primary: true,
                      selected: (app.settings.playbackSpeed - spd).abs() < 0.01,
                      onTap: () {
                        app.setPlaybackSpeed(spd);
                        context.read<AudioPlaybackController>().setSpeed(spd);
                        Navigator.of(ctx).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.control});

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [BText(label, size: 13), control],
      ),
    ),
  );
}
