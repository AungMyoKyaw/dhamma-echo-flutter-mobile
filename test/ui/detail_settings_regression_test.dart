import 'dart:async';
import 'dart:io';

import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/app/dhamma_echo_app.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/downloads/download_client.dart';
import 'package:dhamma_echo/downloads/download_manager.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:dhamma_echo/ui/components/track_tile.dart';
import 'package:dhamma_echo/ui/screens/collection_detail_screen.dart';
import 'package:dhamma_echo/ui/screens/settings_screen.dart';
import 'package:dhamma_echo/ui/screens/teacher_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings reflects controller changes while the route is open', (
    tester,
  ) async {
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(DetailPlaybackPort()),
    );
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(controller: controller)),
    );

    await controller.setVolume(0.5);
    await tester.pump();

    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('keeps downloads'), findsOneWidget);
  });

  testWidgets(
    'active mini player persists on collection detail without refetching',
    (tester) async {
      final catalogue = DetailCatalogue();
      final port = DetailPlaybackPort();
      final controller = AppController(
        catalogue: catalogue,
        playback: PlaybackController(port),
      );
      addTearDown(controller.dispose);
      await controller.initialize(
        persistedState: const PersistedState.defaults(),
      );
      await controller.play(DetailCatalogue.track);
      await tester.pumpWidget(
        MaterialApp(
          home: CollectionDetailScreen(
            controller: controller,
            collection: DetailCatalogue.collection,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mini-player')), findsOneWidget);
      expect(catalogue.collectionDetailCalls, 1);
      expect(find.text('Collection Seven'), findsOneWidget);

      port.emit(const PlaybackPositionEvent(Duration(seconds: 5)));
      await tester.pump();

      expect(catalogue.collectionDetailCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Collection Seven'), findsOneWidget);
    },
  );

  testWidgets('active mini player persists on teacher detail', (tester) async {
    final catalogue = DetailCatalogue();
    final port = DetailPlaybackPort();
    final controller = AppController(
      catalogue: catalogue,
      playback: PlaybackController(port),
    );
    addTearDown(controller.dispose);
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await controller.play(DetailCatalogue.track);
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDetailScreen(
          controller: controller,
          teacher: const TeacherSummary(id: 16, name: 'Teacher', audioCount: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    expect(find.text('Teacher'), findsWidgets);

    port.emit(const PlaybackPositionEvent(Duration(seconds: 5)));
    await tester.pump();
    expect(find.text('Teacher'), findsWidgets);
  });

  testWidgets('track row downloads and removes offline media', (tester) async {
    final directory = await Directory.systemTemp.createTemp(
      'dhamma-ui-download-',
    );
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(DetailPlaybackPort()),
      downloadManager: DownloadManager(
        directory: directory,
        client: DetailDownloadClient(),
      ),
    );
    addTearDown(controller.dispose);
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackTile(controller: controller, track: DetailCatalogue.track),
        ),
      ),
    );

    await tester.tap(find.byTooltip('More actions for Talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download for offline listening'));
    await _pumpUntil(tester, () => controller.isDownloaded(1));
    expect(controller.isDownloaded(1), isTrue);

    await tester.tap(find.byTooltip('More actions for Talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove download'));
    await _pumpUntil(tester, () => !controller.isDownloaded(1));
    expect(controller.isDownloaded(1), isFalse);
  });

  testWidgets('tapping a playable track row starts playback', (tester) async {
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(DetailPlaybackPort()),
    );
    addTearDown(controller.dispose);
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackTile(controller: controller, track: DetailCatalogue.track),
        ),
      ),
    );

    await tester.tap(find.text(DetailCatalogue.track.title));
    await tester.pumpAndSettle();

    expect(controller.playback.current, DetailCatalogue.track);
    expect(controller.playback.playing, isTrue);
  });

  testWidgets('current track leading action pauses without reloading', (
    tester,
  ) async {
    final port = DetailPlaybackPort();
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(port),
    );
    addTearDown(controller.dispose);
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await controller.play(DetailCatalogue.track);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackTile(controller: controller, track: DetailCatalogue.track),
        ),
      ),
    );

    expect(port.loadCalls, 1);
    await tester.tap(find.byTooltip('Pause Talk'));
    await tester.pump();

    expect(port.loadCalls, 1);
    expect(port.pauseCalls, 1);
    expect(controller.playback.playing, isFalse);
  });

  testWidgets('track row keeps actions accessible at compact phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    final directory = await Directory.systemTemp.createTemp(
      'dhamma-ui-accessibility-',
    );
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(DetailPlaybackPort()),
      downloadManager: DownloadManager(
        directory: directory,
        client: DetailDownloadClient(),
      ),
    );
    addTearDown(controller.dispose);
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDhammaEchoTheme(),
        home: Scaffold(
          body: TrackTile(controller: controller, track: DetailCatalogue.track),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Play Talk'), findsOneWidget);
    expect(find.byTooltip('More actions for Talk'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tester.tap(find.byTooltip('More actions for Talk'));
    await tester.pumpAndSettle();
    expect(find.text('Download for offline listening'), findsOneWidget);
    expect(find.text('Add to favorites'), findsOneWidget);
    expect(find.text('Add to queue'), findsOneWidget);
  });

  testWidgets('active track row uses the shared sage selected surface', (
    tester,
  ) async {
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(DetailPlaybackPort()),
    );
    addTearDown(controller.dispose);
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await controller.play(DetailCatalogue.track);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDhammaEchoTheme(),
        home: Scaffold(
          body: TrackTile(controller: controller, track: DetailCatalogue.track),
        ),
      ),
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.tileColor, DhammaEchoColors.sage);
  });

  testWidgets('collection Explore filter returns to the root Explore surface', (
    tester,
  ) async {
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(DetailPlaybackPort()),
    );
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CollectionDetailScreen(
                    controller: controller,
                    collection: DetailCatalogue.collection,
                  ),
                ),
              ),
              child: const Text('Open collection'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore filter'));
    await tester.pumpAndSettle();

    expect(find.byType(CollectionDetailScreen), findsNothing);
    expect(controller.selectedTab, 1);
    expect(controller.audioRequest.collectionId, DetailCatalogue.collection.id);
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  int maxPumps = 100,
}) async {
  for (var pump = 0; pump < maxPumps && !predicate(); pump += 1) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(predicate(), isTrue, reason: 'condition did not complete in time');
  await tester.pump();
}

class DetailCatalogue implements CatalogueRepository {
  int collectionDetailCalls = 0;
  static const collection = CollectionSummary(
    id: 7,
    name: 'Collection Seven',
    teacherId: 16,
    teacherName: 'Teacher',
    audioCount: 1,
  );

  static const track = AudioTrack(
    id: 1,
    title: 'Talk',
    format: 'mp3',
    language: 'english',
    url: 'https://dhammadownload.com/talk.mp3',
    teacherId: 16,
    teacherName: 'Teacher',
    playable: true,
  );

  @override
  Future<CatalogueSummary> getSummary() async {
    return const CatalogueSummary(
      totalAudio: 1,
      totalTeachers: 1,
      myanmarAudio: 0,
      englishAudio: 1,
    );
  }

  @override
  Future<List<AudioCategory>> listAudioCategories() async =>
      const <AudioCategory>[];

  @override
  Future<List<TeacherSummary>> listTeachers() async {
    return const <TeacherSummary>[
      TeacherSummary(id: 16, name: 'Teacher', audioCount: 1),
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
      audioCount: 1,
      collections: <CollectionSummary>[collection],
    );
  }

  @override
  Future<CollectionSearchPage> searchCollections(
    CollectionSearchRequest request,
  ) async {
    return CollectionSearchPage(
      items: const <CollectionSummary>[collection],
      total: 1,
      limit: request.limit,
      offset: request.offset,
    );
  }

  @override
  Future<CollectionDetail> getCollection(int id) async {
    collectionDetailCalls += 1;
    return const CollectionDetail(
      id: 7,
      name: 'Collection Seven',
      teacherId: 16,
      teacherName: 'Teacher',
      audioCount: 1,
      tracks: <AudioTrack>[track],
    );
  }

  @override
  Future<AudioSearchPage> searchAudio(AudioSearchRequest request) async {
    return AudioSearchPage(
      items: const <AudioTrack>[track],
      total: 1,
      limit: request.limit,
      offset: request.offset,
    );
  }

  @override
  Future<AudioTrack> getAudioTrack(int id) async => track;
}

class DetailDownloadClient implements DownloadClient {
  @override
  Future<DownloadResponse> get(Uri uri) async {
    return DownloadResponse(
      statusCode: HttpStatus.ok,
      contentLength: 3,
      bytes: Stream<List<int>>.value(<int>[1, 2, 3]),
    );
  }

  @override
  void close() {}
}

class DetailPlaybackPort implements PlaybackPort {
  final StreamController<PlaybackPortEvent> _events =
      StreamController<PlaybackPortEvent>.broadcast();
  int loadCalls = 0;
  int pauseCalls = 0;

  void emit(PlaybackPortEvent event) => _events.add(event);

  @override
  Stream<PlaybackPortEvent> get events => _events.stream;

  @override
  Future<void> dispose() => _events.close();

  @override
  Future<void> load(AudioTrack track, Uri uri) async {
    loadCalls += 1;
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double value) async {}

  @override
  Future<void> setVolume(double value) async {}
}
