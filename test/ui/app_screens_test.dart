import 'dart:io';

import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/data/user_state_repository.dart';
import 'package:dhamma_echo/main.dart';
import 'package:dhamma_echo/models/models.dart';
import 'package:dhamma_echo/services/app_controller.dart';
import 'package:dhamma_echo/services/audio_engine.dart';
import 'package:dhamma_echo/services/audio_playback_controller.dart';
import 'package:dhamma_echo/services/connectivity_service.dart';
import 'package:dhamma_echo/services/download_manager.dart';
import 'package:dhamma_echo/theme/bagan_theme.dart';
import 'package:dhamma_echo/ui/screens/legacy_media_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _TestConnectivity implements ConnectivityService {
  bool online = true;
  @override
  Stream<bool> get onlineChanges => const Stream.empty();
  @override
  Future<bool> isOnline() async => online;
  @override
  Future<bool> isUnmetered() async => true;
}

class _TestDownloader implements FileDownloader {
  @override
  DownloadTask start(
    Uri url,
    String savePath,
    void Function(int received, int total) onProgress,
  ) => DownloadTask(done: Future<void>.value(), cancel: () {});
}

class _TestAudioEngine implements AudioEngine {
  @override
  Duration? get duration => const Duration(minutes: 45);
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  set onSkipNext(void Function()? callback) {}
  @override
  set onSkipPrevious(void Function()? callback) {}
  @override
  bool get playing => false;
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Duration get position => Duration.zero;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<EngineState> get stateStream => const Stream.empty();
  @override
  Future<void> dispose() async {}
  @override
  Future<void> load(
    MediaItem media, {
    String? filePath,
    Uri? remote,
    Duration? start,
  }) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> stop() async {}
}

Future<Database> _buildSeedCatalogue() async {
  final db = await databaseFactoryFfiNoIsolate.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute(
    'CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT, type TEXT, language TEXT)',
  );
  await db.execute(
    'CREATE TABLE teachers (id INTEGER PRIMARY KEY, name TEXT, name_myanmar TEXT, title TEXT, description TEXT, page_url TEXT, image_url TEXT)',
  );
  await db.execute(
    'CREATE TABLE media (id INTEGER PRIMARY KEY, title TEXT, title_myanmar TEXT, type TEXT, format TEXT, language TEXT, url TEXT, file_size INTEGER, duration TEXT, description TEXT, date_recorded TEXT, location TEXT, teacher_id INTEGER, category_id INTEGER, source_page TEXT)',
  );
  await db.execute(
    'CREATE TABLE collections (id INTEGER PRIMARY KEY, name TEXT, description TEXT, teacher_id INTEGER, type TEXT, source_page TEXT)',
  );
  await db.execute(
    'CREATE TABLE media_collections (media_id INTEGER, collection_id INTEGER, track_number INTEGER, PRIMARY KEY (media_id, collection_id))',
  );
  await db.insert('teachers', {'id': 16, 'name': 'မိုးကုတ်ဆရာတော်ဘုရားကြီး'});
  await db.insert('teachers', {'id': 42, 'name': 'သဲအင်းဂူဆရာတော်ဘုရားကြီး'});
  await db.insert('media', {
    'id': 1,
    'title': '၁။ ပဋ္ဌာန်းအမွှန်းပါဠိတော်',
    'type': 'audio',
    'format': 'mp3',
    'language': 'myanmar',
    'url': 'https://dhammadownload.com/test.mp3',
    'teacher_id': 16,
    'category_id': 4,
  });
  await db.insert('media', {
    'id': 2,
    'title': 'မဟာသမယသုတ် ပါဋ္ဌိတော်',
    'type': 'ebook',
    'format': 'pdf',
    'language': 'myanmar',
    'url': 'https://dhammadownload.com/test.pdf',
    'teacher_id': 16,
    'category_id': 2,
  });
  await db.insert('media', {
    'id': 3,
    'title': 'One Day At Panditarama Forest Centre',
    'type': 'video',
    'format': 'wmv',
    'language': 'english',
    'url': 'https://dhammadownload.com/test.wmv',
    'teacher_id': 42,
    'category_id': 6,
  });
  await db.insert('collections', {
    'id': 10,
    'name': 'MP3 Disc 45',
    'teacher_id': 16,
    'type': 'audio',
  });
  await db.insert('media_collections', {
    'media_id': 1,
    'collection_id': 10,
    'track_number': 1,
  });
  return db;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  sqfliteFfiInit();

  testWidgets(
    'navigates Home, Browse, Search, Library, Settings without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late Database catDb;
      late Database userDb;
      final tmp = Directory.systemTemp.createTempSync('dhamma_ui_');
      late AppController app;
      late DownloadManager downloads;

      await tester.runAsync(() async {
        catDb = await _buildSeedCatalogue();
        userDb = await databaseFactoryFfiNoIsolate.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            singleInstance: false,
            version: UserStateRepository.schemaVersion,
            onCreate: UserStateRepository.createSchema,
          ),
        );
        final userState = UserStateRepository(userDb);
        final conn = _TestConnectivity()..online = false;
        app = AppController(
          catalogue: CatalogueRepository(catDb),
          userState: userState,
          connectivity: conn,
        );
        await app.init();

        downloads = DownloadManager(
          repository: userState,
          downloader: _TestDownloader(),
          connectivity: conn,
          directory: () async => tmp,
          wifiOnly: () => app.settings.wifiOnly,
        );
        await downloads.init();
      });

      final audio = AudioPlaybackController(engine: _TestAudioEngine());
      addTearDown(() async {
        await tester.runAsync(() async {
          audio.dispose();
          downloads.dispose();
          app.dispose();
          await catDb.close();
          await userDb.close();
        });
        tmp.deleteSync(recursive: true);
      });

      await tester.pumpWidget(
        DhammaEchoApp(app: app, downloads: downloads, audio: audio),
      );
      await _settle(tester);

      expect(find.text('Dhamma Echo'), findsOneWidget);
      expect(find.text('Audio Talks'), findsOneWidget);

      // Switch to Browse -> eBooks -> Teachers
      await tester.tap(find.text('Browse'));
      await _settle(tester);
      expect(find.text('၁။ ပဋ္ဌာန်းအမွှန်းပါဠိတော်'), findsOneWidget);

      await tester.tap(find.text('eBooks'));
      await _settle(tester);
      expect(find.text('မဟာသမယသုတ် ပါဋ္ဌိတော်'), findsOneWidget);

      await tester.tap(find.text('Teachers'));
      await _settle(tester);
      expect(find.text('Teachers & Sources'), findsOneWidget);

      // Switch to Search
      await tester.tap(find.text('Search'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Panditarama');
      await tester.pump(const Duration(milliseconds: 350));
      await _settle(tester);
      expect(find.text('One Day At Panditarama Forest Centre'), findsOneWidget);

      // Tap legacy item -> LegacyMediaDetailScreen
      await tester.tap(find.text('One Day At Panditarama Forest Centre'));
      await _settle(tester);
      expect(find.text('Playback not supported in-app'), findsOneWidget);
      await tester.tap(find.text('Media Detail'));
      await _settle(tester);

      // Switch to Library (shows offline banner + empty state)
      await tester.tap(find.text('Library'));
      await _settle(tester);
      expect(find.text('You are offline'), findsOneWidget);
      expect(find.text('Nothing saved yet'), findsOneWidget);

      // Open Settings and toggle Myanmar + Dark mode
      await tester.tap(find.bySemanticsLabel('Settings'));
      await _settle(tester);
      await tester.tap(find.text('မြန်မာ'));
      await tester.tap(find.text('Dark'));
      await _settle(tester);
      expect(find.text('ဆက်တင်'), findsOneWidget);
    },
  );

  testWidgets('wraps 250-char Myanmar title without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late Database catDb;
    late Database userDb;
    late AppController app;
    final longTitle =
        'စင်္ကာပူနိုင်ငံ ဆိုင်ရာ မြန်မာသံရုံး၌ ကျေးဇူးတော်ရှင် ဗန်းမော်ဆရာတော်ဘုရားကြီးအား အမှုးပြု၍ '
        'နိုင်ငံတော် သံဃမဟာနာယက ဆရာတော်ကြီးများနှင့် စင်္ကာပူနိုင်ငံရှိ မြန်မာ ဘုန်းတော်ကြီးကျောင်းပေါင်းစုံ မှ '
        'ဆရာတော်ကြီးများ ၇-ရက် တိုင်တိုင် ကျင်းပ ပူဇော်ခဲ့သော အသံမစဲ အဘိဓမ္မာရွတ်ဖတ်သရဇ္ဇယ် ပွဲကြီး';

    await tester.runAsync(() async {
      catDb = await _buildSeedCatalogue();
      await catDb.insert('media', {
        'id': 99,
        'title': longTitle,
        'type': 'video',
        'format': 'wmv',
        'language': 'myanmar',
        'url': 'https://dhammadownload.com/long.wmv',
        'teacher_id': 16,
        'category_id': 8,
      });
      userDb = await databaseFactoryFfiNoIsolate.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          singleInstance: false,
          version: UserStateRepository.schemaVersion,
          onCreate: UserStateRepository.createSchema,
        ),
      );
      app = AppController(
        catalogue: CatalogueRepository(catDb),
        userState: UserStateRepository(userDb),
        connectivity: _TestConnectivity(),
      );
      await app.init();
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        app.dispose();
        await catDb.close();
        await userDb.close();
      });
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          theme: BaganTheme.light,
          home: const LegacyMediaDetailScreen(mediaId: 99),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text(longTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
