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
  int _completionEpoch = 0;
  int _playGeneration = 0;
  final ValueNotifier<int> _controls = ValueNotifier<int>(0);

  AudioTrack? get current => _current;
  List<AudioTrack> get queue => List<AudioTrack>.unmodifiable(_queue);
  AudioTrack? get nextInQueue => _queue.isEmpty ? null : _queue.first;
  bool get playing => _playing;
  bool get loading => _loading;
  Duration get position => _position;
  Duration get duration => _duration;
  String get error => _error;
  double get volume => _volume;
  double get rate => _rate;
  int get completionEpoch => _completionEpoch;
  ValueListenable<int> get controls => _controls;

  Future<bool> play(
    AudioTrack track, {
    double resumeAt = 0,
    Uri? preferredUri,
  }) async {
    final remoteCandidates = mediaUrlCandidates(track.url, track.format);
    if (!track.playable || remoteCandidates.isEmpty) {
      _error = track.format.toLowerCase() == 'mp3'
          ? 'This audio source is not trusted.'
          : 'This audio format is not supported by the mobile player.';
      _notify(controls: true);
      return false;
    }

    final generation = ++_playGeneration;
    final candidates = <Uri>[
      if (preferredUri != null && preferredUri.scheme == 'file') preferredUri,
      ...remoteCandidates,
    ];
    _loading = true;
    _error = '';
    _notify(controls: true);

    for (final candidate in candidates) {
      try {
        await _port.load(track, candidate);
        await _port.setVolume(_volume);
        await _port.setSpeed(_rate);
        final resumePosition = resumeAt.isFinite && resumeAt > 0
            ? Duration(milliseconds: (resumeAt * 1000).round())
            : Duration.zero;
        if (resumePosition > Duration.zero) {
          await _port.seek(resumePosition);
        }

        _current = track;
        _position = resumePosition;
        _duration = Duration.zero;
        _loading = false;
        _playing = true;
        _notify(controls: true);
        unawaited(_startPlayback(generation));
        return true;
      } on Object {
        // Local media may disappear and approved hosts may be temporarily
        // unavailable. Only the explicitly constructed candidates are tried.
      }
    }

    if (generation != _playGeneration) return false;
    _loading = false;
    _playing = false;
    _error = 'The audio stream is unavailable from Dhamma Download.';
    _notify(controls: true);
    return false;
  }

  Future<void> _startPlayback(int generation) async {
    try {
      await _port.play();
    } on Object {
      if (generation != _playGeneration) return;
      _playing = false;
      _loading = false;
      _error = 'Audio playback failed.';
      _notify(controls: true);
    }
  }

  Future<void> toggle() async {
    if (_current == null) return;
    if (_playing) {
      ++_playGeneration;
      await _port.pause();
      _playing = false;
      _notify(controls: true);
      return;
    }

    final generation = ++_playGeneration;
    _error = '';
    _playing = true;
    _notify(controls: true);
    unawaited(_startPlayback(generation));
  }

  Future<void> seek(Duration value) async {
    final maximum = _duration > Duration.zero
        ? _duration
        : const Duration(days: 365);
    final milliseconds = value.inMilliseconds
        .clamp(0, maximum.inMilliseconds)
        .toInt();
    _position = Duration(milliseconds: milliseconds);
    await _port.seek(_position);
    notifyListeners();
  }

  Future<void> jump(int seconds) =>
      seek(_position + Duration(seconds: seconds));

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
    if (_current?.id == track.id ||
        _queue.any((candidate) => candidate.id == track.id)) {
      return;
    }
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

  Future<bool> playNext({double resumeAt = 0, Uri? preferredUri}) async {
    if (_queue.isEmpty) return false;
    final next = _queue.first;
    final didPlay = await play(
      next,
      resumeAt: resumeAt,
      preferredUri: preferredUri,
    );
    if (didPlay && _queue.isNotEmpty && _queue.first.id == next.id) {
      _queue.removeAt(0);
      notifyListeners();
    }
    return didPlay;
  }

  void _handleEvent(PlaybackPortEvent event) {
    switch (event) {
      case PlaybackStateEvent(:final playing, :final loading):
        _playing = playing;
        _loading = loading;
        _notify(controls: true);
        return;
      case PlaybackPositionEvent(:final position):
        _position = position;
      case PlaybackDurationEvent(:final duration):
        _duration = duration;
      case PlaybackEndedEvent():
        _playing = false;
        _position = Duration.zero;
        _completionEpoch += 1;
        _notify(controls: true);
        return;
      case PlaybackErrorEvent(:final message):
        _error = message;
        _playing = false;
        _loading = false;
        _notify(controls: true);
        return;
    }
    notifyListeners();
  }

  void _notify({bool controls = false}) {
    if (controls) _controls.value += 1;
    notifyListeners();
  }

  @override
  void dispose() {
    ++_playGeneration;
    unawaited(_subscription.cancel());
    unawaited(_port.dispose());
    _controls.dispose();
    super.dispose();
  }
}
