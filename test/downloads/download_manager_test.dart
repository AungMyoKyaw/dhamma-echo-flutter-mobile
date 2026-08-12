import 'dart:async';
import 'dart:io';

import 'package:dhamma_echo/domain/models.dart';
import 'package:dhamma_echo/downloads/download_client.dart';
import 'package:dhamma_echo/downloads/download_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dhamma-downloads-');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('io download client returns bytes without following redirects', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      if (request.uri.path == '/redirect') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '/target');
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..contentLength = 3
          ..add(<int>[1, 2, 3]);
      }
      await request.response.close();
    });
    final client = IoDownloadClient();
    addTearDown(client.close);
    final base = 'http://${server.address.address}:${server.port}';

    final redirect = await client.get(Uri.parse('$base/redirect'));
    expect(redirect.statusCode, HttpStatus.found);
    await redirect.bytes.drain<void>();

    final response = await client.get(Uri.parse('$base/target'));
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 3);
    expect(await response.bytes.expand((chunk) => chunk).toList(), <int>[1, 2, 3]);
  });

  test('download writes an atomic completed file and exposes local uri', () async {
    final client = FakeDownloadClient(
      responses: <String, DownloadResponse>{
        'www.dhammadownload.com': response(<List<int>>[
          <int>[1, 2],
          <int>[3, 4],
        ]),
      },
    );
    final manager = DownloadManager(directory: directory, client: client);
    addTearDown(manager.dispose);
    await manager.initialize();

    expect(await manager.download(track), isTrue);

    expect(manager.isDownloaded(track.id), isTrue);
    final uri = manager.localUriFor(track.id);
    expect(uri?.scheme, 'file');
    expect(await File.fromUri(uri!).readAsBytes(), <int>[1, 2, 3, 4]);
    expect(
      await File('${directory.path}/${track.id}.mp3.part').exists(),
      isFalse,
    );
  });

  test('download retries only the alternate approved host', () async {
    final client = FakeDownloadClient(
      responses: <String, DownloadResponse>{
        'www.dhammadownload.com': const DownloadResponse(
          statusCode: 503,
          contentLength: 0,
          bytes: Stream<List<int>>.empty(),
        ),
        'dhammadownload.com': response(<List<int>>[
          <int>[9, 8, 7],
        ]),
      },
    );
    final manager = DownloadManager(directory: directory, client: client);
    addTearDown(manager.dispose);

    expect(await manager.download(track), isTrue);
    expect(
      client.requestedHosts,
      <String>['www.dhammadownload.com', 'dhammadownload.com'],
    );
  });

  test('unsupported and untrusted tracks never reach the network', () async {
    final client = FakeDownloadClient();
    final manager = DownloadManager(directory: directory, client: client);
    addTearDown(manager.dispose);

    expect(
      await manager.download(
        fixtureTrack(format: 'wma', playable: false, url: track.url),
      ),
      isFalse,
    );
    expect(
      await manager.download(
        fixtureTrack(url: 'https://example.com/talk.mp3'),
      ),
      isFalse,
    );
    expect(client.requestedHosts, isEmpty);
  });

  test('failed and empty responses leave no partial or completed file', () async {
    final client = FakeDownloadClient(
      responses: <String, DownloadResponse>{
        'www.dhammadownload.com': response(const <List<int>>[]),
        'dhammadownload.com': response(const <List<int>>[]),
      },
    );
    final manager = DownloadManager(directory: directory, client: client);
    addTearDown(manager.dispose);

    expect(await manager.download(track), isFalse);
    expect(manager.isDownloaded(track.id), isFalse);
    expect(await File('${directory.path}/${track.id}.mp3').exists(), isFalse);
    expect(
      await File('${directory.path}/${track.id}.mp3.part').exists(),
      isFalse,
    );
    expect(manager.errorFor(track.id), isNotEmpty);
  });

  test('content length mismatch is rejected as an incomplete download', () async {
    final client = FakeDownloadClient(
      responses: <String, DownloadResponse>{
        'www.dhammadownload.com': DownloadResponse(
          statusCode: 200,
          contentLength: 5,
          bytes: Stream<List<int>>.value(<int>[1, 2]),
        ),
        'dhammadownload.com': DownloadResponse(
          statusCode: 200,
          contentLength: 5,
          bytes: Stream<List<int>>.value(<int>[1, 2]),
        ),
      },
    );
    final manager = DownloadManager(directory: directory, client: client);
    addTearDown(manager.dispose);

    expect(await manager.download(track), isFalse);
    expect(manager.errorFor(track.id), contains('incomplete'));
    expect(await File('${directory.path}/${track.id}.mp3').exists(), isFalse);
  });

  test('initialize scans completed files and removes stale partial files', () async {
    await File('${directory.path}/11.mp3').writeAsBytes(<int>[1]);
    await File('${directory.path}/12.mp3.part').writeAsBytes(<int>[2]);
    await File('${directory.path}/notes.txt').writeAsString('keep');
    final manager = DownloadManager(
      directory: directory,
      client: FakeDownloadClient(),
    );
    addTearDown(manager.dispose);

    await manager.initialize();

    expect(manager.downloadedIds, <int>{11});
    expect(await File('${directory.path}/12.mp3.part').exists(), isFalse);
    expect(await File('${directory.path}/notes.txt').exists(), isTrue);
  });

  test('duplicate active download is suppressed and delete removes media', () async {
    final gate = StreamController<List<int>>();
    final client = FakeDownloadClient(
      responses: <String, DownloadResponse>{
        'www.dhammadownload.com': DownloadResponse(
          statusCode: 200,
          contentLength: 2,
          bytes: gate.stream,
        ),
      },
    );
    final manager = DownloadManager(directory: directory, client: client);
    addTearDown(manager.dispose);

    final first = manager.download(track);
    await Future<void>.delayed(Duration.zero);
    expect(manager.isDownloading(track.id), isTrue);
    expect(await manager.download(track), isFalse);
    gate.add(<int>[1, 2]);
    await gate.close();
    expect(await first, isTrue);

    expect(await manager.delete(track.id), isTrue);
    expect(manager.isDownloaded(track.id), isFalse);
    expect(manager.localUriFor(track.id), isNull);
  });
}

DownloadResponse response(List<List<int>> chunks) {
  final length = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
  return DownloadResponse(
    statusCode: 200,
    contentLength: length,
    bytes: Stream<List<int>>.fromIterable(chunks),
  );
}

const track = AudioTrack(
  id: 7,
  title: 'Talk',
  format: 'mp3',
  language: 'english',
  url: 'http://dhammadownload.com/talk.mp3',
  teacherId: 16,
  teacherName: 'Teacher',
  playable: true,
);

AudioTrack fixtureTrack({
  String format = 'mp3',
  bool playable = true,
  String url = 'http://dhammadownload.com/talk.mp3',
}) {
  return AudioTrack(
    id: 8,
    title: 'Fixture',
    format: format,
    language: 'english',
    url: url,
    teacherId: 16,
    teacherName: 'Teacher',
    playable: playable,
  );
}

class FakeDownloadClient implements DownloadClient {
  FakeDownloadClient({Map<String, DownloadResponse>? responses})
    : responses = responses ?? <String, DownloadResponse>{};

  final Map<String, DownloadResponse> responses;
  final List<String> requestedHosts = <String>[];

  @override
  Future<DownloadResponse> get(Uri uri) async {
    requestedHosts.add(uri.host);
    final response = responses[uri.host];
    if (response == null) throw SocketException('unavailable');
    return response;
  }

  @override
  void close() {}
}
