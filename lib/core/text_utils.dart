String normalizeText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+', unicode: true), ' ');
}

String formatDuration(num value) {
  final numeric = value.isFinite ? value : 0;
  final total = numeric.floor().clamp(0, 1 << 31);
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

double clampFinite(double value, double minimum, double maximum) {
  if (!value.isFinite) return minimum;
  return value.clamp(minimum, maximum);
}
