import 'package:dhamma_echo/data/user_state_repository.dart';
import 'package:dhamma_echo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late UserStateRepository repo;

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: UserStateRepository.schemaVersion,
        onCreate: UserStateRepository.createSchema,
      ),
    );
    repo = UserStateRepository(db);
  });

  tearDown(() async {
    await repo.close();
  });

  test('persists settings round-trip', () async {
    const custom = AppSettings(
      language: 'my',
      themeMode: ThemeMode.dark,
      playbackSpeed: 1.5,
      wifiOnly: false,
      showLegacy: false,
      pdfTint: PdfTint.dark,
    );
    await repo.saveSettings(custom);
    final loaded = await repo.loadSettings();
    expect(loaded.language, 'my');
    expect(loaded.themeMode, ThemeMode.dark);
    expect(loaded.playbackSpeed, 1.5);
    expect(loaded.wifiOnly, isFalse);
    expect(loaded.showLegacy, isFalse);
    expect(loaded.pdfTint, PdfTint.dark);
  });

  test('serialises concurrent saved/history/download writes', () async {
    await Future.wait([
      repo.setSaved(1, saved: true),
      repo.setSaved(2, saved: true),
      repo.recordProgress(1, positionMs: 12000, durationMs: 60000),
      repo.upsertDownload(
        const DownloadRecord(
          mediaId: 1,
          status: DownloadStatus.completed,
          receivedBytes: 1024,
          totalBytes: 1024,
          localPath: '/tmp/1.mp3',
        ),
      ),
    ]);
    expect(await repo.savedIds(), containsAll([1, 2]));
    final p = await repo.progressFor(1);
    expect(p?.positionMs, 12000);
    final dls = await repo.downloads();
    expect(dls.single.localPath, '/tmp/1.mp3');
  });
}
