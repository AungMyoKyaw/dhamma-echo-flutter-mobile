import 'dart:async';

import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('play rejects unplayable tracks before reaching the port', () async {
    final port = FakePlaybackPort();
    final controller = PlaybackController(port);
    addTearDown(controller.dispose);
    final track = fixtureTrack(playable: false, format: 'wma');

    expect(await controller.play(track), isFalse);
    expect(port.urls, isEmpty);
    expect(controller.error, contains('not supported'));
  });

  test(
    'play retries approved host candidates and applies resume settings',
    () async {
      final port = FakePlaybackPort(failuresBeforeSuccess: 1);
      final controller = PlaybackController(port);
      addTearDown(controller.dispose);
      await controller.setVolume(0.4);
      await controller.setRate(1.5);

      final result = await controller.play(fixtureTrack(), resumeAt: 42);

      expect(result, isTrue);
      expect(port.urls, hasLength(2));
      expect(port.lastSeek, const Duration(seconds: 42));
      expect(controller.position, const Duration(seconds: 42));
      expect(port.volume, 0.4);
      expect(port.speed, 1.5);
    },
  );

  test('play exposes current state before port play future completes', () async {
    final pendingPlay = Completer<void>();
    final port = FakePlaybackPort(playCompleter: pendingPlay);
    final controller = PlaybackController(port);
    addTearDown(controller.dispose);
    final track = fixtureTrack();

    final resultFuture = controller.play(track);
    await Future<void>.delayed(Duration.zero);
    final currentIdBeforePortCompletes = controller.current?.id;
    final playingBeforePortCompletes = controller.playing;

    pendingPlay.complete();
    expect(await resultFuture, isTrue);
    expect(currentIdBeforePortCompletes, track.id);
    expect(playingBeforePortCompletes, isTrue);
  });

  test('toggle resumes without waiting for port play lifetime', () async {
    final port = FakePlaybackPort();
    final controller = PlaybackController(port);
    addTearDown(controller.dispose);
    await controller.play(fixtureTrack());
    await controller.toggle();
    expect(controller.playing, isFalse);

    final pendingResume = Completer<void>();
    port.playCompleter = pendingResume;
    final toggleFuture = controller.toggle();
    await Future<void>.delayed(Duration.zero);
    final playingBeforePortCompletes = controller.playing;

    pendingResume.complete();
    await toggleFuture;
    expect(playingBeforePortCompletes, isTrue);
  });

  test('preferred local uri is attempted before trusted remote fallback', () async {
    final port = FakePlaybackPort(failuresBeforeSuccess: 1);
    final controller = PlaybackController(port);
    addTearDown(controller.dispose);
    final localUri = Uri.file('/tmp/dhamma-echo/1.mp3');

    expect(
      await controller.play(fixtureTrack(), preferredUri: localUri),
      isTrue,
    );
    expect(port.urls.first, localUri);
    expect(port.urls[1].scheme, 'https');
    expect(port.urls[1].host, 'www.dhammadownload.com');
  });

  test('queue remains unique and next advances predictably', () async {
    final port = FakePlaybackPort();
    final controller = PlaybackController(port);
    addTearDown(controller.dispose);
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

AudioTrack fixtureTrack({
  int id = 1,
  bool playable = true,
  String format = 'mp3',
}) {
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
  FakePlaybackPort({this.failuresBeforeSuccess = 0, this.playCompleter});

  final int failuresBeforeSuccess;
  Completer<void>? playCompleter;
  final List<Uri> urls = <Uri>[];
  final List<AudioTrack> loadedTracks = <AudioTrack>[];
  Duration? lastSeek;
  double volume = 0.8;
  double speed = 1;
  int attempts = 0;

  @override
  Stream<PlaybackPortEvent> get events =>
      const Stream<PlaybackPortEvent>.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load(AudioTrack track, Uri uri) async {
    loadedTracks.add(track);
    urls.add(uri);
    attempts += 1;
    if (attempts <= failuresBeforeSuccess) {
      throw StateError('fail');
    }
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() => playCompleter?.future ?? Future<void>.value();

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
