import 'dart:io';

import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/app/dhamma_echo_app.dart';
import 'package:dhamma_echo/data/catalogue_asset_installer.dart';
import 'package:dhamma_echo/data/local_state_repository.dart';
import 'package:dhamma_echo/data/sqflite_catalogue_repository.dart';
import 'package:dhamma_echo/downloads/download_manager.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.aungmyokyaw.dhammaecho.playback',
    androidNotificationChannelName: 'Dhamma Echo playback',
    androidNotificationOngoing: true,
  );

  final database = await const CatalogueAssetInstaller().openReadOnly();
  final statePath = p.join(
    await getDatabasesPath(),
    'dhamma-echo',
    'state.json',
  );
  final supportDirectory = await getApplicationSupportDirectory();
  final controller = AppController(
    catalogue: SqfliteCatalogueRepository(database),
    playback: PlaybackController(JustAudioPlaybackPort()),
    stateRepository: LocalStateRepository(File(statePath)),
    downloadManager: DownloadManager(
      directory: Directory(
        p.join(supportDirectory.path, 'dhamma-echo', 'downloads'),
      ),
    ),
  );
  await controller.initialize();
  runApp(DhammaEchoApp(controller: controller));
}
