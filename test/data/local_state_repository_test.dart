import 'dart:io';

import 'package:dhamma_echo/data/local_state_repository.dart';
import 'package:dhamma_echo/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File file;
  late LocalStateRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dhamma-echo-state-');
    file = File('${directory.path}/state.json');
    repository = LocalStateRepository(file);
  });

  tearDown(() => directory.delete(recursive: true));

  test('missing and corrupt state fall back safely', () async {
    expect(await repository.load(), const PersistedState.defaults());
    await file.writeAsString('{broken');
    expect(await repository.load(), const PersistedState.defaults());
  });

  test('save validates deduplicates and bounds library state', () async {
    final history = List<HistoryEntry>.generate(
      120,
      (index) => HistoryEntry(id: index + 1, playedAt: index.toDouble()),
    );
    final resume = <int, double>{
      for (var index = 1; index <= 520; index += 1) index: index.toDouble(),
    };
    await repository.save(
      PersistedState(
        library: LibraryState(
          favorites: const [1, 1, -1, 2],
          history: history,
          resume: resume,
        ),
        settings: const SettingsState(playbackRate: 1.5, volume: 0.4),
      ),
    );
    final loaded = await repository.load();
    expect(loaded.library.favorites, [1, 2]);
    expect(loaded.library.history, hasLength(100));
    expect(loaded.library.resume, hasLength(500));
    expect(loaded.settings.playbackRate, 1.5);
  });

  test('invalid persisted settings use defaults', () async {
    await file.writeAsString(
      '{"version":1,"library":{},"settings":{"playbackRate":9,"volume":2}}',
    );
    expect((await repository.load()).settings, const SettingsState.defaults());
  });

  test(
    'concurrent saves are serialized and preserve the latest state',
    () async {
      final saves = <Future<void>>[];
      for (var index = 1; index <= 50; index += 1) {
        saves.add(
          repository.save(
            PersistedState(
              library: LibraryState(
                favorites: <int>[index],
                history: const <HistoryEntry>[],
                resume: const <int, double>{},
              ),
              settings: const SettingsState.defaults(),
            ),
          ),
        );
      }

      await Future.wait(saves);

      expect((await repository.load()).library.favorites, <int>[50]);
    },
  );
}
