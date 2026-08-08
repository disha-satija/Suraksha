import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/models/safe_spot_submission.dart';
import 'package:suraksha/services/database_service.dart';

/// Regression test for the Contribute flow's silent data loss.
///
/// Schema v4 bumped the version but left `m.createTable(safeSpotSubmissions)`
/// commented out, so every device that upgraded through v4 had no local
/// `safe_spot_submissions` table. `ContributeRepository.submitSafeSpot` writes
/// to that table BEFORE syncing, so the write threw and the backend POST was
/// never issued — no API call, no Supabase row, and a success message anyway.
///
/// v5 repairs those devices. These tests open a database that reports itself as
/// an older version with no tables, and assert the upgrade produces a working
/// submissions table.
void main() {
  SafeSpotSubmission sample(String id) => SafeSpotSubmission(
        localId: id,
        name: 'BML Munjal Security Gate 1',
        category: 'University Security',
        address: 'Sidhrawali, Gurugram',
        lat: 28.2100,
        lng: 76.7400,
        whySafe: 'Staffed 24/7 with a manned barrier.',
        submittedAt: DateTime.utc(2026, 8, 8, 12),
      );

  /// A database that claims to be at [version] but holds no tables, which is
  /// what forces drift to run onUpgrade(from: version, to: schemaVersion).
  AppDatabase openAt(int version) => AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (db) => db.execute('PRAGMA user_version = $version;'),
        ),
      );

  test('schema version is 6', () async {
    final db = openAt(6);
    expect(db.schemaVersion, 6);
    await db.close();
  });

  test('upgrading from v4 creates the submissions table', () async {
    // The exact state of an installed app before this fix.
    final db = openAt(4);
    addTearDown(db.close);

    // Would previously throw: no such table: safe_spot_submissions.
    await db.insertSubmission(sample('spot-1'));

    final mine = await db.getMySubmissions();
    expect(mine, hasLength(1));
    expect(mine.single.name, 'BML Munjal Security Gate 1');
    expect(mine.single.isSynced, isFalse, reason: 'must start queued for sync');
  });

  test('a submission is queued for sync, then clears once synced', () async {
    final db = openAt(4);
    addTearDown(db.close);

    await db.insertSubmission(sample('spot-2'));

    // This is the queue ContributeRepository.syncPending() drains — it is what
    // drives the backend POST, so it must be non-empty after a local write.
    expect(await db.getUnsyncedSubmissions(), hasLength(1));

    await db.markSubmissionSynced('spot-2');
    expect(await db.getUnsyncedSubmissions(), isEmpty);
    expect((await db.getMySubmissions()).single.isSynced, isTrue);
  });

  test('upgrading from v3 creates both community tables', () async {
    // v3 devices need the v4/v5 submissions table too, not just verifications.
    final db = openAt(3);
    addTearDown(db.close);

    await db.insertSubmission(sample('spot-3'));
    expect(await db.getMySubmissions(), hasLength(1));
  });

  test('a fresh install gets the table from createAll', () async {
    final db = openAt(0); // user_version 0 → onCreate
    addTearDown(db.close);

    await db.insertSubmission(sample('spot-4'));
    expect(await db.getMySubmissions(), hasLength(1));
  });

  test('repairs a database whose version is current but tables are missing', () async {
    // The state a bumped-version-with-no-createTable leaves behind: sqlite
    // reports the schema as up to date, so drift runs neither onCreate nor
    // onUpgrade, and the missing table is never noticed. The beforeOpen net
    // has to catch this, because no migration ever will.
    final db = openAt(5); // == schemaVersion, so no migration callback fires
    addTearDown(db.close);

    await db.insertSubmission(sample('spot-5'));
    expect(await db.getMySubmissions(), hasLength(1));
  });

  group('cached safe spots (offline regions)', () {
    CachedSafeSpotsCompanion spot(String id, String name, double lat, double lng) =>
        CachedSafeSpotsCompanion.insert(
          id: id,
          name: name,
          category: 'police',
          address: 'Delhi',
          lat: lat,
          lng: lng,
          safetyScore: 0.95,
          whySafe: 'Police facility with trained emergency personnel.',
          source: 'curated',
          cachedAt: DateTime.utc(2026, 8, 8),
        );

    test('upgrading from v5 creates the cache table', () async {
      final db = openAt(5);
      addTearDown(db.close);

      await db.upsertCachedSafeSpots([spot('a', 'Lajpat Nagar Police Station', 28.566, 77.243)]);
      expect(await db.cachedSafeSpotCount(), 1);
    });

    test('a second region adds to the cache rather than replacing it', () async {
      // A user who bundles two cities must keep both.
      final db = openAt(5);
      addTearDown(db.close);

      await db.upsertCachedSafeSpots([spot('delhi-1', 'Saket Police Station', 28.52, 77.20)]);
      await db.upsertCachedSafeSpots([spot('mumbai-1', 'Bandra Police Station', 19.05, 72.83)]);

      expect(await db.cachedSafeSpotCount(), 2);
    });

    test('re-downloading the same region updates rather than duplicates', () async {
      final db = openAt(5);
      addTearDown(db.close);

      await db.upsertCachedSafeSpots([spot('a', 'Old Name', 28.566, 77.243)]);
      await db.upsertCachedSafeSpots([spot('a', 'Corrected Name', 28.566, 77.243)]);

      final rows = await db.getCachedSafeSpots();
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Corrected Name');
    });

    test('clearing the cache frees the device', () async {
      final db = openAt(5);
      addTearDown(db.close);

      await db.upsertCachedSafeSpots([spot('a', 'X', 28.5, 77.2), spot('b', 'Y', 28.6, 77.3)]);
      expect(await db.cachedSafeSpotCount(), 2);

      await db.clearCachedSafeSpots();
      expect(await db.cachedSafeSpotCount(), 0);
    });
  });

  test('repair does not disturb data already in the database', () async {
    final db = openAt(5);
    addTearDown(db.close);

    await db.insertSubmission(sample('spot-6'));
    await db.markSubmissionSynced('spot-6');

    // Re-running the repair path must be idempotent — CREATE TABLE IF NOT
    // EXISTS, never a drop-and-recreate.
    await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
    final mine = await db.getMySubmissions();
    expect(mine, hasLength(1));
    expect(mine.single.isSynced, isTrue);
  });
}
