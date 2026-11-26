/// Decides how a catalogue URL may be used on mobile.
///
/// The bundled catalogue contains `http://` links for hosts that also serve
/// HTTPS, plus a handful of `file:///` and `mms://` entries. App Store ATS and
/// Android's default cleartext policy reject plain HTTP, so trusted hosts are
/// upgraded to HTTPS and everything else is treated as legacy (browser-only).
abstract final class MediaUrlPolicy {
  static const playableFormats = {'mp3', 'mp4', 'pdf'};

  static const _upgradeHosts = {'dhammadownload.com', 'www.dhammadownload.com'};

  /// Returns a safe HTTPS URI for streaming/downloading, or `null` when the
  /// URL cannot be used in-app.
  static Uri? normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final Uri? parsed = Uri.tryParse(trimmed.replaceAll(' ', '%20'));
    if (parsed == null || !parsed.hasAuthority) return null;
    if (parsed.scheme == 'https') return parsed;
    if (parsed.scheme == 'http' && _upgradeHosts.contains(parsed.host)) {
      return parsed.replace(scheme: 'https');
    }
    return null;
  }

  static bool isInAppPlayable(String format, String url) =>
      playableFormats.contains(format.toLowerCase()) && normalize(url) != null;

  /// The URI to hand to the system browser for legacy entries. Falls back to
  /// the raw string when it parses as http/https.
  static Uri? externalUri(String raw) {
    final normalized = normalize(raw);
    if (normalized != null) return normalized;
    final parsed = Uri.tryParse(raw.trim().replaceAll(' ', '%20'));
    if (parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https') &&
        parsed.hasAuthority) {
      return parsed;
    }
    return null;
  }
}
