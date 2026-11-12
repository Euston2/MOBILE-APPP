// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MonitoredAppsTable extends MonitoredApps
    with TableInfo<$MonitoredAppsTable, MonitoredAppRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonitoredAppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pendingEnabledMeta = const VerificationMeta(
    'pendingEnabled',
  );
  @override
  late final GeneratedColumn<bool> pendingEnabled = GeneratedColumn<bool>(
    'pending_enabled',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    packageName,
    displayName,
    isEnabled,
    pendingEnabled,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monitored_apps';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonitoredAppRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('pending_enabled')) {
      context.handle(
        _pendingEnabledMeta,
        pendingEnabled.isAcceptableOrUnknown(
          data['pending_enabled']!,
          _pendingEnabledMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packageName};
  @override
  MonitoredAppRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonitoredAppRow(
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      pendingEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_enabled'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MonitoredAppsTable createAlias(String alias) {
    return $MonitoredAppsTable(attachedDatabase, alias);
  }
}

class MonitoredAppRow extends DataClass implements Insertable<MonitoredAppRow> {
  final String packageName;
  final String displayName;
  final bool isEnabled;

  /// Null = no scheduled change. True = add at next midnight. False = remove.
  final bool? pendingEnabled;
  final DateTime updatedAt;
  const MonitoredAppRow({
    required this.packageName,
    required this.displayName,
    required this.isEnabled,
    this.pendingEnabled,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['package_name'] = Variable<String>(packageName);
    map['display_name'] = Variable<String>(displayName);
    map['is_enabled'] = Variable<bool>(isEnabled);
    if (!nullToAbsent || pendingEnabled != null) {
      map['pending_enabled'] = Variable<bool>(pendingEnabled);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MonitoredAppsCompanion toCompanion(bool nullToAbsent) {
    return MonitoredAppsCompanion(
      packageName: Value(packageName),
      displayName: Value(displayName),
      isEnabled: Value(isEnabled),
      pendingEnabled: pendingEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingEnabled),
      updatedAt: Value(updatedAt),
    );
  }

  factory MonitoredAppRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonitoredAppRow(
      packageName: serializer.fromJson<String>(json['packageName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      pendingEnabled: serializer.fromJson<bool?>(json['pendingEnabled']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packageName': serializer.toJson<String>(packageName),
      'displayName': serializer.toJson<String>(displayName),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'pendingEnabled': serializer.toJson<bool?>(pendingEnabled),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MonitoredAppRow copyWith({
    String? packageName,
    String? displayName,
    bool? isEnabled,
    Value<bool?> pendingEnabled = const Value.absent(),
    DateTime? updatedAt,
  }) => MonitoredAppRow(
    packageName: packageName ?? this.packageName,
    displayName: displayName ?? this.displayName,
    isEnabled: isEnabled ?? this.isEnabled,
    pendingEnabled: pendingEnabled.present
        ? pendingEnabled.value
        : this.pendingEnabled,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MonitoredAppRow copyWithCompanion(MonitoredAppsCompanion data) {
    return MonitoredAppRow(
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      pendingEnabled: data.pendingEnabled.present
          ? data.pendingEnabled.value
          : this.pendingEnabled,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonitoredAppRow(')
          ..write('packageName: $packageName, ')
          ..write('displayName: $displayName, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('pendingEnabled: $pendingEnabled, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    packageName,
    displayName,
    isEnabled,
    pendingEnabled,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonitoredAppRow &&
          other.packageName == this.packageName &&
          other.displayName == this.displayName &&
          other.isEnabled == this.isEnabled &&
          other.pendingEnabled == this.pendingEnabled &&
          other.updatedAt == this.updatedAt);
}

class MonitoredAppsCompanion extends UpdateCompanion<MonitoredAppRow> {
  final Value<String> packageName;
  final Value<String> displayName;
  final Value<bool> isEnabled;
  final Value<bool?> pendingEnabled;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MonitoredAppsCompanion({
    this.packageName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.pendingEnabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonitoredAppsCompanion.insert({
    required String packageName,
    required String displayName,
    this.isEnabled = const Value.absent(),
    this.pendingEnabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : packageName = Value(packageName),
       displayName = Value(displayName);
  static Insertable<MonitoredAppRow> custom({
    Expression<String>? packageName,
    Expression<String>? displayName,
    Expression<bool>? isEnabled,
    Expression<bool>? pendingEnabled,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packageName != null) 'package_name': packageName,
      if (displayName != null) 'display_name': displayName,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (pendingEnabled != null) 'pending_enabled': pendingEnabled,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonitoredAppsCompanion copyWith({
    Value<String>? packageName,
    Value<String>? displayName,
    Value<bool>? isEnabled,
    Value<bool?>? pendingEnabled,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MonitoredAppsCompanion(
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      isEnabled: isEnabled ?? this.isEnabled,
      pendingEnabled: pendingEnabled ?? this.pendingEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (pendingEnabled.present) {
      map['pending_enabled'] = Variable<bool>(pendingEnabled.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonitoredAppsCompanion(')
          ..write('packageName: $packageName, ')
          ..write('displayName: $displayName, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('pendingEnabled: $pendingEnabled, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyUsagesTable extends DailyUsages
    with TableInfo<$DailyUsagesTable, DailyUsageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyUsagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSecondsMeta = const VerificationMeta(
    'totalSeconds',
  );
  @override
  late final GeneratedColumn<int> totalSeconds = GeneratedColumn<int>(
    'total_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lateNightSecondsMeta = const VerificationMeta(
    'lateNightSeconds',
  );
  @override
  late final GeneratedColumn<int> lateNightSeconds = GeneratedColumn<int>(
    'late_night_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    packageName,
    totalSeconds,
    lateNightSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_usage';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyUsageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('total_seconds')) {
      context.handle(
        _totalSecondsMeta,
        totalSeconds.isAcceptableOrUnknown(
          data['total_seconds']!,
          _totalSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSecondsMeta);
    }
    if (data.containsKey('late_night_seconds')) {
      context.handle(
        _lateNightSecondsMeta,
        lateNightSeconds.isAcceptableOrUnknown(
          data['late_night_seconds']!,
          _lateNightSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, packageName};
  @override
  DailyUsageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyUsageRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      totalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seconds'],
      )!,
      lateNightSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}late_night_seconds'],
      )!,
    );
  }

  @override
  $DailyUsagesTable createAlias(String alias) {
    return $DailyUsagesTable(attachedDatabase, alias);
  }
}

class DailyUsageRow extends DataClass implements Insertable<DailyUsageRow> {
  /// Local calendar date as `yyyy-MM-dd`.
  final String date;
  final String packageName;
  final int totalSeconds;

  /// Seconds used between local 00:00 and 08:00.
  final int lateNightSeconds;
  const DailyUsageRow({
    required this.date,
    required this.packageName,
    required this.totalSeconds,
    required this.lateNightSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['package_name'] = Variable<String>(packageName);
    map['total_seconds'] = Variable<int>(totalSeconds);
    map['late_night_seconds'] = Variable<int>(lateNightSeconds);
    return map;
  }

  DailyUsagesCompanion toCompanion(bool nullToAbsent) {
    return DailyUsagesCompanion(
      date: Value(date),
      packageName: Value(packageName),
      totalSeconds: Value(totalSeconds),
      lateNightSeconds: Value(lateNightSeconds),
    );
  }

  factory DailyUsageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyUsageRow(
      date: serializer.fromJson<String>(json['date']),
      packageName: serializer.fromJson<String>(json['packageName']),
      totalSeconds: serializer.fromJson<int>(json['totalSeconds']),
      lateNightSeconds: serializer.fromJson<int>(json['lateNightSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'packageName': serializer.toJson<String>(packageName),
      'totalSeconds': serializer.toJson<int>(totalSeconds),
      'lateNightSeconds': serializer.toJson<int>(lateNightSeconds),
    };
  }

  DailyUsageRow copyWith({
    String? date,
    String? packageName,
    int? totalSeconds,
    int? lateNightSeconds,
  }) => DailyUsageRow(
    date: date ?? this.date,
    packageName: packageName ?? this.packageName,
    totalSeconds: totalSeconds ?? this.totalSeconds,
    lateNightSeconds: lateNightSeconds ?? this.lateNightSeconds,
  );
  DailyUsageRow copyWithCompanion(DailyUsagesCompanion data) {
    return DailyUsageRow(
      date: data.date.present ? data.date.value : this.date,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      totalSeconds: data.totalSeconds.present
          ? data.totalSeconds.value
          : this.totalSeconds,
      lateNightSeconds: data.lateNightSeconds.present
          ? data.lateNightSeconds.value
          : this.lateNightSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyUsageRow(')
          ..write('date: $date, ')
          ..write('packageName: $packageName, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('lateNightSeconds: $lateNightSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(date, packageName, totalSeconds, lateNightSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyUsageRow &&
          other.date == this.date &&
          other.packageName == this.packageName &&
          other.totalSeconds == this.totalSeconds &&
          other.lateNightSeconds == this.lateNightSeconds);
}

class DailyUsagesCompanion extends UpdateCompanion<DailyUsageRow> {
  final Value<String> date;
  final Value<String> packageName;
  final Value<int> totalSeconds;
  final Value<int> lateNightSeconds;
  final Value<int> rowid;
  const DailyUsagesCompanion({
    this.date = const Value.absent(),
    this.packageName = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.lateNightSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyUsagesCompanion.insert({
    required String date,
    required String packageName,
    required int totalSeconds,
    this.lateNightSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       packageName = Value(packageName),
       totalSeconds = Value(totalSeconds);
  static Insertable<DailyUsageRow> custom({
    Expression<String>? date,
    Expression<String>? packageName,
    Expression<int>? totalSeconds,
    Expression<int>? lateNightSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (packageName != null) 'package_name': packageName,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (lateNightSeconds != null) 'late_night_seconds': lateNightSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyUsagesCompanion copyWith({
    Value<String>? date,
    Value<String>? packageName,
    Value<int>? totalSeconds,
    Value<int>? lateNightSeconds,
    Value<int>? rowid,
  }) {
    return DailyUsagesCompanion(
      date: date ?? this.date,
      packageName: packageName ?? this.packageName,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      lateNightSeconds: lateNightSeconds ?? this.lateNightSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (totalSeconds.present) {
      map['total_seconds'] = Variable<int>(totalSeconds.value);
    }
    if (lateNightSeconds.present) {
      map['late_night_seconds'] = Variable<int>(lateNightSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyUsagesCompanion(')
          ..write('date: $date, ')
          ..write('packageName: $packageName, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('lateNightSeconds: $lateNightSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailySummariesTable extends DailySummaries
    with TableInfo<$DailySummariesTable, DailySummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailySummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSecondsMeta = const VerificationMeta(
    'totalSeconds',
  );
  @override
  late final GeneratedColumn<int> totalSeconds = GeneratedColumn<int>(
    'total_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitSecondsMeta = const VerificationMeta(
    'limitSeconds',
  );
  @override
  late final GeneratedColumn<int> limitSeconds = GeneratedColumn<int>(
    'limit_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitHitAtMeta = const VerificationMeta(
    'limitHitAt',
  );
  @override
  late final GeneratedColumn<DateTime> limitHitAt = GeneratedColumn<DateTime>(
    'limit_hit_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _focusSecondsMeta = const VerificationMeta(
    'focusSeconds',
  );
  @override
  late final GeneratedColumn<int> focusSeconds = GeneratedColumn<int>(
    'focus_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lateNightSecondsMeta = const VerificationMeta(
    'lateNightSeconds',
  );
  @override
  late final GeneratedColumn<int> lateNightSeconds = GeneratedColumn<int>(
    'late_night_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    totalSeconds,
    limitSeconds,
    limitHitAt,
    focusSeconds,
    lateNightSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_summary';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailySummaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_seconds')) {
      context.handle(
        _totalSecondsMeta,
        totalSeconds.isAcceptableOrUnknown(
          data['total_seconds']!,
          _totalSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSecondsMeta);
    }
    if (data.containsKey('limit_seconds')) {
      context.handle(
        _limitSecondsMeta,
        limitSeconds.isAcceptableOrUnknown(
          data['limit_seconds']!,
          _limitSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitSecondsMeta);
    }
    if (data.containsKey('limit_hit_at')) {
      context.handle(
        _limitHitAtMeta,
        limitHitAt.isAcceptableOrUnknown(
          data['limit_hit_at']!,
          _limitHitAtMeta,
        ),
      );
    }
    if (data.containsKey('focus_seconds')) {
      context.handle(
        _focusSecondsMeta,
        focusSeconds.isAcceptableOrUnknown(
          data['focus_seconds']!,
          _focusSecondsMeta,
        ),
      );
    }
    if (data.containsKey('late_night_seconds')) {
      context.handle(
        _lateNightSecondsMeta,
        lateNightSeconds.isAcceptableOrUnknown(
          data['late_night_seconds']!,
          _lateNightSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailySummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailySummaryRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      totalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seconds'],
      )!,
      limitSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_seconds'],
      )!,
      limitHitAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}limit_hit_at'],
      ),
      focusSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_seconds'],
      )!,
      lateNightSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}late_night_seconds'],
      )!,
    );
  }

  @override
  $DailySummariesTable createAlias(String alias) {
    return $DailySummariesTable(attachedDatabase, alias);
  }
}

class DailySummaryRow extends DataClass implements Insertable<DailySummaryRow> {
  final String date;
  final int totalSeconds;
  final int limitSeconds;
  final DateTime? limitHitAt;

  /// Focus timer seconds completed on the day.
  final int focusSeconds;

  /// Combined social-app seconds used between local 00:00 and 08:00.
  final int lateNightSeconds;
  const DailySummaryRow({
    required this.date,
    required this.totalSeconds,
    required this.limitSeconds,
    this.limitHitAt,
    required this.focusSeconds,
    required this.lateNightSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['total_seconds'] = Variable<int>(totalSeconds);
    map['limit_seconds'] = Variable<int>(limitSeconds);
    if (!nullToAbsent || limitHitAt != null) {
      map['limit_hit_at'] = Variable<DateTime>(limitHitAt);
    }
    map['focus_seconds'] = Variable<int>(focusSeconds);
    map['late_night_seconds'] = Variable<int>(lateNightSeconds);
    return map;
  }

  DailySummariesCompanion toCompanion(bool nullToAbsent) {
    return DailySummariesCompanion(
      date: Value(date),
      totalSeconds: Value(totalSeconds),
      limitSeconds: Value(limitSeconds),
      limitHitAt: limitHitAt == null && nullToAbsent
          ? const Value.absent()
          : Value(limitHitAt),
      focusSeconds: Value(focusSeconds),
      lateNightSeconds: Value(lateNightSeconds),
    );
  }

  factory DailySummaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailySummaryRow(
      date: serializer.fromJson<String>(json['date']),
      totalSeconds: serializer.fromJson<int>(json['totalSeconds']),
      limitSeconds: serializer.fromJson<int>(json['limitSeconds']),
      limitHitAt: serializer.fromJson<DateTime?>(json['limitHitAt']),
      focusSeconds: serializer.fromJson<int>(json['focusSeconds']),
      lateNightSeconds: serializer.fromJson<int>(json['lateNightSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'totalSeconds': serializer.toJson<int>(totalSeconds),
      'limitSeconds': serializer.toJson<int>(limitSeconds),
      'limitHitAt': serializer.toJson<DateTime?>(limitHitAt),
      'focusSeconds': serializer.toJson<int>(focusSeconds),
      'lateNightSeconds': serializer.toJson<int>(lateNightSeconds),
    };
  }

  DailySummaryRow copyWith({
    String? date,
    int? totalSeconds,
    int? limitSeconds,
    Value<DateTime?> limitHitAt = const Value.absent(),
    int? focusSeconds,
    int? lateNightSeconds,
  }) => DailySummaryRow(
    date: date ?? this.date,
    totalSeconds: totalSeconds ?? this.totalSeconds,
    limitSeconds: limitSeconds ?? this.limitSeconds,
    limitHitAt: limitHitAt.present ? limitHitAt.value : this.limitHitAt,
    focusSeconds: focusSeconds ?? this.focusSeconds,
    lateNightSeconds: lateNightSeconds ?? this.lateNightSeconds,
  );
  DailySummaryRow copyWithCompanion(DailySummariesCompanion data) {
    return DailySummaryRow(
      date: data.date.present ? data.date.value : this.date,
      totalSeconds: data.totalSeconds.present
          ? data.totalSeconds.value
          : this.totalSeconds,
      limitSeconds: data.limitSeconds.present
          ? data.limitSeconds.value
          : this.limitSeconds,
      limitHitAt: data.limitHitAt.present
          ? data.limitHitAt.value
          : this.limitHitAt,
      focusSeconds: data.focusSeconds.present
          ? data.focusSeconds.value
          : this.focusSeconds,
      lateNightSeconds: data.lateNightSeconds.present
          ? data.lateNightSeconds.value
          : this.lateNightSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailySummaryRow(')
          ..write('date: $date, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('limitSeconds: $limitSeconds, ')
          ..write('limitHitAt: $limitHitAt, ')
          ..write('focusSeconds: $focusSeconds, ')
          ..write('lateNightSeconds: $lateNightSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    totalSeconds,
    limitSeconds,
    limitHitAt,
    focusSeconds,
    lateNightSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailySummaryRow &&
          other.date == this.date &&
          other.totalSeconds == this.totalSeconds &&
          other.limitSeconds == this.limitSeconds &&
          other.limitHitAt == this.limitHitAt &&
          other.focusSeconds == this.focusSeconds &&
          other.lateNightSeconds == this.lateNightSeconds);
}

class DailySummariesCompanion extends UpdateCompanion<DailySummaryRow> {
  final Value<String> date;
  final Value<int> totalSeconds;
  final Value<int> limitSeconds;
  final Value<DateTime?> limitHitAt;
  final Value<int> focusSeconds;
  final Value<int> lateNightSeconds;
  final Value<int> rowid;
  const DailySummariesCompanion({
    this.date = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.limitSeconds = const Value.absent(),
    this.limitHitAt = const Value.absent(),
    this.focusSeconds = const Value.absent(),
    this.lateNightSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailySummariesCompanion.insert({
    required String date,
    required int totalSeconds,
    required int limitSeconds,
    this.limitHitAt = const Value.absent(),
    this.focusSeconds = const Value.absent(),
    this.lateNightSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       totalSeconds = Value(totalSeconds),
       limitSeconds = Value(limitSeconds);
  static Insertable<DailySummaryRow> custom({
    Expression<String>? date,
    Expression<int>? totalSeconds,
    Expression<int>? limitSeconds,
    Expression<DateTime>? limitHitAt,
    Expression<int>? focusSeconds,
    Expression<int>? lateNightSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (limitSeconds != null) 'limit_seconds': limitSeconds,
      if (limitHitAt != null) 'limit_hit_at': limitHitAt,
      if (focusSeconds != null) 'focus_seconds': focusSeconds,
      if (lateNightSeconds != null) 'late_night_seconds': lateNightSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailySummariesCompanion copyWith({
    Value<String>? date,
    Value<int>? totalSeconds,
    Value<int>? limitSeconds,
    Value<DateTime?>? limitHitAt,
    Value<int>? focusSeconds,
    Value<int>? lateNightSeconds,
    Value<int>? rowid,
  }) {
    return DailySummariesCompanion(
      date: date ?? this.date,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      limitSeconds: limitSeconds ?? this.limitSeconds,
      limitHitAt: limitHitAt ?? this.limitHitAt,
      focusSeconds: focusSeconds ?? this.focusSeconds,
      lateNightSeconds: lateNightSeconds ?? this.lateNightSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (totalSeconds.present) {
      map['total_seconds'] = Variable<int>(totalSeconds.value);
    }
    if (limitSeconds.present) {
      map['limit_seconds'] = Variable<int>(limitSeconds.value);
    }
    if (limitHitAt.present) {
      map['limit_hit_at'] = Variable<DateTime>(limitHitAt.value);
    }
    if (focusSeconds.present) {
      map['focus_seconds'] = Variable<int>(focusSeconds.value);
    }
    if (lateNightSeconds.present) {
      map['late_night_seconds'] = Variable<int>(lateNightSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailySummariesCompanion(')
          ..write('date: $date, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('limitSeconds: $limitSeconds, ')
          ..write('limitHitAt: $limitHitAt, ')
          ..write('focusSeconds: $focusSeconds, ')
          ..write('lateNightSeconds: $lateNightSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReaderSourcesTable extends ReaderSources
    with TableInfo<$ReaderSourcesTable, ReaderSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedUrlMeta = const VerificationMeta(
    'feedUrl',
  );
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
    'feed_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteUrlMeta = const VerificationMeta(
    'siteUrl',
  );
  @override
  late final GeneratedColumn<String> siteUrl = GeneratedColumn<String>(
    'site_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _topicsJsonMeta = const VerificationMeta(
    'topicsJson',
  );
  @override
  late final GeneratedColumn<String> topicsJson = GeneratedColumn<String>(
    'topics_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    feedUrl,
    siteUrl,
    enabled,
    topicsJson,
    sortOrder,
    lastFetchedAt,
    lastError,
    etag,
    lastModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderSourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('feed_url')) {
      context.handle(
        _feedUrlMeta,
        feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta),
      );
    }
    if (data.containsKey('site_url')) {
      context.handle(
        _siteUrlMeta,
        siteUrl.isAcceptableOrUnknown(data['site_url']!, _siteUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_siteUrlMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('topics_json')) {
      context.handle(
        _topicsJsonMeta,
        topicsJson.isAcceptableOrUnknown(data['topics_json']!, _topicsJsonMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReaderSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderSourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      feedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_url'],
      ),
      siteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_url'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      topicsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topics_json'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified'],
      ),
    );
  }

  @override
  $ReaderSourcesTable createAlias(String alias) {
    return $ReaderSourcesTable(attachedDatabase, alias);
  }
}

class ReaderSourceRow extends DataClass implements Insertable<ReaderSourceRow> {
  final String id;
  final String name;

  /// Wire value from [ReaderSourceKind]: rss, hackerNews or devTo.
  final String kind;
  final String? feedUrl;
  final String siteUrl;
  final bool enabled;

  /// JSON array of selected topic IDs.
  final String topicsJson;
  final int sortOrder;
  final DateTime? lastFetchedAt;
  final String? lastError;
  final String? etag;
  final String? lastModified;
  const ReaderSourceRow({
    required this.id,
    required this.name,
    required this.kind,
    this.feedUrl,
    required this.siteUrl,
    required this.enabled,
    required this.topicsJson,
    required this.sortOrder,
    this.lastFetchedAt,
    this.lastError,
    this.etag,
    this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || feedUrl != null) {
      map['feed_url'] = Variable<String>(feedUrl);
    }
    map['site_url'] = Variable<String>(siteUrl);
    map['enabled'] = Variable<bool>(enabled);
    map['topics_json'] = Variable<String>(topicsJson);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || lastFetchedAt != null) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<String>(lastModified);
    }
    return map;
  }

  ReaderSourcesCompanion toCompanion(bool nullToAbsent) {
    return ReaderSourcesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      feedUrl: feedUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(feedUrl),
      siteUrl: Value(siteUrl),
      enabled: Value(enabled),
      topicsJson: Value(topicsJson),
      sortOrder: Value(sortOrder),
      lastFetchedAt: lastFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
    );
  }

  factory ReaderSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderSourceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      feedUrl: serializer.fromJson<String?>(json['feedUrl']),
      siteUrl: serializer.fromJson<String>(json['siteUrl']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      topicsJson: serializer.fromJson<String>(json['topicsJson']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastFetchedAt: serializer.fromJson<DateTime?>(json['lastFetchedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastModified: serializer.fromJson<String?>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'feedUrl': serializer.toJson<String?>(feedUrl),
      'siteUrl': serializer.toJson<String>(siteUrl),
      'enabled': serializer.toJson<bool>(enabled),
      'topicsJson': serializer.toJson<String>(topicsJson),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastFetchedAt': serializer.toJson<DateTime?>(lastFetchedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'etag': serializer.toJson<String?>(etag),
      'lastModified': serializer.toJson<String?>(lastModified),
    };
  }

  ReaderSourceRow copyWith({
    String? id,
    String? name,
    String? kind,
    Value<String?> feedUrl = const Value.absent(),
    String? siteUrl,
    bool? enabled,
    String? topicsJson,
    int? sortOrder,
    Value<DateTime?> lastFetchedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    Value<String?> lastModified = const Value.absent(),
  }) => ReaderSourceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    feedUrl: feedUrl.present ? feedUrl.value : this.feedUrl,
    siteUrl: siteUrl ?? this.siteUrl,
    enabled: enabled ?? this.enabled,
    topicsJson: topicsJson ?? this.topicsJson,
    sortOrder: sortOrder ?? this.sortOrder,
    lastFetchedAt: lastFetchedAt.present
        ? lastFetchedAt.value
        : this.lastFetchedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    etag: etag.present ? etag.value : this.etag,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
  );
  ReaderSourceRow copyWithCompanion(ReaderSourcesCompanion data) {
    return ReaderSourceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      siteUrl: data.siteUrl.present ? data.siteUrl.value : this.siteUrl,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      topicsJson: data.topicsJson.present
          ? data.topicsJson.value
          : this.topicsJson,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderSourceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('siteUrl: $siteUrl, ')
          ..write('enabled: $enabled, ')
          ..write('topicsJson: $topicsJson, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastError: $lastError, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    feedUrl,
    siteUrl,
    enabled,
    topicsJson,
    sortOrder,
    lastFetchedAt,
    lastError,
    etag,
    lastModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderSourceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.feedUrl == this.feedUrl &&
          other.siteUrl == this.siteUrl &&
          other.enabled == this.enabled &&
          other.topicsJson == this.topicsJson &&
          other.sortOrder == this.sortOrder &&
          other.lastFetchedAt == this.lastFetchedAt &&
          other.lastError == this.lastError &&
          other.etag == this.etag &&
          other.lastModified == this.lastModified);
}

class ReaderSourcesCompanion extends UpdateCompanion<ReaderSourceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String?> feedUrl;
  final Value<String> siteUrl;
  final Value<bool> enabled;
  final Value<String> topicsJson;
  final Value<int> sortOrder;
  final Value<DateTime?> lastFetchedAt;
  final Value<String?> lastError;
  final Value<String?> etag;
  final Value<String?> lastModified;
  final Value<int> rowid;
  const ReaderSourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.siteUrl = const Value.absent(),
    this.enabled = const Value.absent(),
    this.topicsJson = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReaderSourcesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    this.feedUrl = const Value.absent(),
    required String siteUrl,
    this.enabled = const Value.absent(),
    this.topicsJson = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       siteUrl = Value(siteUrl);
  static Insertable<ReaderSourceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? feedUrl,
    Expression<String>? siteUrl,
    Expression<bool>? enabled,
    Expression<String>? topicsJson,
    Expression<int>? sortOrder,
    Expression<DateTime>? lastFetchedAt,
    Expression<String>? lastError,
    Expression<String>? etag,
    Expression<String>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (siteUrl != null) 'site_url': siteUrl,
      if (enabled != null) 'enabled': enabled,
      if (topicsJson != null) 'topics_json': topicsJson,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
      if (lastError != null) 'last_error': lastError,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReaderSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String?>? feedUrl,
    Value<String>? siteUrl,
    Value<bool>? enabled,
    Value<String>? topicsJson,
    Value<int>? sortOrder,
    Value<DateTime?>? lastFetchedAt,
    Value<String?>? lastError,
    Value<String?>? etag,
    Value<String?>? lastModified,
    Value<int>? rowid,
  }) {
    return ReaderSourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      feedUrl: feedUrl ?? this.feedUrl,
      siteUrl: siteUrl ?? this.siteUrl,
      enabled: enabled ?? this.enabled,
      topicsJson: topicsJson ?? this.topicsJson,
      sortOrder: sortOrder ?? this.sortOrder,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastError: lastError ?? this.lastError,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (siteUrl.present) {
      map['site_url'] = Variable<String>(siteUrl.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (topicsJson.present) {
      map['topics_json'] = Variable<String>(topicsJson.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderSourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('siteUrl: $siteUrl, ')
          ..write('enabled: $enabled, ')
          ..write('topicsJson: $topicsJson, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastError: $lastError, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReaderArticlesTable extends ReaderArticles
    with TableInfo<$ReaderArticlesTable, ReaderArticleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excerptMeta = const VerificationMeta(
    'excerpt',
  );
  @override
  late final GeneratedColumn<String> excerpt = GeneratedColumn<String>(
    'excerpt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentHtmlMeta = const VerificationMeta(
    'contentHtml',
  );
  @override
  late final GeneratedColumn<String> contentHtml = GeneratedColumn<String>(
    'content_html',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readingMinutesMeta = const VerificationMeta(
    'readingMinutes',
  );
  @override
  late final GeneratedColumn<int> readingMinutes = GeneratedColumn<int>(
    'reading_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pickDateMeta = const VerificationMeta(
    'pickDate',
  );
  @override
  late final GeneratedColumn<String> pickDate = GeneratedColumn<String>(
    'pick_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pickRankMeta = const VerificationMeta(
    'pickRank',
  );
  @override
  late final GeneratedColumn<int> pickRank = GeneratedColumn<int>(
    'pick_rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    sourceName,
    title,
    url,
    excerpt,
    contentHtml,
    readingMinutes,
    publishedAt,
    fetchedAt,
    isRead,
    pickDate,
    pickRank,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderArticleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('excerpt')) {
      context.handle(
        _excerptMeta,
        excerpt.isAcceptableOrUnknown(data['excerpt']!, _excerptMeta),
      );
    }
    if (data.containsKey('content_html')) {
      context.handle(
        _contentHtmlMeta,
        contentHtml.isAcceptableOrUnknown(
          data['content_html']!,
          _contentHtmlMeta,
        ),
      );
    }
    if (data.containsKey('reading_minutes')) {
      context.handle(
        _readingMinutesMeta,
        readingMinutes.isAcceptableOrUnknown(
          data['reading_minutes']!,
          _readingMinutesMeta,
        ),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('pick_date')) {
      context.handle(
        _pickDateMeta,
        pickDate.isAcceptableOrUnknown(data['pick_date']!, _pickDateMeta),
      );
    }
    if (data.containsKey('pick_rank')) {
      context.handle(
        _pickRankMeta,
        pickRank.isAcceptableOrUnknown(data['pick_rank']!, _pickRankMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {url},
  ];
  @override
  ReaderArticleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderArticleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      excerpt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excerpt'],
      )!,
      contentHtml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_html'],
      ),
      readingMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reading_minutes'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      pickDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pick_date'],
      ),
      pickRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pick_rank'],
      ),
    );
  }

  @override
  $ReaderArticlesTable createAlias(String alias) {
    return $ReaderArticlesTable(attachedDatabase, alias);
  }
}

class ReaderArticleRow extends DataClass
    implements Insertable<ReaderArticleRow> {
  final String id;
  final String sourceId;

  /// Snapshot used for attribution if the source row is edited later.
  final String sourceName;
  final String title;
  final String url;
  final String excerpt;
  final String? contentHtml;
  final int readingMinutes;
  final DateTime? publishedAt;
  final DateTime fetchedAt;
  final bool isRead;
  final String? pickDate;
  final int? pickRank;
  const ReaderArticleRow({
    required this.id,
    required this.sourceId,
    required this.sourceName,
    required this.title,
    required this.url,
    required this.excerpt,
    this.contentHtml,
    required this.readingMinutes,
    this.publishedAt,
    required this.fetchedAt,
    required this.isRead,
    this.pickDate,
    this.pickRank,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['source_name'] = Variable<String>(sourceName);
    map['title'] = Variable<String>(title);
    map['url'] = Variable<String>(url);
    map['excerpt'] = Variable<String>(excerpt);
    if (!nullToAbsent || contentHtml != null) {
      map['content_html'] = Variable<String>(contentHtml);
    }
    map['reading_minutes'] = Variable<int>(readingMinutes);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || pickDate != null) {
      map['pick_date'] = Variable<String>(pickDate);
    }
    if (!nullToAbsent || pickRank != null) {
      map['pick_rank'] = Variable<int>(pickRank);
    }
    return map;
  }

  ReaderArticlesCompanion toCompanion(bool nullToAbsent) {
    return ReaderArticlesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      sourceName: Value(sourceName),
      title: Value(title),
      url: Value(url),
      excerpt: Value(excerpt),
      contentHtml: contentHtml == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHtml),
      readingMinutes: Value(readingMinutes),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      fetchedAt: Value(fetchedAt),
      isRead: Value(isRead),
      pickDate: pickDate == null && nullToAbsent
          ? const Value.absent()
          : Value(pickDate),
      pickRank: pickRank == null && nullToAbsent
          ? const Value.absent()
          : Value(pickRank),
    );
  }

  factory ReaderArticleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderArticleRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String>(json['url']),
      excerpt: serializer.fromJson<String>(json['excerpt']),
      contentHtml: serializer.fromJson<String?>(json['contentHtml']),
      readingMinutes: serializer.fromJson<int>(json['readingMinutes']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      pickDate: serializer.fromJson<String?>(json['pickDate']),
      pickRank: serializer.fromJson<int?>(json['pickRank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'sourceName': serializer.toJson<String>(sourceName),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String>(url),
      'excerpt': serializer.toJson<String>(excerpt),
      'contentHtml': serializer.toJson<String?>(contentHtml),
      'readingMinutes': serializer.toJson<int>(readingMinutes),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'isRead': serializer.toJson<bool>(isRead),
      'pickDate': serializer.toJson<String?>(pickDate),
      'pickRank': serializer.toJson<int?>(pickRank),
    };
  }

  ReaderArticleRow copyWith({
    String? id,
    String? sourceId,
    String? sourceName,
    String? title,
    String? url,
    String? excerpt,
    Value<String?> contentHtml = const Value.absent(),
    int? readingMinutes,
    Value<DateTime?> publishedAt = const Value.absent(),
    DateTime? fetchedAt,
    bool? isRead,
    Value<String?> pickDate = const Value.absent(),
    Value<int?> pickRank = const Value.absent(),
  }) => ReaderArticleRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    sourceName: sourceName ?? this.sourceName,
    title: title ?? this.title,
    url: url ?? this.url,
    excerpt: excerpt ?? this.excerpt,
    contentHtml: contentHtml.present ? contentHtml.value : this.contentHtml,
    readingMinutes: readingMinutes ?? this.readingMinutes,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    isRead: isRead ?? this.isRead,
    pickDate: pickDate.present ? pickDate.value : this.pickDate,
    pickRank: pickRank.present ? pickRank.value : this.pickRank,
  );
  ReaderArticleRow copyWithCompanion(ReaderArticlesCompanion data) {
    return ReaderArticleRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      excerpt: data.excerpt.present ? data.excerpt.value : this.excerpt,
      contentHtml: data.contentHtml.present
          ? data.contentHtml.value
          : this.contentHtml,
      readingMinutes: data.readingMinutes.present
          ? data.readingMinutes.value
          : this.readingMinutes,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      pickDate: data.pickDate.present ? data.pickDate.value : this.pickDate,
      pickRank: data.pickRank.present ? data.pickRank.value : this.pickRank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderArticleRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceName: $sourceName, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('excerpt: $excerpt, ')
          ..write('contentHtml: $contentHtml, ')
          ..write('readingMinutes: $readingMinutes, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('isRead: $isRead, ')
          ..write('pickDate: $pickDate, ')
          ..write('pickRank: $pickRank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    sourceName,
    title,
    url,
    excerpt,
    contentHtml,
    readingMinutes,
    publishedAt,
    fetchedAt,
    isRead,
    pickDate,
    pickRank,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderArticleRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.sourceName == this.sourceName &&
          other.title == this.title &&
          other.url == this.url &&
          other.excerpt == this.excerpt &&
          other.contentHtml == this.contentHtml &&
          other.readingMinutes == this.readingMinutes &&
          other.publishedAt == this.publishedAt &&
          other.fetchedAt == this.fetchedAt &&
          other.isRead == this.isRead &&
          other.pickDate == this.pickDate &&
          other.pickRank == this.pickRank);
}

class ReaderArticlesCompanion extends UpdateCompanion<ReaderArticleRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String> sourceName;
  final Value<String> title;
  final Value<String> url;
  final Value<String> excerpt;
  final Value<String?> contentHtml;
  final Value<int> readingMinutes;
  final Value<DateTime?> publishedAt;
  final Value<DateTime> fetchedAt;
  final Value<bool> isRead;
  final Value<String?> pickDate;
  final Value<int?> pickRank;
  final Value<int> rowid;
  const ReaderArticlesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.contentHtml = const Value.absent(),
    this.readingMinutes = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.isRead = const Value.absent(),
    this.pickDate = const Value.absent(),
    this.pickRank = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReaderArticlesCompanion.insert({
    required String id,
    required String sourceId,
    required String sourceName,
    required String title,
    required String url,
    this.excerpt = const Value.absent(),
    this.contentHtml = const Value.absent(),
    this.readingMinutes = const Value.absent(),
    this.publishedAt = const Value.absent(),
    required DateTime fetchedAt,
    this.isRead = const Value.absent(),
    this.pickDate = const Value.absent(),
    this.pickRank = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       sourceName = Value(sourceName),
       title = Value(title),
       url = Value(url),
       fetchedAt = Value(fetchedAt);
  static Insertable<ReaderArticleRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? sourceName,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? excerpt,
    Expression<String>? contentHtml,
    Expression<int>? readingMinutes,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? fetchedAt,
    Expression<bool>? isRead,
    Expression<String>? pickDate,
    Expression<int>? pickRank,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceName != null) 'source_name': sourceName,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (excerpt != null) 'excerpt': excerpt,
      if (contentHtml != null) 'content_html': contentHtml,
      if (readingMinutes != null) 'reading_minutes': readingMinutes,
      if (publishedAt != null) 'published_at': publishedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (isRead != null) 'is_read': isRead,
      if (pickDate != null) 'pick_date': pickDate,
      if (pickRank != null) 'pick_rank': pickRank,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReaderArticlesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String>? sourceName,
    Value<String>? title,
    Value<String>? url,
    Value<String>? excerpt,
    Value<String?>? contentHtml,
    Value<int>? readingMinutes,
    Value<DateTime?>? publishedAt,
    Value<DateTime>? fetchedAt,
    Value<bool>? isRead,
    Value<String?>? pickDate,
    Value<int?>? pickRank,
    Value<int>? rowid,
  }) {
    return ReaderArticlesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      title: title ?? this.title,
      url: url ?? this.url,
      excerpt: excerpt ?? this.excerpt,
      contentHtml: contentHtml ?? this.contentHtml,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      publishedAt: publishedAt ?? this.publishedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isRead: isRead ?? this.isRead,
      pickDate: pickDate ?? this.pickDate,
      pickRank: pickRank ?? this.pickRank,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (excerpt.present) {
      map['excerpt'] = Variable<String>(excerpt.value);
    }
    if (contentHtml.present) {
      map['content_html'] = Variable<String>(contentHtml.value);
    }
    if (readingMinutes.present) {
      map['reading_minutes'] = Variable<int>(readingMinutes.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (pickDate.present) {
      map['pick_date'] = Variable<String>(pickDate.value);
    }
    if (pickRank.present) {
      map['pick_rank'] = Variable<int>(pickRank.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderArticlesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceName: $sourceName, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('excerpt: $excerpt, ')
          ..write('contentHtml: $contentHtml, ')
          ..write('readingMinutes: $readingMinutes, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('isRead: $isRead, ')
          ..write('pickDate: $pickDate, ')
          ..write('pickRank: $pickRank, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReaderBookmarksTable extends ReaderBookmarks
    with TableInfo<$ReaderBookmarksTable, ReaderBookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _articleIdMeta = const VerificationMeta(
    'articleId',
  );
  @override
  late final GeneratedColumn<String> articleId = GeneratedColumn<String>(
    'article_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [articleId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderBookmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('article_id')) {
      context.handle(
        _articleIdMeta,
        articleId.isAcceptableOrUnknown(data['article_id']!, _articleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {articleId};
  @override
  ReaderBookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderBookmarkRow(
      articleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReaderBookmarksTable createAlias(String alias) {
    return $ReaderBookmarksTable(attachedDatabase, alias);
  }
}

class ReaderBookmarkRow extends DataClass
    implements Insertable<ReaderBookmarkRow> {
  final String articleId;
  final DateTime createdAt;
  const ReaderBookmarkRow({required this.articleId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['article_id'] = Variable<String>(articleId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReaderBookmarksCompanion toCompanion(bool nullToAbsent) {
    return ReaderBookmarksCompanion(
      articleId: Value(articleId),
      createdAt: Value(createdAt),
    );
  }

  factory ReaderBookmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderBookmarkRow(
      articleId: serializer.fromJson<String>(json['articleId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'articleId': serializer.toJson<String>(articleId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReaderBookmarkRow copyWith({String? articleId, DateTime? createdAt}) =>
      ReaderBookmarkRow(
        articleId: articleId ?? this.articleId,
        createdAt: createdAt ?? this.createdAt,
      );
  ReaderBookmarkRow copyWithCompanion(ReaderBookmarksCompanion data) {
    return ReaderBookmarkRow(
      articleId: data.articleId.present ? data.articleId.value : this.articleId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderBookmarkRow(')
          ..write('articleId: $articleId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(articleId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderBookmarkRow &&
          other.articleId == this.articleId &&
          other.createdAt == this.createdAt);
}

class ReaderBookmarksCompanion extends UpdateCompanion<ReaderBookmarkRow> {
  final Value<String> articleId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReaderBookmarksCompanion({
    this.articleId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReaderBookmarksCompanion.insert({
    required String articleId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : articleId = Value(articleId);
  static Insertable<ReaderBookmarkRow> custom({
    Expression<String>? articleId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (articleId != null) 'article_id': articleId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReaderBookmarksCompanion copyWith({
    Value<String>? articleId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ReaderBookmarksCompanion(
      articleId: articleId ?? this.articleId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (articleId.present) {
      map['article_id'] = Variable<String>(articleId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderBookmarksCompanion(')
          ..write('articleId: $articleId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _articleIdMeta = const VerificationMeta(
    'articleId',
  );
  @override
  late final GeneratedColumn<String> articleId = GeneratedColumn<String>(
    'article_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, articleId, seconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('article_id')) {
      context.handle(
        _articleIdMeta,
        articleId.isAcceptableOrUnknown(data['article_id']!, _articleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, articleId};
  @override
  ReadingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSessionRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      articleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article_id'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSessionRow extends DataClass
    implements Insertable<ReadingSessionRow> {
  final String date;
  final String articleId;
  final int seconds;
  const ReadingSessionRow({
    required this.date,
    required this.articleId,
    required this.seconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['article_id'] = Variable<String>(articleId);
    map['seconds'] = Variable<int>(seconds);
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      date: Value(date),
      articleId: Value(articleId),
      seconds: Value(seconds),
    );
  }

  factory ReadingSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSessionRow(
      date: serializer.fromJson<String>(json['date']),
      articleId: serializer.fromJson<String>(json['articleId']),
      seconds: serializer.fromJson<int>(json['seconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'articleId': serializer.toJson<String>(articleId),
      'seconds': serializer.toJson<int>(seconds),
    };
  }

  ReadingSessionRow copyWith({String? date, String? articleId, int? seconds}) =>
      ReadingSessionRow(
        date: date ?? this.date,
        articleId: articleId ?? this.articleId,
        seconds: seconds ?? this.seconds,
      );
  ReadingSessionRow copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSessionRow(
      date: data.date.present ? data.date.value : this.date,
      articleId: data.articleId.present ? data.articleId.value : this.articleId,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionRow(')
          ..write('date: $date, ')
          ..write('articleId: $articleId, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, articleId, seconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSessionRow &&
          other.date == this.date &&
          other.articleId == this.articleId &&
          other.seconds == this.seconds);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSessionRow> {
  final Value<String> date;
  final Value<String> articleId;
  final Value<int> seconds;
  final Value<int> rowid;
  const ReadingSessionsCompanion({
    this.date = const Value.absent(),
    this.articleId = const Value.absent(),
    this.seconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    required String date,
    required String articleId,
    required int seconds,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       articleId = Value(articleId),
       seconds = Value(seconds);
  static Insertable<ReadingSessionRow> custom({
    Expression<String>? date,
    Expression<String>? articleId,
    Expression<int>? seconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (articleId != null) 'article_id': articleId,
      if (seconds != null) 'seconds': seconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<String>? date,
    Value<String>? articleId,
    Value<int>? seconds,
    Value<int>? rowid,
  }) {
    return ReadingSessionsCompanion(
      date: date ?? this.date,
      articleId: articleId ?? this.articleId,
      seconds: seconds ?? this.seconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (articleId.present) {
      map['article_id'] = Variable<String>(articleId.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('date: $date, ')
          ..write('articleId: $articleId, ')
          ..write('seconds: $seconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MonitoredAppsTable monitoredApps = $MonitoredAppsTable(this);
  late final $DailyUsagesTable dailyUsages = $DailyUsagesTable(this);
  late final $DailySummariesTable dailySummaries = $DailySummariesTable(this);
  late final $ReaderSourcesTable readerSources = $ReaderSourcesTable(this);
  late final $ReaderArticlesTable readerArticles = $ReaderArticlesTable(this);
  late final $ReaderBookmarksTable readerBookmarks = $ReaderBookmarksTable(
    this,
  );
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    monitoredApps,
    dailyUsages,
    dailySummaries,
    readerSources,
    readerArticles,
    readerBookmarks,
    readingSessions,
  ];
}

typedef $$MonitoredAppsTableCreateCompanionBuilder =
    MonitoredAppsCompanion Function({
      required String packageName,
      required String displayName,
      Value<bool> isEnabled,
      Value<bool?> pendingEnabled,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MonitoredAppsTableUpdateCompanionBuilder =
    MonitoredAppsCompanion Function({
      Value<String> packageName,
      Value<String> displayName,
      Value<bool> isEnabled,
      Value<bool?> pendingEnabled,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MonitoredAppsTableFilterComposer
    extends Composer<_$AppDatabase, $MonitoredAppsTable> {
  $$MonitoredAppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingEnabled => $composableBuilder(
    column: $table.pendingEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonitoredAppsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonitoredAppsTable> {
  $$MonitoredAppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingEnabled => $composableBuilder(
    column: $table.pendingEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonitoredAppsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonitoredAppsTable> {
  $$MonitoredAppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<bool> get pendingEnabled => $composableBuilder(
    column: $table.pendingEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MonitoredAppsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonitoredAppsTable,
          MonitoredAppRow,
          $$MonitoredAppsTableFilterComposer,
          $$MonitoredAppsTableOrderingComposer,
          $$MonitoredAppsTableAnnotationComposer,
          $$MonitoredAppsTableCreateCompanionBuilder,
          $$MonitoredAppsTableUpdateCompanionBuilder,
          (
            MonitoredAppRow,
            BaseReferences<_$AppDatabase, $MonitoredAppsTable, MonitoredAppRow>,
          ),
          MonitoredAppRow,
          PrefetchHooks Function()
        > {
  $$MonitoredAppsTableTableManager(_$AppDatabase db, $MonitoredAppsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonitoredAppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonitoredAppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonitoredAppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packageName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool?> pendingEnabled = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonitoredAppsCompanion(
                packageName: packageName,
                displayName: displayName,
                isEnabled: isEnabled,
                pendingEnabled: pendingEnabled,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packageName,
                required String displayName,
                Value<bool> isEnabled = const Value.absent(),
                Value<bool?> pendingEnabled = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonitoredAppsCompanion.insert(
                packageName: packageName,
                displayName: displayName,
                isEnabled: isEnabled,
                pendingEnabled: pendingEnabled,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonitoredAppsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonitoredAppsTable,
      MonitoredAppRow,
      $$MonitoredAppsTableFilterComposer,
      $$MonitoredAppsTableOrderingComposer,
      $$MonitoredAppsTableAnnotationComposer,
      $$MonitoredAppsTableCreateCompanionBuilder,
      $$MonitoredAppsTableUpdateCompanionBuilder,
      (
        MonitoredAppRow,
        BaseReferences<_$AppDatabase, $MonitoredAppsTable, MonitoredAppRow>,
      ),
      MonitoredAppRow,
      PrefetchHooks Function()
    >;
typedef $$DailyUsagesTableCreateCompanionBuilder =
    DailyUsagesCompanion Function({
      required String date,
      required String packageName,
      required int totalSeconds,
      Value<int> lateNightSeconds,
      Value<int> rowid,
    });
typedef $$DailyUsagesTableUpdateCompanionBuilder =
    DailyUsagesCompanion Function({
      Value<String> date,
      Value<String> packageName,
      Value<int> totalSeconds,
      Value<int> lateNightSeconds,
      Value<int> rowid,
    });

class $$DailyUsagesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyUsagesTable> {
  $$DailyUsagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lateNightSeconds => $composableBuilder(
    column: $table.lateNightSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyUsagesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyUsagesTable> {
  $$DailyUsagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lateNightSeconds => $composableBuilder(
    column: $table.lateNightSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyUsagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyUsagesTable> {
  $$DailyUsagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lateNightSeconds => $composableBuilder(
    column: $table.lateNightSeconds,
    builder: (column) => column,
  );
}

class $$DailyUsagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyUsagesTable,
          DailyUsageRow,
          $$DailyUsagesTableFilterComposer,
          $$DailyUsagesTableOrderingComposer,
          $$DailyUsagesTableAnnotationComposer,
          $$DailyUsagesTableCreateCompanionBuilder,
          $$DailyUsagesTableUpdateCompanionBuilder,
          (
            DailyUsageRow,
            BaseReferences<_$AppDatabase, $DailyUsagesTable, DailyUsageRow>,
          ),
          DailyUsageRow,
          PrefetchHooks Function()
        > {
  $$DailyUsagesTableTableManager(_$AppDatabase db, $DailyUsagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyUsagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyUsagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyUsagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<int> totalSeconds = const Value.absent(),
                Value<int> lateNightSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyUsagesCompanion(
                date: date,
                packageName: packageName,
                totalSeconds: totalSeconds,
                lateNightSeconds: lateNightSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String packageName,
                required int totalSeconds,
                Value<int> lateNightSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyUsagesCompanion.insert(
                date: date,
                packageName: packageName,
                totalSeconds: totalSeconds,
                lateNightSeconds: lateNightSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyUsagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyUsagesTable,
      DailyUsageRow,
      $$DailyUsagesTableFilterComposer,
      $$DailyUsagesTableOrderingComposer,
      $$DailyUsagesTableAnnotationComposer,
      $$DailyUsagesTableCreateCompanionBuilder,
      $$DailyUsagesTableUpdateCompanionBuilder,
      (
        DailyUsageRow,
        BaseReferences<_$AppDatabase, $DailyUsagesTable, DailyUsageRow>,
      ),
      DailyUsageRow,
      PrefetchHooks Function()
    >;
typedef $$DailySummariesTableCreateCompanionBuilder =
    DailySummariesCompanion Function({
      required String date,
      required int totalSeconds,
      required int limitSeconds,
      Value<DateTime?> limitHitAt,
      Value<int> focusSeconds,
      Value<int> lateNightSeconds,
      Value<int> rowid,
    });
typedef $$DailySummariesTableUpdateCompanionBuilder =
    DailySummariesCompanion Function({
      Value<String> date,
      Value<int> totalSeconds,
      Value<int> limitSeconds,
      Value<DateTime?> limitHitAt,
      Value<int> focusSeconds,
      Value<int> lateNightSeconds,
      Value<int> rowid,
    });

class $$DailySummariesTableFilterComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitSeconds => $composableBuilder(
    column: $table.limitSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get limitHitAt => $composableBuilder(
    column: $table.limitHitAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusSeconds => $composableBuilder(
    column: $table.focusSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lateNightSeconds => $composableBuilder(
    column: $table.lateNightSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailySummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitSeconds => $composableBuilder(
    column: $table.limitSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get limitHitAt => $composableBuilder(
    column: $table.limitHitAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusSeconds => $composableBuilder(
    column: $table.focusSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lateNightSeconds => $composableBuilder(
    column: $table.lateNightSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailySummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get limitSeconds => $composableBuilder(
    column: $table.limitSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get limitHitAt => $composableBuilder(
    column: $table.limitHitAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get focusSeconds => $composableBuilder(
    column: $table.focusSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lateNightSeconds => $composableBuilder(
    column: $table.lateNightSeconds,
    builder: (column) => column,
  );
}

class $$DailySummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailySummariesTable,
          DailySummaryRow,
          $$DailySummariesTableFilterComposer,
          $$DailySummariesTableOrderingComposer,
          $$DailySummariesTableAnnotationComposer,
          $$DailySummariesTableCreateCompanionBuilder,
          $$DailySummariesTableUpdateCompanionBuilder,
          (
            DailySummaryRow,
            BaseReferences<
              _$AppDatabase,
              $DailySummariesTable,
              DailySummaryRow
            >,
          ),
          DailySummaryRow,
          PrefetchHooks Function()
        > {
  $$DailySummariesTableTableManager(
    _$AppDatabase db,
    $DailySummariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailySummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailySummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailySummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> totalSeconds = const Value.absent(),
                Value<int> limitSeconds = const Value.absent(),
                Value<DateTime?> limitHitAt = const Value.absent(),
                Value<int> focusSeconds = const Value.absent(),
                Value<int> lateNightSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesCompanion(
                date: date,
                totalSeconds: totalSeconds,
                limitSeconds: limitSeconds,
                limitHitAt: limitHitAt,
                focusSeconds: focusSeconds,
                lateNightSeconds: lateNightSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required int totalSeconds,
                required int limitSeconds,
                Value<DateTime?> limitHitAt = const Value.absent(),
                Value<int> focusSeconds = const Value.absent(),
                Value<int> lateNightSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesCompanion.insert(
                date: date,
                totalSeconds: totalSeconds,
                limitSeconds: limitSeconds,
                limitHitAt: limitHitAt,
                focusSeconds: focusSeconds,
                lateNightSeconds: lateNightSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailySummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailySummariesTable,
      DailySummaryRow,
      $$DailySummariesTableFilterComposer,
      $$DailySummariesTableOrderingComposer,
      $$DailySummariesTableAnnotationComposer,
      $$DailySummariesTableCreateCompanionBuilder,
      $$DailySummariesTableUpdateCompanionBuilder,
      (
        DailySummaryRow,
        BaseReferences<_$AppDatabase, $DailySummariesTable, DailySummaryRow>,
      ),
      DailySummaryRow,
      PrefetchHooks Function()
    >;
typedef $$ReaderSourcesTableCreateCompanionBuilder =
    ReaderSourcesCompanion Function({
      required String id,
      required String name,
      required String kind,
      Value<String?> feedUrl,
      required String siteUrl,
      Value<bool> enabled,
      Value<String> topicsJson,
      Value<int> sortOrder,
      Value<DateTime?> lastFetchedAt,
      Value<String?> lastError,
      Value<String?> etag,
      Value<String?> lastModified,
      Value<int> rowid,
    });
typedef $$ReaderSourcesTableUpdateCompanionBuilder =
    ReaderSourcesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<String?> feedUrl,
      Value<String> siteUrl,
      Value<bool> enabled,
      Value<String> topicsJson,
      Value<int> sortOrder,
      Value<DateTime?> lastFetchedAt,
      Value<String?> lastError,
      Value<String?> etag,
      Value<String?> lastModified,
      Value<int> rowid,
    });

class $$ReaderSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderSourcesTable> {
  $$ReaderSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteUrl => $composableBuilder(
    column: $table.siteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicsJson => $composableBuilder(
    column: $table.topicsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReaderSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderSourcesTable> {
  $$ReaderSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteUrl => $composableBuilder(
    column: $table.siteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicsJson => $composableBuilder(
    column: $table.topicsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReaderSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderSourcesTable> {
  $$ReaderSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get siteUrl =>
      $composableBuilder(column: $table.siteUrl, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get topicsJson => $composableBuilder(
    column: $table.topicsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$ReaderSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderSourcesTable,
          ReaderSourceRow,
          $$ReaderSourcesTableFilterComposer,
          $$ReaderSourcesTableOrderingComposer,
          $$ReaderSourcesTableAnnotationComposer,
          $$ReaderSourcesTableCreateCompanionBuilder,
          $$ReaderSourcesTableUpdateCompanionBuilder,
          (
            ReaderSourceRow,
            BaseReferences<_$AppDatabase, $ReaderSourcesTable, ReaderSourceRow>,
          ),
          ReaderSourceRow,
          PrefetchHooks Function()
        > {
  $$ReaderSourcesTableTableManager(_$AppDatabase db, $ReaderSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReaderSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> feedUrl = const Value.absent(),
                Value<String> siteUrl = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> topicsJson = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderSourcesCompanion(
                id: id,
                name: name,
                kind: kind,
                feedUrl: feedUrl,
                siteUrl: siteUrl,
                enabled: enabled,
                topicsJson: topicsJson,
                sortOrder: sortOrder,
                lastFetchedAt: lastFetchedAt,
                lastError: lastError,
                etag: etag,
                lastModified: lastModified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                Value<String?> feedUrl = const Value.absent(),
                required String siteUrl,
                Value<bool> enabled = const Value.absent(),
                Value<String> topicsJson = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderSourcesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                feedUrl: feedUrl,
                siteUrl: siteUrl,
                enabled: enabled,
                topicsJson: topicsJson,
                sortOrder: sortOrder,
                lastFetchedAt: lastFetchedAt,
                lastError: lastError,
                etag: etag,
                lastModified: lastModified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReaderSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderSourcesTable,
      ReaderSourceRow,
      $$ReaderSourcesTableFilterComposer,
      $$ReaderSourcesTableOrderingComposer,
      $$ReaderSourcesTableAnnotationComposer,
      $$ReaderSourcesTableCreateCompanionBuilder,
      $$ReaderSourcesTableUpdateCompanionBuilder,
      (
        ReaderSourceRow,
        BaseReferences<_$AppDatabase, $ReaderSourcesTable, ReaderSourceRow>,
      ),
      ReaderSourceRow,
      PrefetchHooks Function()
    >;
typedef $$ReaderArticlesTableCreateCompanionBuilder =
    ReaderArticlesCompanion Function({
      required String id,
      required String sourceId,
      required String sourceName,
      required String title,
      required String url,
      Value<String> excerpt,
      Value<String?> contentHtml,
      Value<int> readingMinutes,
      Value<DateTime?> publishedAt,
      required DateTime fetchedAt,
      Value<bool> isRead,
      Value<String?> pickDate,
      Value<int?> pickRank,
      Value<int> rowid,
    });
typedef $$ReaderArticlesTableUpdateCompanionBuilder =
    ReaderArticlesCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String> sourceName,
      Value<String> title,
      Value<String> url,
      Value<String> excerpt,
      Value<String?> contentHtml,
      Value<int> readingMinutes,
      Value<DateTime?> publishedAt,
      Value<DateTime> fetchedAt,
      Value<bool> isRead,
      Value<String?> pickDate,
      Value<int?> pickRank,
      Value<int> rowid,
    });

class $$ReaderArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderArticlesTable> {
  $$ReaderArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHtml => $composableBuilder(
    column: $table.contentHtml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readingMinutes => $composableBuilder(
    column: $table.readingMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pickDate => $composableBuilder(
    column: $table.pickDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pickRank => $composableBuilder(
    column: $table.pickRank,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReaderArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderArticlesTable> {
  $$ReaderArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHtml => $composableBuilder(
    column: $table.contentHtml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readingMinutes => $composableBuilder(
    column: $table.readingMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pickDate => $composableBuilder(
    column: $table.pickDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pickRank => $composableBuilder(
    column: $table.pickRank,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReaderArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderArticlesTable> {
  $$ReaderArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get excerpt =>
      $composableBuilder(column: $table.excerpt, builder: (column) => column);

  GeneratedColumn<String> get contentHtml => $composableBuilder(
    column: $table.contentHtml,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readingMinutes => $composableBuilder(
    column: $table.readingMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<String> get pickDate =>
      $composableBuilder(column: $table.pickDate, builder: (column) => column);

  GeneratedColumn<int> get pickRank =>
      $composableBuilder(column: $table.pickRank, builder: (column) => column);
}

class $$ReaderArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderArticlesTable,
          ReaderArticleRow,
          $$ReaderArticlesTableFilterComposer,
          $$ReaderArticlesTableOrderingComposer,
          $$ReaderArticlesTableAnnotationComposer,
          $$ReaderArticlesTableCreateCompanionBuilder,
          $$ReaderArticlesTableUpdateCompanionBuilder,
          (
            ReaderArticleRow,
            BaseReferences<
              _$AppDatabase,
              $ReaderArticlesTable,
              ReaderArticleRow
            >,
          ),
          ReaderArticleRow,
          PrefetchHooks Function()
        > {
  $$ReaderArticlesTableTableManager(
    _$AppDatabase db,
    $ReaderArticlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReaderArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> excerpt = const Value.absent(),
                Value<String?> contentHtml = const Value.absent(),
                Value<int> readingMinutes = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<String?> pickDate = const Value.absent(),
                Value<int?> pickRank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderArticlesCompanion(
                id: id,
                sourceId: sourceId,
                sourceName: sourceName,
                title: title,
                url: url,
                excerpt: excerpt,
                contentHtml: contentHtml,
                readingMinutes: readingMinutes,
                publishedAt: publishedAt,
                fetchedAt: fetchedAt,
                isRead: isRead,
                pickDate: pickDate,
                pickRank: pickRank,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                required String sourceName,
                required String title,
                required String url,
                Value<String> excerpt = const Value.absent(),
                Value<String?> contentHtml = const Value.absent(),
                Value<int> readingMinutes = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                required DateTime fetchedAt,
                Value<bool> isRead = const Value.absent(),
                Value<String?> pickDate = const Value.absent(),
                Value<int?> pickRank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderArticlesCompanion.insert(
                id: id,
                sourceId: sourceId,
                sourceName: sourceName,
                title: title,
                url: url,
                excerpt: excerpt,
                contentHtml: contentHtml,
                readingMinutes: readingMinutes,
                publishedAt: publishedAt,
                fetchedAt: fetchedAt,
                isRead: isRead,
                pickDate: pickDate,
                pickRank: pickRank,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReaderArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderArticlesTable,
      ReaderArticleRow,
      $$ReaderArticlesTableFilterComposer,
      $$ReaderArticlesTableOrderingComposer,
      $$ReaderArticlesTableAnnotationComposer,
      $$ReaderArticlesTableCreateCompanionBuilder,
      $$ReaderArticlesTableUpdateCompanionBuilder,
      (
        ReaderArticleRow,
        BaseReferences<_$AppDatabase, $ReaderArticlesTable, ReaderArticleRow>,
      ),
      ReaderArticleRow,
      PrefetchHooks Function()
    >;
typedef $$ReaderBookmarksTableCreateCompanionBuilder =
    ReaderBookmarksCompanion Function({
      required String articleId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ReaderBookmarksTableUpdateCompanionBuilder =
    ReaderBookmarksCompanion Function({
      Value<String> articleId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ReaderBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderBookmarksTable> {
  $$ReaderBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get articleId => $composableBuilder(
    column: $table.articleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReaderBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderBookmarksTable> {
  $$ReaderBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get articleId => $composableBuilder(
    column: $table.articleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReaderBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderBookmarksTable> {
  $$ReaderBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get articleId =>
      $composableBuilder(column: $table.articleId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReaderBookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderBookmarksTable,
          ReaderBookmarkRow,
          $$ReaderBookmarksTableFilterComposer,
          $$ReaderBookmarksTableOrderingComposer,
          $$ReaderBookmarksTableAnnotationComposer,
          $$ReaderBookmarksTableCreateCompanionBuilder,
          $$ReaderBookmarksTableUpdateCompanionBuilder,
          (
            ReaderBookmarkRow,
            BaseReferences<
              _$AppDatabase,
              $ReaderBookmarksTable,
              ReaderBookmarkRow
            >,
          ),
          ReaderBookmarkRow,
          PrefetchHooks Function()
        > {
  $$ReaderBookmarksTableTableManager(
    _$AppDatabase db,
    $ReaderBookmarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReaderBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> articleId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderBookmarksCompanion(
                articleId: articleId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String articleId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderBookmarksCompanion.insert(
                articleId: articleId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReaderBookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderBookmarksTable,
      ReaderBookmarkRow,
      $$ReaderBookmarksTableFilterComposer,
      $$ReaderBookmarksTableOrderingComposer,
      $$ReaderBookmarksTableAnnotationComposer,
      $$ReaderBookmarksTableCreateCompanionBuilder,
      $$ReaderBookmarksTableUpdateCompanionBuilder,
      (
        ReaderBookmarkRow,
        BaseReferences<_$AppDatabase, $ReaderBookmarksTable, ReaderBookmarkRow>,
      ),
      ReaderBookmarkRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      required String date,
      required String articleId,
      required int seconds,
      Value<int> rowid,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<String> date,
      Value<String> articleId,
      Value<int> seconds,
      Value<int> rowid,
    });

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get articleId => $composableBuilder(
    column: $table.articleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get articleId => $composableBuilder(
    column: $table.articleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get articleId =>
      $composableBuilder(column: $table.articleId, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingSessionsTable,
          ReadingSessionRow,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (
            ReadingSessionRow,
            BaseReferences<
              _$AppDatabase,
              $ReadingSessionsTable,
              ReadingSessionRow
            >,
          ),
          ReadingSessionRow,
          PrefetchHooks Function()
        > {
  $$ReadingSessionsTableTableManager(
    _$AppDatabase db,
    $ReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> articleId = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingSessionsCompanion(
                date: date,
                articleId: articleId,
                seconds: seconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String articleId,
                required int seconds,
                Value<int> rowid = const Value.absent(),
              }) => ReadingSessionsCompanion.insert(
                date: date,
                articleId: articleId,
                seconds: seconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingSessionsTable,
      ReadingSessionRow,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (
        ReadingSessionRow,
        BaseReferences<_$AppDatabase, $ReadingSessionsTable, ReadingSessionRow>,
      ),
      ReadingSessionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MonitoredAppsTableTableManager get monitoredApps =>
      $$MonitoredAppsTableTableManager(_db, _db.monitoredApps);
  $$DailyUsagesTableTableManager get dailyUsages =>
      $$DailyUsagesTableTableManager(_db, _db.dailyUsages);
  $$DailySummariesTableTableManager get dailySummaries =>
      $$DailySummariesTableTableManager(_db, _db.dailySummaries);
  $$ReaderSourcesTableTableManager get readerSources =>
      $$ReaderSourcesTableTableManager(_db, _db.readerSources);
  $$ReaderArticlesTableTableManager get readerArticles =>
      $$ReaderArticlesTableTableManager(_db, _db.readerArticles);
  $$ReaderBookmarksTableTableManager get readerBookmarks =>
      $$ReaderBookmarksTableTableManager(_db, _db.readerBookmarks);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
}
