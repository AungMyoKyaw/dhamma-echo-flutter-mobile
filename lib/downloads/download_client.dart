import 'dart:io';

class DownloadResponse {
  const DownloadResponse({
    required this.statusCode,
    required this.contentLength,
    required this.bytes,
  });

  final int statusCode;
  final int contentLength;
  final Stream<List<int>> bytes;
}

abstract interface class DownloadClient {
  Future<DownloadResponse> get(Uri uri);
  void close();
}

class IoDownloadClient implements DownloadClient {
  IoDownloadClient({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<DownloadResponse> get(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.followRedirects = false;
    request.maxRedirects = 0;
    final response = await request.close();
    return DownloadResponse(
      statusCode: response.statusCode,
      contentLength: response.contentLength,
      bytes: response,
    );
  }

  @override
  void close() => _client.close(force: true);
}
