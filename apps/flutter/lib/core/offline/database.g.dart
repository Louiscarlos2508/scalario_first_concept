// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TenantConfigsTable extends TenantConfigs
    with TableInfo<$TenantConfigsTable, TenantConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TenantConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheLimitMbMeta = const VerificationMeta(
    'cacheLimitMb',
  );
  @override
  late final GeneratedColumn<int> cacheLimitMb = GeneratedColumn<int>(
    'cache_limit_mb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(500),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1'),
  );
  static const VerificationMeta _lastFetchAtMeta = const VerificationMeta(
    'lastFetchAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchAt = GeneratedColumn<DateTime>(
    'last_fetch_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    tenantId,
    slug,
    configJson,
    cacheLimitMb,
    version,
    lastFetchAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tenant_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TenantConfig> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('cache_limit_mb')) {
      context.handle(
        _cacheLimitMbMeta,
        cacheLimitMb.isAcceptableOrUnknown(
          data['cache_limit_mb']!,
          _cacheLimitMbMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('last_fetch_at')) {
      context.handle(
        _lastFetchAtMeta,
        lastFetchAt.isAcceptableOrUnknown(
          data['last_fetch_at']!,
          _lastFetchAtMeta,
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
  Set<GeneratedColumn> get $primaryKey => {tenantId};
  @override
  TenantConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TenantConfig(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      cacheLimitMb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_limit_mb'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      lastFetchAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetch_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TenantConfigsTable createAlias(String alias) {
    return $TenantConfigsTable(attachedDatabase, alias);
  }
}

class TenantConfig extends DataClass implements Insertable<TenantConfig> {
  final String tenantId;
  final String slug;
  final String configJson;
  final int cacheLimitMb;
  final String version;
  final DateTime? lastFetchAt;
  final DateTime updatedAt;
  const TenantConfig({
    required this.tenantId,
    required this.slug,
    required this.configJson,
    required this.cacheLimitMb,
    required this.version,
    this.lastFetchAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['slug'] = Variable<String>(slug);
    map['config_json'] = Variable<String>(configJson);
    map['cache_limit_mb'] = Variable<int>(cacheLimitMb);
    map['version'] = Variable<String>(version);
    if (!nullToAbsent || lastFetchAt != null) {
      map['last_fetch_at'] = Variable<DateTime>(lastFetchAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TenantConfigsCompanion toCompanion(bool nullToAbsent) {
    return TenantConfigsCompanion(
      tenantId: Value(tenantId),
      slug: Value(slug),
      configJson: Value(configJson),
      cacheLimitMb: Value(cacheLimitMb),
      version: Value(version),
      lastFetchAt: lastFetchAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TenantConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TenantConfig(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      slug: serializer.fromJson<String>(json['slug']),
      configJson: serializer.fromJson<String>(json['configJson']),
      cacheLimitMb: serializer.fromJson<int>(json['cacheLimitMb']),
      version: serializer.fromJson<String>(json['version']),
      lastFetchAt: serializer.fromJson<DateTime?>(json['lastFetchAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'slug': serializer.toJson<String>(slug),
      'configJson': serializer.toJson<String>(configJson),
      'cacheLimitMb': serializer.toJson<int>(cacheLimitMb),
      'version': serializer.toJson<String>(version),
      'lastFetchAt': serializer.toJson<DateTime?>(lastFetchAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TenantConfig copyWith({
    String? tenantId,
    String? slug,
    String? configJson,
    int? cacheLimitMb,
    String? version,
    Value<DateTime?> lastFetchAt = const Value.absent(),
    DateTime? updatedAt,
  }) => TenantConfig(
    tenantId: tenantId ?? this.tenantId,
    slug: slug ?? this.slug,
    configJson: configJson ?? this.configJson,
    cacheLimitMb: cacheLimitMb ?? this.cacheLimitMb,
    version: version ?? this.version,
    lastFetchAt: lastFetchAt.present ? lastFetchAt.value : this.lastFetchAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TenantConfig copyWithCompanion(TenantConfigsCompanion data) {
    return TenantConfig(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      slug: data.slug.present ? data.slug.value : this.slug,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      cacheLimitMb: data.cacheLimitMb.present
          ? data.cacheLimitMb.value
          : this.cacheLimitMb,
      version: data.version.present ? data.version.value : this.version,
      lastFetchAt: data.lastFetchAt.present
          ? data.lastFetchAt.value
          : this.lastFetchAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TenantConfig(')
          ..write('tenantId: $tenantId, ')
          ..write('slug: $slug, ')
          ..write('configJson: $configJson, ')
          ..write('cacheLimitMb: $cacheLimitMb, ')
          ..write('version: $version, ')
          ..write('lastFetchAt: $lastFetchAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    slug,
    configJson,
    cacheLimitMb,
    version,
    lastFetchAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TenantConfig &&
          other.tenantId == this.tenantId &&
          other.slug == this.slug &&
          other.configJson == this.configJson &&
          other.cacheLimitMb == this.cacheLimitMb &&
          other.version == this.version &&
          other.lastFetchAt == this.lastFetchAt &&
          other.updatedAt == this.updatedAt);
}

class TenantConfigsCompanion extends UpdateCompanion<TenantConfig> {
  final Value<String> tenantId;
  final Value<String> slug;
  final Value<String> configJson;
  final Value<int> cacheLimitMb;
  final Value<String> version;
  final Value<DateTime?> lastFetchAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TenantConfigsCompanion({
    this.tenantId = const Value.absent(),
    this.slug = const Value.absent(),
    this.configJson = const Value.absent(),
    this.cacheLimitMb = const Value.absent(),
    this.version = const Value.absent(),
    this.lastFetchAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TenantConfigsCompanion.insert({
    required String tenantId,
    required String slug,
    required String configJson,
    this.cacheLimitMb = const Value.absent(),
    this.version = const Value.absent(),
    this.lastFetchAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       slug = Value(slug),
       configJson = Value(configJson);
  static Insertable<TenantConfig> custom({
    Expression<String>? tenantId,
    Expression<String>? slug,
    Expression<String>? configJson,
    Expression<int>? cacheLimitMb,
    Expression<String>? version,
    Expression<DateTime>? lastFetchAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (slug != null) 'slug': slug,
      if (configJson != null) 'config_json': configJson,
      if (cacheLimitMb != null) 'cache_limit_mb': cacheLimitMb,
      if (version != null) 'version': version,
      if (lastFetchAt != null) 'last_fetch_at': lastFetchAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TenantConfigsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? slug,
    Value<String>? configJson,
    Value<int>? cacheLimitMb,
    Value<String>? version,
    Value<DateTime?>? lastFetchAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TenantConfigsCompanion(
      tenantId: tenantId ?? this.tenantId,
      slug: slug ?? this.slug,
      configJson: configJson ?? this.configJson,
      cacheLimitMb: cacheLimitMb ?? this.cacheLimitMb,
      version: version ?? this.version,
      lastFetchAt: lastFetchAt ?? this.lastFetchAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (cacheLimitMb.present) {
      map['cache_limit_mb'] = Variable<int>(cacheLimitMb.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (lastFetchAt.present) {
      map['last_fetch_at'] = Variable<DateTime>(lastFetchAt.value);
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
    return (StringBuffer('TenantConfigsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('slug: $slug, ')
          ..write('configJson: $configJson, ')
          ..write('cacheLimitMb: $cacheLimitMb, ')
          ..write('version: $version, ')
          ..write('lastFetchAt: $lastFetchAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedLayoutsTable extends CachedLayouts
    with TableInfo<$CachedLayoutsTable, CachedLayout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLayoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _screenIdMeta = const VerificationMeta(
    'screenId',
  );
  @override
  late final GeneratedColumn<String> screenId = GeneratedColumn<String>(
    'screen_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _layoutJsonMeta = const VerificationMeta(
    'layoutJson',
  );
  @override
  late final GeneratedColumn<String> layoutJson = GeneratedColumn<String>(
    'layout_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lastFetchAtMeta = const VerificationMeta(
    'lastFetchAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchAt = GeneratedColumn<DateTime>(
    'last_fetch_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _bytesSizeMeta = const VerificationMeta(
    'bytesSize',
  );
  @override
  late final GeneratedColumn<int> bytesSize = GeneratedColumn<int>(
    'bytes_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    screenId,
    tenantId,
    layoutJson,
    etag,
    lastFetchAt,
    bytesSize,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_layouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLayout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('screen_id')) {
      context.handle(
        _screenIdMeta,
        screenId.isAcceptableOrUnknown(data['screen_id']!, _screenIdMeta),
      );
    } else if (isInserting) {
      context.missing(_screenIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('layout_json')) {
      context.handle(
        _layoutJsonMeta,
        layoutJson.isAcceptableOrUnknown(data['layout_json']!, _layoutJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutJsonMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_fetch_at')) {
      context.handle(
        _lastFetchAtMeta,
        lastFetchAt.isAcceptableOrUnknown(
          data['last_fetch_at']!,
          _lastFetchAtMeta,
        ),
      );
    }
    if (data.containsKey('bytes_size')) {
      context.handle(
        _bytesSizeMeta,
        bytesSize.isAcceptableOrUnknown(data['bytes_size']!, _bytesSizeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {screenId};
  @override
  CachedLayout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLayout(
      screenId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screen_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      layoutJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout_json'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastFetchAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetch_at'],
      )!,
      bytesSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_size'],
      )!,
    );
  }

  @override
  $CachedLayoutsTable createAlias(String alias) {
    return $CachedLayoutsTable(attachedDatabase, alias);
  }
}

class CachedLayout extends DataClass implements Insertable<CachedLayout> {
  final String screenId;
  final String tenantId;
  final String layoutJson;
  final String? etag;
  final DateTime lastFetchAt;
  final int bytesSize;
  const CachedLayout({
    required this.screenId,
    required this.tenantId,
    required this.layoutJson,
    this.etag,
    required this.lastFetchAt,
    required this.bytesSize,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['screen_id'] = Variable<String>(screenId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['layout_json'] = Variable<String>(layoutJson);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['last_fetch_at'] = Variable<DateTime>(lastFetchAt);
    map['bytes_size'] = Variable<int>(bytesSize);
    return map;
  }

  CachedLayoutsCompanion toCompanion(bool nullToAbsent) {
    return CachedLayoutsCompanion(
      screenId: Value(screenId),
      tenantId: Value(tenantId),
      layoutJson: Value(layoutJson),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastFetchAt: Value(lastFetchAt),
      bytesSize: Value(bytesSize),
    );
  }

  factory CachedLayout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLayout(
      screenId: serializer.fromJson<String>(json['screenId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      layoutJson: serializer.fromJson<String>(json['layoutJson']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastFetchAt: serializer.fromJson<DateTime>(json['lastFetchAt']),
      bytesSize: serializer.fromJson<int>(json['bytesSize']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'screenId': serializer.toJson<String>(screenId),
      'tenantId': serializer.toJson<String>(tenantId),
      'layoutJson': serializer.toJson<String>(layoutJson),
      'etag': serializer.toJson<String?>(etag),
      'lastFetchAt': serializer.toJson<DateTime>(lastFetchAt),
      'bytesSize': serializer.toJson<int>(bytesSize),
    };
  }

  CachedLayout copyWith({
    String? screenId,
    String? tenantId,
    String? layoutJson,
    Value<String?> etag = const Value.absent(),
    DateTime? lastFetchAt,
    int? bytesSize,
  }) => CachedLayout(
    screenId: screenId ?? this.screenId,
    tenantId: tenantId ?? this.tenantId,
    layoutJson: layoutJson ?? this.layoutJson,
    etag: etag.present ? etag.value : this.etag,
    lastFetchAt: lastFetchAt ?? this.lastFetchAt,
    bytesSize: bytesSize ?? this.bytesSize,
  );
  CachedLayout copyWithCompanion(CachedLayoutsCompanion data) {
    return CachedLayout(
      screenId: data.screenId.present ? data.screenId.value : this.screenId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      layoutJson: data.layoutJson.present
          ? data.layoutJson.value
          : this.layoutJson,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastFetchAt: data.lastFetchAt.present
          ? data.lastFetchAt.value
          : this.lastFetchAt,
      bytesSize: data.bytesSize.present ? data.bytesSize.value : this.bytesSize,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLayout(')
          ..write('screenId: $screenId, ')
          ..write('tenantId: $tenantId, ')
          ..write('layoutJson: $layoutJson, ')
          ..write('etag: $etag, ')
          ..write('lastFetchAt: $lastFetchAt, ')
          ..write('bytesSize: $bytesSize')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(screenId, tenantId, layoutJson, etag, lastFetchAt, bytesSize);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLayout &&
          other.screenId == this.screenId &&
          other.tenantId == this.tenantId &&
          other.layoutJson == this.layoutJson &&
          other.etag == this.etag &&
          other.lastFetchAt == this.lastFetchAt &&
          other.bytesSize == this.bytesSize);
}

class CachedLayoutsCompanion extends UpdateCompanion<CachedLayout> {
  final Value<String> screenId;
  final Value<String> tenantId;
  final Value<String> layoutJson;
  final Value<String?> etag;
  final Value<DateTime> lastFetchAt;
  final Value<int> bytesSize;
  final Value<int> rowid;
  const CachedLayoutsCompanion({
    this.screenId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.layoutJson = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastFetchAt = const Value.absent(),
    this.bytesSize = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLayoutsCompanion.insert({
    required String screenId,
    required String tenantId,
    required String layoutJson,
    this.etag = const Value.absent(),
    this.lastFetchAt = const Value.absent(),
    this.bytesSize = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : screenId = Value(screenId),
       tenantId = Value(tenantId),
       layoutJson = Value(layoutJson);
  static Insertable<CachedLayout> custom({
    Expression<String>? screenId,
    Expression<String>? tenantId,
    Expression<String>? layoutJson,
    Expression<String>? etag,
    Expression<DateTime>? lastFetchAt,
    Expression<int>? bytesSize,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (screenId != null) 'screen_id': screenId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (layoutJson != null) 'layout_json': layoutJson,
      if (etag != null) 'etag': etag,
      if (lastFetchAt != null) 'last_fetch_at': lastFetchAt,
      if (bytesSize != null) 'bytes_size': bytesSize,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLayoutsCompanion copyWith({
    Value<String>? screenId,
    Value<String>? tenantId,
    Value<String>? layoutJson,
    Value<String?>? etag,
    Value<DateTime>? lastFetchAt,
    Value<int>? bytesSize,
    Value<int>? rowid,
  }) {
    return CachedLayoutsCompanion(
      screenId: screenId ?? this.screenId,
      tenantId: tenantId ?? this.tenantId,
      layoutJson: layoutJson ?? this.layoutJson,
      etag: etag ?? this.etag,
      lastFetchAt: lastFetchAt ?? this.lastFetchAt,
      bytesSize: bytesSize ?? this.bytesSize,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (screenId.present) {
      map['screen_id'] = Variable<String>(screenId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (layoutJson.present) {
      map['layout_json'] = Variable<String>(layoutJson.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastFetchAt.present) {
      map['last_fetch_at'] = Variable<DateTime>(lastFetchAt.value);
    }
    if (bytesSize.present) {
      map['bytes_size'] = Variable<int>(bytesSize.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLayoutsCompanion(')
          ..write('screenId: $screenId, ')
          ..write('tenantId: $tenantId, ')
          ..write('layoutJson: $layoutJson, ')
          ..write('etag: $etag, ')
          ..write('lastFetchAt: $lastFetchAt, ')
          ..write('bytesSize: $bytesSize, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDataTable extends LocalData
    with TableInfo<$LocalDataTable, LocalDataRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleIdMeta = const VerificationMeta(
    'moduleId',
  );
  @override
  late final GeneratedColumn<String> moduleId = GeneratedColumn<String>(
    'module_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUpdatedAtMeta = const VerificationMeta(
    'baseUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> baseUpdatedAt =
      GeneratedColumn<DateTime>(
        'base_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    moduleId,
    entityType,
    dataJson,
    baseUpdatedAt,
    localUpdatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDataRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('module_id')) {
      context.handle(
        _moduleIdMeta,
        moduleId.isAcceptableOrUnknown(data['module_id']!, _moduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('base_updated_at')) {
      context.handle(
        _baseUpdatedAtMeta,
        baseUpdatedAt.isAcceptableOrUnknown(
          data['base_updated_at']!,
          _baseUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDataRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDataRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      moduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      baseUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}base_updated_at'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $LocalDataTable createAlias(String alias) {
    return $LocalDataTable(attachedDatabase, alias);
  }
}

class LocalDataRecord extends DataClass implements Insertable<LocalDataRecord> {
  final String id;
  final String tenantId;
  final String moduleId;
  final String entityType;
  final String dataJson;
  final DateTime? baseUpdatedAt;
  final DateTime localUpdatedAt;
  final String syncStatus;
  const LocalDataRecord({
    required this.id,
    required this.tenantId,
    required this.moduleId,
    required this.entityType,
    required this.dataJson,
    this.baseUpdatedAt,
    required this.localUpdatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['module_id'] = Variable<String>(moduleId);
    map['entity_type'] = Variable<String>(entityType);
    map['data_json'] = Variable<String>(dataJson);
    if (!nullToAbsent || baseUpdatedAt != null) {
      map['base_updated_at'] = Variable<DateTime>(baseUpdatedAt);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalDataCompanion toCompanion(bool nullToAbsent) {
    return LocalDataCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      moduleId: Value(moduleId),
      entityType: Value(entityType),
      dataJson: Value(dataJson),
      baseUpdatedAt: baseUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUpdatedAt),
      localUpdatedAt: Value(localUpdatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalDataRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDataRecord(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      moduleId: serializer.fromJson<String>(json['moduleId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      baseUpdatedAt: serializer.fromJson<DateTime?>(json['baseUpdatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'moduleId': serializer.toJson<String>(moduleId),
      'entityType': serializer.toJson<String>(entityType),
      'dataJson': serializer.toJson<String>(dataJson),
      'baseUpdatedAt': serializer.toJson<DateTime?>(baseUpdatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalDataRecord copyWith({
    String? id,
    String? tenantId,
    String? moduleId,
    String? entityType,
    String? dataJson,
    Value<DateTime?> baseUpdatedAt = const Value.absent(),
    DateTime? localUpdatedAt,
    String? syncStatus,
  }) => LocalDataRecord(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    moduleId: moduleId ?? this.moduleId,
    entityType: entityType ?? this.entityType,
    dataJson: dataJson ?? this.dataJson,
    baseUpdatedAt: baseUpdatedAt.present
        ? baseUpdatedAt.value
        : this.baseUpdatedAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  LocalDataRecord copyWithCompanion(LocalDataCompanion data) {
    return LocalDataRecord(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      moduleId: data.moduleId.present ? data.moduleId.value : this.moduleId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      baseUpdatedAt: data.baseUpdatedAt.present
          ? data.baseUpdatedAt.value
          : this.baseUpdatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDataRecord(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('moduleId: $moduleId, ')
          ..write('entityType: $entityType, ')
          ..write('dataJson: $dataJson, ')
          ..write('baseUpdatedAt: $baseUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    moduleId,
    entityType,
    dataJson,
    baseUpdatedAt,
    localUpdatedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDataRecord &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.moduleId == this.moduleId &&
          other.entityType == this.entityType &&
          other.dataJson == this.dataJson &&
          other.baseUpdatedAt == this.baseUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.syncStatus == this.syncStatus);
}

class LocalDataCompanion extends UpdateCompanion<LocalDataRecord> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> moduleId;
  final Value<String> entityType;
  final Value<String> dataJson;
  final Value<DateTime?> baseUpdatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalDataCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.moduleId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.baseUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDataCompanion.insert({
    required String id,
    required String tenantId,
    required String moduleId,
    required String entityType,
    required String dataJson,
    this.baseUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       moduleId = Value(moduleId),
       entityType = Value(entityType),
       dataJson = Value(dataJson);
  static Insertable<LocalDataRecord> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? moduleId,
    Expression<String>? entityType,
    Expression<String>? dataJson,
    Expression<DateTime>? baseUpdatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (moduleId != null) 'module_id': moduleId,
      if (entityType != null) 'entity_type': entityType,
      if (dataJson != null) 'data_json': dataJson,
      if (baseUpdatedAt != null) 'base_updated_at': baseUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDataCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? moduleId,
    Value<String>? entityType,
    Value<String>? dataJson,
    Value<DateTime?>? baseUpdatedAt,
    Value<DateTime>? localUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return LocalDataCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      moduleId: moduleId ?? this.moduleId,
      entityType: entityType ?? this.entityType,
      dataJson: dataJson ?? this.dataJson,
      baseUpdatedAt: baseUpdatedAt ?? this.baseUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (moduleId.present) {
      map['module_id'] = Variable<String>(moduleId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (baseUpdatedAt.present) {
      map['base_updated_at'] = Variable<DateTime>(baseUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDataCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('moduleId: $moduleId, ')
          ..write('entityType: $entityType, ')
          ..write('dataJson: $dataJson, ')
          ..write('baseUpdatedAt: $baseUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleIdMeta = const VerificationMeta(
    'moduleId',
  );
  @override
  late final GeneratedColumn<String> moduleId = GeneratedColumn<String>(
    'module_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
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
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mutationId,
    tenantId,
    moduleId,
    action,
    payloadJson,
    idempotencyKey,
    createdAt,
    retryCount,
    status,
    lastError,
    nextRetryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('module_id')) {
      context.handle(
        _moduleIdMeta,
        moduleId.isAcceptableOrUnknown(data['module_id']!, _moduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mutationId};
  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      moduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final String mutationId;
  final String tenantId;
  final String moduleId;
  final String action;
  final String payloadJson;
  final String idempotencyKey;
  final DateTime createdAt;
  final int retryCount;
  final String status;
  final String? lastError;
  final DateTime? nextRetryAt;
  const SyncQueueItem({
    required this.mutationId,
    required this.tenantId,
    required this.moduleId,
    required this.action,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    this.lastError,
    this.nextRetryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mutation_id'] = Variable<String>(mutationId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['module_id'] = Variable<String>(moduleId);
    map['action'] = Variable<String>(action);
    map['payload_json'] = Variable<String>(payloadJson);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      mutationId: Value(mutationId),
      tenantId: Value(tenantId),
      moduleId: Value(moduleId),
      action: Value(action),
      payloadJson: Value(payloadJson),
      idempotencyKey: Value(idempotencyKey),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
    );
  }

  factory SyncQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItem(
      mutationId: serializer.fromJson<String>(json['mutationId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      moduleId: serializer.fromJson<String>(json['moduleId']),
      action: serializer.fromJson<String>(json['action']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mutationId': serializer.toJson<String>(mutationId),
      'tenantId': serializer.toJson<String>(tenantId),
      'moduleId': serializer.toJson<String>(moduleId),
      'action': serializer.toJson<String>(action),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
    };
  }

  SyncQueueItem copyWith({
    String? mutationId,
    String? tenantId,
    String? moduleId,
    String? action,
    String? payloadJson,
    String? idempotencyKey,
    DateTime? createdAt,
    int? retryCount,
    String? status,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextRetryAt = const Value.absent(),
  }) => SyncQueueItem(
    mutationId: mutationId ?? this.mutationId,
    tenantId: tenantId ?? this.tenantId,
    moduleId: moduleId ?? this.moduleId,
    action: action ?? this.action,
    payloadJson: payloadJson ?? this.payloadJson,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
  );
  SyncQueueItem copyWithCompanion(SyncQueueItemsCompanion data) {
    return SyncQueueItem(
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      moduleId: data.moduleId.present ? data.moduleId.value : this.moduleId,
      action: data.action.present ? data.action.value : this.action,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItem(')
          ..write('mutationId: $mutationId, ')
          ..write('tenantId: $tenantId, ')
          ..write('moduleId: $moduleId, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mutationId,
    tenantId,
    moduleId,
    action,
    payloadJson,
    idempotencyKey,
    createdAt,
    retryCount,
    status,
    lastError,
    nextRetryAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItem &&
          other.mutationId == this.mutationId &&
          other.tenantId == this.tenantId &&
          other.moduleId == this.moduleId &&
          other.action == this.action &&
          other.payloadJson == this.payloadJson &&
          other.idempotencyKey == this.idempotencyKey &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.lastError == this.lastError &&
          other.nextRetryAt == this.nextRetryAt);
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<String> mutationId;
  final Value<String> tenantId;
  final Value<String> moduleId;
  final Value<String> action;
  final Value<String> payloadJson;
  final Value<String> idempotencyKey;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<DateTime?> nextRetryAt;
  final Value<int> rowid;
  const SyncQueueItemsCompanion({
    this.mutationId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.moduleId = const Value.absent(),
    this.action = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueItemsCompanion.insert({
    required String mutationId,
    required String tenantId,
    required String moduleId,
    required String action,
    required String payloadJson,
    required String idempotencyKey,
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mutationId = Value(mutationId),
       tenantId = Value(tenantId),
       moduleId = Value(moduleId),
       action = Value(action),
       payloadJson = Value(payloadJson),
       idempotencyKey = Value(idempotencyKey);
  static Insertable<SyncQueueItem> custom({
    Expression<String>? mutationId,
    Expression<String>? tenantId,
    Expression<String>? moduleId,
    Expression<String>? action,
    Expression<String>? payloadJson,
    Expression<String>? idempotencyKey,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<DateTime>? nextRetryAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mutationId != null) 'mutation_id': mutationId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (moduleId != null) 'module_id': moduleId,
      if (action != null) 'action': action,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueItemsCompanion copyWith({
    Value<String>? mutationId,
    Value<String>? tenantId,
    Value<String>? moduleId,
    Value<String>? action,
    Value<String>? payloadJson,
    Value<String>? idempotencyKey,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String>? status,
    Value<String?>? lastError,
    Value<DateTime?>? nextRetryAt,
    Value<int>? rowid,
  }) {
    return SyncQueueItemsCompanion(
      mutationId: mutationId ?? this.mutationId,
      tenantId: tenantId ?? this.tenantId,
      moduleId: moduleId ?? this.moduleId,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (moduleId.present) {
      map['module_id'] = Variable<String>(moduleId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsCompanion(')
          ..write('mutationId: $mutationId, ')
          ..write('tenantId: $tenantId, ')
          ..write('moduleId: $moduleId, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConflictsTable extends Conflicts
    with TableInfo<$ConflictsTable, ConflictRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localStateJsonMeta = const VerificationMeta(
    'localStateJson',
  );
  @override
  late final GeneratedColumn<String> localStateJson = GeneratedColumn<String>(
    'local_state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverStateJsonMeta = const VerificationMeta(
    'serverStateJson',
  );
  @override
  late final GeneratedColumn<String> serverStateJson = GeneratedColumn<String>(
    'server_state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mutationId,
    localStateJson,
    serverStateJson,
    detectedAt,
    resolvedAt,
    resolution,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('local_state_json')) {
      context.handle(
        _localStateJsonMeta,
        localStateJson.isAcceptableOrUnknown(
          data['local_state_json']!,
          _localStateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localStateJsonMeta);
    }
    if (data.containsKey('server_state_json')) {
      context.handle(
        _serverStateJsonMeta,
        serverStateJson.isAcceptableOrUnknown(
          data['server_state_json']!,
          _serverStateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverStateJsonMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConflictRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      localStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_state_json'],
      )!,
      serverStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_state_json'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detected_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      ),
    );
  }

  @override
  $ConflictsTable createAlias(String alias) {
    return $ConflictsTable(attachedDatabase, alias);
  }
}

class ConflictRecord extends DataClass implements Insertable<ConflictRecord> {
  final String id;
  final String mutationId;
  final String localStateJson;
  final String serverStateJson;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final String? resolution;
  const ConflictRecord({
    required this.id,
    required this.mutationId,
    required this.localStateJson,
    required this.serverStateJson,
    required this.detectedAt,
    this.resolvedAt,
    this.resolution,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mutation_id'] = Variable<String>(mutationId);
    map['local_state_json'] = Variable<String>(localStateJson);
    map['server_state_json'] = Variable<String>(serverStateJson);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    if (!nullToAbsent || resolution != null) {
      map['resolution'] = Variable<String>(resolution);
    }
    return map;
  }

  ConflictsCompanion toCompanion(bool nullToAbsent) {
    return ConflictsCompanion(
      id: Value(id),
      mutationId: Value(mutationId),
      localStateJson: Value(localStateJson),
      serverStateJson: Value(serverStateJson),
      detectedAt: Value(detectedAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      resolution: resolution == null && nullToAbsent
          ? const Value.absent()
          : Value(resolution),
    );
  }

  factory ConflictRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictRecord(
      id: serializer.fromJson<String>(json['id']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      localStateJson: serializer.fromJson<String>(json['localStateJson']),
      serverStateJson: serializer.fromJson<String>(json['serverStateJson']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      resolution: serializer.fromJson<String?>(json['resolution']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mutationId': serializer.toJson<String>(mutationId),
      'localStateJson': serializer.toJson<String>(localStateJson),
      'serverStateJson': serializer.toJson<String>(serverStateJson),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'resolution': serializer.toJson<String?>(resolution),
    };
  }

  ConflictRecord copyWith({
    String? id,
    String? mutationId,
    String? localStateJson,
    String? serverStateJson,
    DateTime? detectedAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
    Value<String?> resolution = const Value.absent(),
  }) => ConflictRecord(
    id: id ?? this.id,
    mutationId: mutationId ?? this.mutationId,
    localStateJson: localStateJson ?? this.localStateJson,
    serverStateJson: serverStateJson ?? this.serverStateJson,
    detectedAt: detectedAt ?? this.detectedAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    resolution: resolution.present ? resolution.value : this.resolution,
  );
  ConflictRecord copyWithCompanion(ConflictsCompanion data) {
    return ConflictRecord(
      id: data.id.present ? data.id.value : this.id,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      localStateJson: data.localStateJson.present
          ? data.localStateJson.value
          : this.localStateJson,
      serverStateJson: data.serverStateJson.present
          ? data.serverStateJson.value
          : this.serverStateJson,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictRecord(')
          ..write('id: $id, ')
          ..write('mutationId: $mutationId, ')
          ..write('localStateJson: $localStateJson, ')
          ..write('serverStateJson: $serverStateJson, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolution: $resolution')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mutationId,
    localStateJson,
    serverStateJson,
    detectedAt,
    resolvedAt,
    resolution,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictRecord &&
          other.id == this.id &&
          other.mutationId == this.mutationId &&
          other.localStateJson == this.localStateJson &&
          other.serverStateJson == this.serverStateJson &&
          other.detectedAt == this.detectedAt &&
          other.resolvedAt == this.resolvedAt &&
          other.resolution == this.resolution);
}

class ConflictsCompanion extends UpdateCompanion<ConflictRecord> {
  final Value<String> id;
  final Value<String> mutationId;
  final Value<String> localStateJson;
  final Value<String> serverStateJson;
  final Value<DateTime> detectedAt;
  final Value<DateTime?> resolvedAt;
  final Value<String?> resolution;
  final Value<int> rowid;
  const ConflictsCompanion({
    this.id = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.localStateJson = const Value.absent(),
    this.serverStateJson = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolution = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictsCompanion.insert({
    required String id,
    required String mutationId,
    required String localStateJson,
    required String serverStateJson,
    this.detectedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolution = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mutationId = Value(mutationId),
       localStateJson = Value(localStateJson),
       serverStateJson = Value(serverStateJson);
  static Insertable<ConflictRecord> custom({
    Expression<String>? id,
    Expression<String>? mutationId,
    Expression<String>? localStateJson,
    Expression<String>? serverStateJson,
    Expression<DateTime>? detectedAt,
    Expression<DateTime>? resolvedAt,
    Expression<String>? resolution,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mutationId != null) 'mutation_id': mutationId,
      if (localStateJson != null) 'local_state_json': localStateJson,
      if (serverStateJson != null) 'server_state_json': serverStateJson,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (resolution != null) 'resolution': resolution,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictsCompanion copyWith({
    Value<String>? id,
    Value<String>? mutationId,
    Value<String>? localStateJson,
    Value<String>? serverStateJson,
    Value<DateTime>? detectedAt,
    Value<DateTime?>? resolvedAt,
    Value<String?>? resolution,
    Value<int>? rowid,
  }) {
    return ConflictsCompanion(
      id: id ?? this.id,
      mutationId: mutationId ?? this.mutationId,
      localStateJson: localStateJson ?? this.localStateJson,
      serverStateJson: serverStateJson ?? this.serverStateJson,
      detectedAt: detectedAt ?? this.detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (localStateJson.present) {
      map['local_state_json'] = Variable<String>(localStateJson.value);
    }
    if (serverStateJson.present) {
      map['server_state_json'] = Variable<String>(serverStateJson.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictsCompanion(')
          ..write('id: $id, ')
          ..write('mutationId: $mutationId, ')
          ..write('localStateJson: $localStateJson, ')
          ..write('serverStateJson: $serverStateJson, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolution: $resolution, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ScalarioDatabase extends GeneratedDatabase {
  _$ScalarioDatabase(QueryExecutor e) : super(e);
  $ScalarioDatabaseManager get managers => $ScalarioDatabaseManager(this);
  late final $TenantConfigsTable tenantConfigs = $TenantConfigsTable(this);
  late final $CachedLayoutsTable cachedLayouts = $CachedLayoutsTable(this);
  late final $LocalDataTable localData = $LocalDataTable(this);
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);
  late final $ConflictsTable conflicts = $ConflictsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tenantConfigs,
    cachedLayouts,
    localData,
    syncQueueItems,
    conflicts,
  ];
}

typedef $$TenantConfigsTableCreateCompanionBuilder =
    TenantConfigsCompanion Function({
      required String tenantId,
      required String slug,
      required String configJson,
      Value<int> cacheLimitMb,
      Value<String> version,
      Value<DateTime?> lastFetchAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TenantConfigsTableUpdateCompanionBuilder =
    TenantConfigsCompanion Function({
      Value<String> tenantId,
      Value<String> slug,
      Value<String> configJson,
      Value<int> cacheLimitMb,
      Value<String> version,
      Value<DateTime?> lastFetchAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TenantConfigsTableFilterComposer
    extends Composer<_$ScalarioDatabase, $TenantConfigsTable> {
  $$TenantConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheLimitMb => $composableBuilder(
    column: $table.cacheLimitMb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TenantConfigsTableOrderingComposer
    extends Composer<_$ScalarioDatabase, $TenantConfigsTable> {
  $$TenantConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheLimitMb => $composableBuilder(
    column: $table.cacheLimitMb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TenantConfigsTableAnnotationComposer
    extends Composer<_$ScalarioDatabase, $TenantConfigsTable> {
  $$TenantConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheLimitMb => $composableBuilder(
    column: $table.cacheLimitMb,
    builder: (column) => column,
  );

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TenantConfigsTableTableManager
    extends
        RootTableManager<
          _$ScalarioDatabase,
          $TenantConfigsTable,
          TenantConfig,
          $$TenantConfigsTableFilterComposer,
          $$TenantConfigsTableOrderingComposer,
          $$TenantConfigsTableAnnotationComposer,
          $$TenantConfigsTableCreateCompanionBuilder,
          $$TenantConfigsTableUpdateCompanionBuilder,
          (
            TenantConfig,
            BaseReferences<
              _$ScalarioDatabase,
              $TenantConfigsTable,
              TenantConfig
            >,
          ),
          TenantConfig,
          PrefetchHooks Function()
        > {
  $$TenantConfigsTableTableManager(
    _$ScalarioDatabase db,
    $TenantConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TenantConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TenantConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TenantConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<int> cacheLimitMb = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<DateTime?> lastFetchAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenantConfigsCompanion(
                tenantId: tenantId,
                slug: slug,
                configJson: configJson,
                cacheLimitMb: cacheLimitMb,
                version: version,
                lastFetchAt: lastFetchAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String slug,
                required String configJson,
                Value<int> cacheLimitMb = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<DateTime?> lastFetchAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenantConfigsCompanion.insert(
                tenantId: tenantId,
                slug: slug,
                configJson: configJson,
                cacheLimitMb: cacheLimitMb,
                version: version,
                lastFetchAt: lastFetchAt,
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

typedef $$TenantConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$ScalarioDatabase,
      $TenantConfigsTable,
      TenantConfig,
      $$TenantConfigsTableFilterComposer,
      $$TenantConfigsTableOrderingComposer,
      $$TenantConfigsTableAnnotationComposer,
      $$TenantConfigsTableCreateCompanionBuilder,
      $$TenantConfigsTableUpdateCompanionBuilder,
      (
        TenantConfig,
        BaseReferences<_$ScalarioDatabase, $TenantConfigsTable, TenantConfig>,
      ),
      TenantConfig,
      PrefetchHooks Function()
    >;
typedef $$CachedLayoutsTableCreateCompanionBuilder =
    CachedLayoutsCompanion Function({
      required String screenId,
      required String tenantId,
      required String layoutJson,
      Value<String?> etag,
      Value<DateTime> lastFetchAt,
      Value<int> bytesSize,
      Value<int> rowid,
    });
typedef $$CachedLayoutsTableUpdateCompanionBuilder =
    CachedLayoutsCompanion Function({
      Value<String> screenId,
      Value<String> tenantId,
      Value<String> layoutJson,
      Value<String?> etag,
      Value<DateTime> lastFetchAt,
      Value<int> bytesSize,
      Value<int> rowid,
    });

class $$CachedLayoutsTableFilterComposer
    extends Composer<_$ScalarioDatabase, $CachedLayoutsTable> {
  $$CachedLayoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get screenId => $composableBuilder(
    column: $table.screenId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layoutJson => $composableBuilder(
    column: $table.layoutJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesSize => $composableBuilder(
    column: $table.bytesSize,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedLayoutsTableOrderingComposer
    extends Composer<_$ScalarioDatabase, $CachedLayoutsTable> {
  $$CachedLayoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get screenId => $composableBuilder(
    column: $table.screenId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layoutJson => $composableBuilder(
    column: $table.layoutJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesSize => $composableBuilder(
    column: $table.bytesSize,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLayoutsTableAnnotationComposer
    extends Composer<_$ScalarioDatabase, $CachedLayoutsTable> {
  $$CachedLayoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get screenId =>
      $composableBuilder(column: $table.screenId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get layoutJson => $composableBuilder(
    column: $table.layoutJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesSize =>
      $composableBuilder(column: $table.bytesSize, builder: (column) => column);
}

class $$CachedLayoutsTableTableManager
    extends
        RootTableManager<
          _$ScalarioDatabase,
          $CachedLayoutsTable,
          CachedLayout,
          $$CachedLayoutsTableFilterComposer,
          $$CachedLayoutsTableOrderingComposer,
          $$CachedLayoutsTableAnnotationComposer,
          $$CachedLayoutsTableCreateCompanionBuilder,
          $$CachedLayoutsTableUpdateCompanionBuilder,
          (
            CachedLayout,
            BaseReferences<
              _$ScalarioDatabase,
              $CachedLayoutsTable,
              CachedLayout
            >,
          ),
          CachedLayout,
          PrefetchHooks Function()
        > {
  $$CachedLayoutsTableTableManager(
    _$ScalarioDatabase db,
    $CachedLayoutsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLayoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLayoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedLayoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> screenId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> layoutJson = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> lastFetchAt = const Value.absent(),
                Value<int> bytesSize = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLayoutsCompanion(
                screenId: screenId,
                tenantId: tenantId,
                layoutJson: layoutJson,
                etag: etag,
                lastFetchAt: lastFetchAt,
                bytesSize: bytesSize,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String screenId,
                required String tenantId,
                required String layoutJson,
                Value<String?> etag = const Value.absent(),
                Value<DateTime> lastFetchAt = const Value.absent(),
                Value<int> bytesSize = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLayoutsCompanion.insert(
                screenId: screenId,
                tenantId: tenantId,
                layoutJson: layoutJson,
                etag: etag,
                lastFetchAt: lastFetchAt,
                bytesSize: bytesSize,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLayoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$ScalarioDatabase,
      $CachedLayoutsTable,
      CachedLayout,
      $$CachedLayoutsTableFilterComposer,
      $$CachedLayoutsTableOrderingComposer,
      $$CachedLayoutsTableAnnotationComposer,
      $$CachedLayoutsTableCreateCompanionBuilder,
      $$CachedLayoutsTableUpdateCompanionBuilder,
      (
        CachedLayout,
        BaseReferences<_$ScalarioDatabase, $CachedLayoutsTable, CachedLayout>,
      ),
      CachedLayout,
      PrefetchHooks Function()
    >;
typedef $$LocalDataTableCreateCompanionBuilder =
    LocalDataCompanion Function({
      required String id,
      required String tenantId,
      required String moduleId,
      required String entityType,
      required String dataJson,
      Value<DateTime?> baseUpdatedAt,
      Value<DateTime> localUpdatedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$LocalDataTableUpdateCompanionBuilder =
    LocalDataCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> moduleId,
      Value<String> entityType,
      Value<String> dataJson,
      Value<DateTime?> baseUpdatedAt,
      Value<DateTime> localUpdatedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$LocalDataTableFilterComposer
    extends Composer<_$ScalarioDatabase, $LocalDataTable> {
  $$LocalDataTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get baseUpdatedAt => $composableBuilder(
    column: $table.baseUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDataTableOrderingComposer
    extends Composer<_$ScalarioDatabase, $LocalDataTable> {
  $$LocalDataTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get baseUpdatedAt => $composableBuilder(
    column: $table.baseUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDataTableAnnotationComposer
    extends Composer<_$ScalarioDatabase, $LocalDataTable> {
  $$LocalDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get moduleId =>
      $composableBuilder(column: $table.moduleId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get baseUpdatedAt => $composableBuilder(
    column: $table.baseUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$LocalDataTableTableManager
    extends
        RootTableManager<
          _$ScalarioDatabase,
          $LocalDataTable,
          LocalDataRecord,
          $$LocalDataTableFilterComposer,
          $$LocalDataTableOrderingComposer,
          $$LocalDataTableAnnotationComposer,
          $$LocalDataTableCreateCompanionBuilder,
          $$LocalDataTableUpdateCompanionBuilder,
          (
            LocalDataRecord,
            BaseReferences<
              _$ScalarioDatabase,
              $LocalDataTable,
              LocalDataRecord
            >,
          ),
          LocalDataRecord,
          PrefetchHooks Function()
        > {
  $$LocalDataTableTableManager(_$ScalarioDatabase db, $LocalDataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> moduleId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<DateTime?> baseUpdatedAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDataCompanion(
                id: id,
                tenantId: tenantId,
                moduleId: moduleId,
                entityType: entityType,
                dataJson: dataJson,
                baseUpdatedAt: baseUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String moduleId,
                required String entityType,
                required String dataJson,
                Value<DateTime?> baseUpdatedAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDataCompanion.insert(
                id: id,
                tenantId: tenantId,
                moduleId: moduleId,
                entityType: entityType,
                dataJson: dataJson,
                baseUpdatedAt: baseUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDataTableProcessedTableManager =
    ProcessedTableManager<
      _$ScalarioDatabase,
      $LocalDataTable,
      LocalDataRecord,
      $$LocalDataTableFilterComposer,
      $$LocalDataTableOrderingComposer,
      $$LocalDataTableAnnotationComposer,
      $$LocalDataTableCreateCompanionBuilder,
      $$LocalDataTableUpdateCompanionBuilder,
      (
        LocalDataRecord,
        BaseReferences<_$ScalarioDatabase, $LocalDataTable, LocalDataRecord>,
      ),
      LocalDataRecord,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueItemsTableCreateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      required String mutationId,
      required String tenantId,
      required String moduleId,
      required String action,
      required String payloadJson,
      required String idempotencyKey,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<String?> lastError,
      Value<DateTime?> nextRetryAt,
      Value<int> rowid,
    });
typedef $$SyncQueueItemsTableUpdateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<String> mutationId,
      Value<String> tenantId,
      Value<String> moduleId,
      Value<String> action,
      Value<String> payloadJson,
      Value<String> idempotencyKey,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<String?> lastError,
      Value<DateTime?> nextRetryAt,
      Value<int> rowid,
    });

class $$SyncQueueItemsTableFilterComposer
    extends Composer<_$ScalarioDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueItemsTableOrderingComposer
    extends Composer<_$ScalarioDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueItemsTableAnnotationComposer
    extends Composer<_$ScalarioDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get moduleId =>
      $composableBuilder(column: $table.moduleId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );
}

class $$SyncQueueItemsTableTableManager
    extends
        RootTableManager<
          _$ScalarioDatabase,
          $SyncQueueItemsTable,
          SyncQueueItem,
          $$SyncQueueItemsTableFilterComposer,
          $$SyncQueueItemsTableOrderingComposer,
          $$SyncQueueItemsTableAnnotationComposer,
          $$SyncQueueItemsTableCreateCompanionBuilder,
          $$SyncQueueItemsTableUpdateCompanionBuilder,
          (
            SyncQueueItem,
            BaseReferences<
              _$ScalarioDatabase,
              $SyncQueueItemsTable,
              SyncQueueItem
            >,
          ),
          SyncQueueItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueItemsTableTableManager(
    _$ScalarioDatabase db,
    $SyncQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mutationId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> moduleId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueItemsCompanion(
                mutationId: mutationId,
                tenantId: tenantId,
                moduleId: moduleId,
                action: action,
                payloadJson: payloadJson,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                lastError: lastError,
                nextRetryAt: nextRetryAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mutationId,
                required String tenantId,
                required String moduleId,
                required String action,
                required String payloadJson,
                required String idempotencyKey,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueItemsCompanion.insert(
                mutationId: mutationId,
                tenantId: tenantId,
                moduleId: moduleId,
                action: action,
                payloadJson: payloadJson,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                lastError: lastError,
                nextRetryAt: nextRetryAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$ScalarioDatabase,
      $SyncQueueItemsTable,
      SyncQueueItem,
      $$SyncQueueItemsTableFilterComposer,
      $$SyncQueueItemsTableOrderingComposer,
      $$SyncQueueItemsTableAnnotationComposer,
      $$SyncQueueItemsTableCreateCompanionBuilder,
      $$SyncQueueItemsTableUpdateCompanionBuilder,
      (
        SyncQueueItem,
        BaseReferences<_$ScalarioDatabase, $SyncQueueItemsTable, SyncQueueItem>,
      ),
      SyncQueueItem,
      PrefetchHooks Function()
    >;
typedef $$ConflictsTableCreateCompanionBuilder =
    ConflictsCompanion Function({
      required String id,
      required String mutationId,
      required String localStateJson,
      required String serverStateJson,
      Value<DateTime> detectedAt,
      Value<DateTime?> resolvedAt,
      Value<String?> resolution,
      Value<int> rowid,
    });
typedef $$ConflictsTableUpdateCompanionBuilder =
    ConflictsCompanion Function({
      Value<String> id,
      Value<String> mutationId,
      Value<String> localStateJson,
      Value<String> serverStateJson,
      Value<DateTime> detectedAt,
      Value<DateTime?> resolvedAt,
      Value<String?> resolution,
      Value<int> rowid,
    });

class $$ConflictsTableFilterComposer
    extends Composer<_$ScalarioDatabase, $ConflictsTable> {
  $$ConflictsTableFilterComposer({
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

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localStateJson => $composableBuilder(
    column: $table.localStateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverStateJson => $composableBuilder(
    column: $table.serverStateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConflictsTableOrderingComposer
    extends Composer<_$ScalarioDatabase, $ConflictsTable> {
  $$ConflictsTableOrderingComposer({
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

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localStateJson => $composableBuilder(
    column: $table.localStateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverStateJson => $composableBuilder(
    column: $table.serverStateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConflictsTableAnnotationComposer
    extends Composer<_$ScalarioDatabase, $ConflictsTable> {
  $$ConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localStateJson => $composableBuilder(
    column: $table.localStateJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverStateJson => $composableBuilder(
    column: $table.serverStateJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );
}

class $$ConflictsTableTableManager
    extends
        RootTableManager<
          _$ScalarioDatabase,
          $ConflictsTable,
          ConflictRecord,
          $$ConflictsTableFilterComposer,
          $$ConflictsTableOrderingComposer,
          $$ConflictsTableAnnotationComposer,
          $$ConflictsTableCreateCompanionBuilder,
          $$ConflictsTableUpdateCompanionBuilder,
          (
            ConflictRecord,
            BaseReferences<_$ScalarioDatabase, $ConflictsTable, ConflictRecord>,
          ),
          ConflictRecord,
          PrefetchHooks Function()
        > {
  $$ConflictsTableTableManager(_$ScalarioDatabase db, $ConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mutationId = const Value.absent(),
                Value<String> localStateJson = const Value.absent(),
                Value<String> serverStateJson = const Value.absent(),
                Value<DateTime> detectedAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictsCompanion(
                id: id,
                mutationId: mutationId,
                localStateJson: localStateJson,
                serverStateJson: serverStateJson,
                detectedAt: detectedAt,
                resolvedAt: resolvedAt,
                resolution: resolution,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mutationId,
                required String localStateJson,
                required String serverStateJson,
                Value<DateTime> detectedAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictsCompanion.insert(
                id: id,
                mutationId: mutationId,
                localStateJson: localStateJson,
                serverStateJson: serverStateJson,
                detectedAt: detectedAt,
                resolvedAt: resolvedAt,
                resolution: resolution,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$ScalarioDatabase,
      $ConflictsTable,
      ConflictRecord,
      $$ConflictsTableFilterComposer,
      $$ConflictsTableOrderingComposer,
      $$ConflictsTableAnnotationComposer,
      $$ConflictsTableCreateCompanionBuilder,
      $$ConflictsTableUpdateCompanionBuilder,
      (
        ConflictRecord,
        BaseReferences<_$ScalarioDatabase, $ConflictsTable, ConflictRecord>,
      ),
      ConflictRecord,
      PrefetchHooks Function()
    >;

class $ScalarioDatabaseManager {
  final _$ScalarioDatabase _db;
  $ScalarioDatabaseManager(this._db);
  $$TenantConfigsTableTableManager get tenantConfigs =>
      $$TenantConfigsTableTableManager(_db, _db.tenantConfigs);
  $$CachedLayoutsTableTableManager get cachedLayouts =>
      $$CachedLayoutsTableTableManager(_db, _db.cachedLayouts);
  $$LocalDataTableTableManager get localData =>
      $$LocalDataTableTableManager(_db, _db.localData);
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
  $$ConflictsTableTableManager get conflicts =>
      $$ConflictsTableTableManager(_db, _db.conflicts);
}
