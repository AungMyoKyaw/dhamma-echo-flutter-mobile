import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import 'data/catalogue_database.dart';
import 'data/catalogue_repository.dart';
import 'data/user_state_repository.dart';
import 'models/models.dart';
import 'router/app_router.dart';
import 'services/app_controller.dart';
import 'services/audio_engine.dart';
import 'services/audio_playback_controller.dart';
import 'services/connectivity_service.dart';
import 'services/download_manager.dart';
import 'theme/bagan_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await pdfrxFlutterInitialize();

  final support = await getApplicationSupportDirectory();
  final catalogueDb = await CatalogueDatabase.open();
  final userState = await UserStateRepository.open(
    p.join(support.path, 'user_state.db'),
  );
  final connectivity = PlusConnectivityService();
  final app = AppController(
    catalogue: CatalogueRepository(catalogueDb),
    userState: userState,
    connectivity: connectivity,
  );
  await app.init();

  final downloads = DownloadManager(
    repository: userState,
    downloader: DioDownloader(),
    connectivity: connectivity,
    directory: () async => Directory(p.join(support.path, 'downloads')),
    wifiOnly: () => app.settings.wifiOnly,
  );
  await downloads.init();

  AudioEngine engine;
  try {
    engine = await JustAudioEngine.create();
  } on Object catch (e) {
    debugPrint('AudioService init failed, falling back to idle engine: $e');
    engine = _IdleAudioEngine();
  }

  final audio = AudioPlaybackController(
    engine: engine,
    userState: userState,
    localPathFor: downloads.localPathFor,
    defaultSpeed: app.settings.playbackSpeed,
    onHistoryChanged: () => unawaited(app.refreshHistory()),
  );

  runApp(DhammaEchoApp(app: app, downloads: downloads, audio: audio));
}

class DhammaEchoApp extends StatefulWidget {
  const DhammaEchoApp({
    super.key,
    required this.app,
    required this.downloads,
    required this.audio,
  });

  final AppController app;
  final DownloadManager downloads;
  final AudioPlaybackController audio;

  @override
  State<DhammaEchoApp> createState() => _DhammaEchoAppState();
}

class _DhammaEchoAppState extends State<DhammaEchoApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.app),
      ChangeNotifierProvider.value(value: widget.downloads),
      ChangeNotifierProvider.value(value: widget.audio),
    ],
    child: Selector<AppController, ThemeMode>(
      selector: (_, a) => a.themeMode,
      builder: (context, mode, _) => MaterialApp.router(
        title: 'Dhamma Echo',
        debugShowCheckedModeBanner: false,
        theme: BaganTheme.light,
        darkTheme: BaganTheme.dark,
        themeMode: mode,
        routerConfig: _router,
      ),
    ),
  );
}

class _IdleAudioEngine implements AudioEngine {
  @override
  Duration? get duration => null;
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
