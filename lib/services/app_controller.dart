import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../data/catalogue_repository.dart';
import '../data/user_state_repository.dart';
import '../models/models.dart';
import 'connectivity_service.dart';

/// App-wide state: settings, bookmarks, resume entry and connectivity.
class AppController extends ChangeNotifier {
  AppController({
    required this.catalogue,
    required this.userState,
    required this._connectivity,
  });

  final CatalogueRepository catalogue;
  final UserStateRepository userState;
  final ConnectivityService _connectivity;

  AppSettings _settings = const AppSettings();
  ArchiveCounts _counts = ArchiveCounts.empty;
  Set<int> _saved = {};
  List<HistoryEntry> _history = const [];
  ({MediaItem media, HistoryEntry entry})? _resume;
  bool _online = true;
  StreamSubscription<bool>? _connSub;
  bool _disposed = false;

  AppSettings get settings => _settings;
  ArchiveCounts get counts => _counts;
  Set<int> get savedIds => _saved;
  List<HistoryEntry> get history => _history;
  ({MediaItem media, HistoryEntry entry})? get resume => _resume;
  bool get online => _online;
  String get language => _settings.language;
  ThemeMode get themeMode => _settings.themeMode;

  Future<void> init() async {
    _settings = await userState.loadSettings();
    _counts = await catalogue.getArchiveCounts();
    _saved = (await userState.savedIds()).toSet();
    await refreshHistory();
    _online = await _connectivity.isOnline();
    _connSub = _connectivity.onlineChanges.listen((v) {
      _online = v;
      _notify();
    });
    _notify();
  }

  bool isSaved(int mediaId) => _saved.contains(mediaId);

  Future<void> toggleSaved(int mediaId) async {
    final next = !_saved.contains(mediaId);
    _saved = next ? ({..._saved, mediaId}) : ({..._saved}..remove(mediaId));
    _notify();
    await userState.setSaved(mediaId, saved: next);
  }

  Future<void> refreshHistory() async {
    _history = await userState.history();
    final candidates = _history.where((h) => h.positionMs > 0).toList();
    ({MediaItem media, HistoryEntry entry})? found;
    if (candidates.isNotEmpty) {
      final media = await catalogue.getMediaByIds(
        candidates.take(10).map((h) => h.mediaId),
      );
      for (final h in candidates) {
        final m = media.where((e) => e.id == h.mediaId).firstOrNull;
        if (m != null && m.isInAppPlayable) {
          found = (media: m, entry: h);
          break;
        }
      }
    }
    _resume = found;
    _notify();
  }

  Future<void> clearHistory() async {
    await userState.clearHistory();
    await refreshHistory();
  }

  Future<void> _update(AppSettings next) async {
    _settings = next;
    _notify();
    await userState.saveSettings(next);
  }

  Future<void> setLanguage(String code) =>
      _update(_settings.copyWith(language: code));

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(_settings.copyWith(themeMode: mode));

  Future<void> setPlaybackSpeed(double speed) =>
      _update(_settings.copyWith(playbackSpeed: speed));

  Future<void> setWifiOnly({required bool value}) =>
      _update(_settings.copyWith(wifiOnly: value));

  Future<void> setShowLegacy({required bool value}) =>
      _update(_settings.copyWith(showLegacy: value));

  Future<void> setPdfTint(PdfTint tint) =>
      _update(_settings.copyWith(pdfTint: tint));

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_connSub?.cancel());
    super.dispose();
  }
}
