import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/core/constants/app_constants.dart';
import 'package:suraksha/models/safety_score_result.dart';
import 'package:suraksha/repositories/safety_repository.dart';
import 'package:suraksha/services/onnx_service.dart';

/// The bundled grid holds ONE centroid per area — 50 areas for all of India,
/// 5 of them in Delhi. The dashboard used to name whichever centroid was
/// nearest as "your area", so anywhere in south-east Delhi or Noida reported
/// "Lajpat Nagar". These tests pin the distance gates that fixed that.
///
/// ONNX is not available under `flutter test`, so every case here exercises the
/// bundled-grid path — which is exactly the path that produced the wrong label.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SafetyRepository repo;

  setUp(() async {
    // No ApiClient and no ConnectivityService: offline-only, so getScore()
    // resolves purely from the bundled grid.
    repo = SafetyRepository(onnxService: OnnxService());
    await repo.initialize();
  });

  test('bundled grid loads', () {
    expect(repo.grid, isNotEmpty);
    expect(repo.grid.where((e) => e.city == 'Delhi').length, 5);
  });

  group('nearestEntry', () {
    test('finds the containing area at its own centroid', () {
      final near = repo.nearestEntry(28.56609, 77.24329);
      expect(near.entry?.area, 'Lajpat Nagar');
      expect(near.distanceKm, lessThan(0.1));
    });

    test('Noida Sector 62 is 14 km from the nearest known area', () {
      final near = repo.nearestEntry(28.6270, 77.3720);
      expect(near.entry?.area, 'Lajpat Nagar');
      expect(near.distanceKm, closeTo(14.28, 0.1));
    });
  });

  group('area naming is distance-gated', () {
    test('names the area when the centroid is close', () {
      final result = repo.getScore(lat: 28.56609, lng: 77.24329);

      expect(result.areaLabel, 'Lajpat Nagar');
      expect(result.summaryExplanation, contains('Lajpat Nagar scores'));
      expect(result.source, ScoreSource.cachedGrid);
      expect(result.isIndicativeOnly, isFalse);
    });

    test('presents a mid-range centroid as a reference, not as your area', () {
      // ~5 km north of the Lajpat Nagar centroid: inside the trust radius, but
      // beyond the radius at which we are willing to call it "your area".
      final result = repo.getScore(lat: 28.6110, lng: 77.2433);

      expect(result.source, ScoreSource.cachedGrid);
      expect(result.referenceDistanceKm, greaterThan(AppConstants.areaLabelMaxKm));
      expect(result.referenceDistanceKm, lessThan(AppConstants.gridTrustMaxKm));
      // Must not assert the user is in Lajpat Nagar...
      expect(result.summaryExplanation, isNot(contains('Lajpat Nagar scores')));
      // ...but should still say what it is referencing, and how far away.
      expect(result.summaryExplanation, contains('Nearest reference area'));
      expect(result.summaryExplanation, contains('Lajpat Nagar'));
      expect(result.isIndicativeOnly, isTrue);
    });

    test('reports no coverage rather than a distant area\'s score', () {
      // Noida Sector 62 — 14 km from the nearest centroid. This is the exact
      // case that used to render "Lajpat Nagar" on the home dashboard.
      final result = repo.getScore(lat: 28.6270, lng: 77.3720);

      expect(result.source, ScoreSource.unavailable);
      expect(result.areaLabel, isNull, reason: 'must not claim an area it does not cover');
      expect(result.summaryExplanation, contains('No safety data covers this location'));
      // The reference is still disclosed, with its distance, as context only.
      expect(result.summaryExplanation, contains('14 km away'));
      expect(result.isIndicativeOnly, isTrue);
    });
  });

  group('score provenance', () {
    test('grid results are labelled as offline data, not as a live model', () {
      final result = repo.getScore(lat: 28.56609, lng: 77.24329);
      expect(result.source, ScoreSource.cachedGrid);
      expect(result.sourceLabel, 'Offline data');
      expect(result.isFromCache, isTrue);
    });

    test('an uncovered location carries no fabricated feature breakdown', () {
      final result = repo.getScore(lat: 28.6270, lng: 77.3720);
      expect(result.contributions, isEmpty);
    });

    test('a covered location explains itself with all four features', () {
      final result = repo.getScore(lat: 28.56609, lng: 77.24329);
      expect(result.contributions.map((c) => c.featureName), containsAll([
        'lighting_score',
        'police_station_distance_km',
        'crowd_density',
        'crime_count',
      ]));
    });
  });
}
