import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/map_tile_provider.dart';
import '../../viewmodels/map_viewmodel.dart';

enum _DownloadStage { idle, counting, downloading, done, failed }

/// Lets the user download the map tiles around a chosen area so the safety map
/// keeps working with no connection at all.
class DownloadOfflineMapsScreen extends StatefulWidget {
  const DownloadOfflineMapsScreen({super.key});

  @override
  State<DownloadOfflineMapsScreen> createState() =>
      _DownloadOfflineMapsScreenState();
}

class _DownloadOfflineMapsScreenState extends State<DownloadOfflineMapsScreen> {
  static const _store = FMTCStore(AppConstants.offlineTileStoreName);

  final MapController _mapController = MapController();

  final TileLayer _tileLayer = TileLayer(
    urlTemplate: AppConstants.onlineTileUrl,
    userAgentPackageName: 'com.suraksha.app',
  );

  RangeValues _zoomRange = const RangeValues(12, 16);
  _DownloadStage _stage = _DownloadStage.idle;
  int _tileCount = 0;
  double _progress = 0;
  int _downloadedTiles = 0;
  String _errorMessage = '';
  StreamSubscription<DownloadProgress>? _progressSub;
  DownloadProgress? _lastProgress;

  /// Snapshot of the bounds at the moment "Measure This Area" ran, so a pan
  /// between measuring and downloading can't silently change the region.
  LatLngBounds? _measuredBounds;

  /// Whether the offline tile cache backend started successfully. If not,
  /// downloading is impossible and the screen shows an unavailable state.
  late final bool _cacheUnavailable = !MapTileProvider.isOfflineCacheReady;

  @override
  void initState() {
    super.initState();
    if (_cacheUnavailable) {
      _stage = _DownloadStage.failed;
      _errorMessage = 'Offline map storage is unavailable on this device.';
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  /// The visible map area is what gets downloaded.
  LatLngBounds get _visibleBounds => _mapController.camera.visibleBounds;

  DownloadableRegion _regionFor(LatLngBounds bounds) =>
      RectangleRegion(bounds).toDownloadable(
        minZoom: _zoomRange.start.round(),
        maxZoom: _zoomRange.end.round(),
        options: _tileLayer,
      );

  Future<void> _estimate() async {
    setState(() => _stage = _DownloadStage.counting);
    final bounds = _visibleBounds;
    try {
      final count = await _store.download.countTiles(_regionFor(bounds));
      if (!mounted) return;
      setState(() {
        _tileCount = count;
        _measuredBounds = bounds;
        _stage = _DownloadStage.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _DownloadStage.failed;
        _errorMessage = 'Could not measure this area. $e';
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _stage = _DownloadStage.downloading;
      _progress = 0;
      _downloadedTiles = 0;
      _errorMessage = '';
      _lastProgress = null;
    });

    try {
      final result = _store.download.startForeground(
        region: _regionFor(_measuredBounds ?? _visibleBounds),
        parallelThreads: 3,
        skipExistingTiles: true,
        // OSM's tile usage policy asks for gentle bulk access.
        rateLimit: 20,
      );

      await _progressSub?.cancel();
      _progressSub = result.downloadProgress.listen(
        (progress) {
          if (!mounted) return;
          _lastProgress = progress;
          setState(() {
            final pct = progress.percentageProgress;
            _progress = pct.isFinite ? (pct / 100).clamp(0.0, 1.0) : 0.0;
            _downloadedTiles = progress.attemptedTilesCount;
            _tileCount = progress.maxTilesCount;
          });
        },
        onDone: () {
          if (!mounted) return;
          // FMTC never emits addError on this stream — onDone fires on every
          // terminal outcome, including one where every tile failed. Check
          // the last known progress to tell success from silent failure.
          final progress = _lastProgress;
          final failed = progress?.failedTilesCount ?? 0;
          if (progress != null && failed > 0) {
            setState(() {
              _stage = _DownloadStage.failed;
              _errorMessage =
                  '$failed of ${progress.maxTilesCount} tiles could not be '
                  'downloaded. Check your connection and try again.';
            });
          } else {
            setState(() => _stage = _DownloadStage.done);
          }
        },
        onError: (Object e) {
          // Defensive only — FMTC's downloadProgress stream is only ever
          // added to and closed, never given an error.
          if (!mounted) return;
          setState(() {
            _stage = _DownloadStage.failed;
            _errorMessage =
                'Download stopped. Check your connection and try again.';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _DownloadStage.failed;
        _errorMessage = 'Could not start the download. $e';
      });
    }
  }

  Future<void> _cancelDownload() async {
    await _store.download.cancel();
    await _progressSub?.cancel();
    if (!mounted) return;
    setState(() => _stage = _DownloadStage.idle);
  }

  /// OSM raster tiles average roughly 15 KB each.
  String get _estimatedSize {
    final mb = (_tileCount * 15) / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final center = context.read<MapViewModel>().center;

    return Scaffold(
      appBar: AppBar(title: const Text('Download Offline Maps')),
      body: Column(
        children: [
          // ── Area preview ────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(center.latitude, center.longitude),
                    initialZoom: AppConstants.demoDefaultZoom,
                  ),
                  children: [_tileLayer],
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: _HintPill(
                    text: 'Pan and zoom to frame the area you want offline',
                  ),
                ),
              ],
            ),
          ),

          // ── Controls ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail level  ·  zoom ${_zoomRange.start.round()}–${_zoomRange.end.round()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  RangeSlider(
                    values: _zoomRange,
                    min: 8,
                    max: 18,
                    divisions: 10,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    labels: RangeLabels(
                      '${_zoomRange.start.round()}',
                      '${_zoomRange.end.round()}',
                    ),
                    onChanged: _stage == _DownloadStage.downloading
                        ? null
                        : (values) => setState(() {
                              _zoomRange = values;
                              _tileCount = 0;
                              _measuredBounds = null;
                            }),
                  ),
                  const SizedBox(height: 4),
                  _buildStatus(),
                  const SizedBox(height: 12),
                  _buildAction(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    switch (_stage) {
      case _DownloadStage.counting:
        return const Text(
          'Measuring this area…',
          style: TextStyle(fontSize: 13, color: AppColors.subtitle),
        );
      case _DownloadStage.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_downloadedTiles of $_tileCount tiles  ·  ${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
          ],
        );
      case _DownloadStage.done:
        return const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 20, color: AppColors.safeGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This area is available offline.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.safeGreen,
                ),
              ),
            ),
          ],
        );
      case _DownloadStage.failed:
        return Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(fontSize: 13, color: AppColors.primary),
              ),
            ),
          ],
        );
      case _DownloadStage.idle:
        return Text(
          _tileCount == 0
              ? 'Measure the area to see how much space it needs.'
              : '$_tileCount tiles  ·  about $_estimatedSize',
          style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
        );
    }
  }

  Widget _buildAction() {
    switch (_stage) {
      case _DownloadStage.downloading:
        return OutlinedButton(
          onPressed: _cancelDownload,
          child: const Text('Cancel Download'),
        );
      case _DownloadStage.done:
        return ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        );
      case _DownloadStage.failed:
        // No download is possible when the offline cache backend never
        // started — don't offer a Retry that would just fail again.
        return _cacheUnavailable
            ? const SizedBox.shrink()
            : ElevatedButton(
                onPressed: _startDownload,
                child: const Text('Retry'),
              );
      case _DownloadStage.counting:
        return const ElevatedButton(
          onPressed: null,
          child: Text('Measuring…'),
        );
      case _DownloadStage.idle:
        return _tileCount == 0
            ? ElevatedButton(
                onPressed: _estimate,
                child: const Text('Measure This Area'),
              )
            : ElevatedButton(
                onPressed: _startDownload,
                child: const Text('Download for Offline Use'),
              );
    }
  }
}

// ── Hint pill ────────────────────────────────────────────────────────────────

class _HintPill extends StatelessWidget {
  final String text;

  const _HintPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
