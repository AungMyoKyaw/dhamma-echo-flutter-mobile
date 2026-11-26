import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/user_state_repository.dart';
import '../models/models.dart';
import 'audio_engine.dart';

enum SleepMode { off, minutes, endOfTrack }

/// Queue, transport, resume and sleep-timer logic for audio talks.
class AudioPlaybackController extends ChangeNotifier {
  AudioPlaybackController({
    required this._engine,
    this._userState,
    this._localPathFor,
    double defaultSpeed = 1.0,
    this.onHistoryChanged,
  }) : _speed = defaultSpeed {
    _engine.onSkipNext = () => unawaited(next());
    _engine.onSkipPrevious = () => unawaited(previous());
    _subs.addAll([
      _engine.positionStream.listen(_onPosition),
      _engine.durationStream.listen((d) {
        _duration = d ?? Duration.zero;
        notifyListeners();
      }),
      _engine.playingStream.listen((p) {
        _playing = p;
        if (!p) _persistProgress();
        notifyListeners();
      }),
      _engine.stateStream.listen(_onState),
    ]);
  }

  static const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  static const sleepOptions = [15, 30, 45];

  final AudioEngine _engine;
  final UserStateRepository? _userState;
  final String? Function(int mediaId)? _localPathFor;
  final VoidCallback? onHistoryChanged;
  final List<StreamSubscription<Object?>> _subs = [];

  List<MediaItem> _queue = const [];
  int _index = -1;
  bool _playing = false;
  bool _loading = false;
  bool _error = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed;
  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;

  SleepMode _sleepMode = SleepMode.off;
  int _sleepMinutes = 0;
  DateTime? _sleepEndsAt;
  Timer? _sleepTicker;

  List<MediaItem> get queue => _queue;
  int get index => _index;
  MediaItem? get current =>
      _index >= 0 && _index < _queue.length ? _queue[_index] : null;
  List<MediaItem> get upNext => _index >= 0 && _index + 1 < _queue.length
      ? _queue.sublist(_index + 1)
      : const [];
  bool get hasCurrent => current != null;
  bool get playing => _playing;
  bool get loading => _loading;
  bool get hasError => _error;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  double get fraction => _duration.inMilliseconds > 0
      ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
      : 0;
  bool get hasNext => _index + 1 < _queue.length;
  bool get isCurrentOffline =>
      current != null && _localPathFor?.call(current!.id) != null;

  SleepMode get sleepMode => _sleepMode;
  int get sleepMinutes => _sleepMinutes;
  Duration? get sleepRemaining {
    final end = _sleepEndsAt;
    if (end == null) return null;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Short label for the utility bar, e.g. `30m` / `End`, or null when off.
  String? get sleepLabel => switch (_sleepMode) {
    SleepMode.off => null,
    SleepMode.minutes => '${_sleepMinutes}m',
    SleepMode.endOfTrack => 'End',
  };

  Future<void> playQueue(List<MediaItem> items, int startIndex) async {
    if (items.isEmpty) return;
    _queue = List.unmodifiable(items);
    await _playIndex(startIndex.clamp(0, items.length - 1));
  }

  Future<void> playItem(MediaItem item) => playQueue([item], 0);

  Future<void> _playIndex(int i, {bool autoPlay = true}) async {
    await _persistProgress(force: true);
    _index = i;
    _error = false;
    _loading = true;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    final item = _queue[i];
    try {
      final local = _localPathFor?.call(item.id);
      final remote = item.remoteUri;
      if (local == null && remote == null) {
        throw StateError('No playable source for ${item.id}');
      }
      final saved = await _userState?.progressFor(item.id);
      Duration? start;
      if (saved != null && saved.positionMs > 5000) {
        final nearEnd =
            saved.durationMs > 0 && saved.positionMs > saved.durationMs - 10000;
        if (!nearEnd) start = Duration(milliseconds: saved.positionMs);
      }
      await _engine.load(item, filePath: local, remote: remote, start: start);
      await _engine.setSpeed(_speed);
      _loading = false;
      if (autoPlay) {
        notifyListeners();
        unawaited(_engine.play());
      }
    } on Object catch (e, s) {
      debugPrint('Playback failed: $e\n$s');
      _loading = false;
      _error = true;
      _playing = false;
    }
    if (!_disposed) notifyListeners();
  }

  /// Loads an item without starting playback (used when resuming from Home).
  Future<void> prepare(MediaItem item) async {
    _queue = List.unmodifiable([item]);
    await _playIndex(0, autoPlay: false);
  }

  Future<void> togglePlay() async {
    if (!hasCurrent) return;
    if (_error) {
      await _playIndex(_index);
      return;
    }
    if (_playing) {
      await _engine.pause();
    } else {
      await _engine.play();
    }
  }

  Future<void> seekTo(Duration target) async {
    final max = _duration;
    var t = target < Duration.zero ? Duration.zero : target;
    if (max > Duration.zero && t > max) t = max;
    _position = t;
    notifyListeners();
    await _engine.seek(t);
  }

  Future<void> skipForward() => seekTo(_position + const Duration(seconds: 15));

  Future<void> skipBack() => seekTo(_position - const Duration(seconds: 15));

  Future<void> next() async {
    if (hasNext) await _playIndex(_index + 1);
  }

  Future<void> previous() async {
    if (_position > const Duration(seconds: 3) || _index <= 0) {
      await seekTo(Duration.zero);
    } else {
      await _playIndex(_index - 1);
    }
  }

  Future<void> jumpTo(int queueIndex) async {
    if (queueIndex >= 0 && queueIndex < _queue.length) {
      await _playIndex(queueIndex);
    }
  }

  /// Drops everything after the current item.
  void clearUpNext() {
    if (_index < 0) return;
    _queue = List.unmodifiable(_queue.sublist(0, _index + 1));
    notifyListeners();
  }

  Future<void> setSpeed(double value) async {
    _speed = value;
    notifyListeners();
    await _engine.setSpeed(value);
  }

  Future<void> stop() async {
    await _persistProgress(force: true);
    await _engine.stop();
    _queue = const [];
    _index = -1;
    _playing = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    cancelSleep();
    notifyListeners();
  }

  // ── Sleep timer ─────────────────────────────────────────────────────────

  void setSleepMinutes(int minutes) {
    _cancelTicker();
    _sleepMode = SleepMode.minutes;
    _sleepMinutes = minutes;
    _sleepEndsAt = DateTime.now().add(Duration(minutes: minutes));
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = sleepRemaining;
      if (left == null) return;
      if (left <= Duration.zero) {
        cancelSleep();
        unawaited(_engine.pause());
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void setSleepEndOfTrack() {
    _cancelTicker();
    _sleepMode = SleepMode.endOfTrack;
    _sleepMinutes = 0;
    _sleepEndsAt = null;
    notifyListeners();
  }

  void cancelSleep() {
    _cancelTicker();
    _sleepMode = SleepMode.off;
    _sleepMinutes = 0;
    _sleepEndsAt = null;
    if (!_disposed) notifyListeners();
  }

  void _cancelTicker() {
    _sleepTicker?.cancel();
    _sleepTicker = null;
  }

  // ── Engine events ───────────────────────────────────────────────────────

  void _onPosition(Duration p) {
    _position = p;
    notifyListeners();
    if (_playing &&
        DateTime.now().difference(_lastPersist) > const Duration(seconds: 5)) {
      unawaited(_persistProgress());
    }
  }

  void _onState(EngineState state) {
    if (state == EngineState.completed) {
      unawaited(_onCompleted());
    }
  }

  Future<void> _onCompleted() async {
    final item = current;
    if (item != null) {
      await _userState?.recordProgress(
        item.id,
        positionMs: 0,
        durationMs: _duration.inMilliseconds,
      );
      onHistoryChanged?.call();
    }
    if (_sleepMode == SleepMode.endOfTrack) {
      cancelSleep();
      await _engine.pause();
      return;
    }
    if (hasNext) {
      await next();
    } else {
      _playing = false;
      notifyListeners();
    }
  }

  Future<void> _persistProgress({bool force = false}) async {
    final item = current;
    final repo = _userState;
    if (item == null || repo == null) return;
    if (!force && _position == Duration.zero) return;
    _lastPersist = DateTime.now();
    await repo.recordProgress(
      item.id,
      positionMs: _position.inMilliseconds,
      durationMs: _duration.inMilliseconds,
    );
    onHistoryChanged?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTicker();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    unawaited(_persistProgress(force: true));
    unawaited(_engine.dispose());
    super.dispose();
  }
}
