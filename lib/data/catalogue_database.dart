import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Installs the bundled catalogue and opens it read-only.
abstract final class CatalogueDatabase {
  static const assetPath = 'assets/catalogue/dhamma.db';

  /// Bump when a new catalogue ships so existing installs refresh the copy.
  static const catalogueVersion = '1';

  static Future<Database> open() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'catalogue'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'dhamma-v$catalogueVersion.db'));
    final data = await rootBundle.load(assetPath);
    if (!await file.exists() || await file.length() != data.lengthInBytes) {
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await temp.rename(file.path);
    }
    return openDatabase(file.path, readOnly: true, singleInstance: true);
  }
}
