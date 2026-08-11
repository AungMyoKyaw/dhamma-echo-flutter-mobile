import 'dart:io';

import 'package:dhamma_echo/data/catalogue_asset_installer.dart';
import 'package:dhamma_echo/data/catalogue_repository.dart';
import 'package:dhamma_echo/data/sqflite_catalogue_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('packaged catalogue is the production SQLite catalogue', () async {
    final file = File('assets/catalogue/dhamma.db');
    expect(file.existsSync(), isTrue);
    expect(
      file.lengthSync(),
      CatalogueAssetInstaller.productionByteLength,
    );

    final database = await databaseFactoryFfi.openDatabase(file.path);
    addTearDown(database.close);
    final repository = SqfliteCatalogueRepository(database);

    final summary = await repository.getSummary();
    final teachers = await repository.listTeachers();
    final collections = await repository.searchCollections(
      const CollectionSearchRequest(limit: 24),
    );

    expect(summary.totalAudio, 30563);
    expect(summary.totalTeachers, 257);
    expect(summary.myanmarAudio, 30098);
    expect(summary.englishAudio, 465);
    expect(teachers, hasLength(257));
    expect(collections.total, 429);
  });
}
