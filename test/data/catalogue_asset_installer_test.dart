import 'dart:convert';
import 'dart:typed_data';

import 'package:dhamma_echo/data/catalogue_asset_installer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const installer = CatalogueAssetInstaller();

  test('catalogue validation rejects data without a SQLite header', () {
    expect(
      () => installer.validateReleaseAsset(
        Uint8List.fromList(const <int>[1, 2, 3, 4]),
      ),
      throwsStateError,
    );
  });

  test(
    'catalogue validation rejects a fixture-sized SQLite database',
    () {
      final bytes = Uint8List.fromList(<int>[
        ...ascii.encode('SQLite format 3\u0000'),
        ...List<int>.filled(64, 0),
      ]);

      expect(() => installer.validateReleaseAsset(bytes), throwsStateError);
    },
  );
}
