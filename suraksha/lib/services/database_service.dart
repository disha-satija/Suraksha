import 'dart:async';
import 'dart:io';
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

// ── Database ───────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  IncidentOutbox,
  LocationQueue,
  SafeSpotVerifications,
  SafeSpotSubmissions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
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
          if (from < 4) {
            // v3 → v4: user-suggested safe places awaiting moderation
            await m.createTable(safeSpotSubmissions);
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = p.join(dir.path, 'suraksha.db');
    return NativeDatabase.createInBackground(File(file));
  });
}
