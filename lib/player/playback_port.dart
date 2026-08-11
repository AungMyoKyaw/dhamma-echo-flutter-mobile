import 'dart:async';

import 'package:just_audio/just_audio.dart';

sealed class PlaybackPortEvent {
  const PlaybackPortEvent();
}

class PlaybackStateEvent extends PlaybackPortEvent {
  const PlaybackStateEvent({required this.playing, required this.loading});
  final bool playing;
  final bool loading;
}

class PlaybackPositionEvent extends PlaybackPortEvent {
  const PlaybackPositionEvent(this.position);
  final Duration position;
}

class PlaybackDurationEvent extends PlaybackPortEvent {
  const PlaybackDurationEvent(this.duration);
  final Duration duration;
}

class PlaybackEndedEvent extends PlaybackPortEvent {
  const PlaybackEndedEvent();
}

class PlaybackErrorEvent extends PlaybackPortEvent {
  const PlaybackErrorEvent(this.message);
  final String message;
}

abstract interface class PlaybackPort {
  Stream<PlaybackPortEvent> get events;
  Future<void> load(Uri uri);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double value);
  Future<void> setSpeed(double value);
  Future<void> dispose();
}

class JustAudioPlaybackPort implements PlaybackPort {
  JustAudioPlaybackPort({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        _events.add(
          PlaybackStateEvent(
            playing: state.playing,
            loading:
                state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering,
          ),
        );
        if (state.processingState == ProcessingState.completed) {
          _events.add(const PlaybackEndedEvent());
        }
      }),
    );
    _subscriptions.add(
      _player.positionStream.listen(
        (position) => _events.add(PlaybackPositionEvent(position)),
      ),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (duration != null) _events.add(PlaybackDurationEvent(duration));
      }),
    );
    _subscriptions.add(
      _player.errorStream.listen(
        (error) => _events.add(
          PlaybackErrorEvent(error.message ?? 'Audio playback failed.'),
        ),
      ),
    );
  }

  final AudioPlayer _player;
  final StreamController<PlaybackPortEvent> _events =
      StreamController<PlaybackPortEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  @override
  Stream<PlaybackPortEvent> get events => _events.stream;

  @override
  Future<void> load(Uri uri) async {
    await _player.setUrl(uri.toString());
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double value) => _player.setVolume(value);

  @override
  Future<void> setSpeed(double value) => _player.setSpeed(value);

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _events.close();
    await _player.dispose();
  }
}
