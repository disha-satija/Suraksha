import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import '../models/incident.dart';
import '../models/guardian.dart';
import '../models/safe_spot_verification.dart';
import '../models/safe_spot_submission.dart';

part 'database_service.g.dart';

// ── Table definitions ──────────────────────────────────────────────────────────

class IncidentOutbox extends Table {
  TextColumn get localId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get city => text().nullable()();
  TextColumn get area => text().nullable()();
  TextColumn get crimeType => text()();
  TextColumn get description => text()();
  RealColumn get lightingScore => real().withDefault(const Constant(3.0))();
  RealColumn get policeStationDistanceKm => real().withDefault(const Constant(2.0))();
  RealColumn get crowdDensity => real().withDefault(const Constant(300.0))();
  IntColumn get crimeCount => integer().withDefault(const Constant(5))();
  TextColumn get weatherCondition => text().withDefault(const Constant('Clear'))();
  TextColumn get timeOfDay => text()();
  DateTimeColumn get reportedAt => dateTime()();
  DateTimeColumn get incidentTimestamp => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

class LocationQueue extends Table {
  TextColumn get localId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get recordedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

@DataClassName('SafeSpotVerificationsData')
class SafeSpotVerifications extends Table {
  TextColumn get localId => text()();
  TextColumn get spotId => text()();
  TextColumn get spotName => text()();
  TextColumn get question => text()();
  BoolColumn get answer => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

@DataClassName('SafeSpotSubmissionsData')
class SafeSpotSubmissions extends Table {
  TextColumn get localId => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get address => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get whySafe => text()();
  DateTimeColumn get submittedAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

/// Verified safe places bundled for offline use alongside downloaded map tiles.
///
/// Only ever holds spots the backend confirmed as verified — AI-suggested
/// places are excluded server-side, because a cached suggestion is
/// indistinguishable from a cached fact once the device is offline.
@DataClassName('CachedSafeSpotsData')
class CachedSafeSpots extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get address => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get safetyScore => real()();
  TextColumn get whySafe => text()();
  TextColumn get operatingHours => text().nullable()();
  TextColumn get contactNumber => text().nullable()();

  /// 'curated' or 'provider' — never an AI suggestion.
  TextColumn get source => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ───────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  IncidentOutbox,
  LocationQueue,
  SafeSpotVerifications,
  SafeSpotSubmissions,
  CachedSafeSpots,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Opens the database over a caller-supplied executor. Used by tests to
  /// exercise the migration path against an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          debugPrint('[AppDatabase] creating schema v$schemaVersion');
          await m.createAll();
        },

        // Runs on every open, after any create/upgrade. Self-healing net:
        // if the recorded schema version says the database is current but a
        // table is actually missing, recreate it.
        //
        // This exists because that is precisely the state a commented-out
        // `createTable` left devices in — version bumped, table absent — and
        // the only symptom was an exception swallowed three layers up. Version
        // bookkeeping is not evidence that the tables exist, so check.
        //
        // createAll() emits CREATE TABLE IF NOT EXISTS, so repairing is safe
        // and never touches existing data.
        beforeOpen: (details) async {
          final expected = allTables.map((t) => t.actualTableName).toSet();
          final rows = await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          ).get();
          final present = rows.map((r) => r.read<String>('name')).toSet();
          final missing = expected.difference(present);

          if (missing.isNotEmpty) {
            debugPrint(
              '[AppDatabase] schema v${details.versionNow} is missing '
              '${missing.length} table(s): ${missing.join(', ')} — repairing',
            );
            await createMigrator().createAll();
            debugPrint('[AppDatabase] repair complete');
          }
        },

        onUpgrade: (m, from, to) async {
          debugPrint('[AppDatabase] migrating v$from -> v$to');
          if (from < 2) {
            // v1 → v2: add new incident reporting fields
            await m.addColumn(incidentOutbox, incidentOutbox.city);
            await m.addColumn(incidentOutbox, incidentOutbox.area);
            await m.addColumn(incidentOutbox, incidentOutbox.lightingScore);
            await m.addColumn(incidentOutbox, incidentOutbox.policeStationDistanceKm);
            await m.addColumn(incidentOutbox, incidentOutbox.crowdDensity);
            await m.addColumn(incidentOutbox, incidentOutbox.crimeCount);
            await m.addColumn(incidentOutbox, incidentOutbox.weatherCondition);
            await m.addColumn(incidentOutbox, incidentOutbox.incidentTimestamp);
          }
          if (from < 3) {
            // v2 → v3: community safe-spot verifications
            await m.createTable(safeSpotVerifications);
          }
          if (from < 5) {
            // v4 → v5: user-suggested safe places awaiting moderation.
            //
            // This table was supposed to be created at v4, but the call was
            // left commented out while the version was still bumped. Every
            // device that upgraded through v4 therefore has no local
            // `safe_spot_submissions` table.
            //
            // ContributeRepository.submitSafeSpot writes to the local outbox
            // BEFORE attempting to sync, so the missing table threw first and
            // the backend POST was never reached — which is why submissions
            // produced no API call in the logs and no row in Supabase, while
            // verifications (whose table was created correctly at v3) synced
            // fine. Fresh installs were unaffected because onCreate runs
            // createAll().
            //
            // Safe to run for any `from`: drift emits CREATE TABLE IF NOT
            // EXISTS, so devices that already have the table are unaffected.
            await m.createTable(safeSpotSubmissions);
          }
          if (from < 6) {
            // v5 → v6: verified safe places bundled with offline map regions.
            await m.createTable(cachedSafeSpots);
          }
        },
      );

  // ── Incident outbox ──────────────────────────────────────────────────────────

  Future<void> insertIncident(Incident incident) async {
    await into(incidentOutbox).insert(
      IncidentOutboxCompanion.insert(
        localId: incident.localId,
        latitude: incident.latitude,
        longitude: incident.longitude,
        city: Value(incident.city),
        area: Value(incident.area),
        crimeType: incident.crimeType,
        description: incident.description,
        lightingScore: Value(incident.lightingScore),
        policeStationDistanceKm: Value(incident.policeStationDistanceKm),
        crowdDensity: Value(incident.crowdDensity),
        crimeCount: Value(incident.crimeCount),
        weatherCondition: Value(incident.weatherCondition),
        timeOfDay: incident.timeOfDay,
        reportedAt: incident.reportedAt,
        incidentTimestamp: Value(incident.incidentTimestamp),
      ),
    );
  }

  Future<List<IncidentOutboxData>> getUnsyncedIncidents() {
    return (select(incidentOutbox)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> markIncidentSynced(String localId) async {
    await (update(incidentOutbox)
          ..where((t) => t.localId.equals(localId)))
        .write(const IncidentOutboxCompanion(
          isSynced: Value(true),
        ));
  }

  // ── Location queue ───────────────────────────────────────────────────────────

  Future<void> insertLocationUpdate(LocationUpdate update) async {
    await into(locationQueue).insert(
      LocationQueueCompanion.insert(
        localId: update.localId,
        latitude: update.latitude,
        longitude: update.longitude,
        recordedAt: update.timestamp,
      ),
    );
  }

  Future<List<LocationQueueData>> getUnsyncedLocations() {
    return (select(locationQueue)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> markLocationSynced(String localId) async {
    await (update(locationQueue)
          ..where((t) => t.localId.equals(localId)))
        .write(const LocationQueueCompanion(
          isSynced: Value(true),
        ));
  }

  // ── Safe spot verifications ──────────────────────────────────────────────────

  Future<void> insertVerification(SafeSpotVerification verification) async {
    await into(safeSpotVerifications).insert(
      SafeSpotVerificationsCompanion.insert(
        localId: verification.localId,
        spotId: verification.spotId,
        spotName: verification.spotName,
        question: verification.question,
        answer: verification.answer,
        answeredAt: verification.answeredAt,
      ),
    );
  }

  Future<List<SafeSpotVerification>> getUnsyncedVerifications() async {
    final rows = await (select(safeSpotVerifications)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    return rows
        .map((r) => SafeSpotVerification(
              localId: r.localId,
              spotId: r.spotId,
              spotName: r.spotName,
              question: r.question,
              answer: r.answer,
              answeredAt: r.answeredAt,
              isSynced: r.isSynced,
            ))
        .toList();
  }

  Future<void> markVerificationSynced(String localId) async {
    await (update(safeSpotVerifications)
          ..where((t) => t.localId.equals(localId)))
        .write(const SafeSpotVerificationsCompanion(
          isSynced: Value(true),
        ));
  }

  /// IDs of spots this device has already answered about since [cutoff].
  /// Used to avoid asking the same question twice.
  Future<Set<String>> getVerifiedSpotIdsSince(DateTime cutoff) async {
    final rows = await (select(safeSpotVerifications)
          ..where((t) => t.answeredAt.isBiggerOrEqualValue(cutoff)))
        .get();
    return rows.map((r) => r.spotId).toSet();
  }

  // ── Safe spot submissions ────────────────────────────────────────────────────

  Future<void> insertSubmission(SafeSpotSubmission submission) async {
    await into(safeSpotSubmissions).insert(
      SafeSpotSubmissionsCompanion.insert(
        localId: submission.localId,
        name: submission.name,
        category: submission.category,
        address: submission.address,
        lat: submission.lat,
        lng: submission.lng,
        whySafe: submission.whySafe,
        submittedAt: submission.submittedAt,
        status: Value(submission.status),
      ),
    );
  }

  Future<List<SafeSpotSubmission>> getUnsyncedSubmissions() async {
    final rows = await (select(safeSpotSubmissions)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    return rows
        .map((r) => SafeSpotSubmission(
              localId: r.localId,
              name: r.name,
              category: r.category,
              address: r.address,
              lat: r.lat,
              lng: r.lng,
              whySafe: r.whySafe,
              submittedAt: r.submittedAt,
              status: r.status,
              isSynced: r.isSynced,
            ))
        .toList();
  }

  Future<void> markSubmissionSynced(String localId) async {
    await (update(safeSpotSubmissions)
          ..where((t) => t.localId.equals(localId)))
        .write(const SafeSpotSubmissionsCompanion(
          isSynced: Value(true),
        ));
  }

  /// All of this device's suggestions, newest first.
  Future<List<SafeSpotSubmission>> getMySubmissions() async {
    final rows = await (select(safeSpotSubmissions)
          ..orderBy([(t) => OrderingTerm.desc(t.submittedAt)]))
        .get();
    return rows
        .map((r) => SafeSpotSubmission(
              localId: r.localId,
              name: r.name,
              category: r.category,
              address: r.address,
              lat: r.lat,
              lng: r.lng,
              whySafe: r.whySafe,
              submittedAt: r.submittedAt,
              status: r.status,
              isSynced: r.isSynced,
            ))
        .toList();
  }

  // ── Cached safe spots (offline regions) ──────────────────────────────────────

  /// Upserts verified safe spots downloaded for a region.
  ///
  /// Upsert rather than replace, so downloading a second region does not wipe
  /// the first — a user who bundled two cities keeps both.
  Future<int> upsertCachedSafeSpots(List<CachedSafeSpotsCompanion> spots) async {
    if (spots.isEmpty) return 0;
    await batch((b) => b.insertAllOnConflictUpdate(cachedSafeSpots, spots));
    return spots.length;
  }

  /// All cached spots, nearest first.
  ///
  /// Sorting happens in Dart because SQLite has no haversine and the cache is
  /// small by construction — the entire verified dataset is under 200 rows.
  /// Revisit if that ever stops being true.
  Future<List<CachedSafeSpotsData>> getCachedSafeSpots() =>
      select(cachedSafeSpots).get();

  Future<int> cachedSafeSpotCount() async {
    final rows = await select(cachedSafeSpots).get();
    return rows.length;
  }

  Future<void> clearCachedSafeSpots() => delete(cachedSafeSpots).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = p.join(dir.path, 'suraksha.db');
    return NativeDatabase.createInBackground(File(file));
  });
}
