import 'dart:async';

import 'package:audio_service/audio_service.dart' as svc;
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../models/models.dart';

enum EngineState { idle, loading, ready, completed }

/// Abstraction over the native audio stack so playback logic is testable.
abstract class AudioEngine {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;
  Stream<EngineState> get stateStream;

  Duration get position;
  Duration? get duration;
  bool get playing;

  /// Called when the lock-screen / notification asks for next/previous.
  set onSkipNext(void Function()? callback);
  set onSkipPrevious(void Function()? callback);

  Future<void> load(
    MediaItem media, {
    String? filePath,
    Uri? remote,
    Duration? start,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> stop();
  Future<void> dispose();
}

/// `audio_service` handler that mirrors a [AudioPlayer] to the OS media
/// session (lock screen, notification shade, Control Center, headsets).
class DhammaAudioHandler extends svc.BaseAudioHandler with svc.SeekHandler {
  DhammaAudioHandler(this._player) {
    _player.playbackEventStream.listen(
      (event) => playbackState.add(_transform(event)),
      onError: (Object _, StackTrace _) {},
    );
  }

  final AudioPlayer _player;
  void Function()? onSkipNext;
  void Function()? onSkipPrevious;

  svc.PlaybackState _transform(PlaybackEvent event) {
    final playing = _player.playing;
    return svc.PlaybackState(
      controls: [
        svc.MediaControl.skipToPrevious,
        svc.MediaControl.rewind,
        if (playing) svc.MediaControl.pause else svc.MediaControl.play,
        svc.MediaControl.fastForward,
        svc.MediaControl.skipToNext,
      ],
      systemActions: const {
        svc.MediaAction.seek,
        svc.MediaAction.seekForward,
        svc.MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 2, 4],
      processingState: const {
        ProcessingState.idle: svc.AudioProcessingState.idle,
        ProcessingState.loading: svc.AudioProcessingState.loading,
        ProcessingState.buffering: svc.AudioProcessingState.buffering,
        ProcessingState.ready: svc.AudioProcessingState.ready,
        ProcessingState.completed: svc.AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> fastForward() =>
      _player.seek(_player.position + const Duration(seconds: 15));

  @override
  Future<void> rewind() async {
    final target = _player.position - const Duration(seconds: 15);
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  @override
  Future<void> skipToNext() async => onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipPrevious?.call();
}

class JustAudioEngine implements AudioEngine {
  JustAudioEngine._(this._player, this._handler);

  /// Boots the OS media session and returns a ready engine.
  static Future<JustAudioEngine> create() async {
    final player = AudioPlayer();
    final handler = await svc.AudioService.init(
      builder: () => DhammaAudioHandler(player),
      config: const svc.AudioServiceConfig(
        androidNotificationChannelId: 'com.aungmyokyaw.dhammaecho.playback',
        androidNotificationChannelName: 'Dhamma Echo playback',
        androidNotificationOngoing: true,
      ),
    );
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    return JustAudioEngine._(player, handler);
  }

  final AudioPlayer _player;
  final DhammaAudioHandler _handler;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  Stream<EngineState> get stateStream => _player.processingStateStream.map(
    (s) => switch (s) {
      ProcessingState.idle => EngineState.idle,
      ProcessingState.loading ||
      ProcessingState.buffering => EngineState.loading,
      ProcessingState.ready => EngineState.ready,
      ProcessingState.completed => EngineState.completed,
    },
  );

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  bool get playing => _player.playing;

  @override
  set onSkipNext(void Function()? callback) => _handler.onSkipNext = callback;

  @override
  set onSkipPrevious(void Function()? callback) =>
      _handler.onSkipPrevious = callback;

  @override
  Future<void> load(
    MediaItem media, {
    String? filePath,
    Uri? remote,
    Duration? start,
  }) async {
    _handler.mediaItem.add(
      svc.MediaItem(
        id: media.id.toString(),
        title: media.displayTitle,
        artist: media.teacherName,
        album: 'Dhamma Echo',
      ),
    );
    final source = filePath != null
        ? AudioSource.file(filePath)
        : AudioSource.uri(remote!);
    await _player.setAudioSource(source, initialPosition: start);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
