import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:dhamma_echo/ui/screens/collection_detail_screen.dart';
import 'package:dhamma_echo/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings reflects controller changes while the route is open', (tester) async {
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(DetailPlaybackPort()),
    );
    await controller.initialize(persistedState: const PersistedState.defaults());
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(controller: controller)));

    await controller.setVolume(0.5);
    await tester.pump();

    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('collection Explore filter returns to the root Explore surface', (tester) async {
    final controller = AppController(
      catalogue: DetailCatalogue(),
      playback: PlaybackController(DetailPlaybackPort()),
    );
    await controller.initialize(persistedState: const PersistedState.defaults());
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

class DetailCatalogue implements CatalogueRepository {
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
    return const CatalogueSummary(totalAudio: 1, totalTeachers: 1, myanmarAudio: 0, englishAudio: 1);
  }

  @override
  Future<List<AudioCategory>> listAudioCategories() async => const <AudioCategory>[];

  @override
  Future<List<TeacherSummary>> listFeaturedTeachers({int limit = 100}) async {
    return const <TeacherSummary>[TeacherSummary(id: 16, name: 'Teacher', audioCount: 1)];
  }

  @override
  Future<List<TeacherSummary>> searchTeachers(String query, {int limit = 100}) async {
    return listFeaturedTeachers(limit: limit);
  }

  @override
  Future<TeacherDetail> getTeacher(int id) async {
    return const TeacherDetail(id: 16, name: 'Teacher', audioCount: 1, collections: <CollectionSummary>[collection]);
  }

  @override
  Future<CollectionSearchPage> searchCollections(CollectionSearchRequest request) async {
    return CollectionSearchPage(items: const <CollectionSummary>[collection], total: 1, limit: request.limit, offset: request.offset);
  }

  @override
  Future<CollectionDetail> getCollection(int id) async {
    return const CollectionDetail(id: 7, name: 'Collection Seven', teacherId: 16, teacherName: 'Teacher', audioCount: 1, tracks: <AudioTrack>[track]);
  }

  @override
  Future<AudioSearchPage> searchAudio(AudioSearchRequest request) async {
    return AudioSearchPage(items: const <AudioTrack>[track], total: 1, limit: request.limit, offset: request.offset);
  }

  @override
  Future<AudioTrack> getAudioTrack(int id) async => track;
}

class DetailPlaybackPort implements PlaybackPort {
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
