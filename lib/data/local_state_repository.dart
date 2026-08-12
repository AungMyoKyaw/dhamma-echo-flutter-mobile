import 'dart:convert';
import 'dart:io';

import 'package:dhamma_echo/domain/models.dart';

class LocalStateRepository {
  LocalStateRepository(this._file);

  static const int version = 1;
  static const List<double> allowedRates = <double>[
    0.75,
    1,
    1.25,
    1.5,
    1.75,
    2,
  ];

  final File _file;
  Future<void> _pendingSave = Future<void>.value();

  Future<PersistedState> load() async {
    if (!await _file.exists()) return const PersistedState.defaults();
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map<String, Object?> || decoded['version'] != version) {
        return const PersistedState.defaults();
      }
      return PersistedState(
        library: _decodeLibrary(decoded['library']),
        settings: _decodeSettings(decoded['settings']),
      );
    } on FormatException {
      return const PersistedState.defaults();
    } on FileSystemException {
      return const PersistedState.defaults();
    }
  }

  Future<void> save(PersistedState state) {
    final sanitized = PersistedState(
      library: _sanitizeLibrary(state.library),
      settings: _sanitizeSettings(state.settings),
    );
    final save = _pendingSave.then((_) => _write(sanitized));
    _pendingSave = save.catchError((_) {});
    return save;
  }

  Future<void> _write(PersistedState state) async {
    await _file.parent.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(_encode(state)), flush: true);
    if (await _file.exists()) await _file.delete();
    await temporary.rename(_file.path);
  }

  Map<String, Object?> _encode(PersistedState state) {
    return <String, Object?>{
      'version': version,
      'library': <String, Object?>{
        'favorites': state.library.favorites,
        'history': state.library.history
            .map(
              (entry) => <String, Object?>{
                'id': entry.id,
                'playedAt': entry.playedAt,
              },
            )
            .toList(growable: false),
        'resume': <String, Object?>{
          for (final entry in state.library.resume.entries)
            entry.key.toString(): entry.value,
        },
      },
      'settings': <String, Object?>{
        'playbackRate': state.settings.playbackRate,
        'volume': state.settings.volume,
      },
    };
  }

  LibraryState _decodeLibrary(Object? value) {
    if (value is! Map<String, Object?>) return const LibraryState.defaults();
    final favorites = <int>[];
    final rawFavorites = value['favorites'];
    if (rawFavorites is List<Object?>) {
      for (final item in rawFavorites) {
        if (item is int && item > 0 && !favorites.contains(item)) {
          favorites.add(item);
        }
      }
    }
    final history = <HistoryEntry>[];
    final rawHistory = value['history'];
    if (rawHistory is List<Object?>) {
      for (final item in rawHistory) {
        if (item is Map<String, Object?>) {
          final id = item['id'];
          final playedAt = item['playedAt'];
          if (id is int && id > 0 && playedAt is num && playedAt.isFinite) {
            history.add(HistoryEntry(id: id, playedAt: playedAt.toDouble()));
          }
        }
        if (history.length == 100) break;
      }
    }
    final resume = <int, double>{};
    final rawResume = value['resume'];
    if (rawResume is Map<String, Object?>) {
      final valid = <MapEntry<int, double>>[];
      for (final entry in rawResume.entries) {
        final id = int.tryParse(entry.key);
        final position = entry.value;
        if (id != null &&
            id > 0 &&
            position is num &&
            position.isFinite &&
            position >= 0) {
          valid.add(MapEntry<int, double>(id, position.toDouble()));
        }
      }
      for (final entry in valid.skip(
        valid.length > 500 ? valid.length - 500 : 0,
      )) {
        resume[entry.key] = entry.value;
      }
    }
    return LibraryState(favorites: favorites, history: history, resume: resume);
  }

  SettingsState _decodeSettings(Object? value) {
    if (value is! Map<String, Object?>) return const SettingsState.defaults();
    final rate = value['playbackRate'];
    final volume = value['volume'];
    if (rate is! num || volume is! num) return const SettingsState.defaults();
    final playbackRate = rate.toDouble();
    final normalizedVolume = volume.toDouble();
    if (!allowedRates.contains(playbackRate) ||
        !normalizedVolume.isFinite ||
        normalizedVolume < 0 ||
        normalizedVolume > 1) {
      return const SettingsState.defaults();
    }
    return SettingsState(playbackRate: playbackRate, volume: normalizedVolume);
  }

  LibraryState _sanitizeLibrary(LibraryState state) {
    final favorites = <int>[];
    for (final id in state.favorites) {
      if (id > 0 && !favorites.contains(id)) favorites.add(id);
    }
    final history = state.history
        .where((entry) => entry.id > 0 && entry.playedAt.isFinite)
        .take(100)
        .toList(growable: false);
    final entries = state.resume.entries
        .where(
          (entry) => entry.key > 0 && entry.value.isFinite && entry.value >= 0,
        )
        .toList(growable: false);
    final start = entries.length > 500 ? entries.length - 500 : 0;
    return LibraryState(
      favorites: favorites,
      history: history,
      resume: <int, double>{
        for (final entry in entries.skip(start)) entry.key: entry.value,
      },
    );
  }

  SettingsState _sanitizeSettings(SettingsState settings) {
    if (!allowedRates.contains(settings.playbackRate) ||
        !settings.volume.isFinite ||
        settings.volume < 0 ||
        settings.volume > 1) {
      return const SettingsState.defaults();
    }
    return settings;
  }
}
