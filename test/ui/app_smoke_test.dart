import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/app/dhamma_echo_app.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('root navigation exposes five mobile destinations and settings', (
    tester,
  ) async {
    final controller = AppController(
      catalogue: FakeCatalogue(),
      playback: PlaybackController(FakePlaybackPort()),
    );
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(DhammaEchoApp(controller: controller));
    await tester.pumpAndSettle();
    final navigation = find.byType(NavigationBar);
    expect(
      find.descendant(of: navigation, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(
      find.descendant(of: navigation, matching: find.text('Explore')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Collections')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Teachers')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Library')),
      findsOneWidget,
    );
  });

  testWidgets('theme uses neutral surfaces and matched Material 3 roles', (
    tester,
  ) async {
    final controller = AppController(
      catalogue: FakeCatalogue(),
      playback: PlaybackController(FakePlaybackPort()),
    );
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(DhammaEchoApp(controller: controller));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = app.theme!;
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAF7));
    expect(
      theme.navigationBarTheme.indicatorColor,
      theme.colorScheme.secondaryContainer,
    );
    expect(
      theme.searchBarTheme.elevation?.resolve(<WidgetState>{}),
      0,
    );
  });

  testWidgets('filters and library use clear section labels', (tester) async {
    final controller = AppController(
      catalogue: FakeCatalogue(),
      playback: PlaybackController(FakePlaybackPort()),
    );
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(DhammaEchoApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Your library'), findsOneWidget);
  });

  testWidgets('selecting a talk shows the persistent mini player', (
    tester,
  ) async {
    final controller = AppController(
      catalogue: FakeCatalogue(),
      playback: PlaybackController(FakePlaybackPort()),
    );
    await controller.initialize(
      persistedState: const PersistedState.defaults(),
    );
    await tester.pumpWidget(DhammaEchoApp(controller: controller));
    await controller.play(FakeCatalogue.track);
    await tester.pump();
    expect(find.text('Fixture Talk'), findsWidgets);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
  });
}

class FakeCatalogue implements CatalogueRepository {
  static const track = AudioTrack(
    id: 1,
    title: 'Fixture Talk',
    format: 'mp3',
    language: 'english',
    url: 'https://dhammadownload.com/fixture.mp3',
    teacherId: 16,
    teacherName: 'Fixture Teacher',
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
    return const [
      TeacherSummary(id: 16, name: 'Fixture Teacher', audioCount: 1),
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
      name: 'Fixture Teacher',
      audioCount: 1,
      collections: [],
    );
  }

  @override
  Future<CollectionSearchPage> searchCollections(
    CollectionSearchRequest request,
  ) async {
    return const CollectionSearchPage(
      items: [],
      total: 0,
      limit: 24,
      offset: 0,
    );
  }

  @override
  Future<CollectionDetail> getCollection(int id) async {
    return const CollectionDetail(
      id: 1,
      name: 'Collection',
      teacherName: 'Fixture Teacher',
      audioCount: 1,
      tracks: [track],
    );
  }

  @override
  Future<AudioSearchPage> searchAudio(AudioSearchRequest request) async {
    return const AudioSearchPage(
      items: [track],
      total: 1,
      limit: 50,
      offset: 0,
    );
  }

  @override
  Future<AudioTrack> getAudioTrack(int id) async => track;
}

class FakePlaybackPort implements PlaybackPort {
  @override
  Stream<PlaybackPortEvent> get events =>
      const Stream<PlaybackPortEvent>.empty();

  @override
  Future<void> dispose() async {}

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
