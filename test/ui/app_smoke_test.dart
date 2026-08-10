import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/app/dhamma_echo_app.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('root navigation exposes five mobile destinations and settings', (tester) async {
    final controller = AppController(
      catalogue: FakeCatalogue(),
      playback: PlaybackController(FakePlaybackPort()),
    );
    await controller.initialize(persistedState: const PersistedState.defaults());
    await tester.pumpWidget(DhammaEchoApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Teachers'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('selecting a talk shows the persistent mini player', (tester) async {
    final controller = AppController(
      catalogue: FakeCatalogue(),
      playback: PlaybackController(FakePlaybackPort()),
    );
    await controller.initialize(persistedState: const PersistedState.defaults());
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
  Future<List<AudioCategory>> listAudioCategories() async => const <AudioCategory>[];

  @override
  Future<List<TeacherSummary>> listFeaturedTeachers({int limit = 100}) async {
    return const [TeacherSummary(id: 16, name: 'Fixture Teacher', audioCount: 1)];
  }

  @override
  Future<List<TeacherSummary>> searchTeachers(String query, {int limit = 100}) async {
    return listFeaturedTeachers(limit: limit);
  }

  @override
  Future<TeacherDetail> getTeacher(int id) async {
    return const TeacherDetail(id: 16, name: 'Fixture Teacher', audioCount: 1, collections: []);
  }

  @override
  Future<CollectionSearchPage> searchCollections(CollectionSearchRequest request) async {
    return const CollectionSearchPage(items: [], total: 0, limit: 24, offset: 0);
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
    return const AudioSearchPage(items: [track], total: 1, limit: 50, offset: 0);
  }

  @override
  Future<AudioTrack> getAudioTrack(int id) async => track;
}

class FakePlaybackPort implements PlaybackPort {
  @override
  Stream<PlaybackPortEvent> get events => const Stream<PlaybackPortEvent>.empty();

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
