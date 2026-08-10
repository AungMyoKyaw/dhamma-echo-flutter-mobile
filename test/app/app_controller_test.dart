import 'dart:async';

import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('language and format filters preserve the active teacher filter', () async {
    final catalogue = RecordingCatalogue();
    final port = RecordingPlaybackPort();
    final controller = AppController(
      catalogue: catalogue,
      playback: PlaybackController(port),
    );
    addTearDown(controller.dispose);

    await controller.initialize(persistedState: const PersistedState.defaults());
    await controller.filterByTeacher(16);
    await controller.setLanguage('english');
    await controller.setFormat('mp3');

    expect(controller.audioRequest.teacherId, 16);
    expect(controller.audioRequest.language, 'english');
    expect(controller.audioRequest.format, 'mp3');
    expect(catalogue.lastAudioRequest?.teacherId, 16);
  });

  test('switching tracks stores the previous resume position', () async {
    final port = RecordingPlaybackPort();
    final controller = AppController(
      catalogue: RecordingCatalogue(),
      playback: PlaybackController(port),
    );
    addTearDown(controller.dispose);

    await controller.initialize(persistedState: const PersistedState.defaults());
    await controller.play(trackOne);
    port.emit(const PlaybackPositionEvent(Duration(seconds: 42)));
    await Future<void>.delayed(Duration.zero);
    await controller.play(trackTwo);

    expect(controller.library.resume[trackOne.id], 42);
  });

  test('completed playback clears the stored resume position', () async {
    final port = RecordingPlaybackPort();
    final controller = AppController(
      catalogue: RecordingCatalogue(),
      playback: PlaybackController(port),
    );
    addTearDown(controller.dispose);

    await controller.initialize(
      persistedState: const PersistedState(
        library: LibraryState(favorites: <int>[], history: <HistoryEntry>[], resume: <int, double>{1: 42}),
        settings: SettingsState.defaults(),
      ),
    );
    await controller.play(trackOne);
    port.emit(const PlaybackEndedEvent());
    await Future<void>.delayed(Duration.zero);

    expect(controller.library.resume.containsKey(trackOne.id), isFalse);
  });
}

const trackOne = AudioTrack(
  id: 1,
  title: 'One',
  format: 'mp3',
  language: 'english',
  url: 'https://dhammadownload.com/one.mp3',
  teacherId: 16,
  teacherName: 'Teacher',
  playable: true,
);

const trackTwo = AudioTrack(
  id: 2,
  title: 'Two',
  format: 'mp3',
  language: 'english',
  url: 'https://dhammadownload.com/two.mp3',
  teacherId: 16,
  teacherName: 'Teacher',
  playable: true,
);

class RecordingCatalogue implements CatalogueRepository {
  AudioSearchRequest? lastAudioRequest;

  @override
  Future<CatalogueSummary> getSummary() async {
    return const CatalogueSummary(totalAudio: 2, totalTeachers: 1, myanmarAudio: 0, englishAudio: 2);
  }

  @override
  Future<List<AudioCategory>> listAudioCategories() async => const <AudioCategory>[];

  @override
  Future<List<TeacherSummary>> listFeaturedTeachers({int limit = 100}) async {
    return const <TeacherSummary>[TeacherSummary(id: 16, name: 'Teacher', audioCount: 2)];
  }

  @override
  Future<List<TeacherSummary>> searchTeachers(String query, {int limit = 100}) async {
    return listFeaturedTeachers(limit: limit);
  }

  @override
  Future<TeacherDetail> getTeacher(int id) async {
    return const TeacherDetail(id: 16, name: 'Teacher', audioCount: 2, collections: <CollectionSummary>[]);
  }

  @override
  Future<CollectionSearchPage> searchCollections(CollectionSearchRequest request) async {
    return CollectionSearchPage(items: const <CollectionSummary>[], total: 0, limit: request.limit, offset: request.offset);
  }

  @override
  Future<CollectionDetail> getCollection(int id) async {
    return const CollectionDetail(id: 1, name: 'Collection', teacherName: 'Teacher', audioCount: 2, tracks: <AudioTrack>[trackOne, trackTwo]);
  }

  @override
  Future<AudioSearchPage> searchAudio(AudioSearchRequest request) async {
    lastAudioRequest = request;
    return AudioSearchPage(items: const <AudioTrack>[trackOne, trackTwo], total: 2, limit: request.limit, offset: request.offset);
  }

  @override
  Future<AudioTrack> getAudioTrack(int id) async {
    if (id == trackOne.id) return trackOne;
    if (id == trackTwo.id) return trackTwo;
    throw CatalogueNotFoundException('track', id);
  }
}

class RecordingPlaybackPort implements PlaybackPort {
  final StreamController<PlaybackPortEvent> _events = StreamController<PlaybackPortEvent>.broadcast();

  void emit(PlaybackPortEvent event) => _events.add(event);

  @override
  Stream<PlaybackPortEvent> get events => _events.stream;

  @override
  Future<void> dispose() => _events.close();

  @override
  Future<void> load(Uri uri) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double value) async {}

  @override
  Future<void> setVolume(double value) async {}
}
