import 'dart:async';

import 'package:dhamma_echo/core/media_url_policy.dart';
import 'package:dhamma_echo/core/text_utils.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter/foundation.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController(this._port) {
    _subscription = _port.events.listen(_handleEvent);
  }

  final PlaybackPort _port;
  late final StreamSubscription<PlaybackPortEvent> _subscription;
  final List<AudioTrack> _queue = <AudioTrack>[];

  AudioTrack? _current;
  bool _playing = false;
  bool _loading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String _error = '';
  double _volume = 0.8;
  double _rate = 1;

  AudioTrack? get current => _current;
  List<AudioTrack> get queue => List<AudioTrack>.unmodifiable(_queue);
  bool get playing => _playing;
  bool get loading => _loading;
  Duration get position => _position;
  Duration get duration => _duration;
  String get error => _error;
  double get volume => _volume;
  double get rate => _rate;

  Future<bool> play(AudioTrack track, {double resumeAt = 0}) async {
    final candidates = mediaUrlCandidates(track.url, track.format);
    if (!track.playable || candidates.isEmpty) {
      _error = track.format.toLowerCase() == 'mp3'
          ? 'This audio source is not trusted.'
          : 'This audio format is not supported by the mobile player.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = '';
    notifyListeners();
    for (final candidate in candidates) {
      try {
        await _port.load(candidate);
        await _port.setVolume(_volume);
        await _port.setSpeed(_rate);
        if (resumeAt.isFinite && resumeAt > 0) {
          await _port.seek(Duration(milliseconds: (resumeAt * 1000).round()));
        }
        await _port.play();
        _current = track;
        _loading = false;
        _playing = true;
        notifyListeners();
        return true;
      } on Object {
        // The only allowed fallback is the alternate approved hostname.
      }
    }
    _loading = false;
    _playing = false;
    _error = 'The audio stream is unavailable from Dhamma Download.';
    notifyListeners();
    return false;
  }

  Future<void> toggle() async {
    if (_current == null) return;
    if (_playing) {
      await _port.pause();
      _playing = false;
    } else {
      await _port.play();
      _playing = true;
    }
    notifyListeners();
  }

  Future<void> seek(Duration value) async {
    final maximum = _duration > Duration.zero ? _duration : const Duration(days: 365);
    final milliseconds = value.inMilliseconds.clamp(0, maximum.inMilliseconds);
    _position = Duration(milliseconds: milliseconds);
    await _port.seek(_position);
    notifyListeners();
  }

  Future<void> jump(int seconds) => seek(_position + Duration(seconds: seconds));

  Future<void> setVolume(double value) async {
    _volume = clampFinite(value, 0, 1);
    await _port.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setRate(double value) async {
    _rate = clampFinite(value, 0.75, 2);
    await _port.setSpeed(_rate);
    notifyListeners();
  }

  void enqueue(AudioTrack track) {
    if (_current?.id == track.id || _queue.any((candidate) => candidate.id == track.id)) return;
    _queue.add(track);
    notifyListeners();
  }

  void removeFromQueue(int id) {
    _queue.removeWhere((track) => track.id == id);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  Future<bool> playNext() async {
    if (_queue.isEmpty) return false;
    final next = _queue.removeAt(0);
    return play(next);
  }

  void _handleEvent(PlaybackPortEvent event) {
    switch (event) {
      case PlaybackStateEvent(:final playing, :final loading):
        _playing = playing;
        _loading = loading;
      case PlaybackPositionEvent(:final position):
        _position = position;
      case PlaybackDurationEvent(:final duration):
        _duration = duration;
      case PlaybackEndedEvent():
        _playing = false;
        unawaited(playNext());
      case PlaybackErrorEvent(:final message):
        _error = message;
        _loading = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_port.dispose());
    super.dispose();
  }
}
