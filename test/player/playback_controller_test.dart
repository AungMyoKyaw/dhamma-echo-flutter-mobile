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

  test('newest overlapping play request wins', () async {
    final port = OverlappingLoadPlaybackPort();
    final controller = PlaybackController(port);
    addTearDown(controller.dispose);
    final olderTrack = fixtureTrack(id: 1);
    final newerTrack = fixtureTrack(id: 2);

    final older = controller.play(olderTrack);
    final newer = controller.play(newerTrack);
    expect(port.loadedTracks.map((track) => track.id), <int>[1, 2]);

    port.completeLoad(2);
    expect(await newer, isTrue);
    port.completeLoad(1);
    expect(await older, isFalse);

    expect(controller.current?.id, newerTrack.id);
    expect(controller.playing, isTrue);
  });

  test('play preserves duration emitted while the source loads', () async {
    final port = FakePlaybackPort(
      loadDuration: const Duration(minutes: 12, seconds: 34),
    );
    final controller = PlaybackController(port);
    addTearDown(controller.dispose);

    expect(await controller.play(fixtureTrack()), isTrue);
    expect(controller.duration, const Duration(minutes: 12, seconds: 34));
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
  FakePlaybackPort({
    this.failuresBeforeSuccess = 0,
    this.playCompleter,
    this.loadDuration,
  });

  final int failuresBeforeSuccess;
  Completer<void>? playCompleter;
  final Duration? loadDuration;
  final StreamController<PlaybackPortEvent> _events =
      StreamController<PlaybackPortEvent>.broadcast(sync: true);
  final List<Uri> urls = <Uri>[];
  final List<AudioTrack> loadedTracks = <AudioTrack>[];
  Duration? lastSeek;
  double volume = 0.8;
  double speed = 1;
  int attempts = 0;

  @override
  Stream<PlaybackPortEvent> get events => _events.stream;

  @override
  Future<void> dispose() => _events.close();

  @override
  Future<void> load(AudioTrack track, Uri uri) async {
    loadedTracks.add(track);
    urls.add(uri);
    attempts += 1;
    if (attempts <= failuresBeforeSuccess) {
      throw StateError('fail');
    }
    if (loadDuration case final duration?) {
      _events.add(PlaybackDurationEvent(duration));
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

class OverlappingLoadPlaybackPort implements PlaybackPort {
  final StreamController<PlaybackPortEvent> _events =
      StreamController<PlaybackPortEvent>.broadcast(sync: true);
  final List<AudioTrack> loadedTracks = <AudioTrack>[];
  final Map<int, Completer<void>> _loads = <int, Completer<void>>{};

  @override
  Stream<PlaybackPortEvent> get events => _events.stream;

  void completeLoad(int trackId) => _loads[trackId]?.complete();

  @override
  Future<void> dispose() => _events.close();

  @override
  Future<void> load(AudioTrack track, Uri uri) {
    loadedTracks.add(track);
    final completer = Completer<void>();
    _loads[track.id] = completer;
    return completer.future;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double value) async {}

  @override
  Future<void> setVolume(double value) async {}
}
