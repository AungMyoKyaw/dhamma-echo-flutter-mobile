import 'dart:async';

import 'package:dhamma_echo/core/catalogue_policy.dart';
import 'package:dhamma_echo/core/text_utils.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/data/local_state_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:flutter/foundation.dart';

class AppController extends ChangeNotifier {
  AppController({
    required CatalogueRepository catalogue,
    required PlaybackController playback,
    LocalStateRepository? stateRepository,
  })  : _catalogue = catalogue,
        playback = playback,
        _stateRepository = stateRepository {
    playback.addListener(_onPlaybackChanged);
  }

  final CatalogueRepository _catalogue;
  final LocalStateRepository? _stateRepository;
  final PlaybackController playback;
  int _seenCompletionEpoch = 0;
  int? _seenTrackId;
  bool _wasPlaying = false;

  int selectedTab = 0;
  bool initializing = true;
  String initializationError = '';
  CatalogueSummary summary = const CatalogueSummary(totalAudio: 0, totalTeachers: 0, myanmarAudio: 0, englishAudio: 0);
  List<AudioCategory> categories = const <AudioCategory>[];
  List<TeacherSummary> teachers = const <TeacherSummary>[];
  List<TeacherSummary> teacherResults = const <TeacherSummary>[];
  List<AudioTrack> recentTracks = const <AudioTrack>[];
  List<AudioTrack> favoriteTracks = const <AudioTrack>[];

  AudioSearchRequest audioRequest = const AudioSearchRequest(limit: 50);
  AudioSearchPage audioPage = const AudioSearchPage(items: <AudioTrack>[], total: 0, limit: 50, offset: 0);
  bool audioLoading = false;
  bool audioLoadingMore = false;
  String audioError = '';
  String audioLoadMoreError = '';

  CollectionSearchRequest collectionRequest = const CollectionSearchRequest(limit: 24);
  CollectionSearchPage collectionPage = const CollectionSearchPage(items: <CollectionSummary>[], total: 0, limit: 24, offset: 0);
  bool collectionsLoading = false;
  bool collectionsLoadingMore = false;
  String collectionsError = '';
  String collectionsLoadMoreError = '';

  LibraryState library = const LibraryState.defaults();
  SettingsState settings = const SettingsState.defaults();

  bool get hasMoreAudio => audioPage.items.length < audioPage.total;
  bool get hasMoreCollections => collectionPage.items.length < collectionPage.total;
  List<TeacherSummary> get orderedTeachers => orderTeachersFeaturedFirst(teachers);
  List<TeacherSummary> get homeFeaturedTeachers => featuredTeachers(teachers);

  Future<void> initialize({PersistedState? persistedState}) async {
    initializing = true;
    initializationError = '';
    notifyListeners();
    try {
      final state = persistedState ?? await _stateRepository?.load() ?? const PersistedState.defaults();
      library = state.library;
      settings = state.settings;
      await playback.setVolume(settings.volume);
      await playback.setRate(settings.playbackRate);
      final values = await Future.wait<Object>(<Future<Object>>[
        _catalogue.getSummary(),
        _catalogue.listAudioCategories(),
        _catalogue.listFeaturedTeachers(limit: 100),
      ]);
      summary = values[0] as CatalogueSummary;
      categories = values[1] as List<AudioCategory>;
      teachers = values[2] as List<TeacherSummary>;
      teacherResults = orderedTeachers;
      await Future.wait<void>(<Future<void>>[
        searchAudio(),
        searchCollections(),
        _loadLibraryTracks(),
      ]);
    } on Object catch (error) {
      initializationError = _message(error);
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  void selectTab(int index) {
    selectedTab = index.clamp(0, 4).toInt();
    notifyListeners();
  }

  Future<void> setAudioQuery(String query) async {
    audioRequest = audioRequest.copyWith(query: normalizeText(query), offset: 0);
    await searchAudio();
  }

  Future<void> setLanguage(String? language) async {
    audioRequest = language == null
        ? audioRequest.copyWith(clearLanguage: true, offset: 0)
        : audioRequest.copyWith(language: language, offset: 0);
    await searchAudio();
  }

  Future<void> setFormat(String? format) async {
    audioRequest = format == null
        ? audioRequest.copyWith(clearFormat: true, offset: 0)
        : audioRequest.copyWith(format: format, offset: 0);
    await searchAudio();
  }

  Future<void> setCategory(int? categoryId) async {
    audioRequest = categoryId == null
        ? audioRequest.copyWith(clearCategory: true, offset: 0)
        : audioRequest.copyWith(categoryId: categoryId, offset: 0);
    await searchAudio();
  }

  Future<void> filterByTeacher(int teacherId) async {
    audioRequest = audioRequest.copyWith(teacherId: teacherId, offset: 0);
    selectedTab = 1;
    await searchAudio();
  }

  Future<void> filterByCollection(int collectionId) async {
    audioRequest = audioRequest.copyWith(collectionId: collectionId, offset: 0);
    selectedTab = 1;
    await searchAudio();
  }

  Future<void> clearTeacherFilter() async {
    audioRequest = audioRequest.copyWith(clearTeacher: true, offset: 0);
    await searchAudio();
  }

  Future<void> clearCollectionFilter() async {
    audioRequest = audioRequest.copyWith(clearCollection: true, offset: 0);
    await searchAudio();
  }

  Future<void> searchAudio({bool append = false}) async {
    if (append && (audioLoadingMore || !hasMoreAudio)) return;
    if (append) {
      audioLoadingMore = true;
      audioLoadMoreError = '';
    } else {
      audioLoading = true;
      audioError = '';
    }
    notifyListeners();
    final request = append ? audioRequest.copyWith(offset: audioPage.items.length) : audioRequest.copyWith(offset: 0);
    try {
      final page = await _catalogue.searchAudio(request);
      if (append) {
        final known = audioPage.items.map((track) => track.id).toSet();
        final appended = page.items.where((track) => !known.contains(track.id));
        audioPage = AudioSearchPage(
          items: <AudioTrack>[...audioPage.items, ...appended],
          total: page.total,
          limit: page.limit,
          offset: 0,
        );
      } else {
        audioPage = AudioSearchPage(items: page.items, total: page.total, limit: page.limit, offset: 0);
      }
    } on Object catch (error) {
      if (append) {
        audioLoadMoreError = _message(error);
      } else {
        audioError = _message(error);
      }
    } finally {
      audioLoading = false;
      audioLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setCollectionQuery(String query) async {
    collectionRequest = collectionRequest.copyWith(query: normalizeText(query), offset: 0);
    await searchCollections();
  }

  Future<void> setCollectionTeacher(int? teacherId) async {
    collectionRequest = teacherId == null
        ? collectionRequest.copyWith(clearTeacher: true, offset: 0)
        : collectionRequest.copyWith(teacherId: teacherId, offset: 0);
    await searchCollections();
  }

  Future<void> searchCollections({bool append = false}) async {
    if (append && (collectionsLoadingMore || !hasMoreCollections)) return;
    if (append) {
      collectionsLoadingMore = true;
      collectionsLoadMoreError = '';
    } else {
      collectionsLoading = true;
      collectionsError = '';
    }
    notifyListeners();
    final request = append
        ? collectionRequest.copyWith(offset: collectionPage.items.length)
        : collectionRequest.copyWith(offset: 0);
    try {
      final page = await _catalogue.searchCollections(request);
      if (append) {
        final known = collectionPage.items.map((collection) => collection.id).toSet();
        final appended = page.items.where((collection) => !known.contains(collection.id));
        collectionPage = CollectionSearchPage(
          items: <CollectionSummary>[...collectionPage.items, ...appended],
          total: page.total,
          limit: page.limit,
          offset: 0,
        );
      } else {
        collectionPage = CollectionSearchPage(items: page.items, total: page.total, limit: page.limit, offset: 0);
      }
    } on Object catch (error) {
      if (append) {
        collectionsLoadMoreError = _message(error);
      } else {
        collectionsError = _message(error);
      }
    } finally {
      collectionsLoading = false;
      collectionsLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> searchTeachers(String query) async {
    final normalized = normalizeText(query);
    teacherResults = normalized.isEmpty
        ? orderedTeachers
        : await _catalogue.searchTeachers(normalized, limit: 100);
    notifyListeners();
  }

  Future<TeacherDetail> getTeacher(int id) => _catalogue.getTeacher(id);
  Future<CollectionDetail> getCollection(int id) => _catalogue.getCollection(id);

  Future<AudioSearchPage> teacherTalks(int teacherId, {int offset = 0}) {
    return _catalogue.searchAudio(AudioSearchRequest(teacherId: teacherId, limit: 50, offset: offset));
  }

  Future<bool> play(AudioTrack track) async {
    final previous = playback.current;
    if (previous != null && previous.id != track.id) {
      await saveCurrentResume();
    }
    final didPlay = await playback.play(track, resumeAt: library.resume[track.id] ?? 0);
    if (!didPlay) return false;
    if (previous?.id == track.id) {
      _recordHistory(track.id);
    }
    await _persist();
    notifyListeners();
    return true;
  }

  void enqueue(AudioTrack track) => playback.enqueue(track);

  Future<bool> playNext({bool saveCurrent = true}) async {
    final next = playback.nextInQueue;
    if (next == null) return false;
    if (saveCurrent) {
      await saveCurrentResume();
    }
    final didPlay = await playback.playNext(resumeAt: library.resume[next.id] ?? 0);
    if (didPlay) {
      await _persist();
    }
    return didPlay;
  }

  Future<void> toggleFavorite(int id) async {
    final favorites = <int>[...library.favorites];
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    library = LibraryState(favorites: favorites, history: library.history, resume: library.resume);
    await _loadFavoriteTracks();
    await _persist();
    notifyListeners();
  }

  bool isFavorite(int id) => library.favorites.contains(id);

  Future<void> setVolume(double value) async {
    await playback.setVolume(value);
    settings = SettingsState(playbackRate: settings.playbackRate, volume: playback.volume);
    await _persist();
    notifyListeners();
  }

  Future<void> setPlaybackRate(double value) async {
    await playback.setRate(value);
    settings = SettingsState(playbackRate: playback.rate, volume: settings.volume);
    await _persist();
    notifyListeners();
  }

  Future<void> saveCurrentResume() async {
    if (_updateResume(force: true)) {
      await _persist();
    }
  }

  bool _updateResume({required bool force}) {
    final current = playback.current;
    if (current == null) return false;
    final position = playback.position.inMilliseconds / 1000;
    final saved = library.resume[current.id] ?? 0;
    if (!force && (saved - position).abs() < 5) return false;
    final resume = <int, double>{...library.resume};
    resume[current.id] = position;
    if (resume.length > 500) resume.remove(resume.keys.first);
    library = LibraryState(favorites: library.favorites, history: library.history, resume: resume);
    return true;
  }

  void _recordHistory(int id) {
    final history = <HistoryEntry>[
      HistoryEntry(id: id, playedAt: DateTime.now().millisecondsSinceEpoch.toDouble()),
      ...library.history.where((entry) => entry.id != id),
    ].take(100).toList(growable: false);
    library = LibraryState(favorites: library.favorites, history: history, resume: library.resume);
    unawaited(_loadRecentTracks());
  }

  Future<void> _loadLibraryTracks() async {
    await Future.wait<void>(<Future<void>>[_loadRecentTracks(), _loadFavoriteTracks()]);
  }

  Future<void> _loadRecentTracks() async {
    recentTracks = await _resolveTracks(library.history.map((entry) => entry.id).take(12));
    notifyListeners();
  }

  Future<void> _loadFavoriteTracks() async {
    favoriteTracks = await _resolveTracks(library.favorites);
    notifyListeners();
  }

  Future<List<AudioTrack>> _resolveTracks(Iterable<int> ids) async {
    final tracks = <AudioTrack>[];
    for (final id in ids) {
      try {
        tracks.add(await _catalogue.getAudioTrack(id));
      } on CatalogueNotFoundException {
        // Old local state can reference tracks removed by a refreshed catalogue.
      }
    }
    return tracks;
  }

  Future<void> _persist() async {
    await _stateRepository?.save(PersistedState(library: library, settings: settings));
  }

  void _onPlaybackChanged() {
    final current = playback.current;
    if (current != null && current.id != _seenTrackId) {
      _seenTrackId = current.id;
      _recordHistory(current.id);
      unawaited(_persist());
    }

    final completed = playback.completionEpoch != _seenCompletionEpoch;
    if (completed) {
      _seenCompletionEpoch = playback.completionEpoch;
      if (_updateResume(force: true)) {
        unawaited(_persist());
      }
      if (playback.nextInQueue != null) {
        unawaited(playNext(saveCurrent: false));
      }
    } else if (_wasPlaying && !playback.playing) {
      if (_updateResume(force: true)) {
        unawaited(_persist());
      }
    } else if (_updateResume(force: false)) {
      unawaited(_persist());
    }

    _wasPlaying = playback.playing;
    notifyListeners();
  }

  String _message(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }

  @override
  void dispose() {
    playback.removeListener(_onPlaybackChanged);
    playback.dispose();
    super.dispose();
  }
}
