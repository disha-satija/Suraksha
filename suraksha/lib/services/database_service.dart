import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import '../models/incident.dart';
import '../models/guardian.dart';

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

// ── Database ───────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [IncidentOutbox, LocationQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = p.join(dir.path, 'suraksha.db');
    return NativeDatabase.createInBackground(File(file));
  });
}
