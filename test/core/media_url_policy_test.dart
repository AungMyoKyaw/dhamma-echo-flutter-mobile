import 'package:dhamma_echo/core/media_url_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('approved HTTP MP3 becomes two HTTPS host candidates', () {
    final candidates = mediaUrlCandidates(
      'http://dhammadownload.com/audio/Loving Kindness.mp3#fragment',
      'MP3',
    );
    expect(candidates, hasLength(2));
    expect(candidates[0].scheme, 'https');
    expect(candidates[0].host, 'www.dhammadownload.com');
    expect(candidates[0].fragment, isEmpty);
    expect(candidates[0].path, '/audio/Loving%20Kindness.mp3');
    expect(candidates[1].host, 'dhammadownload.com');
  });

  test('unsafe sources and unsupported formats are rejected', () {
    expect(mediaUrlCandidates('https://example.com/a.mp3', 'mp3'), isEmpty);
    expect(
      mediaUrlCandidates('https://dhammadownload.com/a.wma', 'wma'),
      isEmpty,
    );
    expect(
      mediaUrlCandidates('https://user:pass@dhammadownload.com/a.mp3', 'mp3'),
      isEmpty,
    );
    expect(
      mediaUrlCandidates('https://dhammadownload.com:8443/a.mp3', 'mp3'),
      isEmpty,
    );
    expect(mediaUrlCandidates('not a url', 'mp3'), isEmpty);
  });
}
