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
  @override
  List<GeneratedColumn> get $columns => [date, packageName, totalSeconds];
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
  const DailyUsageRow({
    required this.date,
    required this.packageName,
    required this.totalSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['package_name'] = Variable<String>(packageName);
    map['total_seconds'] = Variable<int>(totalSeconds);
    return map;
  }

  DailyUsagesCompanion toCompanion(bool nullToAbsent) {
    return DailyUsagesCompanion(
      date: Value(date),
      packageName: Value(packageName),
      totalSeconds: Value(totalSeconds),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'packageName': serializer.toJson<String>(packageName),
      'totalSeconds': serializer.toJson<int>(totalSeconds),
    };
  }

  DailyUsageRow copyWith({
    String? date,
    String? packageName,
    int? totalSeconds,
  }) => DailyUsageRow(
    date: date ?? this.date,
    packageName: packageName ?? this.packageName,
    totalSeconds: totalSeconds ?? this.totalSeconds,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyUsageRow(')
          ..write('date: $date, ')
          ..write('packageName: $packageName, ')
          ..write('totalSeconds: $totalSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, packageName, totalSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyUsageRow &&
          other.date == this.date &&
          other.packageName == this.packageName &&
          other.totalSeconds == this.totalSeconds);
}

class DailyUsagesCompanion extends UpdateCompanion<DailyUsageRow> {
  final Value<String> date;
  final Value<String> packageName;
  final Value<int> totalSeconds;
  final Value<int> rowid;
  const DailyUsagesCompanion({
    this.date = const Value.absent(),
    this.packageName = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyUsagesCompanion.insert({
    required String date,
    required String packageName,
    required int totalSeconds,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       packageName = Value(packageName),
       totalSeconds = Value(totalSeconds);
  static Insertable<DailyUsageRow> custom({
    Expression<String>? date,
    Expression<String>? packageName,
    Expression<int>? totalSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (packageName != null) 'package_name': packageName,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyUsagesCompanion copyWith({
    Value<String>? date,
    Value<String>? packageName,
    Value<int>? totalSeconds,
    Value<int>? rowid,
  }) {
    return DailyUsagesCompanion(
      date: date ?? this.date,
      packageName: packageName ?? this.packageName,
      totalSeconds: totalSeconds ?? this.totalSeconds,
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
  @override
  List<GeneratedColumn> get $columns => [
    date,
    totalSeconds,
    limitSeconds,
    limitHitAt,
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
  const DailySummaryRow({
    required this.date,
    required this.totalSeconds,
    required this.limitSeconds,
    this.limitHitAt,
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
    };
  }

  DailySummaryRow copyWith({
    String? date,
    int? totalSeconds,
    int? limitSeconds,
    Value<DateTime?> limitHitAt = const Value.absent(),
  }) => DailySummaryRow(
    date: date ?? this.date,
    totalSeconds: totalSeconds ?? this.totalSeconds,
    limitSeconds: limitSeconds ?? this.limitSeconds,
    limitHitAt: limitHitAt.present ? limitHitAt.value : this.limitHitAt,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailySummaryRow(')
          ..write('date: $date, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('limitSeconds: $limitSeconds, ')
          ..write('limitHitAt: $limitHitAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, totalSeconds, limitSeconds, limitHitAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailySummaryRow &&
          other.date == this.date &&
          other.totalSeconds == this.totalSeconds &&
          other.limitSeconds == this.limitSeconds &&
          other.limitHitAt == this.limitHitAt);
}

class DailySummariesCompanion extends UpdateCompanion<DailySummaryRow> {
  final Value<String> date;
  final Value<int> totalSeconds;
  final Value<int> limitSeconds;
  final Value<DateTime?> limitHitAt;
  final Value<int> rowid;
  const DailySummariesCompanion({
    this.date = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.limitSeconds = const Value.absent(),
    this.limitHitAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailySummariesCompanion.insert({
    required String date,
    required int totalSeconds,
    required int limitSeconds,
    this.limitHitAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       totalSeconds = Value(totalSeconds),
       limitSeconds = Value(limitSeconds);
  static Insertable<DailySummaryRow> custom({
    Expression<String>? date,
    Expression<int>? totalSeconds,
    Expression<int>? limitSeconds,
    Expression<DateTime>? limitHitAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (limitSeconds != null) 'limit_seconds': limitSeconds,
      if (limitHitAt != null) 'limit_hit_at': limitHitAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailySummariesCompanion copyWith({
    Value<String>? date,
    Value<int>? totalSeconds,
    Value<int>? limitSeconds,
    Value<DateTime?>? limitHitAt,
    Value<int>? rowid,
  }) {
    return DailySummariesCompanion(
      date: date ?? this.date,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      limitSeconds: limitSeconds ?? this.limitSeconds,
      limitHitAt: limitHitAt ?? this.limitHitAt,
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    monitoredApps,
    dailyUsages,
    dailySummaries,
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
      Value<int> rowid,
    });
typedef $$DailyUsagesTableUpdateCompanionBuilder =
    DailyUsagesCompanion Function({
      Value<String> date,
      Value<String> packageName,
      Value<int> totalSeconds,
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
                Value<int> rowid = const Value.absent(),
              }) => DailyUsagesCompanion(
                date: date,
                packageName: packageName,
                totalSeconds: totalSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String packageName,
                required int totalSeconds,
                Value<int> rowid = const Value.absent(),
              }) => DailyUsagesCompanion.insert(
                date: date,
                packageName: packageName,
                totalSeconds: totalSeconds,
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
      Value<int> rowid,
    });
typedef $$DailySummariesTableUpdateCompanionBuilder =
    DailySummariesCompanion Function({
      Value<String> date,
      Value<int> totalSeconds,
      Value<int> limitSeconds,
      Value<DateTime?> limitHitAt,
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
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesCompanion(
                date: date,
                totalSeconds: totalSeconds,
                limitSeconds: limitSeconds,
                limitHitAt: limitHitAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required int totalSeconds,
                required int limitSeconds,
                Value<DateTime?> limitHitAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesCompanion.insert(
                date: date,
                totalSeconds: totalSeconds,
                limitSeconds: limitSeconds,
                limitHitAt: limitHitAt,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MonitoredAppsTableTableManager get monitoredApps =>
      $$MonitoredAppsTableTableManager(_db, _db.monitoredApps);
  $$DailyUsagesTableTableManager get dailyUsages =>
      $$DailyUsagesTableTableManager(_db, _db.dailyUsages);
  $$DailySummariesTableTableManager get dailySummaries =>
      $$DailySummariesTableTableManager(_db, _db.dailySummaries);
}
