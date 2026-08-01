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
  TextColumn get crimeType => text()();
  TextColumn get description => text()();
  TextColumn get timeOfDay => text()();
  DateTimeColumn get reportedAt => dateTime()();
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
  int get schemaVersion => 1;

  // ── Incident outbox ──────────────────────────────────────────────────────────

  Future<void> insertIncident(Incident incident) async {
    await into(incidentOutbox).insert(
      IncidentOutboxCompanion.insert(
        localId: incident.localId,
        latitude: incident.latitude,
        longitude: incident.longitude,
        crimeType: incident.crimeType,
        description: incident.description,
        timeOfDay: incident.timeOfDay,
        reportedAt: incident.reportedAt,
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
