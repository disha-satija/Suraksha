import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/connectivity_state.dart';

/// Monitors network state and exposes a stream of [ConnectivityStatus].
/// Also tracks when the local cache was last updated to distinguish
/// OFFLINE-CACHED (fresh) from OFFLINE-STALE (>24h old).
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  DateTime? _lastCacheUpdate;
  ConnectivityStatus _current = ConnectivityStatus.offlineCached;

  Stream<ConnectivityStatus> get statusStream => _controller.stream;
  ConnectivityStatus get currentStatus => _current;

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _current = _toStatus(result);
    _controller.add(_current);

    _connectivity.onConnectivityChanged.listen((result) {
      _current = _toStatus(result);
      _controller.add(_current);
    });
  }

  ConnectivityStatus _toStatus(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    if (hasNetwork) return ConnectivityStatus.online;

    // Offline — check cache freshness
    if (_lastCacheUpdate == null) return ConnectivityStatus.offlineStale;
    final age = DateTime.now().difference(_lastCacheUpdate!);
    return age.inHours < 24
        ? ConnectivityStatus.offlineCached
        : ConnectivityStatus.offlineStale;
  }

  void markCacheUpdated() {
    _lastCacheUpdate = DateTime.now();
  }

  bool get isOnline => _current == ConnectivityStatus.online;

  void dispose() {
    _controller.close();
  }
}
