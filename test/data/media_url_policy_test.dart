import 'package:dhamma_echo/data/media_url_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaUrlPolicy', () {
    test('upgrades dhammadownload http URLs to https', () {
      final uri = MediaUrlPolicy.normalize(
        'http://dhammadownload.com/MP3Library/Test Talk.mp3',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'dhammadownload.com');
      expect(uri.toString(), contains('Test%20Talk.mp3'));
    });

    test('rejects unknown http, file, and mms URLs for in-app playback', () {
      expect(MediaUrlPolicy.normalize('http://example.com/a.mp3'), isNull);
      expect(MediaUrlPolicy.normalize('file:///tmp/a.mp3'), isNull);
      expect(MediaUrlPolicy.normalize('mms://stream/a.wma'), isNull);
    });

    test('classifies playable vs legacy formats', () {
      expect(
        MediaUrlPolicy.isInAppPlayable(
          'mp3',
          'https://dhammadownload.com/a.mp3',
        ),
        isTrue,
      );
      expect(
        MediaUrlPolicy.isInAppPlayable(
          'MP4',
          'http://dhammadownload.com/a.mp4',
        ),
        isTrue,
      );
      expect(
        MediaUrlPolicy.isInAppPlayable(
          'pdf',
          'https://dhammadownload.com/a.pdf',
        ),
        isTrue,
      );
      expect(
        MediaUrlPolicy.isInAppPlayable(
          'wma',
          'https://dhammadownload.com/a.wma',
        ),
        isFalse,
      );
      expect(
        MediaUrlPolicy.isInAppPlayable(
          'wmv',
          'https://dhammadownload.com/a.wmv',
        ),
        isFalse,
      );
      expect(
        MediaUrlPolicy.isInAppPlayable(
          'doc',
          'https://dhammadownload.com/a.doc',
        ),
        isFalse,
      );
      expect(
        MediaUrlPolicy.isInAppPlayable('mp3', 'file:///local/a.mp3'),
        isFalse,
      );
    });
  });
}
