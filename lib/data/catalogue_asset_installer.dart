import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class CatalogueAssetInstaller {
  const CatalogueAssetInstaller({this.assetPath = 'assets/catalogue/dhamma.db'});

  static const int productionByteLength = 27750400;
  final String assetPath;

  Future<Database> openReadOnly({AssetBundle bundle = rootBundle}) async {
    final data = await bundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    validateReleaseAsset(bytes);
    final databasesPath = await getDatabasesPath();
    final destination = File(p.join(databasesPath, 'dhamma-echo', 'dhamma.db'));
    await destination.parent.create(recursive: true);
    if (!await destination.exists() || await destination.length() != bytes.length) {
      await destination.writeAsBytes(bytes, flush: true);
    }
    return openDatabase(destination.path, readOnly: true, singleInstance: true);
  }

  @visibleForTesting
  void validateReleaseAsset(Uint8List bytes) {
    if (!kDebugMode && bytes.lengthInBytes != productionByteLength) {
      throw StateError(
        'The production Dhamma catalogue is missing. Run tool/fetch_catalogue.py before a release build.',
      );
    }
  }
}
