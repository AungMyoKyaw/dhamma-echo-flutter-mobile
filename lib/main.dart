import 'dart:io';

import 'package:dhamma_echo/app/app_controller.dart';
import 'package:dhamma_echo/app/dhamma_echo_app.dart';
import 'package:dhamma_echo/data/catalogue_asset_installer.dart';
import 'package:dhamma_echo/data/local_state_repository.dart';
import 'package:dhamma_echo/data/sqflite_catalogue_repository.dart';
import 'package:dhamma_echo/player/playback_controller.dart';
import 'package:dhamma_echo/player/playback_port.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await const CatalogueAssetInstaller().openReadOnly();
  final statePath = p.join(
    await getDatabasesPath(),
    'dhamma-echo',
    'state.json',
  );
  final controller = AppController(
    catalogue: SqfliteCatalogueRepository(database),
    playback: PlaybackController(JustAudioPlaybackPort()),
    stateRepository: LocalStateRepository(File(statePath)),
  );
  await controller.initialize();
  runApp(DhammaEchoApp(controller: controller));
}
