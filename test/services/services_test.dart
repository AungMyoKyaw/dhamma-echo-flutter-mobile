import 'dart:async';
import 'dart:io';

import 'package:dhamma_echo/data/user_state_repository.dart';
import 'package:dhamma_echo/models/models.dart';
import 'package:dhamma_echo/services/audio_engine.dart';
import 'package:dhamma_echo/services/audio_playback_controller.dart';
import 'package:dhamma_echo/services/connectivity_service.dart';
import 'package:dhamma_echo/services/download_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({this.unmetered = true});
  bool unmetered;
  @override
  Stream<bool> get onlineChanges => const Stream.empty();
  @override
  Future<bool> isOnline() async => true;
  @override
  Future<bool> isUnmetered() async => unmetered;
}

class _FakeDownloader implements FileDownloader {
  @override
  DownloadTask start(
    Uri url,
    String savePath,
    void Function(int received, int total) onProgress,
  ) {
    final c = Completer<void>();
    var canceled = false;
    Future<void>.microtask(() async {
      if (canceled) return;
      onProgress(50, 100);
      await File(savePath).writeAsBytes(List.filled(100, 7));
      onProgress(100, 100);
      if (!c.isCompleted) c.complete();
    });
    return DownloadTask(
      done: c.future,
      cancel: () {
        canceled = true;
        if (!c.isCompleted) c.completeError(Exception('canceled'));
      },
    );
  }
}

class _FakeAudioEngine implements AudioEngine {
  final _pos = StreamController<Duration>.broadcast();
  final _dur = StreamController<Duration?>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _state = StreamController<EngineState>.broadcast();
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(minutes: 10);
  bool _isPlaying = false;
  double lastSpeed = 1.0;

  @override
  Duration? get duration => _duration;
  @override
  Stream<Duration?> get durationStream => _dur.stream;
  @override
  set onSkipNext(void Function()? callback) {}
  @override
  set onSkipPrevious(void Function()? callback) {}
  @override
  bool get playing => _isPlaying;
  @override
  Stream<bool> get playingStream => _playing.stream;
  @override
  Duration get position => _position;
  @override
  Stream<Duration> get positionStream => _pos.stream;
  @override
  Stream<EngineState> get stateStream => _state.stream;

  void emitCompleted() => _state.add(EngineState.completed);

  @override
  Future<void> load(
    MediaItem media, {
    String? filePath,
    Uri? remote,
    Duration? start,
  }) async {
    _position = start ?? Duration.zero;
    _dur.add(_duration);
    _pos.add(_position);
    _state.add(EngineState.ready);
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration p) async {
    _position = p;
    _pos.add(p);
  }

  @override
  Future<void> setSpeed(double s) async => lastSpeed = s;

  @override
  Future<void> stop() async => pause();

  @override
  Future<void> dispose() async {
    await _pos.close();
    await _dur.close();
    await _playing.close();
    await _state.close();
  }
}

void main() {
  sqfliteFfiInit();

  const sample = MediaItem(
    id: 42,
    title: 'Sample Talk',
    kind: MediaKind.audio,
    format: 'mp3',
    language: 'myanmar',
    url: 'https://dhammadownload.com/sample.mp3',
    teacherName: 'Sayadaw',
  );

  test('DownloadManager respects Wi-Fi only and completes download', () async {
    final tmp = await Directory.systemTemp.createTemp('dhamma_dl_test_');
    addTearDown(() => tmp.delete(recursive: true));
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: UserStateRepository.schemaVersion,
        onCreate: UserStateRepository.createSchema,
      ),
    );
    final repo = UserStateRepository(db);
    addTearDown(repo.close);
    final conn = _FakeConnectivity(unmetered: false);
    final dl = DownloadManager(
      repository: repo,
      downloader: _FakeDownloader(),
      connectivity: conn,
      directory: () async => tmp,
      wifiOnly: () => true,
    );
    await dl.init();

    expect(await dl.enqueue(sample), EnqueueResult.blockedByWifi);

    conn.unmetered = true;
    expect(await dl.enqueue(sample), EnqueueResult.started);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(dl.localPathFor(42), isNotNull);
    expect(dl.storageBytes(), 100);
    await dl.remove(42);
    expect(dl.localPathFor(42), isNull);
  });

  test(
    'AudioPlaybackController manages queue, speed, and sleep timer',
    () async {
      final engine = _FakeAudioEngine();
      final ctrl = AudioPlaybackController(engine: engine);
      addTearDown(ctrl.dispose);

      final second = MediaItem(
        id: 43,
        title: 'Second Talk',
        kind: MediaKind.audio,
        format: 'mp3',
        language: 'myanmar',
        url: 'https://dhammadownload.com/second.mp3',
      );
      await ctrl.playQueue([sample, second], 0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(ctrl.current?.id, 42);
      expect(ctrl.playing, isTrue);

      await ctrl.setSpeed(1.5);
      expect(engine.lastSpeed, 1.5);

      ctrl.setSleepEndOfTrack();
      expect(ctrl.sleepLabel, 'End');
      engine.emitCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(ctrl.playing, isFalse);
      expect(ctrl.sleepMode, SleepMode.off);
    },
  );
}
