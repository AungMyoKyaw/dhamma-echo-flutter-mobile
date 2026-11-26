import 'dart:async';

import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Local-only, writable state: settings, bookmarks, resume positions and
/// download records. Nothing here ever leaves the device.
class UserStateRepository {
  UserStateRepository(this._db);

  final Database _db;
  Future<void> _writeQueue = Future<void>.value();

  static const schemaVersion = 1;

  static Future<void> createSchema(Database db, int version) async {
    await db.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE saved_items (media_id INTEGER PRIMARY KEY, saved_at INTEGER NOT NULL)',
    );
    await db.execute('''
      CREATE TABLE playback_history (
        media_id INTEGER PRIMARY KEY,
        position_ms INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE downloads (
        media_id INTEGER PRIMARY KEY,
        status TEXT NOT NULL,
        received_bytes INTEGER NOT NULL DEFAULT 0,
        total_bytes INTEGER NOT NULL DEFAULT 0,
        local_path TEXT,
        error TEXT,
        updated_at INTEGER NOT NULL
      )''');
  }

  static Future<UserStateRepository> open(String path) async {
    final db = await openDatabase(
      path,
      version: schemaVersion,
      onCreate: createSchema,
    );
    return UserStateRepository(db);
  }

  /// Serialises writes so concurrent saves never interleave.
  Future<T> _write<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  // ── Settings ────────────────────────────────────────────────────────────

  Future<AppSettings> loadSettings() async {
    final rows = await _db.query('settings');
    final map = {
      for (final r in rows) r['key']! as String: r['value']! as String,
    };
    const defaults = AppSettings();
    return AppSettings(
      language: map['language'] == 'my' ? 'my' : 'en',
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == map['themeMode'],
        orElse: () => defaults.themeMode,
      ),
      playbackSpeed:
          double.tryParse(map['playbackSpeed'] ?? '') ?? defaults.playbackSpeed,
      wifiOnly: map['wifiOnly'] == null
          ? defaults.wifiOnly
          : map['wifiOnly'] == 'true',
      showLegacy: map['showLegacy'] == null
          ? defaults.showLegacy
          : map['showLegacy'] == 'true',
      pdfTint: PdfTint.values.firstWhere(
        (m) => m.name == map['pdfTint'],
        orElse: () => defaults.pdfTint,
      ),
    );
  }

  Future<void> saveSettings(AppSettings s) => _write(() async {
    final batch = _db.batch();
    void put(String k, String v) => batch.insert('settings', {
      'key': k,
      'value': v,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    put('language', s.language);
    put('themeMode', s.themeMode.name);
    put('playbackSpeed', s.playbackSpeed.toString());
    put('wifiOnly', s.wifiOnly.toString());
    put('showLegacy', s.showLegacy.toString());
    put('pdfTint', s.pdfTint.name);
    await batch.commit(noResult: true);
  });

  // ── Saved items ─────────────────────────────────────────────────────────

  Future<List<int>> savedIds() async {
    final rows = await _db.query('saved_items', orderBy: 'saved_at DESC');
    return [for (final r in rows) r['media_id']! as int];
  }

  Future<void> setSaved(int mediaId, {required bool saved}) => _write(() async {
    if (saved) {
      await _db.insert('saved_items', {
        'media_id': mediaId,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await _db.delete(
        'saved_items',
        where: 'media_id = ?',
        whereArgs: [mediaId],
      );
    }
  });

  // ── Playback history ────────────────────────────────────────────────────

  Future<void> recordProgress(
    int mediaId, {
    required int positionMs,
    required int durationMs,
  }) => _write(
    () => _db.insert('playback_history', {
      'media_id': mediaId,
      'position_ms': positionMs,
      'duration_ms': durationMs,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace),
  );

  HistoryEntry _history(Map<String, Object?> r) => HistoryEntry(
    mediaId: r['media_id']! as int,
    positionMs: r['position_ms']! as int,
    durationMs: r['duration_ms']! as int,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at']! as int),
  );

  Future<List<HistoryEntry>> history({int limit = 50}) async {
    final rows = await _db.query(
      'playback_history',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(_history).toList();
  }

  Future<HistoryEntry?> progressFor(int mediaId) async {
    final rows = await _db.query(
      'playback_history',
      where: 'media_id = ?',
      whereArgs: [mediaId],
    );
    return rows.isEmpty ? null : _history(rows.first);
  }

  Future<void> clearHistory() => _write(() => _db.delete('playback_history'));

  // ── Downloads ───────────────────────────────────────────────────────────

  Future<List<DownloadRecord>> downloads() async {
    final rows = await _db.query('downloads', orderBy: 'updated_at DESC');
    return rows.map(DownloadRecord.fromRow).toList();
  }

  Future<void> upsertDownload(DownloadRecord r) => _write(
    () => _db.insert('downloads', {
      'media_id': r.mediaId,
      'status': r.status.name,
      'received_bytes': r.receivedBytes,
      'total_bytes': r.totalBytes,
      'local_path': r.localPath,
      'error': r.error,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace),
  );

  Future<void> deleteDownload(int mediaId) => _write(
    () => _db.delete('downloads', where: 'media_id = ?', whereArgs: [mediaId]),
  );

  Future<void> deleteAllDownloads() => _write(() => _db.delete('downloads'));

  Future<void> close() => _db.close();
}
