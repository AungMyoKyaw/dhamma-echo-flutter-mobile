import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin seam over `connectivity_plus` so controllers can be tested offline.
abstract class ConnectivityService {
  /// Emits whenever reachability changes (true = some network available).
  Stream<bool> get onlineChanges;

  Future<bool> isOnline();

  /// True on Wi-Fi or ethernet (i.e. not metered cellular only).
  Future<bool> isUnmetered();
}

class PlusConnectivityService implements ConnectivityService {
  PlusConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> r) =>
      r.isNotEmpty && !r.every((e) => e == ConnectivityResult.none);

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_online);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Future<bool> isUnmetered() async {
    final r = await _connectivity.checkConnectivity();
    return r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.ethernet);
  }
}
