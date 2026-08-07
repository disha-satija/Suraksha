/// Three-state connectivity model as specified in the roadmap.
enum ConnectivityStatus {
  online,          // Full internet — Supabase + OSRM available
  offlineCached,   // No internet — serving from local SQLite cache (fresh)
  offlineStale,    // No internet — cache exists but is old (>24h)
}

extension ConnectivityStatusLabel on ConnectivityStatus {
  String get label {
    switch (this) {
      case ConnectivityStatus.online:
        return 'ONLINE';
      case ConnectivityStatus.offlineCached:
        return 'OFFLINE — CACHED';
      case ConnectivityStatus.offlineStale:
        return 'OFFLINE — STALE';
    }
  }

  bool get isOnline => this == ConnectivityStatus.online;
}
