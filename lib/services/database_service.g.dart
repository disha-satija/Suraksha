// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_service.dart';

// ignore_for_file: type=lint
class $IncidentOutboxTable extends IncidentOutbox
    with TableInfo<$IncidentOutboxTable, IncidentOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncidentOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _crimeTypeMeta =
      const VerificationMeta('crimeType');
  @override
  late final GeneratedColumn<String> crimeType = GeneratedColumn<String>(
      'crime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeOfDayMeta =
      const VerificationMeta('timeOfDay');
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
      'time_of_day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reportedAtMeta =
      const VerificationMeta('reportedAt');
  @override
  late final GeneratedColumn<DateTime> reportedAt = GeneratedColumn<DateTime>(
      'reported_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        latitude,
        longitude,
        crimeType,
        description,
        timeOfDay,
        reportedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incident_outbox';
  @override
  VerificationContext validateIntegrity(Insertable<IncidentOutboxData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('crime_type')) {
      context.handle(_crimeTypeMeta,
          crimeType.isAcceptableOrUnknown(data['crime_type']!, _crimeTypeMeta));
    } else if (isInserting) {
      context.missing(_crimeTypeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
          _timeOfDayMeta,
          timeOfDay.isAcceptableOrUnknown(
              data['time_of_day']!, _timeOfDayMeta));
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    if (data.containsKey('reported_at')) {
      context.handle(
          _reportedAtMeta,
          reportedAt.isAcceptableOrUnknown(
              data['reported_at']!, _reportedAtMeta));
    } else if (isInserting) {
      context.missing(_reportedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  IncidentOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncidentOutboxData(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      crimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crime_type'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      timeOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_of_day'])!,
      reportedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reported_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $IncidentOutboxTable createAlias(String alias) {
    return $IncidentOutboxTable(attachedDatabase, alias);
  }
}

class IncidentOutboxData extends DataClass
    implements Insertable<IncidentOutboxData> {
  final String localId;
  final double latitude;
  final double longitude;
  final String crimeType;
  final String description;
  final String timeOfDay;
  final DateTime reportedAt;
  final bool isSynced;
  const IncidentOutboxData(
      {required this.localId,
      required this.latitude,
      required this.longitude,
      required this.crimeType,
      required this.description,
      required this.timeOfDay,
      required this.reportedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['crime_type'] = Variable<String>(crimeType);
    map['description'] = Variable<String>(description);
    map['time_of_day'] = Variable<String>(timeOfDay);
    map['reported_at'] = Variable<DateTime>(reportedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  IncidentOutboxCompanion toCompanion(bool nullToAbsent) {
    return IncidentOutboxCompanion(
      localId: Value(localId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      crimeType: Value(crimeType),
      description: Value(description),
      timeOfDay: Value(timeOfDay),
      reportedAt: Value(reportedAt),
      isSynced: Value(isSynced),
    );
  }

  factory IncidentOutboxData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncidentOutboxData(
      localId: serializer.fromJson<String>(json['localId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      crimeType: serializer.fromJson<String>(json['crimeType']),
      description: serializer.fromJson<String>(json['description']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      reportedAt: serializer.fromJson<DateTime>(json['reportedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'crimeType': serializer.toJson<String>(crimeType),
      'description': serializer.toJson<String>(description),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'reportedAt': serializer.toJson<DateTime>(reportedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  IncidentOutboxData copyWith(
          {String? localId,
          double? latitude,
          double? longitude,
          String? crimeType,
          String? description,
          String? timeOfDay,
          DateTime? reportedAt,
          bool? isSynced}) =>
      IncidentOutboxData(
        localId: localId ?? this.localId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        crimeType: crimeType ?? this.crimeType,
        description: description ?? this.description,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        reportedAt: reportedAt ?? this.reportedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  IncidentOutboxData copyWithCompanion(IncidentOutboxCompanion data) {
    return IncidentOutboxData(
      localId: data.localId.present ? data.localId.value : this.localId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      crimeType: data.crimeType.present ? data.crimeType.value : this.crimeType,
      description:
          data.description.present ? data.description.value : this.description,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      reportedAt:
          data.reportedAt.present ? data.reportedAt.value : this.reportedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncidentOutboxData(')
          ..write('localId: $localId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('crimeType: $crimeType, ')
          ..write('description: $description, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, latitude, longitude, crimeType,
      description, timeOfDay, reportedAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncidentOutboxData &&
          other.localId == this.localId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.crimeType == this.crimeType &&
          other.description == this.description &&
          other.timeOfDay == this.timeOfDay &&
          other.reportedAt == this.reportedAt &&
          other.isSynced == this.isSynced);
}

class IncidentOutboxCompanion extends UpdateCompanion<IncidentOutboxData> {
  final Value<String> localId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> crimeType;
  final Value<String> description;
  final Value<String> timeOfDay;
  final Value<DateTime> reportedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const IncidentOutboxCompanion({
    this.localId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.crimeType = const Value.absent(),
    this.description = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.reportedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncidentOutboxCompanion.insert({
    required String localId,
    required double latitude,
    required double longitude,
    required String crimeType,
    required String description,
    required String timeOfDay,
    required DateTime reportedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        latitude = Value(latitude),
        longitude = Value(longitude),
        crimeType = Value(crimeType),
        description = Value(description),
        timeOfDay = Value(timeOfDay),
        reportedAt = Value(reportedAt);
  static Insertable<IncidentOutboxData> custom({
    Expression<String>? localId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? crimeType,
    Expression<String>? description,
    Expression<String>? timeOfDay,
    Expression<DateTime>? reportedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (crimeType != null) 'crime_type': crimeType,
      if (description != null) 'description': description,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (reportedAt != null) 'reported_at': reportedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncidentOutboxCompanion copyWith(
      {Value<String>? localId,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<String>? crimeType,
      Value<String>? description,
      Value<String>? timeOfDay,
      Value<DateTime>? reportedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return IncidentOutboxCompanion(
      localId: localId ?? this.localId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      crimeType: crimeType ?? this.crimeType,
      description: description ?? this.description,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      reportedAt: reportedAt ?? this.reportedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (crimeType.present) {
      map['crime_type'] = Variable<String>(crimeType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (reportedAt.present) {
      map['reported_at'] = Variable<DateTime>(reportedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncidentOutboxCompanion(')
          ..write('localId: $localId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('crimeType: $crimeType, ')
          ..write('description: $description, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocationQueueTable extends LocationQueue
    with TableInfo<$LocationQueueTable, LocationQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [localId, latitude, longitude, recordedAt, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_queue';
  @override
  VerificationContext validateIntegrity(Insertable<LocationQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocationQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationQueueData(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocationQueueTable createAlias(String alias) {
    return $LocationQueueTable(attachedDatabase, alias);
  }
}

class LocationQueueData extends DataClass
    implements Insertable<LocationQueueData> {
  final String localId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final bool isSynced;
  const LocationQueueData(
      {required this.localId,
      required this.latitude,
      required this.longitude,
      required this.recordedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocationQueueCompanion toCompanion(bool nullToAbsent) {
    return LocationQueueCompanion(
      localId: Value(localId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      recordedAt: Value(recordedAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocationQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationQueueData(
      localId: serializer.fromJson<String>(json['localId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocationQueueData copyWith(
          {String? localId,
          double? latitude,
          double? longitude,
          DateTime? recordedAt,
          bool? isSynced}) =>
      LocationQueueData(
        localId: localId ?? this.localId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        recordedAt: recordedAt ?? this.recordedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocationQueueData copyWithCompanion(LocationQueueCompanion data) {
    return LocationQueueData(
      localId: data.localId.present ? data.localId.value : this.localId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationQueueData(')
          ..write('localId: $localId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(localId, latitude, longitude, recordedAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationQueueData &&
          other.localId == this.localId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.recordedAt == this.recordedAt &&
          other.isSynced == this.isSynced);
}

class LocationQueueCompanion extends UpdateCompanion<LocationQueueData> {
  final Value<String> localId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> recordedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocationQueueCompanion({
    this.localId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocationQueueCompanion.insert({
    required String localId,
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        latitude = Value(latitude),
        longitude = Value(longitude),
        recordedAt = Value(recordedAt);
  static Insertable<LocationQueueData> custom({
    Expression<String>? localId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? recordedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocationQueueCompanion copyWith(
      {Value<String>? localId,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<DateTime>? recordedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocationQueueCompanion(
      localId: localId ?? this.localId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      recordedAt: recordedAt ?? this.recordedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationQueueCompanion(')
          ..write('localId: $localId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IncidentOutboxTable incidentOutbox = $IncidentOutboxTable(this);
  late final $LocationQueueTable locationQueue = $LocationQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [incidentOutbox, locationQueue];
}

typedef $$IncidentOutboxTableCreateCompanionBuilder = IncidentOutboxCompanion
    Function({
  required String localId,
  required double latitude,
  required double longitude,
  required String crimeType,
  required String description,
  required String timeOfDay,
  required DateTime reportedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$IncidentOutboxTableUpdateCompanionBuilder = IncidentOutboxCompanion
    Function({
  Value<String> localId,
  Value<double> latitude,
  Value<double> longitude,
  Value<String> crimeType,
  Value<String> description,
  Value<String> timeOfDay,
  Value<DateTime> reportedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$IncidentOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $IncidentOutboxTable> {
  $$IncidentOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get crimeType => $composableBuilder(
      column: $table.crimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reportedAt => $composableBuilder(
      column: $table.reportedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$IncidentOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $IncidentOutboxTable> {
  $$IncidentOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get crimeType => $composableBuilder(
      column: $table.crimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reportedAt => $composableBuilder(
      column: $table.reportedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$IncidentOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncidentOutboxTable> {
  $$IncidentOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get crimeType =>
      $composableBuilder(column: $table.crimeType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<DateTime> get reportedAt => $composableBuilder(
      column: $table.reportedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$IncidentOutboxTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IncidentOutboxTable,
    IncidentOutboxData,
    $$IncidentOutboxTableFilterComposer,
    $$IncidentOutboxTableOrderingComposer,
    $$IncidentOutboxTableAnnotationComposer,
    $$IncidentOutboxTableCreateCompanionBuilder,
    $$IncidentOutboxTableUpdateCompanionBuilder,
    (
      IncidentOutboxData,
      BaseReferences<_$AppDatabase, $IncidentOutboxTable, IncidentOutboxData>
    ),
    IncidentOutboxData,
    PrefetchHooks Function()> {
  $$IncidentOutboxTableTableManager(
      _$AppDatabase db, $IncidentOutboxTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncidentOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncidentOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncidentOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<String> crimeType = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> timeOfDay = const Value.absent(),
            Value<DateTime> reportedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IncidentOutboxCompanion(
            localId: localId,
            latitude: latitude,
            longitude: longitude,
            crimeType: crimeType,
            description: description,
            timeOfDay: timeOfDay,
            reportedAt: reportedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required double latitude,
            required double longitude,
            required String crimeType,
            required String description,
            required String timeOfDay,
            required DateTime reportedAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IncidentOutboxCompanion.insert(
            localId: localId,
            latitude: latitude,
            longitude: longitude,
            crimeType: crimeType,
            description: description,
            timeOfDay: timeOfDay,
            reportedAt: reportedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IncidentOutboxTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IncidentOutboxTable,
    IncidentOutboxData,
    $$IncidentOutboxTableFilterComposer,
    $$IncidentOutboxTableOrderingComposer,
    $$IncidentOutboxTableAnnotationComposer,
    $$IncidentOutboxTableCreateCompanionBuilder,
    $$IncidentOutboxTableUpdateCompanionBuilder,
    (
      IncidentOutboxData,
      BaseReferences<_$AppDatabase, $IncidentOutboxTable, IncidentOutboxData>
    ),
    IncidentOutboxData,
    PrefetchHooks Function()>;
typedef $$LocationQueueTableCreateCompanionBuilder = LocationQueueCompanion
    Function({
  required String localId,
  required double latitude,
  required double longitude,
  required DateTime recordedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocationQueueTableUpdateCompanionBuilder = LocationQueueCompanion
    Function({
  Value<String> localId,
  Value<double> latitude,
  Value<double> longitude,
  Value<DateTime> recordedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocationQueueTableFilterComposer
    extends Composer<_$AppDatabase, $LocationQueueTable> {
  $$LocationQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LocationQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationQueueTable> {
  $$LocationQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocationQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationQueueTable> {
  $$LocationQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocationQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocationQueueTable,
    LocationQueueData,
    $$LocationQueueTableFilterComposer,
    $$LocationQueueTableOrderingComposer,
    $$LocationQueueTableAnnotationComposer,
    $$LocationQueueTableCreateCompanionBuilder,
    $$LocationQueueTableUpdateCompanionBuilder,
    (
      LocationQueueData,
      BaseReferences<_$AppDatabase, $LocationQueueTable, LocationQueueData>
    ),
    LocationQueueData,
    PrefetchHooks Function()> {
  $$LocationQueueTableTableManager(_$AppDatabase db, $LocationQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocationQueueCompanion(
            localId: localId,
            latitude: latitude,
            longitude: longitude,
            recordedAt: recordedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required double latitude,
            required double longitude,
            required DateTime recordedAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocationQueueCompanion.insert(
            localId: localId,
            latitude: latitude,
            longitude: longitude,
            recordedAt: recordedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocationQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocationQueueTable,
    LocationQueueData,
    $$LocationQueueTableFilterComposer,
    $$LocationQueueTableOrderingComposer,
    $$LocationQueueTableAnnotationComposer,
    $$LocationQueueTableCreateCompanionBuilder,
    $$LocationQueueTableUpdateCompanionBuilder,
    (
      LocationQueueData,
      BaseReferences<_$AppDatabase, $LocationQueueTable, LocationQueueData>
    ),
    LocationQueueData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IncidentOutboxTableTableManager get incidentOutbox =>
      $$IncidentOutboxTableTableManager(_db, _db.incidentOutbox);
  $$LocationQueueTableTableManager get locationQueue =>
      $$LocationQueueTableTableManager(_db, _db.locationQueue);
}
