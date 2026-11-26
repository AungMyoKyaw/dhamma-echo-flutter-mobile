import 'dart:io';

import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  CatalogueRepository? repo;

  setUpAll(() async {
    db = await databaseFactoryFfi.openDatabase(
      File('assets/catalogue/dhamma.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    repo = CatalogueRepository(db);
  });

  tearDownAll(() async {
    await repo?.close();
  });

  test('matches production catalogue totals', () async {
    final counts = await repo!.getArchiveCounts();
    expect(counts.total, 47960);
    expect(counts.audio, 30563);
    expect(counts.video, 14865);
    expect(counts.ebook, 2532);
    expect(counts.abhidhamma, 1194);
    expect(counts.teachers, 256);
    expect(counts.collections, 1315);
  });

  test('pins featured teachers in canonical order', () async {
    const expected = [16, 42, 40, 53, 61, 8, 55, 1307];
    final featured = await repo!.getFeaturedTeachers();
    expect(featured.map((t) => t.id).toList(), expected);
    expect(featured.every((t) => t.featured), isTrue);

    final all = await repo!.getTeachers();
    expect(all.length, 256);
    expect(all.take(8).map((t) => t.id).toList(), expected);
  });

  test('filters Abhidhamma, legacy, and searches Myanmar text', () async {
    final abhiCount = await repo!.countMedia(abhidhammaOnly: true);
    expect(abhiCount, 1194);

    final playableAudio = await repo!.countMedia(
      kind: MediaKind.audio,
      showLegacy: false,
    );
    expect(playableAudio, 29070);

    final results = await repo!.searchMedia('ပဋ္ဌာန်း', limit: 20);
    expect(results, isNotEmpty);
  });

  test('loads collection tracks ordered', () async {
    final collections = await repo!.getFeaturedCollections(limit: 2);
    expect(collections.length, 2);
    expect(collections.first.itemCount, 752);

    final tracks = await repo!.getCollectionTracks(
      collections.first.id,
      limit: 10,
    );
    expect(tracks.length, 10);
  });
}
