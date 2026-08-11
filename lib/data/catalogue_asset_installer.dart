import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class CatalogueAssetInstaller {
  const CatalogueAssetInstaller({
    this.assetPath = 'assets/catalogue/dhamma.db',
  });

  static const int productionByteLength = 27750400;
  static const String productionSha256 =
      'd88cfda6d761d0e682dac3bf29ab3b1d7019496a114defe057bfc55a6e746d31';
  static const List<int> _sqliteHeader = <int>[
    83,
    81,
    76,
    105,
    116,
    101,
    32,
    102,
    111,
    114,
    109,
    97,
    116,
    32,
    51,
    0,
  ];

  final String assetPath;

  Future<Database> openReadOnly({AssetBundle? bundle}) async {
    final data = await (bundle ?? rootBundle).load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    validateReleaseAsset(bytes);
    final databasesPath = await getDatabasesPath();
    final version = productionSha256.substring(0, 12);
    final destination = File(
      p.join(databasesPath, 'dhamma-echo', 'dhamma-$version.db'),
    );
    await destination.parent.create(recursive: true);
    if (!await destination.exists() ||
        await destination.length() != bytes.length) {
      await destination.writeAsBytes(bytes, flush: true);
    }
    return openDatabase(destination.path, readOnly: true, singleInstance: true);
  }

  @visibleForTesting
  void validateReleaseAsset(Uint8List bytes) {
    if (bytes.lengthInBytes < _sqliteHeader.length) {
      throw StateError(
        'The bundled Dhamma catalogue is not a SQLite database.',
      );
    }
    for (var index = 0; index < _sqliteHeader.length; index += 1) {
      if (bytes[index] != _sqliteHeader[index]) {
        throw StateError(
          'The bundled Dhamma catalogue is not a SQLite database.',
        );
      }
    }
    if (bytes.lengthInBytes != productionByteLength) {
      throw StateError(
        'The production Dhamma catalogue is missing or invalid. Verify assets/catalogue/dhamma.db before running the app.',
      );
    }
  }
}
