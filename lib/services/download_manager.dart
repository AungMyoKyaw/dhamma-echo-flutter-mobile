import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../data/user_state_repository.dart';
import '../models/models.dart';
import 'connectivity_service.dart';

class DownloadTask {
  DownloadTask({required this.done, required this.cancel});

  final Future<void> done;
  final void Function() cancel;
}

abstract class FileDownloader {
  DownloadTask start(
    Uri url,
    String savePath,
    void Function(int received, int total) onProgress,
  );
}

class DioDownloader implements FileDownloader {
  DioDownloader([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  DownloadTask start(
    Uri url,
    String savePath,
    void Function(int received, int total) onProgress,
  ) {
    final token = CancelToken();
    final done = _dio
        .download(
          url.toString(),
          savePath,
          cancelToken: token,
          onReceiveProgress: onProgress,
          options: Options(
            followRedirects: true,
            receiveTimeout: const Duration(minutes: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        )
        .then<void>((_) {});
    return DownloadTask(done: done, cancel: () => token.cancel('canceled'));
  }
}

enum EnqueueResult { started, alreadyDownloaded, blockedByWifi, unsupported }

/// Persisted in-app download queue with limited concurrency.
class DownloadManager extends ChangeNotifier {
  DownloadManager({
    required UserStateRepository repository,
    required this._downloader,
    required this._connectivity,
    required this._directory,
    required this._wifiOnly,
    this.maxConcurrent = 2,
  }) : _repo = repository;

  final UserStateRepository _repo;
  final FileDownloader _downloader;
  final ConnectivityService _connectivity;
  final Future<Directory> Function() _directory;
  final bool Function() _wifiOnly;
  final int maxConcurrent;

  final Map<int, DownloadRecord> _records = {};
  final List<MediaItem> _pending = [];
  final Map<int, DownloadTask> _running = {};
  final Map<int, MediaItem> _media = {};
  bool _disposed = false;

  Map<int, DownloadRecord> get records => Map.unmodifiable(_records);

  List<DownloadRecord> get all => _records.values.toList();

  List<DownloadRecord> get active =>
      all.where((r) => r.isActive).toList(growable: false);

  List<DownloadRecord> get completed => all
      .where((r) => r.status == DownloadStatus.completed)
      .toList(growable: false);

  List<DownloadRecord> get failed => all
      .where(
        (r) =>
            r.status == DownloadStatus.failed ||
            r.status == DownloadStatus.canceled,
      )
      .toList(growable: false);

  DownloadRecord? recordFor(int mediaId) => _records[mediaId];

  /// Local file for a completed download, or null if absent/missing on disk.
  String? localPathFor(int mediaId) {
    final r = _records[mediaId];
    if (r == null || r.status != DownloadStatus.completed) return null;
    final path = r.localPath;
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  Future<void> init() async {
    final stored = await _repo.downloads();
    for (final r in stored) {
      if (r.isActive) {
        // The app was closed mid-download; surface it as retryable.
        final interrupted = r.copyWith(
          status: DownloadStatus.failed,
          error: 'interrupted',
        );
        _records[r.mediaId] = interrupted;
        await _repo.upsertDownload(interrupted);
      } else if (r.status == DownloadStatus.completed &&
          (r.localPath == null || !File(r.localPath!).existsSync())) {
        await _repo.deleteDownload(r.mediaId);
      } else {
        _records[r.mediaId] = r;
      }
    }
    _notify();
  }

  Future<EnqueueResult> enqueue(MediaItem item) async {
    final result = await enqueueAll([item]);
    return result;
  }

  Future<EnqueueResult> enqueueAll(List<MediaItem> items) async {
    final usable = items.where((m) => m.remoteUri != null).toList();
    if (usable.isEmpty) return EnqueueResult.unsupported;
    if (_wifiOnly() && !await _connectivity.isUnmetered()) {
      return EnqueueResult.blockedByWifi;
    }
    var started = 0;
    for (final item in usable) {
      if (localPathFor(item.id) != null) continue;
      if (_running.containsKey(item.id) ||
          _pending.any((m) => m.id == item.id)) {
        continue;
      }
      _media[item.id] = item;
      _pending.add(item);
      await _setRecord(
        DownloadRecord(mediaId: item.id, status: DownloadStatus.queued),
      );
      started++;
    }
    unawaited(_pump());
    return started == 0
        ? EnqueueResult.alreadyDownloaded
        : EnqueueResult.started;
  }

  Future<void> retry(MediaItem item) => enqueue(item).then((_) {});

  Future<void> cancel(int mediaId) async {
    _pending.removeWhere((m) => m.id == mediaId);
    final task = _running.remove(mediaId);
    task?.cancel();
    final r = _records[mediaId];
    if (r != null && r.isActive) {
      await _setRecord(r.copyWith(status: DownloadStatus.canceled));
    }
    await _deletePartial(mediaId);
    unawaited(_pump());
  }

  Future<void> remove(int mediaId) async {
    await cancel(mediaId);
    final path = _records[mediaId]?.localPath;
    if (path != null) {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    }
    _records.remove(mediaId);
    await _repo.deleteDownload(mediaId);
    _notify();
  }

  Future<void> clearAll() async {
    for (final id in _records.keys.toList()) {
      await remove(id);
    }
    await _repo.deleteAllDownloads();
  }

  /// Total bytes used by completed downloads on disk.
  int storageBytes() {
    var total = 0;
    for (final r in completed) {
      final path = r.localPath;
      if (path == null) continue;
      final f = File(path);
      if (f.existsSync()) total += f.lengthSync();
    }
    return total;
  }

  Future<String> _target(MediaItem item) async {
    final dir = await _directory();
    await dir.create(recursive: true);
    return p.join(dir.path, '${item.id}.${item.format}');
  }

  Future<void> _deletePartial(int mediaId) async {
    final item = _media[mediaId];
    if (item == null) return;
    final part = File('${await _target(item)}.part');
    if (part.existsSync()) await part.delete();
  }

  Future<void> _pump() async {
    while (_running.length < maxConcurrent && _pending.isNotEmpty) {
      final item = _pending.removeAt(0);
      _running[item.id] = DownloadTask(
        done: Future<void>.value(),
        cancel: () {},
      );
      unawaited(_run(item));
    }
  }

  Future<void> _run(MediaItem item) async {
    final uri = item.remoteUri;
    if (uri == null) {
      _running.remove(item.id);
      await _setRecord(
        DownloadRecord(
          mediaId: item.id,
          status: DownloadStatus.failed,
          error: 'unsupported',
        ),
      );
      unawaited(_pump());
      return;
    }
    if (_wifiOnly() && !await _connectivity.isUnmetered()) {
      _running.remove(item.id);
      await _setRecord(
        DownloadRecord(
          mediaId: item.id,
          status: DownloadStatus.failed,
          error: 'wifi',
        ),
      );
      unawaited(_pump());
      return;
    }
    final target = await _target(item);
    final part = '$target.part';
    var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    await _setRecord(
      DownloadRecord(mediaId: item.id, status: DownloadStatus.downloading),
      persist: false,
    );
    final task = _downloader.start(uri, part, (received, total) {
      final r = _records[item.id];
      if (r == null || r.status != DownloadStatus.downloading) return;
      _records[item.id] = r.copyWith(
        receivedBytes: received,
        totalBytes: total > 0 ? total : 0,
      );
      final now = DateTime.now();
      if (now.difference(lastNotify) > const Duration(milliseconds: 250)) {
        lastNotify = now;
        _notify();
      }
    });
    _running[item.id] = task;
    try {
      await task.done;
      final done = File(part);
      if (!done.existsSync()) throw const FileSystemException('missing file');
      final finalFile = await done.rename(target);
      final size = await finalFile.length();
      _running.remove(item.id);
      await _setRecord(
        DownloadRecord(
          mediaId: item.id,
          status: DownloadStatus.completed,
          receivedBytes: size,
          totalBytes: size,
          localPath: target,
        ),
      );
    } on Object catch (e) {
      final wasCanceled = _records[item.id]?.status == DownloadStatus.canceled;
      _running.remove(item.id);
      if (!wasCanceled) {
        await _setRecord(
          DownloadRecord(
            mediaId: item.id,
            status: DownloadStatus.failed,
            error: e.toString(),
          ),
        );
        final f = File(part);
        if (f.existsSync()) await f.delete();
      }
    }
    unawaited(_pump());
  }

  Future<void> _setRecord(DownloadRecord r, {bool persist = true}) async {
    _records[r.mediaId] = r;
    _notify();
    if (persist) await _repo.upsertDownload(r);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _running.values) {
      t.cancel();
    }
    super.dispose();
  }
}
