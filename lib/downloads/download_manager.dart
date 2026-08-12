import 'dart:async';
import 'dart:io';

import 'package:dhamma_echo/core/media_url_policy.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/downloads/download_client.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class DownloadManager extends ChangeNotifier {
  DownloadManager({required Directory directory, DownloadClient? client})
    : _directory = directory,
      _client = client ?? IoDownloadClient();

  final Directory _directory;
  final DownloadClient _client;
  final Set<int> _downloadedIds = <int>{};
  final Set<int> _activeIds = <int>{};
  final Map<int, double> _progress = <int, double>{};
  final Map<int, String> _errors = <int, String>{};
  bool _initialized = false;

  Set<int> get downloadedIds => Set<int>.unmodifiable(_downloadedIds);

  bool isDownloaded(int trackId) => _downloadedIds.contains(trackId);
  bool isDownloading(int trackId) => _activeIds.contains(trackId);
  double? progressFor(int trackId) => _progress[trackId];
  String errorFor(int trackId) => _errors[trackId] ?? '';

  Uri? localUriFor(int trackId) {
    if (!_downloadedIds.contains(trackId)) return null;
    return File(_completedPath(trackId)).uri;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await _directory.create(recursive: true);
    await for (final entity in _directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.endsWith('.part')) {
        await entity.delete();
        continue;
      }
      final match = RegExp(r'^(\d+)\.mp3$').firstMatch(name);
      final id = match == null ? null : int.tryParse(match.group(1)!);
      if (id != null) _downloadedIds.add(id);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> download(AudioTrack track) async {
    if (!_initialized) await initialize();
    if (_downloadedIds.contains(track.id)) return true;
    if (_activeIds.contains(track.id)) return false;

    final candidates = mediaUrlCandidates(track.url, track.format);
    if (!track.playable || candidates.isEmpty) {
      _errors[track.id] = track.format.toLowerCase() == 'mp3'
          ? 'This audio source is not trusted.'
          : 'Only playable MP3 talks can be downloaded.';
      notifyListeners();
      return false;
    }

    _activeIds.add(track.id);
    _progress[track.id] = 0;
    _errors.remove(track.id);
    notifyListeners();

    Object? lastError;
    try {
      for (final candidate in candidates) {
        try {
          await _downloadCandidate(track.id, candidate);
          _downloadedIds.add(track.id);
          _errors.remove(track.id);
          notifyListeners();
          return true;
        } on Object catch (error) {
          lastError = error;
          await _deleteIfExists(File(_partialPath(track.id)));
        }
      }

      _errors[track.id] = _downloadErrorMessage(lastError);
      notifyListeners();
      return false;
    } finally {
      _activeIds.remove(track.id);
      _progress.remove(track.id);
      notifyListeners();
    }
  }

  Future<void> _downloadCandidate(int trackId, Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.bytes.drain<void>();
      throw HttpException(
        'Download returned HTTP ${response.statusCode}.',
        uri: uri,
      );
    }

    final partial = File(_partialPath(trackId));
    final completed = File(_completedPath(trackId));
    await _deleteIfExists(partial);
    final sink = partial.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.bytes) {
        if (chunk.isEmpty) continue;
        sink.add(chunk);
        received += chunk.length;
        if (response.contentLength > 0) {
          _progress[trackId] = (received / response.contentLength)
              .clamp(0.0, 1.0)
              .toDouble();
          notifyListeners();
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (received <= 0) {
      throw const FileSystemException('Downloaded audio was empty.');
    }
    if (response.contentLength > 0 && received != response.contentLength) {
      throw const FileSystemException('Downloaded audio was incomplete.');
    }
    await _deleteIfExists(completed);
    await partial.rename(completed.path);
  }

  Future<bool> delete(int trackId) async {
    if (!_initialized) await initialize();
    if (_activeIds.contains(trackId)) return false;
    await _deleteIfExists(File(_completedPath(trackId)));
    final removed = _downloadedIds.remove(trackId);
    _errors.remove(trackId);
    _progress.remove(trackId);
    if (removed) notifyListeners();
    return true;
  }

  String _completedPath(int trackId) =>
      p.join(_directory.path, '$trackId.mp3');
  String _partialPath(int trackId) =>
      p.join(_directory.path, '$trackId.mp3.part');

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }

  String _downloadErrorMessage(Object? error) {
    if (error == null) return 'The audio download failed.';
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
