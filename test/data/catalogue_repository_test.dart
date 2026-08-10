import 'package:dhamma_echo/data/sqflite_catalogue_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late SqfliteCatalogueRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await seedCatalogueFixture(database);
    repository = SqfliteCatalogueRepository(database);
  });

  tearDown(() => database.close());

  test('summary and categories remain audio-only', () async {
    final summary = await repository.getSummary();
    expect(summary.totalAudio, 5);
    expect(summary.totalTeachers, 3);
    expect(summary.myanmarAudio, 2);
    expect(summary.englishAudio, 3);
    final categories = await repository.listAudioCategories();
    expect(categories.map((e) => e.id), [1, 4, 5, 7]);
  });

  test('teacher search and detail preserve fallbacks and natural collections', () async {
    final search = await repository.searchTeachers('mogok', limit: 100);
    expect(search.single.id, 16);
    final detail = await repository.getTeacher(16);
    expect(detail.collections.map((e) => e.name), ['Course 2', 'Course 10']);
  });

  test('collection search groups naturally and detail orders track numbers', () async {
    final page = await repository.searchCollections(const CollectionSearchRequest(limit: 24));
    expect(page.total, 3);
    expect(page.items.map((e) => e.id), [11, 10, 12]);
    final detail = await repository.getCollection(10);
    expect(detail.tracks.map((e) => e.id), [1, 3]);
    expect(detail.tracks.last.title, 'Untitled talk');
  });

  test('audio search applies every filter and playback trust policy', () async {
    final page = await repository.searchAudio(
      const AudioSearchRequest(
        query: 'loving',
        language: 'english',
        format: 'mp3',
        teacherId: 16,
        categoryId: 7,
        collectionId: 10,
        limit: 50,
      ),
    );
    expect(page.total, 1);
    expect(page.items.single.title, 'Loving Kindness');
    expect(page.items.single.playable, isTrue);
    expect((await repository.getAudioTrack(6)).playable, isFalse);
  });

  test('missing details and invalid requests fail', () async {
    expect(repository.getAudioTrack(999), throwsA(isA<CatalogueNotFoundException>()));
    expect(repository.getCollection(999), throwsA(isA<CatalogueNotFoundException>()));
    expect(repository.getTeacher(999), throwsA(isA<CatalogueNotFoundException>()));
    expect(
      repository.searchAudio(const AudioSearchRequest(language: 'thai', limit: 50)),
      throwsArgumentError,
    );
  });
}

Future<void> seedCatalogueFixture(Database db) async {
  await db.execute('CREATE TABLE teachers (id INTEGER PRIMARY KEY, name TEXT NOT NULL, name_myanmar TEXT, title TEXT, description TEXT)');
  await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL, language TEXT NOT NULL)');
  await db.execute('CREATE TABLE media (id INTEGER PRIMARY KEY, title TEXT, type TEXT NOT NULL, format TEXT, language TEXT NOT NULL, url TEXT NOT NULL, date_recorded TEXT, location TEXT, teacher_id INTEGER, category_id INTEGER)');
  await db.execute('CREATE TABLE collections (id INTEGER PRIMARY KEY, name TEXT NOT NULL, description TEXT, teacher_id INTEGER, type TEXT, source_page TEXT)');
  await db.execute('CREATE TABLE media_collections (media_id INTEGER NOT NULL, collection_id INTEGER NOT NULL, track_number INTEGER, PRIMARY KEY(media_id, collection_id))');
  await db.rawInsert("INSERT INTO teachers VALUES (16, ' Mogok  Sayadaw ', 'မိုးကုတ်ဆရာတော်ဘုရားကြီး', NULL, NULL)");
  await db.rawInsert("INSERT INTO teachers VALUES (42, 'The Inn Gu Sayadaw', NULL, NULL, NULL)");
  await db.rawInsert("INSERT INTO teachers VALUES (99, 'Teacher 99', NULL, 'Sayadaw', 'Fixture')");
  for (final row in <List<Object>>[
    [1, 'Audio in Myanmar', 'audio', 'myanmar'],
    [4, 'Abhidhamma in Myanmar', 'abhidhamma', 'myanmar'],
    [5, 'Abhidhamma in English', 'abhidhamma', 'english'],
    [7, 'Audio in English', 'audio', 'english'],
    [8, 'Video in Myanmar', 'video', 'myanmar'],
  ]) {
    await db.rawInsert('INSERT INTO categories VALUES (?, ?, ?, ?)', row);
  }
  for (final row in <List<Object?>>[
    [1, ' Loving Kindness ', 'audio', 'mp3', 'english', 'http://dhammadownload.com/audio/Loving Kindness.mp3', null, null, 16, 7],
    [2, 'Talk Two', 'audio', 'wma', 'myanmar', 'http://dhammadownload.com/audio/two.wma', null, null, 42, 1],
    [3, '   ', 'audio', 'mp3', 'myanmar', 'https://www.dhammadownload.com/audio/three.mp3', null, null, null, 4],
    [4, 'Abhidhamma English', 'audio', 'mp3', 'english', 'https://dhammadownload.com/audio/four.mp3', null, null, 99, 5],
    [5, 'Video', 'video', 'mp4', 'myanmar', 'https://dhammadownload.com/video.mp4', null, null, 99, 8],
    [6, 'Untrusted', 'audio', 'mp3', 'english', 'https://example.com/six.mp3', null, null, 99, 7],
  ]) {
    await db.rawInsert('INSERT INTO media VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', row);
  }
  await db.rawInsert("INSERT INTO collections VALUES (10, 'Course 10', 'Ten', 16, 'audio', 'x')");
  await db.rawInsert("INSERT INTO collections VALUES (11, 'Course 2', 'Two', 16, 'audio', 'x')");
  await db.rawInsert("INSERT INTO collections VALUES (12, 'Unknown Collection', NULL, NULL, 'audio', 'x')");
  await db.rawInsert('INSERT INTO media_collections VALUES (1, 10, 2)');
  await db.rawInsert('INSERT INTO media_collections VALUES (3, 10, NULL)');
  await db.rawInsert('INSERT INTO media_collections VALUES (4, 11, 1)');
  await db.rawInsert('INSERT INTO media_collections VALUES (2, 12, 1)');
}
