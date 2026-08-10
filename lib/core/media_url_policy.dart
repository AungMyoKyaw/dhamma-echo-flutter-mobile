const List<String> _approvedHosts = <String>[
  'www.dhammadownload.com',
  'dhammadownload.com',
];

List<Uri> mediaUrlCandidates(String value, String format) {
  if (format.trim().toLowerCase() != 'mp3') return const <Uri>[];
  final Uri uri;
  try {
    uri = Uri.parse(value.trim());
  } on FormatException {
    return const <Uri>[];
  }
  if (!const <String>{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      !_approvedHosts.contains(uri.host.toLowerCase()) ||
      uri.hasPort ||
      uri.userInfo.isNotEmpty) {
    return const <Uri>[];
  }

  final normalized = uri.replace(scheme: 'https', fragment: '');
  return _approvedHosts
      .map((host) => normalized.replace(host: host))
      .toList(growable: false);
}

bool isPlayableUrl(String value) => mediaUrlCandidates(value, 'mp3').isNotEmpty;
