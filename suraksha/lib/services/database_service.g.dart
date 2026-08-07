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
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
      'city', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
      'area', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _lightingScoreMeta =
      const VerificationMeta('lightingScore');
  @override
  late final GeneratedColumn<double> lightingScore = GeneratedColumn<double>(
      'lighting_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(3.0));
  static const VerificationMeta _policeStationDistanceKmMeta =
      const VerificationMeta('policeStationDistanceKm');
  @override
  late final GeneratedColumn<double> policeStationDistanceKm =
      GeneratedColumn<double>('police_station_distance_km', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(2.0));
  static const VerificationMeta _crowdDensityMeta =
      const VerificationMeta('crowdDensity');
  @override
  late final GeneratedColumn<double> crowdDensity = GeneratedColumn<double>(
      'crowd_density', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(300.0));
  static const VerificationMeta _crimeCountMeta =
      const VerificationMeta('crimeCount');
  @override
  late final GeneratedColumn<int> crimeCount = GeneratedColumn<int>(
      'crime_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _weatherConditionMeta =
      const VerificationMeta('weatherCondition');
  @override
  late final GeneratedColumn<String> weatherCondition = GeneratedColumn<String>(
      'weather_condition', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Clear'));
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
  static const VerificationMeta _incidentTimestampMeta =
      const VerificationMeta('incidentTimestamp');
  @override
  late final GeneratedColumn<DateTime> incidentTimestamp =
      GeneratedColumn<DateTime>('incident_timestamp', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
        city,
        area,
        crimeType,
        description,
        lightingScore,
        policeStationDistanceKm,
        crowdDensity,
        crimeCount,
        weatherCondition,
        timeOfDay,
        reportedAt,
        incidentTimestamp,
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
    if (data.containsKey('city')) {
      context.handle(
          _cityMeta, city.isAcceptableOrUnknown(data['city']!, _cityMeta));
    }
    if (data.containsKey('area')) {
      context.handle(
          _areaMeta, area.isAcceptableOrUnknown(data['area']!, _areaMeta));
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
    if (data.containsKey('lighting_score')) {
      context.handle(
          _lightingScoreMeta,
          lightingScore.isAcceptableOrUnknown(
              data['lighting_score']!, _lightingScoreMeta));
    }
    if (data.containsKey('police_station_distance_km')) {
      context.handle(
          _policeStationDistanceKmMeta,
          policeStationDistanceKm.isAcceptableOrUnknown(
              data['police_station_distance_km']!,
              _policeStationDistanceKmMeta));
    }
    if (data.containsKey('crowd_density')) {
      context.handle(
          _crowdDensityMeta,
          crowdDensity.isAcceptableOrUnknown(
              data['crowd_density']!, _crowdDensityMeta));
    }
    if (data.containsKey('crime_count')) {
      context.handle(
          _crimeCountMeta,
          crimeCount.isAcceptableOrUnknown(
              data['crime_count']!, _crimeCountMeta));
    }
    if (data.containsKey('weather_condition')) {
      context.handle(
          _weatherConditionMeta,
          weatherCondition.isAcceptableOrUnknown(
              data['weather_condition']!, _weatherConditionMeta));
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
    if (data.containsKey('incident_timestamp')) {
      context.handle(
          _incidentTimestampMeta,
          incidentTimestamp.isAcceptableOrUnknown(
              data['incident_timestamp']!, _incidentTimestampMeta));
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
      city: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city']),
      area: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}area']),
      crimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crime_type'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      lightingScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lighting_score'])!,
      policeStationDistanceKm: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}police_station_distance_km'])!,
      crowdDensity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}crowd_density'])!,
      crimeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}crime_count'])!,
      weatherCondition: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}weather_condition'])!,
      timeOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_of_day'])!,
      reportedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reported_at'])!,
      incidentTimestamp: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}incident_timestamp']),
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
  final String? city;
  final String? area;
  final String crimeType;
  final String description;
  final double lightingScore;
  final double policeStationDistanceKm;
  final double crowdDensity;
  final int crimeCount;
  final String weatherCondition;
  final String timeOfDay;
  final DateTime reportedAt;
  final DateTime? incidentTimestamp;
  final bool isSynced;
  const IncidentOutboxData(
      {required this.localId,
      required this.latitude,
      required this.longitude,
      this.city,
      this.area,
      required this.crimeType,
      required this.description,
      required this.lightingScore,
      required this.policeStationDistanceKm,
      required this.crowdDensity,
      required this.crimeCount,
      required this.weatherCondition,
      required this.timeOfDay,
      required this.reportedAt,
      this.incidentTimestamp,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || area != null) {
      map['area'] = Variable<String>(area);
    }
    map['crime_type'] = Variable<String>(crimeType);
    map['description'] = Variable<String>(description);
    map['lighting_score'] = Variable<double>(lightingScore);
    map['police_station_distance_km'] =
        Variable<double>(policeStationDistanceKm);
    map['crowd_density'] = Variable<double>(crowdDensity);
    map['crime_count'] = Variable<int>(crimeCount);
    map['weather_condition'] = Variable<String>(weatherCondition);
    map['time_of_day'] = Variable<String>(timeOfDay);
    map['reported_at'] = Variable<DateTime>(reportedAt);
    if (!nullToAbsent || incidentTimestamp != null) {
      map['incident_timestamp'] = Variable<DateTime>(incidentTimestamp);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  IncidentOutboxCompanion toCompanion(bool nullToAbsent) {
    return IncidentOutboxCompanion(
      localId: Value(localId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      area: area == null && nullToAbsent ? const Value.absent() : Value(area),
      crimeType: Value(crimeType),
      description: Value(description),
      lightingScore: Value(lightingScore),
      policeStationDistanceKm: Value(policeStationDistanceKm),
      crowdDensity: Value(crowdDensity),
      crimeCount: Value(crimeCount),
      weatherCondition: Value(weatherCondition),
      timeOfDay: Value(timeOfDay),
      reportedAt: Value(reportedAt),
      incidentTimestamp: incidentTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(incidentTimestamp),
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
      city: serializer.fromJson<String?>(json['city']),
      area: serializer.fromJson<String?>(json['area']),
      crimeType: serializer.fromJson<String>(json['crimeType']),
      description: serializer.fromJson<String>(json['description']),
      lightingScore: serializer.fromJson<double>(json['lightingScore']),
      policeStationDistanceKm:
          serializer.fromJson<double>(json['policeStationDistanceKm']),
      crowdDensity: serializer.fromJson<double>(json['crowdDensity']),
      crimeCount: serializer.fromJson<int>(json['crimeCount']),
      weatherCondition: serializer.fromJson<String>(json['weatherCondition']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      reportedAt: serializer.fromJson<DateTime>(json['reportedAt']),
      incidentTimestamp:
          serializer.fromJson<DateTime?>(json['incidentTimestamp']),
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
      'city': serializer.toJson<String?>(city),
      'area': serializer.toJson<String?>(area),
      'crimeType': serializer.toJson<String>(crimeType),
      'description': serializer.toJson<String>(description),
      'lightingScore': serializer.toJson<double>(lightingScore),
      'policeStationDistanceKm':
          serializer.toJson<double>(policeStationDistanceKm),
      'crowdDensity': serializer.toJson<double>(crowdDensity),
      'crimeCount': serializer.toJson<int>(crimeCount),
      'weatherCondition': serializer.toJson<String>(weatherCondition),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'reportedAt': serializer.toJson<DateTime>(reportedAt),
      'incidentTimestamp': serializer.toJson<DateTime?>(incidentTimestamp),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  IncidentOutboxData copyWith(
          {String? localId,
          double? latitude,
          double? longitude,
          Value<String?> city = const Value.absent(),
          Value<String?> area = const Value.absent(),
          String? crimeType,
          String? description,
          double? lightingScore,
          double? policeStationDistanceKm,
          double? crowdDensity,
          int? crimeCount,
          String? weatherCondition,
          String? timeOfDay,
          DateTime? reportedAt,
          Value<DateTime?> incidentTimestamp = const Value.absent(),
          bool? isSynced}) =>
      IncidentOutboxData(
        localId: localId ?? this.localId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        city: city.present ? city.value : this.city,
        area: area.present ? area.value : this.area,
        crimeType: crimeType ?? this.crimeType,
        description: description ?? this.description,
        lightingScore: lightingScore ?? this.lightingScore,
        policeStationDistanceKm:
            policeStationDistanceKm ?? this.policeStationDistanceKm,
        crowdDensity: crowdDensity ?? this.crowdDensity,
        crimeCount: crimeCount ?? this.crimeCount,
        weatherCondition: weatherCondition ?? this.weatherCondition,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        reportedAt: reportedAt ?? this.reportedAt,
        incidentTimestamp: incidentTimestamp.present
            ? incidentTimestamp.value
            : this.incidentTimestamp,
        isSynced: isSynced ?? this.isSynced,
      );
  IncidentOutboxData copyWithCompanion(IncidentOutboxCompanion data) {
    return IncidentOutboxData(
      localId: data.localId.present ? data.localId.value : this.localId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      city: data.city.present ? data.city.value : this.city,
      area: data.area.present ? data.area.value : this.area,
      crimeType: data.crimeType.present ? data.crimeType.value : this.crimeType,
      description:
          data.description.present ? data.description.value : this.description,
      lightingScore: data.lightingScore.present
          ? data.lightingScore.value
          : this.lightingScore,
      policeStationDistanceKm: data.policeStationDistanceKm.present
          ? data.policeStationDistanceKm.value
          : this.policeStationDistanceKm,
      crowdDensity: data.crowdDensity.present
          ? data.crowdDensity.value
          : this.crowdDensity,
      crimeCount:
          data.crimeCount.present ? data.crimeCount.value : this.crimeCount,
      weatherCondition: data.weatherCondition.present
          ? data.weatherCondition.value
          : this.weatherCondition,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      reportedAt:
          data.reportedAt.present ? data.reportedAt.value : this.reportedAt,
      incidentTimestamp: data.incidentTimestamp.present
          ? data.incidentTimestamp.value
          : this.incidentTimestamp,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncidentOutboxData(')
          ..write('localId: $localId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('city: $city, ')
          ..write('area: $area, ')
          ..write('crimeType: $crimeType, ')
          ..write('description: $description, ')
          ..write('lightingScore: $lightingScore, ')
          ..write('policeStationDistanceKm: $policeStationDistanceKm, ')
          ..write('crowdDensity: $crowdDensity, ')
          ..write('crimeCount: $crimeCount, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('incidentTimestamp: $incidentTimestamp, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      latitude,
      longitude,
      city,
      area,
      crimeType,
      description,
      lightingScore,
      policeStationDistanceKm,
      crowdDensity,
      crimeCount,
      weatherCondition,
      timeOfDay,
      reportedAt,
      incidentTimestamp,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncidentOutboxData &&
          other.localId == this.localId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.city == this.city &&
          other.area == this.area &&
          other.crimeType == this.crimeType &&
          other.description == this.description &&
          other.lightingScore == this.lightingScore &&
          other.policeStationDistanceKm == this.policeStationDistanceKm &&
          other.crowdDensity == this.crowdDensity &&
          other.crimeCount == this.crimeCount &&
          other.weatherCondition == this.weatherCondition &&
          other.timeOfDay == this.timeOfDay &&
          other.reportedAt == this.reportedAt &&
          other.incidentTimestamp == this.incidentTimestamp &&
          other.isSynced == this.isSynced);
}

class IncidentOutboxCompanion extends UpdateCompanion<IncidentOutboxData> {
  final Value<String> localId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> city;
  final Value<String?> area;
  final Value<String> crimeType;
  final Value<String> description;
  final Value<double> lightingScore;
  final Value<double> policeStationDistanceKm;
  final Value<double> crowdDensity;
  final Value<int> crimeCount;
  final Value<String> weatherCondition;
  final Value<String> timeOfDay;
  final Value<DateTime> reportedAt;
  final Value<DateTime?> incidentTimestamp;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const IncidentOutboxCompanion({
    this.localId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.city = const Value.absent(),
    this.area = const Value.absent(),
    this.crimeType = const Value.absent(),
    this.description = const Value.absent(),
    this.lightingScore = const Value.absent(),
    this.policeStationDistanceKm = const Value.absent(),
    this.crowdDensity = const Value.absent(),
    this.crimeCount = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.reportedAt = const Value.absent(),
    this.incidentTimestamp = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncidentOutboxCompanion.insert({
    required String localId,
    required double latitude,
    required double longitude,
    this.city = const Value.absent(),
    this.area = const Value.absent(),
    required String crimeType,
    required String description,
    this.lightingScore = const Value.absent(),
    this.policeStationDistanceKm = const Value.absent(),
    this.crowdDensity = const Value.absent(),
    this.crimeCount = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    required String timeOfDay,
    required DateTime reportedAt,
    this.incidentTimestamp = const Value.absent(),
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
    Expression<String>? city,
    Expression<String>? area,
    Expression<String>? crimeType,
    Expression<String>? description,
    Expression<double>? lightingScore,
    Expression<double>? policeStationDistanceKm,
    Expression<double>? crowdDensity,
    Expression<int>? crimeCount,
    Expression<String>? weatherCondition,
    Expression<String>? timeOfDay,
    Expression<DateTime>? reportedAt,
    Expression<DateTime>? incidentTimestamp,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (city != null) 'city': city,
      if (area != null) 'area': area,
      if (crimeType != null) 'crime_type': crimeType,
      if (description != null) 'description': description,
      if (lightingScore != null) 'lighting_score': lightingScore,
      if (policeStationDistanceKm != null)
        'police_station_distance_km': policeStationDistanceKm,
      if (crowdDensity != null) 'crowd_density': crowdDensity,
      if (crimeCount != null) 'crime_count': crimeCount,
      if (weatherCondition != null) 'weather_condition': weatherCondition,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (reportedAt != null) 'reported_at': reportedAt,
      if (incidentTimestamp != null) 'incident_timestamp': incidentTimestamp,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncidentOutboxCompanion copyWith(
      {Value<String>? localId,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<String?>? city,
      Value<String?>? area,
      Value<String>? crimeType,
      Value<String>? description,
      Value<double>? lightingScore,
      Value<double>? policeStationDistanceKm,
      Value<double>? crowdDensity,
      Value<int>? crimeCount,
      Value<String>? weatherCondition,
      Value<String>? timeOfDay,
      Value<DateTime>? reportedAt,
      Value<DateTime?>? incidentTimestamp,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return IncidentOutboxCompanion(
      localId: localId ?? this.localId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      area: area ?? this.area,
      crimeType: crimeType ?? this.crimeType,
      description: description ?? this.description,
      lightingScore: lightingScore ?? this.lightingScore,
      policeStationDistanceKm:
          policeStationDistanceKm ?? this.policeStationDistanceKm,
      crowdDensity: crowdDensity ?? this.crowdDensity,
      crimeCount: crimeCount ?? this.crimeCount,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      reportedAt: reportedAt ?? this.reportedAt,
      incidentTimestamp: incidentTimestamp ?? this.incidentTimestamp,
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
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (crimeType.present) {
      map['crime_type'] = Variable<String>(crimeType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (lightingScore.present) {
      map['lighting_score'] = Variable<double>(lightingScore.value);
    }
    if (policeStationDistanceKm.present) {
      map['police_station_distance_km'] =
          Variable<double>(policeStationDistanceKm.value);
    }
    if (crowdDensity.present) {
      map['crowd_density'] = Variable<double>(crowdDensity.value);
    }
    if (crimeCount.present) {
      map['crime_count'] = Variable<int>(crimeCount.value);
    }
    if (weatherCondition.present) {
      map['weather_condition'] = Variable<String>(weatherCondition.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (reportedAt.present) {
      map['reported_at'] = Variable<DateTime>(reportedAt.value);
    }
    if (incidentTimestamp.present) {
      map['incident_timestamp'] = Variable<DateTime>(incidentTimestamp.value);
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
          ..write('city: $city, ')
          ..write('area: $area, ')
          ..write('crimeType: $crimeType, ')
          ..write('description: $description, ')
          ..write('lightingScore: $lightingScore, ')
          ..write('policeStationDistanceKm: $policeStationDistanceKm, ')
          ..write('crowdDensity: $crowdDensity, ')
          ..write('crimeCount: $crimeCount, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('incidentTimestamp: $incidentTimestamp, ')
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
  Value<String?> city,
  Value<String?> area,
  required String crimeType,
  required String description,
  Value<double> lightingScore,
  Value<double> policeStationDistanceKm,
  Value<double> crowdDensity,
  Value<int> crimeCount,
  Value<String> weatherCondition,
  required String timeOfDay,
  required DateTime reportedAt,
  Value<DateTime?> incidentTimestamp,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$IncidentOutboxTableUpdateCompanionBuilder = IncidentOutboxCompanion
    Function({
  Value<String> localId,
  Value<double> latitude,
  Value<double> longitude,
  Value<String?> city,
  Value<String?> area,
  Value<String> crimeType,
  Value<String> description,
  Value<double> lightingScore,
  Value<double> policeStationDistanceKm,
  Value<double> crowdDensity,
  Value<int> crimeCount,
  Value<String> weatherCondition,
  Value<String> timeOfDay,
  Value<DateTime> reportedAt,
  Value<DateTime?> incidentTimestamp,
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

  ColumnFilters<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get area => $composableBuilder(
      column: $table.area, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get crimeType => $composableBuilder(
      column: $table.crimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lightingScore => $composableBuilder(
      column: $table.lightingScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get policeStationDistanceKm => $composableBuilder(
      column: $table.policeStationDistanceKm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get crowdDensity => $composableBuilder(
      column: $table.crowdDensity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get crimeCount => $composableBuilder(
      column: $table.crimeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weatherCondition => $composableBuilder(
      column: $table.weatherCondition,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reportedAt => $composableBuilder(
      column: $table.reportedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get incidentTimestamp => $composableBuilder(
      column: $table.incidentTimestamp,
      builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get area => $composableBuilder(
      column: $table.area, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get crimeType => $composableBuilder(
      column: $table.crimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lightingScore => $composableBuilder(
      column: $table.lightingScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get policeStationDistanceKm => $composableBuilder(
      column: $table.policeStationDistanceKm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get crowdDensity => $composableBuilder(
      column: $table.crowdDensity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get crimeCount => $composableBuilder(
      column: $table.crimeCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weatherCondition => $composableBuilder(
      column: $table.weatherCondition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reportedAt => $composableBuilder(
      column: $table.reportedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get incidentTimestamp => $composableBuilder(
      column: $table.incidentTimestamp,
      builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  GeneratedColumn<String> get crimeType =>
      $composableBuilder(column: $table.crimeType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get lightingScore => $composableBuilder(
      column: $table.lightingScore, builder: (column) => column);

  GeneratedColumn<double> get policeStationDistanceKm => $composableBuilder(
      column: $table.policeStationDistanceKm, builder: (column) => column);

  GeneratedColumn<double> get crowdDensity => $composableBuilder(
      column: $table.crowdDensity, builder: (column) => column);

  GeneratedColumn<int> get crimeCount => $composableBuilder(
      column: $table.crimeCount, builder: (column) => column);

  GeneratedColumn<String> get weatherCondition => $composableBuilder(
      column: $table.weatherCondition, builder: (column) => column);

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<DateTime> get reportedAt => $composableBuilder(
      column: $table.reportedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get incidentTimestamp => $composableBuilder(
      column: $table.incidentTimestamp, builder: (column) => column);

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
            Value<String?> city = const Value.absent(),
            Value<String?> area = const Value.absent(),
            Value<String> crimeType = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double> lightingScore = const Value.absent(),
            Value<double> policeStationDistanceKm = const Value.absent(),
            Value<double> crowdDensity = const Value.absent(),
            Value<int> crimeCount = const Value.absent(),
            Value<String> weatherCondition = const Value.absent(),
            Value<String> timeOfDay = const Value.absent(),
            Value<DateTime> reportedAt = const Value.absent(),
            Value<DateTime?> incidentTimestamp = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IncidentOutboxCompanion(
            localId: localId,
            latitude: latitude,
            longitude: longitude,
            city: city,
            area: area,
            crimeType: crimeType,
            description: description,
            lightingScore: lightingScore,
            policeStationDistanceKm: policeStationDistanceKm,
            crowdDensity: crowdDensity,
            crimeCount: crimeCount,
            weatherCondition: weatherCondition,
            timeOfDay: timeOfDay,
            reportedAt: reportedAt,
            incidentTimestamp: incidentTimestamp,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required double latitude,
            required double longitude,
            Value<String?> city = const Value.absent(),
            Value<String?> area = const Value.absent(),
            required String crimeType,
            required String description,
            Value<double> lightingScore = const Value.absent(),
            Value<double> policeStationDistanceKm = const Value.absent(),
            Value<double> crowdDensity = const Value.absent(),
            Value<int> crimeCount = const Value.absent(),
            Value<String> weatherCondition = const Value.absent(),
            required String timeOfDay,
            required DateTime reportedAt,
            Value<DateTime?> incidentTimestamp = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IncidentOutboxCompanion.insert(
            localId: localId,
            latitude: latitude,
            longitude: longitude,
            city: city,
            area: area,
            crimeType: crimeType,
            description: description,
            lightingScore: lightingScore,
            policeStationDistanceKm: policeStationDistanceKm,
            crowdDensity: crowdDensity,
            crimeCount: crimeCount,
            weatherCondition: weatherCondition,
            timeOfDay: timeOfDay,
            reportedAt: reportedAt,
            incidentTimestamp: incidentTimestamp,
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
