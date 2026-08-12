import 'dart:async';
import 'dart:io';

import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/downloads/download_client.dart';
import 'package:dhamma_echo/downloads/download_manager.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'language and format filters preserve the active teacher filter',
    () async {
      final catalogue = RecordingCatalogue();
      final port = RecordingPlaybackPort();
      final controller = AppController(
        catalogue: catalogue,
        playback: PlaybackController(port),
      );
      addTearDown(controller.dispose);

      await controller.initialize(
        persistedState: const PersistedState.defaults(),
      );
      await controller.filterByTeacher(16);
      await controller.setLanguage('english');
      await controller.setFormat('mp3');

      expect(controller.audioRequest.teacherId, 16);
      expect(controller.audioRequest.language, 'english');
      expect(controller.audioRequest.format, 'mp3');
      expect(catalogue.lastAudioRequest?.teacherId, 16);
    },
  );

  test('newest audio search wins when an older request completes last', () async {
    final catalogue = DeferredSearchCatalogue();
    final controller = AppController(
      catalogue: catalogue,
      playback: PlaybackController(RecordingPlaybackPort()),
    );
    addTearDown(controller.dispose);

    final older = controller.setAudioQuery('older');
    final newer = controller.setAudioQuery('newer');

    expect(catalogue.audioSearches, hasLength(2));
    catalogue.audioSearches[1].complete(
      const AudioSearchPage(
        items: <AudioTrack>[trackTwo],
        total: 1,
        limit: 50,
        offset: 0,
      ),
    );
    await newer;
    catalogue.audioSearches[0].complete(
      const AudioSearchPage(
        items: <AudioTrack>[trackOne],
        total: 1,
        limit: 50,
        offset: 0,
      ),
    );
    await older;

    expect(controller.audioPage.items, <AudioTrack>[trackTwo]);
    expect(controller.audioRequest.query, 'newer');
    expect(controller.audioLoading, isFalse);
  });

  test('stale audio search errors are ignored', () async {
    final catalogue = DeferredSearchCatalogue();
    final controller = AppController(
      catalogue: catalogue,
      playback: PlaybackController(RecordingPlaybackPort()),
    );
    addTearDown(controller.dispose);

    final older = controller.setAudioQuery('older');
    final newer = controller.setAudioQuery('newer');
    catalogue.audioSearches[1].complete(
      const AudioSearchPage(
        items: <AudioTrack>[trackTwo],
        total: 1,
        limit: 50,
        offset: 0,
      ),
    );
    await newer;
    catalogue.audioSearches[0].completeError(StateError('stale failure'));
    await older;

    expect(controller.audioPage.items, <AudioTrack>[trackTwo]);
    expect(controller.audioError, isEmpty);
  });

  test(
    'newest collection search wins when an older request completes last',
    () async {
      final catalogue = DeferredSearchCatalogue();
      final controller = AppController(
        catalogue: catalogue,
        playback: PlaybackController(RecordingPlaybackPort()),
      );
      addTearDown(controller.dispose);

      final older = controller.setCollectionQuery('older');
      final newer = controller.setCollectionQuery('newer');

      expect(catalogue.collectionSearches, hasLength(2));
      catalogue.collectionSearches[1].complete(
        const CollectionSearchPage(
          items: <CollectionSummary>[collectionTwo],
          total: 1,
          limit: 24,
          offset: 0,
        ),
      );
      await newer;
      catalogue.collectionSearches[0].complete(
        const CollectionSearchPage(
          items: <CollectionSummary>[collectionOne],
          total: 1,
          limit: 24,
          offset: 0,
        ),
      );
      await older;

      expect(controller.collectionPage.items, <CollectionSummary>[collectionTwo]);
      expect(controller.collectionRequest.query, 'newer');
      expect(controller.collectionsLoading, isFalse);
    },
  );

  test('stale collection search errors are ignored', () async {
    final catalogue = DeferredSearchCatalogue();
    final controller = AppController(
      catalogue: catalogue,
      playback: PlaybackController(RecordingPlaybackPort()),
    );
    addTearDown(controller.dispose);

    final older = controller.setCollectionQuery('older');
    final newer = controller.setCollectionQuery('newer');
    catalogue.collectionSearches[1].complete(
      const CollectionSearchPage(
        items: <CollectionSummary>[collectionTwo],
        total: 1,
        limit: 24,
        offset: 0,
      ),
    );
    await newer;
    catalogue.collectionSearches[0].completeError(StateError('stale failure'));
    await older;

    expect(controller.collectionPage.items, <CollectionSummary>[collectionTwo]);
    expect(controller.collectionsError, isEmpty);
  });

  test('newest teacher search wins when an older request completes last', () async {
    final catalogue = DeferredSearchCatalogue();
    final controller = AppController(
      catalogue: catalogue,
      playback: PlaybackController(RecordingPlaybackPort()),
    );
    addTearDown(controller.dispose);

    final older = controller.searchTeachers('older');
    final newer = controller.searchTeachers('newer');

    expect(catalogue.teacherSearches, hasLength(2));
    catalogue.teacherSearches[1].complete(
      const <TeacherSummary>[teacherTwo],
    );
    await newer;
    catalogue.teacherSearches[0].completeError(StateError('stale failure'));
    await older;

    expect(controller.teacherResults, <TeacherSummary>[teacherTwo]);
  });

  test('clearing teacher search invalidates an older request', () async {
    final catalogue = DeferredSearchCatalogue();
    final controller = AppController(
      catalogue: catalogue,
      playback: PlaybackController(RecordingPlaybackPort()),
    );
    addTearDown(controller.dispose);

    final older = controller.searchTeachers('older');
    await controller.searchTeachers('');
    catalogue.teacherSearches.single.complete(
      const <TeacherSummary>[teacherOne],
    );
    await older;

    expect(controller.teacherResults, isEmpty);
  });

  test('switching tracks stores the previous resume position', () async {
    final port = RecordingPlaybackPort();
    final controller = AppController(
      catalogue: RecordingCatalogue(),
      playback: PlaybackController(port),
    );
    addTearDown(controller.dispose);

    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await controller.play(trackOne);
    port.emit(const PlaybackPositionEvent(Duration(seconds: 42)));
    await Future<void>.delayed(Duration.zero);
    await controller.play(trackTwo);

    expect(controller.library.resume[trackOne.id], 42);
  });

  test(
    'progress persists resume after the desktop five-second threshold',
    () async {
      final port = RecordingPlaybackPort();
      final controller = AppController(
        catalogue: RecordingCatalogue(),
        playback: PlaybackController(port),
      );
      addTearDown(controller.dispose);

      await controller.initialize(
        persistedState: const PersistedState.defaults(),
      );
      await controller.play(trackOne);
      port.emit(const PlaybackPositionEvent(Duration(seconds: 3)));
      await Future<void>.delayed(Duration.zero);
      expect(controller.library.resume.containsKey(trackOne.id), isFalse);

      port.emit(const PlaybackPositionEvent(Duration(seconds: 6)));
      await Future<void>.delayed(Duration.zero);
      expect(controller.library.resume[trackOne.id], 6);
    },
  );

  test('pausing forces the current resume position to persist', () async {
    final port = RecordingPlaybackPort();
    final controller = AppController(
      catalogue: RecordingCatalogue(),
      playback: PlaybackController(port),
    );
    addTearDown(controller.dispose);

    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await controller.play(trackOne);
    port.emit(const PlaybackPositionEvent(Duration(seconds: 2)));
    await Future<void>.delayed(Duration.zero);
    port.emit(const PlaybackStateEvent(playing: false, loading: false));
    await Future<void>.delayed(Duration.zero);

    expect(controller.library.resume[trackOne.id], 2);
  });

  test(
    'automatic queue advancement records the next talk in history',
    () async {
      final port = RecordingPlaybackPort();
      final controller = AppController(
        catalogue: RecordingCatalogue(),
        playback: PlaybackController(port),
      );
      addTearDown(controller.dispose);

      await controller.initialize(
        persistedState: const PersistedState.defaults(),
      );
      await controller.play(trackOne);
      controller.enqueue(trackTwo);
      port.emit(const PlaybackEndedEvent());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.playback.current?.id, trackTwo.id);
      expect(controller.library.history.first.id, trackTwo.id);
    },
  );

  test(
    'automatic queue advancement restores the queued talk resume position',
    () async {
      final port = RecordingPlaybackPort();
      final controller = AppController(
        catalogue: RecordingCatalogue(),
        playback: PlaybackController(port),
      );
      addTearDown(controller.dispose);

      await controller.initialize(
        persistedState: const PersistedState(
          library: LibraryState(
            favorites: <int>[],
            history: <HistoryEntry>[],
            resume: <int, double>{2: 33},
          ),
          settings: SettingsState.defaults(),
        ),
      );
      await controller.play(trackOne);
      controller.enqueue(trackTwo);
      port.emit(const PlaybackEndedEvent());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.playback.current?.id, trackTwo.id);
      expect(port.lastSeek, const Duration(seconds: 33));
    },
  );

  test('playback position ticks do not notify app-wide listeners', () async {
    final port = RecordingPlaybackPort();
    final controller = AppController(
      catalogue: RecordingCatalogue(),
      playback: PlaybackController(port),
    );
    addTearDown(controller.dispose);

    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await controller.play(trackOne);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    port.emit(const PlaybackPositionEvent(Duration(seconds: 1)));
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
    expect(controller.playback.position, const Duration(seconds: 1));
  });

  test('downloaded media is resolved and preferred for playback', () async {
    final directory = await Directory.systemTemp.createTemp('dhamma-app-');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await File('${directory.path}/${trackOne.id}.mp3').writeAsBytes(<int>[1]);
    final port = RecordingPlaybackPort();
    final controller = AppController(
      catalogue: RecordingCatalogue(),
      playback: PlaybackController(port),
      downloadManager: DownloadManager(
        directory: directory,
        client: NoNetworkDownloadClient(),
      ),
    );
    addTearDown(controller.dispose);

    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    expect(controller.downloadedTracks.map((track) => track.id), <int>[1]);

    expect(await controller.play(trackOne), isTrue);
    expect(port.urls.first.scheme, 'file');
  });

  test(
    'completed playback resets the stored resume position to zero',
    () async {
      final port = RecordingPlaybackPort();
      final controller = AppController(
        catalogue: RecordingCatalogue(),
        playback: PlaybackController(port),
      );
      addTearDown(controller.dispose);

      await controller.initialize(
        persistedState: const PersistedState(
          library: LibraryState(
            favorites: <int>[],
            history: <HistoryEntry>[],
            resume: <int, double>{1: 42},
          ),
          settings: SettingsState.defaults(),
        ),
      );
      await controller.play(trackOne);
      port.emit(const PlaybackEndedEvent());
      await Future<void>.delayed(Duration.zero);

      expect(controller.library.resume[trackOne.id], 0);
    },
  );
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

const collectionOne = CollectionSummary(
  id: 1,
  name: 'Collection One',
  teacherId: 16,
  teacherName: 'Teacher One',
  audioCount: 1,
);

const collectionTwo = CollectionSummary(
  id: 2,
  name: 'Collection Two',
  teacherId: 17,
  teacherName: 'Teacher Two',
  audioCount: 1,
);

const teacherOne = TeacherSummary(id: 16, name: 'Teacher One', audioCount: 1);
const teacherTwo = TeacherSummary(id: 17, name: 'Teacher Two', audioCount: 1);

class DeferredSearchCatalogue extends RecordingCatalogue {
  final List<Completer<AudioSearchPage>> audioSearches =
      <Completer<AudioSearchPage>>[];
  final List<Completer<CollectionSearchPage>> collectionSearches =
      <Completer<CollectionSearchPage>>[];
  final List<Completer<List<TeacherSummary>>> teacherSearches =
      <Completer<List<TeacherSummary>>>[];

  @override
  Future<AudioSearchPage> searchAudio(AudioSearchRequest request) {
    final completer = Completer<AudioSearchPage>();
    audioSearches.add(completer);
    return completer.future;
  }

  @override
  Future<CollectionSearchPage> searchCollections(
    CollectionSearchRequest request,
  ) {
    final completer = Completer<CollectionSearchPage>();
    collectionSearches.add(completer);
    return completer.future;
  }

  @override
  Future<List<TeacherSummary>> searchTeachers(
    String query, {
    int limit = 100,
  }) {
    final completer = Completer<List<TeacherSummary>>();
    teacherSearches.add(completer);
    return completer.future;
  }
}

class RecordingCatalogue implements CatalogueRepository {
  AudioSearchRequest? lastAudioRequest;

  @override
  Future<CatalogueSummary> getSummary() async {
    return const CatalogueSummary(
      totalAudio: 2,
      totalTeachers: 1,
      myanmarAudio: 0,
      englishAudio: 2,
    );
  }

  @override
  Future<List<AudioCategory>> listAudioCategories() async =>
      const <AudioCategory>[];

  @override
  Future<List<TeacherSummary>> listTeachers() async {
    return const <TeacherSummary>[
      TeacherSummary(id: 16, name: 'Teacher', audioCount: 2),
    ];
  }

  @override
  Future<List<TeacherSummary>> searchTeachers(
    String query, {
    int limit = 100,
  }) async {
    return listTeachers();
  }

  @override
  Future<TeacherDetail> getTeacher(int id) async {
    return const TeacherDetail(
      id: 16,
      name: 'Teacher',
      audioCount: 2,
      collections: <CollectionSummary>[],
    );
  }

  @override
  Future<CollectionSearchPage> searchCollections(
    CollectionSearchRequest request,
  ) async {
    return CollectionSearchPage(
      items: const <CollectionSummary>[],
      total: 0,
      limit: request.limit,
      offset: request.offset,
    );
  }

  @override
  Future<CollectionDetail> getCollection(int id) async {
    return const CollectionDetail(
      id: 1,
      name: 'Collection',
      teacherName: 'Teacher',
      audioCount: 2,
      tracks: <AudioTrack>[trackOne, trackTwo],
    );
  }

  @override
  Future<AudioSearchPage> searchAudio(AudioSearchRequest request) async {
    lastAudioRequest = request;
    return AudioSearchPage(
      items: const <AudioTrack>[trackOne, trackTwo],
      total: 2,
      limit: request.limit,
      offset: request.offset,
    );
  }

  @override
  Future<AudioTrack> getAudioTrack(int id) async {
    if (id == trackOne.id) return trackOne;
    if (id == trackTwo.id) return trackTwo;
    throw CatalogueNotFoundException('track', id);
  }
}

class RecordingPlaybackPort implements PlaybackPort {
  final StreamController<PlaybackPortEvent> _events =
      StreamController<PlaybackPortEvent>.broadcast();

  Duration? lastSeek;
  final List<Uri> urls = <Uri>[];

  void emit(PlaybackPortEvent event) => _events.add(event);

  @override
  Stream<PlaybackPortEvent> get events => _events.stream;

  @override
  Future<void> dispose() => _events.close();

  @override
  Future<void> load(AudioTrack track, Uri uri) async {
    urls.add(uri);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
  }

  @override
  Future<void> setSpeed(double value) async {}

  @override
  Future<void> setVolume(double value) async {}
}


class NoNetworkDownloadClient implements DownloadClient {
  @override
  Future<DownloadResponse> get(Uri uri) {
    throw StateError('network should not be used');
  }

  @override
  void close() {}
}
