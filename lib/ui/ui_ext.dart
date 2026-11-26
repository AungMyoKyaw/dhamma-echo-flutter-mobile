import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/app_controller.dart';

export '../l10n/app_strings.dart';

extension AppContext on BuildContext {
  /// Strings for the active UI language; rebuilds when the language changes.
  AppStrings get s => AppStrings(
    select<AppController, String>((AppController a) => a.settings.language),
  );
}

String formatDuration(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  var value = bytes / 1024;
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[i]}';
}
