import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('play rejects unplayable tracks before reaching the port', () async {
    final port = FakePlaybackPort();
    final controller = PlaybackController(port);
    final track = fixtureTrack(playable: false, format: 'wma');
    expect(await controller.play(track), isFalse);
    expect(port.urls, isEmpty);
    expect(controller.error, contains('not supported'));
  });

  test('play retries approved host candidates and applies resume settings', () async {
    final port = FakePlaybackPort(failuresBeforeSuccess: 1);
    final controller = PlaybackController(port);
    await controller.setVolume(0.4);
    await controller.setRate(1.5);
    final result = await controller.play(fixtureTrack(), resumeAt: 42);
    expect(result, isTrue);
    expect(port.urls, hasLength(2));
    expect(port.lastSeek, const Duration(seconds: 42));
    expect(controller.position, const Duration(seconds: 42));
    expect(port.volume, 0.4);
    expect(port.speed, 1.5);
  });

  test('queue remains unique and next advances predictably', () async {
    final port = FakePlaybackPort();
    final controller = PlaybackController(port);
    final one = fixtureTrack(id: 1);
    final two = fixtureTrack(id: 2);
    controller.enqueue(two);
    controller.enqueue(two);
    expect(controller.queue.map((track) => track.id), [2]);
    await controller.play(one);
    expect(await controller.playNext(), isTrue);
    expect(controller.current?.id, 2);
    expect(controller.queue, isEmpty);
  });
}

AudioTrack fixtureTrack({int id = 1, bool playable = true, String format = 'mp3'}) {
  return AudioTrack(
    id: id,
    title: 'Talk $id',
    format: format,
    language: 'english',
    url: 'http://dhammadownload.com/$id.mp3',
    teacherId: 16,
    teacherName: 'Teacher',
    playable: playable,
  );
}

class FakePlaybackPort implements PlaybackPort {
  FakePlaybackPort({this.failuresBeforeSuccess = 0});

  final int failuresBeforeSuccess;
  final List<Uri> urls = <Uri>[];
  Duration? lastSeek;
  double volume = 0.8;
  double speed = 1;
  int attempts = 0;

  @override
  Stream<PlaybackPortEvent> get events => const Stream<PlaybackPortEvent>.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load(Uri uri) async {
    urls.add(uri);
    attempts += 1;
    if (attempts <= failuresBeforeSuccess) {
      throw StateError('fail');
    }
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
  }

  @override
  Future<void> setSpeed(double value) async {
    speed = value;
  }

  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }
}
