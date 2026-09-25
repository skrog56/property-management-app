// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PropertiesTable extends Properties
    with TableInfo<$PropertiesTable, Property> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PropertiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _picMeta = const VerificationMeta('pic');
  @override
  late final GeneratedColumn<String> pic = GeneratedColumn<String>(
    'pic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    pic,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'properties';
  @override
  VerificationContext validateIntegrity(
    Insertable<Property> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('pic')) {
      context.handle(
        _picMeta,
        pic.isAcceptableOrUnknown(data['pic']!, _picMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Property map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Property(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      pic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pic'],
      ),
    );
  }

  @override
  $PropertiesTable createAlias(String alias) {
    return $PropertiesTable(attachedDatabase, alias);
  }
}

class Property extends DataClass implements Insertable<Property> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String name;

  /// Property Identification Code, for if compliance reporting ever lands.
  final String? pic;
  const Property({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    this.pic,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || pic != null) {
      map['pic'] = Variable<String>(pic);
    }
    return map;
  }

  PropertiesCompanion toCompanion(bool nullToAbsent) {
    return PropertiesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      pic: pic == null && nullToAbsent ? const Value.absent() : Value(pic),
    );
  }

  factory Property.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Property(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      pic: serializer.fromJson<String?>(json['pic']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'pic': serializer.toJson<String?>(pic),
    };
  }

  Property copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    Value<String?> pic = const Value.absent(),
  }) => Property(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    pic: pic.present ? pic.value : this.pic,
  );
  Property copyWithCompanion(PropertiesCompanion data) {
    return Property(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      pic: data.pic.present ? data.pic.value : this.pic,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Property(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('pic: $pic')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, deletedAt, name, pic);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Property &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.pic == this.pic);
}

class PropertiesCompanion extends UpdateCompanion<Property> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String?> pic;
  final Value<int> rowid;
  const PropertiesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.pic = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PropertiesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    this.pic = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name);
  static Insertable<Property> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? pic,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (pic != null) 'pic': pic,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PropertiesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String?>? pic,
    Value<int>? rowid,
  }) {
    return PropertiesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      pic: pic ?? this.pic,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pic.present) {
      map['pic'] = Variable<String>(pic.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PropertiesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('pic: $pic, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaddocksTable extends Paddocks with TableInfo<$PaddocksTable, Paddock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaddocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _propertyIdMeta = const VerificationMeta(
    'propertyId',
  );
  @override
  late final GeneratedColumn<String> propertyId = GeneratedColumn<String>(
    'property_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES properties (id)',
    ),
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
  static const VerificationMeta _hectaresMeta = const VerificationMeta(
    'hectares',
  );
  @override
  late final GeneratedColumn<double> hectares = GeneratedColumn<double>(
    'hectares',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _boundaryMeta = const VerificationMeta(
    'boundary',
  );
  @override
  late final GeneratedColumn<String> boundary = GeneratedColumn<String>(
    'boundary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    propertyId,
    name,
    hectares,
    boundary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paddocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Paddock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('property_id')) {
      context.handle(
        _propertyIdMeta,
        propertyId.isAcceptableOrUnknown(data['property_id']!, _propertyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_propertyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('hectares')) {
      context.handle(
        _hectaresMeta,
        hectares.isAcceptableOrUnknown(data['hectares']!, _hectaresMeta),
      );
    }
    if (data.containsKey('boundary')) {
      context.handle(
        _boundaryMeta,
        boundary.isAcceptableOrUnknown(data['boundary']!, _boundaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Paddock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Paddock(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      propertyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}property_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      hectares: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hectares'],
      )!,
      boundary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boundary'],
      ),
    );
  }

  @override
  $PaddocksTable createAlias(String alias) {
    return $PaddocksTable(attachedDatabase, alias);
  }
}

class Paddock extends DataClass implements Insertable<Paddock> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String propertyId;
  final String name;
  final double hectares;

  /// GeoJSON polygon, filled in when map drawing lands.
  final String? boundary;
  const Paddock({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.propertyId,
    required this.name,
    required this.hectares,
    this.boundary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['property_id'] = Variable<String>(propertyId);
    map['name'] = Variable<String>(name);
    map['hectares'] = Variable<double>(hectares);
    if (!nullToAbsent || boundary != null) {
      map['boundary'] = Variable<String>(boundary);
    }
    return map;
  }

  PaddocksCompanion toCompanion(bool nullToAbsent) {
    return PaddocksCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      propertyId: Value(propertyId),
      name: Value(name),
      hectares: Value(hectares),
      boundary: boundary == null && nullToAbsent
          ? const Value.absent()
          : Value(boundary),
    );
  }

  factory Paddock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Paddock(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      propertyId: serializer.fromJson<String>(json['propertyId']),
      name: serializer.fromJson<String>(json['name']),
      hectares: serializer.fromJson<double>(json['hectares']),
      boundary: serializer.fromJson<String?>(json['boundary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'propertyId': serializer.toJson<String>(propertyId),
      'name': serializer.toJson<String>(name),
      'hectares': serializer.toJson<double>(hectares),
      'boundary': serializer.toJson<String?>(boundary),
    };
  }

  Paddock copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? propertyId,
    String? name,
    double? hectares,
    Value<String?> boundary = const Value.absent(),
  }) => Paddock(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    propertyId: propertyId ?? this.propertyId,
    name: name ?? this.name,
    hectares: hectares ?? this.hectares,
    boundary: boundary.present ? boundary.value : this.boundary,
  );
  Paddock copyWithCompanion(PaddocksCompanion data) {
    return Paddock(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      propertyId: data.propertyId.present
          ? data.propertyId.value
          : this.propertyId,
      name: data.name.present ? data.name.value : this.name,
      hectares: data.hectares.present ? data.hectares.value : this.hectares,
      boundary: data.boundary.present ? data.boundary.value : this.boundary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Paddock(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('propertyId: $propertyId, ')
          ..write('name: $name, ')
          ..write('hectares: $hectares, ')
          ..write('boundary: $boundary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    propertyId,
    name,
    hectares,
    boundary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Paddock &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.propertyId == this.propertyId &&
          other.name == this.name &&
          other.hectares == this.hectares &&
          other.boundary == this.boundary);
}

class PaddocksCompanion extends UpdateCompanion<Paddock> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> propertyId;
  final Value<String> name;
  final Value<double> hectares;
  final Value<String?> boundary;
  final Value<int> rowid;
  const PaddocksCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.propertyId = const Value.absent(),
    this.name = const Value.absent(),
    this.hectares = const Value.absent(),
    this.boundary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaddocksCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String propertyId,
    required String name,
    this.hectares = const Value.absent(),
    this.boundary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       propertyId = Value(propertyId),
       name = Value(name);
  static Insertable<Paddock> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? propertyId,
    Expression<String>? name,
    Expression<double>? hectares,
    Expression<String>? boundary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (propertyId != null) 'property_id': propertyId,
      if (name != null) 'name': name,
      if (hectares != null) 'hectares': hectares,
      if (boundary != null) 'boundary': boundary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaddocksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? propertyId,
    Value<String>? name,
    Value<double>? hectares,
    Value<String?>? boundary,
    Value<int>? rowid,
  }) {
    return PaddocksCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      hectares: hectares ?? this.hectares,
      boundary: boundary ?? this.boundary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (propertyId.present) {
      map['property_id'] = Variable<String>(propertyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hectares.present) {
      map['hectares'] = Variable<double>(hectares.value);
    }
    if (boundary.present) {
      map['boundary'] = Variable<String>(boundary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaddocksCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('propertyId: $propertyId, ')
          ..write('name: $name, ')
          ..write('hectares: $hectares, ')
          ..write('boundary: $boundary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, Template> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    isBuiltIn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<Template> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Template map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Template(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class Template extends DataClass implements Insertable<Template> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String name;
  final bool isBuiltIn;
  const Template({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.isBuiltIn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      isBuiltIn: Value(isBuiltIn),
    );
  }

  factory Template.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Template(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
    };
  }

  Template copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    bool? isBuiltIn,
  }) => Template(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
  );
  Template copyWithCompanion(TemplatesCompanion data) {
    return Template(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Template(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('isBuiltIn: $isBuiltIn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, deletedAt, name, isBuiltIn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Template &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.isBuiltIn == this.isBuiltIn);
}

class TemplatesCompanion extends UpdateCompanion<Template> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<bool> isBuiltIn;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    this.isBuiltIn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name);
  static Insertable<Template> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<bool>? isBuiltIn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<bool>? isBuiltIn,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LivestockClassesTable extends LivestockClasses
    with TableInfo<$LivestockClassesTable, LivestockClass> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LivestockClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id)',
    ),
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
  static const VerificationMeta _breedMeta = const VerificationMeta('breed');
  @override
  late final GeneratedColumn<String> breed = GeneratedColumn<String>(
    'breed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ageBandMeta = const VerificationMeta(
    'ageBand',
  );
  @override
  late final GeneratedColumn<String> ageBand = GeneratedColumn<String>(
    'age_band',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agesIntoClassIdMeta = const VerificationMeta(
    'agesIntoClassId',
  );
  @override
  late final GeneratedColumn<String> agesIntoClassId = GeneratedColumn<String>(
    'ages_into_class_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    templateId,
    kind,
    breed,
    ageBand,
    agesIntoClassId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'livestock_classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LivestockClass> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('breed')) {
      context.handle(
        _breedMeta,
        breed.isAcceptableOrUnknown(data['breed']!, _breedMeta),
      );
    }
    if (data.containsKey('age_band')) {
      context.handle(
        _ageBandMeta,
        ageBand.isAcceptableOrUnknown(data['age_band']!, _ageBandMeta),
      );
    } else if (isInserting) {
      context.missing(_ageBandMeta);
    }
    if (data.containsKey('ages_into_class_id')) {
      context.handle(
        _agesIntoClassIdMeta,
        agesIntoClassId.isAcceptableOrUnknown(
          data['ages_into_class_id']!,
          _agesIntoClassIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LivestockClass map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LivestockClass(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      breed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breed'],
      ),
      ageBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age_band'],
      )!,
      agesIntoClassId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ages_into_class_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $LivestockClassesTable createAlias(String alias) {
    return $LivestockClassesTable(attachedDatabase, alias);
  }
}

class LivestockClass extends DataClass implements Insertable<LivestockClass> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String templateId;
  final String kind;
  final String? breed;
  final String ageBand;

  /// Makes aging one tap instead of a class picker.
  final String? agesIntoClassId;
  final int sortOrder;
  const LivestockClass({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.templateId,
    required this.kind,
    this.breed,
    required this.ageBand,
    this.agesIntoClassId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['template_id'] = Variable<String>(templateId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || breed != null) {
      map['breed'] = Variable<String>(breed);
    }
    map['age_band'] = Variable<String>(ageBand);
    if (!nullToAbsent || agesIntoClassId != null) {
      map['ages_into_class_id'] = Variable<String>(agesIntoClassId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LivestockClassesCompanion toCompanion(bool nullToAbsent) {
    return LivestockClassesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      templateId: Value(templateId),
      kind: Value(kind),
      breed: breed == null && nullToAbsent
          ? const Value.absent()
          : Value(breed),
      ageBand: Value(ageBand),
      agesIntoClassId: agesIntoClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(agesIntoClassId),
      sortOrder: Value(sortOrder),
    );
  }

  factory LivestockClass.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LivestockClass(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      templateId: serializer.fromJson<String>(json['templateId']),
      kind: serializer.fromJson<String>(json['kind']),
      breed: serializer.fromJson<String?>(json['breed']),
      ageBand: serializer.fromJson<String>(json['ageBand']),
      agesIntoClassId: serializer.fromJson<String?>(json['agesIntoClassId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'templateId': serializer.toJson<String>(templateId),
      'kind': serializer.toJson<String>(kind),
      'breed': serializer.toJson<String?>(breed),
      'ageBand': serializer.toJson<String>(ageBand),
      'agesIntoClassId': serializer.toJson<String?>(agesIntoClassId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LivestockClass copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? templateId,
    String? kind,
    Value<String?> breed = const Value.absent(),
    String? ageBand,
    Value<String?> agesIntoClassId = const Value.absent(),
    int? sortOrder,
  }) => LivestockClass(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    templateId: templateId ?? this.templateId,
    kind: kind ?? this.kind,
    breed: breed.present ? breed.value : this.breed,
    ageBand: ageBand ?? this.ageBand,
    agesIntoClassId: agesIntoClassId.present
        ? agesIntoClassId.value
        : this.agesIntoClassId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LivestockClass copyWithCompanion(LivestockClassesCompanion data) {
    return LivestockClass(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      kind: data.kind.present ? data.kind.value : this.kind,
      breed: data.breed.present ? data.breed.value : this.breed,
      ageBand: data.ageBand.present ? data.ageBand.value : this.ageBand,
      agesIntoClassId: data.agesIntoClassId.present
          ? data.agesIntoClassId.value
          : this.agesIntoClassId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LivestockClass(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('templateId: $templateId, ')
          ..write('kind: $kind, ')
          ..write('breed: $breed, ')
          ..write('ageBand: $ageBand, ')
          ..write('agesIntoClassId: $agesIntoClassId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    templateId,
    kind,
    breed,
    ageBand,
    agesIntoClassId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LivestockClass &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.templateId == this.templateId &&
          other.kind == this.kind &&
          other.breed == this.breed &&
          other.ageBand == this.ageBand &&
          other.agesIntoClassId == this.agesIntoClassId &&
          other.sortOrder == this.sortOrder);
}

class LivestockClassesCompanion extends UpdateCompanion<LivestockClass> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> templateId;
  final Value<String> kind;
  final Value<String?> breed;
  final Value<String> ageBand;
  final Value<String?> agesIntoClassId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LivestockClassesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.templateId = const Value.absent(),
    this.kind = const Value.absent(),
    this.breed = const Value.absent(),
    this.ageBand = const Value.absent(),
    this.agesIntoClassId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LivestockClassesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String templateId,
    required String kind,
    this.breed = const Value.absent(),
    required String ageBand,
    this.agesIntoClassId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       templateId = Value(templateId),
       kind = Value(kind),
       ageBand = Value(ageBand);
  static Insertable<LivestockClass> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? templateId,
    Expression<String>? kind,
    Expression<String>? breed,
    Expression<String>? ageBand,
    Expression<String>? agesIntoClassId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (templateId != null) 'template_id': templateId,
      if (kind != null) 'kind': kind,
      if (breed != null) 'breed': breed,
      if (ageBand != null) 'age_band': ageBand,
      if (agesIntoClassId != null) 'ages_into_class_id': agesIntoClassId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LivestockClassesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? templateId,
    Value<String>? kind,
    Value<String?>? breed,
    Value<String>? ageBand,
    Value<String?>? agesIntoClassId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LivestockClassesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      templateId: templateId ?? this.templateId,
      kind: kind ?? this.kind,
      breed: breed ?? this.breed,
      ageBand: ageBand ?? this.ageBand,
      agesIntoClassId: agesIntoClassId ?? this.agesIntoClassId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (breed.present) {
      map['breed'] = Variable<String>(breed.value);
    }
    if (ageBand.present) {
      map['age_band'] = Variable<String>(ageBand.value);
    }
    if (agesIntoClassId.present) {
      map['ages_into_class_id'] = Variable<String>(agesIntoClassId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LivestockClassesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('templateId: $templateId, ')
          ..write('kind: $kind, ')
          ..write('breed: $breed, ')
          ..write('ageBand: $ageBand, ')
          ..write('agesIntoClassId: $agesIntoClassId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovementsTable extends Movements
    with TableInfo<$MovementsTable, Movement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MovementKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MovementKind>($MovementsTable.$converterkind);
  static const VerificationMeta _fromPaddockIdMeta = const VerificationMeta(
    'fromPaddockId',
  );
  @override
  late final GeneratedColumn<String> fromPaddockId = GeneratedColumn<String>(
    'from_paddock_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES paddocks (id)',
    ),
  );
  static const VerificationMeta _fromClassIdMeta = const VerificationMeta(
    'fromClassId',
  );
  @override
  late final GeneratedColumn<String> fromClassId = GeneratedColumn<String>(
    'from_class_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES livestock_classes (id)',
    ),
  );
  static const VerificationMeta _toPaddockIdMeta = const VerificationMeta(
    'toPaddockId',
  );
  @override
  late final GeneratedColumn<String> toPaddockId = GeneratedColumn<String>(
    'to_paddock_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES paddocks (id)',
    ),
  );
  static const VerificationMeta _toClassIdMeta = const VerificationMeta(
    'toClassId',
  );
  @override
  late final GeneratedColumn<String> toClassId = GeneratedColumn<String>(
    'to_class_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES livestock_classes (id)',
    ),
  );
  static const VerificationMeta _headMeta = const VerificationMeta('head');
  @override
  late final GeneratedColumn<int> head = GeneratedColumn<int>(
    'head',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EndState?, String> endState =
      GeneratedColumn<String>(
        'end_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<EndState?>($MovementsTable.$converterendStaten);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    occurredAt,
    kind,
    fromPaddockId,
    fromClassId,
    toPaddockId,
    toClassId,
    head,
    endState,
    note,
    actorId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('from_paddock_id')) {
      context.handle(
        _fromPaddockIdMeta,
        fromPaddockId.isAcceptableOrUnknown(
          data['from_paddock_id']!,
          _fromPaddockIdMeta,
        ),
      );
    }
    if (data.containsKey('from_class_id')) {
      context.handle(
        _fromClassIdMeta,
        fromClassId.isAcceptableOrUnknown(
          data['from_class_id']!,
          _fromClassIdMeta,
        ),
      );
    }
    if (data.containsKey('to_paddock_id')) {
      context.handle(
        _toPaddockIdMeta,
        toPaddockId.isAcceptableOrUnknown(
          data['to_paddock_id']!,
          _toPaddockIdMeta,
        ),
      );
    }
    if (data.containsKey('to_class_id')) {
      context.handle(
        _toClassIdMeta,
        toClassId.isAcceptableOrUnknown(data['to_class_id']!, _toClassIdMeta),
      );
    }
    if (data.containsKey('head')) {
      context.handle(
        _headMeta,
        head.isAcceptableOrUnknown(data['head']!, _headMeta),
      );
    } else if (isInserting) {
      context.missing(_headMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actorIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Movement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      kind: $MovementsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      fromPaddockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_paddock_id'],
      ),
      fromClassId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_class_id'],
      ),
      toPaddockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_paddock_id'],
      ),
      toClassId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_class_id'],
      ),
      head: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}head'],
      )!,
      endState: $MovementsTable.$converterendStaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}end_state'],
        ),
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
    );
  }

  @override
  $MovementsTable createAlias(String alias) {
    return $MovementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MovementKind, String, String> $converterkind =
      const EnumNameConverter<MovementKind>(MovementKind.values);
  static JsonTypeConverter2<EndState, String, String> $converterendState =
      const EnumNameConverter<EndState>(EndState.values);
  static JsonTypeConverter2<EndState?, String?, String?> $converterendStaten =
      JsonTypeConverter2.asNullable($converterendState);
}

class Movement extends DataClass implements Insertable<Movement> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime occurredAt;
  final MovementKind kind;

  /// Null on intake.
  final String? fromPaddockId;
  final String? fromClassId;

  /// Null on endState.
  final String? toPaddockId;
  final String? toClassId;
  final int head;
  final EndState? endState;
  final String? note;

  /// Local placeholder until accounts exist.
  final String actorId;
  const Movement({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.occurredAt,
    required this.kind,
    this.fromPaddockId,
    this.fromClassId,
    this.toPaddockId,
    this.toClassId,
    required this.head,
    this.endState,
    this.note,
    required this.actorId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    {
      map['kind'] = Variable<String>(
        $MovementsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || fromPaddockId != null) {
      map['from_paddock_id'] = Variable<String>(fromPaddockId);
    }
    if (!nullToAbsent || fromClassId != null) {
      map['from_class_id'] = Variable<String>(fromClassId);
    }
    if (!nullToAbsent || toPaddockId != null) {
      map['to_paddock_id'] = Variable<String>(toPaddockId);
    }
    if (!nullToAbsent || toClassId != null) {
      map['to_class_id'] = Variable<String>(toClassId);
    }
    map['head'] = Variable<int>(head);
    if (!nullToAbsent || endState != null) {
      map['end_state'] = Variable<String>(
        $MovementsTable.$converterendStaten.toSql(endState),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['actor_id'] = Variable<String>(actorId);
    return map;
  }

  MovementsCompanion toCompanion(bool nullToAbsent) {
    return MovementsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      occurredAt: Value(occurredAt),
      kind: Value(kind),
      fromPaddockId: fromPaddockId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromPaddockId),
      fromClassId: fromClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromClassId),
      toPaddockId: toPaddockId == null && nullToAbsent
          ? const Value.absent()
          : Value(toPaddockId),
      toClassId: toClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(toClassId),
      head: Value(head),
      endState: endState == null && nullToAbsent
          ? const Value.absent()
          : Value(endState),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      actorId: Value(actorId),
    );
  }

  factory Movement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movement(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      kind: $MovementsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      fromPaddockId: serializer.fromJson<String?>(json['fromPaddockId']),
      fromClassId: serializer.fromJson<String?>(json['fromClassId']),
      toPaddockId: serializer.fromJson<String?>(json['toPaddockId']),
      toClassId: serializer.fromJson<String?>(json['toClassId']),
      head: serializer.fromJson<int>(json['head']),
      endState: $MovementsTable.$converterendStaten.fromJson(
        serializer.fromJson<String?>(json['endState']),
      ),
      note: serializer.fromJson<String?>(json['note']),
      actorId: serializer.fromJson<String>(json['actorId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'kind': serializer.toJson<String>(
        $MovementsTable.$converterkind.toJson(kind),
      ),
      'fromPaddockId': serializer.toJson<String?>(fromPaddockId),
      'fromClassId': serializer.toJson<String?>(fromClassId),
      'toPaddockId': serializer.toJson<String?>(toPaddockId),
      'toClassId': serializer.toJson<String?>(toClassId),
      'head': serializer.toJson<int>(head),
      'endState': serializer.toJson<String?>(
        $MovementsTable.$converterendStaten.toJson(endState),
      ),
      'note': serializer.toJson<String?>(note),
      'actorId': serializer.toJson<String>(actorId),
    };
  }

  Movement copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? occurredAt,
    MovementKind? kind,
    Value<String?> fromPaddockId = const Value.absent(),
    Value<String?> fromClassId = const Value.absent(),
    Value<String?> toPaddockId = const Value.absent(),
    Value<String?> toClassId = const Value.absent(),
    int? head,
    Value<EndState?> endState = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? actorId,
  }) => Movement(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    occurredAt: occurredAt ?? this.occurredAt,
    kind: kind ?? this.kind,
    fromPaddockId: fromPaddockId.present
        ? fromPaddockId.value
        : this.fromPaddockId,
    fromClassId: fromClassId.present ? fromClassId.value : this.fromClassId,
    toPaddockId: toPaddockId.present ? toPaddockId.value : this.toPaddockId,
    toClassId: toClassId.present ? toClassId.value : this.toClassId,
    head: head ?? this.head,
    endState: endState.present ? endState.value : this.endState,
    note: note.present ? note.value : this.note,
    actorId: actorId ?? this.actorId,
  );
  Movement copyWithCompanion(MovementsCompanion data) {
    return Movement(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      fromPaddockId: data.fromPaddockId.present
          ? data.fromPaddockId.value
          : this.fromPaddockId,
      fromClassId: data.fromClassId.present
          ? data.fromClassId.value
          : this.fromClassId,
      toPaddockId: data.toPaddockId.present
          ? data.toPaddockId.value
          : this.toPaddockId,
      toClassId: data.toClassId.present ? data.toClassId.value : this.toClassId,
      head: data.head.present ? data.head.value : this.head,
      endState: data.endState.present ? data.endState.value : this.endState,
      note: data.note.present ? data.note.value : this.note,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movement(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('kind: $kind, ')
          ..write('fromPaddockId: $fromPaddockId, ')
          ..write('fromClassId: $fromClassId, ')
          ..write('toPaddockId: $toPaddockId, ')
          ..write('toClassId: $toClassId, ')
          ..write('head: $head, ')
          ..write('endState: $endState, ')
          ..write('note: $note, ')
          ..write('actorId: $actorId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    occurredAt,
    kind,
    fromPaddockId,
    fromClassId,
    toPaddockId,
    toClassId,
    head,
    endState,
    note,
    actorId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movement &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.occurredAt == this.occurredAt &&
          other.kind == this.kind &&
          other.fromPaddockId == this.fromPaddockId &&
          other.fromClassId == this.fromClassId &&
          other.toPaddockId == this.toPaddockId &&
          other.toClassId == this.toClassId &&
          other.head == this.head &&
          other.endState == this.endState &&
          other.note == this.note &&
          other.actorId == this.actorId);
}

class MovementsCompanion extends UpdateCompanion<Movement> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> occurredAt;
  final Value<MovementKind> kind;
  final Value<String?> fromPaddockId;
  final Value<String?> fromClassId;
  final Value<String?> toPaddockId;
  final Value<String?> toClassId;
  final Value<int> head;
  final Value<EndState?> endState;
  final Value<String?> note;
  final Value<String> actorId;
  final Value<int> rowid;
  const MovementsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.fromPaddockId = const Value.absent(),
    this.fromClassId = const Value.absent(),
    this.toPaddockId = const Value.absent(),
    this.toClassId = const Value.absent(),
    this.head = const Value.absent(),
    this.endState = const Value.absent(),
    this.note = const Value.absent(),
    this.actorId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovementsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required DateTime occurredAt,
    required MovementKind kind,
    this.fromPaddockId = const Value.absent(),
    this.fromClassId = const Value.absent(),
    this.toPaddockId = const Value.absent(),
    this.toClassId = const Value.absent(),
    required int head,
    this.endState = const Value.absent(),
    this.note = const Value.absent(),
    required String actorId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       occurredAt = Value(occurredAt),
       kind = Value(kind),
       head = Value(head),
       actorId = Value(actorId);
  static Insertable<Movement> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? occurredAt,
    Expression<String>? kind,
    Expression<String>? fromPaddockId,
    Expression<String>? fromClassId,
    Expression<String>? toPaddockId,
    Expression<String>? toClassId,
    Expression<int>? head,
    Expression<String>? endState,
    Expression<String>? note,
    Expression<String>? actorId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (kind != null) 'kind': kind,
      if (fromPaddockId != null) 'from_paddock_id': fromPaddockId,
      if (fromClassId != null) 'from_class_id': fromClassId,
      if (toPaddockId != null) 'to_paddock_id': toPaddockId,
      if (toClassId != null) 'to_class_id': toClassId,
      if (head != null) 'head': head,
      if (endState != null) 'end_state': endState,
      if (note != null) 'note': note,
      if (actorId != null) 'actor_id': actorId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovementsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? occurredAt,
    Value<MovementKind>? kind,
    Value<String?>? fromPaddockId,
    Value<String?>? fromClassId,
    Value<String?>? toPaddockId,
    Value<String?>? toClassId,
    Value<int>? head,
    Value<EndState?>? endState,
    Value<String?>? note,
    Value<String>? actorId,
    Value<int>? rowid,
  }) {
    return MovementsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      occurredAt: occurredAt ?? this.occurredAt,
      kind: kind ?? this.kind,
      fromPaddockId: fromPaddockId ?? this.fromPaddockId,
      fromClassId: fromClassId ?? this.fromClassId,
      toPaddockId: toPaddockId ?? this.toPaddockId,
      toClassId: toClassId ?? this.toClassId,
      head: head ?? this.head,
      endState: endState ?? this.endState,
      note: note ?? this.note,
      actorId: actorId ?? this.actorId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $MovementsTable.$converterkind.toSql(kind.value),
      );
    }
    if (fromPaddockId.present) {
      map['from_paddock_id'] = Variable<String>(fromPaddockId.value);
    }
    if (fromClassId.present) {
      map['from_class_id'] = Variable<String>(fromClassId.value);
    }
    if (toPaddockId.present) {
      map['to_paddock_id'] = Variable<String>(toPaddockId.value);
    }
    if (toClassId.present) {
      map['to_class_id'] = Variable<String>(toClassId.value);
    }
    if (head.present) {
      map['head'] = Variable<int>(head.value);
    }
    if (endState.present) {
      map['end_state'] = Variable<String>(
        $MovementsTable.$converterendStaten.toSql(endState.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovementsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('kind: $kind, ')
          ..write('fromPaddockId: $fromPaddockId, ')
          ..write('fromClassId: $fromClassId, ')
          ..write('toPaddockId: $toPaddockId, ')
          ..write('toClassId: $toClassId, ')
          ..write('head: $head, ')
          ..write('endState: $endState, ')
          ..write('note: $note, ')
          ..write('actorId: $actorId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PropertiesTable properties = $PropertiesTable(this);
  late final $PaddocksTable paddocks = $PaddocksTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $LivestockClassesTable livestockClasses = $LivestockClassesTable(
    this,
  );
  late final $MovementsTable movements = $MovementsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    properties,
    paddocks,
    templates,
    livestockClasses,
    movements,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$PropertiesTableCreateCompanionBuilder =
    PropertiesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String name,
      Value<String?> pic,
      Value<int> rowid,
    });
typedef $$PropertiesTableUpdateCompanionBuilder =
    PropertiesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<String?> pic,
      Value<int> rowid,
    });

final class $$PropertiesTableReferences
    extends BaseReferences<_$AppDatabase, $PropertiesTable, Property> {
  $$PropertiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PaddocksTable, List<Paddock>> _paddocksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.paddocks,
    aliasName: 'properties__id__paddocks__property_id',
  );

  $$PaddocksTableProcessedTableManager get paddocksRefs {
    final manager = $$PaddocksTableTableManager(
      $_db,
      $_db.paddocks,
    ).filter((f) => f.propertyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_paddocksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PropertiesTableFilterComposer
    extends Composer<_$AppDatabase, $PropertiesTable> {
  $$PropertiesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pic => $composableBuilder(
    column: $table.pic,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> paddocksRefs(
    Expression<bool> Function($$PaddocksTableFilterComposer f) f,
  ) {
    final $$PaddocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paddocks,
      getReferencedColumn: (t) => t.propertyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaddocksTableFilterComposer(
            $db: $db,
            $table: $db.paddocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PropertiesTableOrderingComposer
    extends Composer<_$AppDatabase, $PropertiesTable> {
  $$PropertiesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pic => $composableBuilder(
    column: $table.pic,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PropertiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PropertiesTable> {
  $$PropertiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get pic =>
      $composableBuilder(column: $table.pic, builder: (column) => column);

  Expression<T> paddocksRefs<T extends Object>(
    Expression<T> Function($$PaddocksTableAnnotationComposer a) f,
  ) {
    final $$PaddocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paddocks,
      getReferencedColumn: (t) => t.propertyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaddocksTableAnnotationComposer(
            $db: $db,
            $table: $db.paddocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PropertiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PropertiesTable,
          Property,
          $$PropertiesTableFilterComposer,
          $$PropertiesTableOrderingComposer,
          $$PropertiesTableAnnotationComposer,
          $$PropertiesTableCreateCompanionBuilder,
          $$PropertiesTableUpdateCompanionBuilder,
          (Property, $$PropertiesTableReferences),
          Property,
          PrefetchHooks Function({bool paddocksRefs})
        > {
  $$PropertiesTableTableManager(_$AppDatabase db, $PropertiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PropertiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PropertiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PropertiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> pic = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropertiesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                pic: pic,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<String?> pic = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropertiesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                pic: pic,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PropertiesTable, Property>(table),
                  $$PropertiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({paddocksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (paddocksRefs) db.paddocks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (paddocksRefs)
                    await $_getPrefetchedData<
                      Property,
                      $PropertiesTable,
                      Paddock
                    >(
                      currentTable: table,
                      referencedTable: $$PropertiesTableReferences
                          ._paddocksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PropertiesTableReferences(
                            db,
                            table,
                            p0,
                          ).paddocksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.propertyId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PropertiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PropertiesTable,
      Property,
      $$PropertiesTableFilterComposer,
      $$PropertiesTableOrderingComposer,
      $$PropertiesTableAnnotationComposer,
      $$PropertiesTableCreateCompanionBuilder,
      $$PropertiesTableUpdateCompanionBuilder,
      (Property, $$PropertiesTableReferences),
      Property,
      PrefetchHooks Function({bool paddocksRefs})
    >;
typedef $$PaddocksTableCreateCompanionBuilder =
    PaddocksCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String propertyId,
      required String name,
      Value<double> hectares,
      Value<String?> boundary,
      Value<int> rowid,
    });
typedef $$PaddocksTableUpdateCompanionBuilder =
    PaddocksCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> propertyId,
      Value<String> name,
      Value<double> hectares,
      Value<String?> boundary,
      Value<int> rowid,
    });

final class $$PaddocksTableReferences
    extends BaseReferences<_$AppDatabase, $PaddocksTable, Paddock> {
  $$PaddocksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PropertiesTable _propertyIdTable(_$AppDatabase db) =>
      db.properties.createAlias('paddocks__property_id__properties__id');

  $$PropertiesTableProcessedTableManager get propertyId {
    final $_column = $_itemColumn<String>('property_id')!;

    final manager = $$PropertiesTableTableManager(
      $_db,
      $_db.properties,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_propertyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MovementsTable, List<Movement>>
  _movementsOutTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.movements,
    aliasName: 'paddocks__id__movements__from_paddock_id',
  );

  $$MovementsTableProcessedTableManager get movementsOut {
    final manager = $$MovementsTableTableManager(
      $_db,
      $_db.movements,
    ).filter((f) => f.fromPaddockId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movementsOutTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MovementsTable, List<Movement>> _movementsInTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.movements,
    aliasName: 'paddocks__id__movements__to_paddock_id',
  );

  $$MovementsTableProcessedTableManager get movementsIn {
    final manager = $$MovementsTableTableManager(
      $_db,
      $_db.movements,
    ).filter((f) => f.toPaddockId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movementsInTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PaddocksTableFilterComposer
    extends Composer<_$AppDatabase, $PaddocksTable> {
  $$PaddocksTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hectares => $composableBuilder(
    column: $table.hectares,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boundary => $composableBuilder(
    column: $table.boundary,
    builder: (column) => ColumnFilters(column),
  );

  $$PropertiesTableFilterComposer get propertyId {
    final $$PropertiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableFilterComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movementsOut(
    Expression<bool> Function($$MovementsTableFilterComposer f) f,
  ) {
    final $$MovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.fromPaddockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableFilterComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> movementsIn(
    Expression<bool> Function($$MovementsTableFilterComposer f) f,
  ) {
    final $$MovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.toPaddockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableFilterComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PaddocksTableOrderingComposer
    extends Composer<_$AppDatabase, $PaddocksTable> {
  $$PaddocksTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hectares => $composableBuilder(
    column: $table.hectares,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boundary => $composableBuilder(
    column: $table.boundary,
    builder: (column) => ColumnOrderings(column),
  );

  $$PropertiesTableOrderingComposer get propertyId {
    final $$PropertiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableOrderingComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaddocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaddocksTable> {
  $$PaddocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get hectares =>
      $composableBuilder(column: $table.hectares, builder: (column) => column);

  GeneratedColumn<String> get boundary =>
      $composableBuilder(column: $table.boundary, builder: (column) => column);

  $$PropertiesTableAnnotationComposer get propertyId {
    final $$PropertiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableAnnotationComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movementsOut<T extends Object>(
    Expression<T> Function($$MovementsTableAnnotationComposer a) f,
  ) {
    final $$MovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.fromPaddockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> movementsIn<T extends Object>(
    Expression<T> Function($$MovementsTableAnnotationComposer a) f,
  ) {
    final $$MovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.toPaddockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PaddocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaddocksTable,
          Paddock,
          $$PaddocksTableFilterComposer,
          $$PaddocksTableOrderingComposer,
          $$PaddocksTableAnnotationComposer,
          $$PaddocksTableCreateCompanionBuilder,
          $$PaddocksTableUpdateCompanionBuilder,
          (Paddock, $$PaddocksTableReferences),
          Paddock,
          PrefetchHooks Function({
            bool propertyId,
            bool movementsOut,
            bool movementsIn,
          })
        > {
  $$PaddocksTableTableManager(_$AppDatabase db, $PaddocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaddocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaddocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaddocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> propertyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> hectares = const Value.absent(),
                Value<String?> boundary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaddocksCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                propertyId: propertyId,
                name: name,
                hectares: hectares,
                boundary: boundary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String propertyId,
                required String name,
                Value<double> hectares = const Value.absent(),
                Value<String?> boundary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaddocksCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                propertyId: propertyId,
                name: name,
                hectares: hectares,
                boundary: boundary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaddocksTable, Paddock>(table),
                  $$PaddocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                propertyId = false,
                movementsOut = false,
                movementsIn = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movementsOut) db.movements,
                    if (movementsIn) db.movements,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (propertyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.propertyId,
                                    referencedTable: $$PaddocksTableReferences
                                        ._propertyIdTable(db),
                                    referencedColumn: $$PaddocksTableReferences
                                        ._propertyIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movementsOut)
                        await $_getPrefetchedData<
                          Paddock,
                          $PaddocksTable,
                          Movement
                        >(
                          currentTable: table,
                          referencedTable: $$PaddocksTableReferences
                              ._movementsOutTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PaddocksTableReferences(
                                db,
                                table,
                                p0,
                              ).movementsOut,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fromPaddockId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (movementsIn)
                        await $_getPrefetchedData<
                          Paddock,
                          $PaddocksTable,
                          Movement
                        >(
                          currentTable: table,
                          referencedTable: $$PaddocksTableReferences
                              ._movementsInTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PaddocksTableReferences(
                                db,
                                table,
                                p0,
                              ).movementsIn,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toPaddockId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PaddocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaddocksTable,
      Paddock,
      $$PaddocksTableFilterComposer,
      $$PaddocksTableOrderingComposer,
      $$PaddocksTableAnnotationComposer,
      $$PaddocksTableCreateCompanionBuilder,
      $$PaddocksTableUpdateCompanionBuilder,
      (Paddock, $$PaddocksTableReferences),
      Paddock,
      PrefetchHooks Function({
        bool propertyId,
        bool movementsOut,
        bool movementsIn,
      })
    >;
typedef $$TemplatesTableCreateCompanionBuilder =
    TemplatesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String name,
      Value<bool> isBuiltIn,
      Value<int> rowid,
    });
typedef $$TemplatesTableUpdateCompanionBuilder =
    TemplatesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<bool> isBuiltIn,
      Value<int> rowid,
    });

final class $$TemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $TemplatesTable, Template> {
  $$TemplatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LivestockClassesTable, List<LivestockClass>>
  _livestockClassesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.livestockClasses,
    aliasName: 'templates__id__livestock_classes__template_id',
  );

  $$LivestockClassesTableProcessedTableManager get livestockClassesRefs {
    final manager = $$LivestockClassesTableTableManager(
      $_db,
      $_db.livestockClasses,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _livestockClassesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> livestockClassesRefs(
    Expression<bool> Function($$LivestockClassesTableFilterComposer f) f,
  ) {
    final $$LivestockClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.livestockClasses,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivestockClassesTableFilterComposer(
            $db: $db,
            $table: $db.livestockClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  Expression<T> livestockClassesRefs<T extends Object>(
    Expression<T> Function($$LivestockClassesTableAnnotationComposer a) f,
  ) {
    final $$LivestockClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.livestockClasses,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivestockClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.livestockClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          Template,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (Template, $$TemplatesTableReferences),
          Template,
          PrefetchHooks Function({bool livestockClassesRefs})
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                isBuiltIn: isBuiltIn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                isBuiltIn: isBuiltIn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplatesTable, Template>(table),
                  $$TemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({livestockClassesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (livestockClassesRefs) db.livestockClasses,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (livestockClassesRefs)
                    await $_getPrefetchedData<
                      Template,
                      $TemplatesTable,
                      LivestockClass
                    >(
                      currentTable: table,
                      referencedTable: $$TemplatesTableReferences
                          ._livestockClassesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).livestockClassesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      Template,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (Template, $$TemplatesTableReferences),
      Template,
      PrefetchHooks Function({bool livestockClassesRefs})
    >;
typedef $$LivestockClassesTableCreateCompanionBuilder =
    LivestockClassesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String templateId,
      required String kind,
      Value<String?> breed,
      required String ageBand,
      Value<String?> agesIntoClassId,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$LivestockClassesTableUpdateCompanionBuilder =
    LivestockClassesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> templateId,
      Value<String> kind,
      Value<String?> breed,
      Value<String> ageBand,
      Value<String?> agesIntoClassId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$LivestockClassesTableReferences
    extends
        BaseReferences<_$AppDatabase, $LivestockClassesTable, LivestockClass> {
  $$LivestockClassesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.templates.createAlias('livestock_classes__template_id__templates__id');

  $$TemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$TemplatesTableTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MovementsTable, List<Movement>>
  _movementsOutTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.movements,
    aliasName: 'livestock_classes__id__movements__from_class_id',
  );

  $$MovementsTableProcessedTableManager get movementsOut {
    final manager = $$MovementsTableTableManager(
      $_db,
      $_db.movements,
    ).filter((f) => f.fromClassId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movementsOutTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MovementsTable, List<Movement>> _movementsInTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.movements,
    aliasName: 'livestock_classes__id__movements__to_class_id',
  );

  $$MovementsTableProcessedTableManager get movementsIn {
    final manager = $$MovementsTableTableManager(
      $_db,
      $_db.movements,
    ).filter((f) => f.toClassId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movementsInTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LivestockClassesTableFilterComposer
    extends Composer<_$AppDatabase, $LivestockClassesTable> {
  $$LivestockClassesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ageBand => $composableBuilder(
    column: $table.ageBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agesIntoClassId => $composableBuilder(
    column: $table.agesIntoClassId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplatesTableFilterComposer get templateId {
    final $$TemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movementsOut(
    Expression<bool> Function($$MovementsTableFilterComposer f) f,
  ) {
    final $$MovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.fromClassId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableFilterComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> movementsIn(
    Expression<bool> Function($$MovementsTableFilterComposer f) f,
  ) {
    final $$MovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.toClassId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableFilterComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LivestockClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $LivestockClassesTable> {
  $$LivestockClassesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ageBand => $composableBuilder(
    column: $table.ageBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agesIntoClassId => $composableBuilder(
    column: $table.agesIntoClassId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplatesTableOrderingComposer get templateId {
    final $$TemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LivestockClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LivestockClassesTable> {
  $$LivestockClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => column);

  GeneratedColumn<String> get ageBand =>
      $composableBuilder(column: $table.ageBand, builder: (column) => column);

  GeneratedColumn<String> get agesIntoClassId => $composableBuilder(
    column: $table.agesIntoClassId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$TemplatesTableAnnotationComposer get templateId {
    final $$TemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movementsOut<T extends Object>(
    Expression<T> Function($$MovementsTableAnnotationComposer a) f,
  ) {
    final $$MovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.fromClassId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> movementsIn<T extends Object>(
    Expression<T> Function($$MovementsTableAnnotationComposer a) f,
  ) {
    final $$MovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.toClassId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LivestockClassesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LivestockClassesTable,
          LivestockClass,
          $$LivestockClassesTableFilterComposer,
          $$LivestockClassesTableOrderingComposer,
          $$LivestockClassesTableAnnotationComposer,
          $$LivestockClassesTableCreateCompanionBuilder,
          $$LivestockClassesTableUpdateCompanionBuilder,
          (LivestockClass, $$LivestockClassesTableReferences),
          LivestockClass,
          PrefetchHooks Function({
            bool templateId,
            bool movementsOut,
            bool movementsIn,
          })
        > {
  $$LivestockClassesTableTableManager(
    _$AppDatabase db,
    $LivestockClassesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LivestockClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LivestockClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LivestockClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> breed = const Value.absent(),
                Value<String> ageBand = const Value.absent(),
                Value<String?> agesIntoClassId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LivestockClassesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                templateId: templateId,
                kind: kind,
                breed: breed,
                ageBand: ageBand,
                agesIntoClassId: agesIntoClassId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String templateId,
                required String kind,
                Value<String?> breed = const Value.absent(),
                required String ageBand,
                Value<String?> agesIntoClassId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LivestockClassesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                templateId: templateId,
                kind: kind,
                breed: breed,
                ageBand: ageBand,
                agesIntoClassId: agesIntoClassId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LivestockClassesTable, LivestockClass>(table),
                  $$LivestockClassesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                templateId = false,
                movementsOut = false,
                movementsIn = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movementsOut) db.movements,
                    if (movementsIn) db.movements,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.templateId,
                                    referencedTable:
                                        $$LivestockClassesTableReferences
                                            ._templateIdTable(db),
                                    referencedColumn:
                                        $$LivestockClassesTableReferences
                                            ._templateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movementsOut)
                        await $_getPrefetchedData<
                          LivestockClass,
                          $LivestockClassesTable,
                          Movement
                        >(
                          currentTable: table,
                          referencedTable: $$LivestockClassesTableReferences
                              ._movementsOutTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LivestockClassesTableReferences(
                                db,
                                table,
                                p0,
                              ).movementsOut,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fromClassId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (movementsIn)
                        await $_getPrefetchedData<
                          LivestockClass,
                          $LivestockClassesTable,
                          Movement
                        >(
                          currentTable: table,
                          referencedTable: $$LivestockClassesTableReferences
                              ._movementsInTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LivestockClassesTableReferences(
                                db,
                                table,
                                p0,
                              ).movementsIn,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toClassId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LivestockClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LivestockClassesTable,
      LivestockClass,
      $$LivestockClassesTableFilterComposer,
      $$LivestockClassesTableOrderingComposer,
      $$LivestockClassesTableAnnotationComposer,
      $$LivestockClassesTableCreateCompanionBuilder,
      $$LivestockClassesTableUpdateCompanionBuilder,
      (LivestockClass, $$LivestockClassesTableReferences),
      LivestockClass,
      PrefetchHooks Function({
        bool templateId,
        bool movementsOut,
        bool movementsIn,
      })
    >;
typedef $$MovementsTableCreateCompanionBuilder =
    MovementsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required DateTime occurredAt,
      required MovementKind kind,
      Value<String?> fromPaddockId,
      Value<String?> fromClassId,
      Value<String?> toPaddockId,
      Value<String?> toClassId,
      required int head,
      Value<EndState?> endState,
      Value<String?> note,
      required String actorId,
      Value<int> rowid,
    });
typedef $$MovementsTableUpdateCompanionBuilder =
    MovementsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> occurredAt,
      Value<MovementKind> kind,
      Value<String?> fromPaddockId,
      Value<String?> fromClassId,
      Value<String?> toPaddockId,
      Value<String?> toClassId,
      Value<int> head,
      Value<EndState?> endState,
      Value<String?> note,
      Value<String> actorId,
      Value<int> rowid,
    });

final class $$MovementsTableReferences
    extends BaseReferences<_$AppDatabase, $MovementsTable, Movement> {
  $$MovementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PaddocksTable _fromPaddockIdTable(_$AppDatabase db) =>
      db.paddocks.createAlias('movements__from_paddock_id__paddocks__id');

  $$PaddocksTableProcessedTableManager? get fromPaddockId {
    final $_column = $_itemColumn<String>('from_paddock_id');
    if ($_column == null) return null;
    final manager = $$PaddocksTableTableManager(
      $_db,
      $_db.paddocks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromPaddockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LivestockClassesTable _fromClassIdTable(_$AppDatabase db) => db
      .livestockClasses
      .createAlias('movements__from_class_id__livestock_classes__id');

  $$LivestockClassesTableProcessedTableManager? get fromClassId {
    final $_column = $_itemColumn<String>('from_class_id');
    if ($_column == null) return null;
    final manager = $$LivestockClassesTableTableManager(
      $_db,
      $_db.livestockClasses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromClassIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PaddocksTable _toPaddockIdTable(_$AppDatabase db) =>
      db.paddocks.createAlias('movements__to_paddock_id__paddocks__id');

  $$PaddocksTableProcessedTableManager? get toPaddockId {
    final $_column = $_itemColumn<String>('to_paddock_id');
    if ($_column == null) return null;
    final manager = $$PaddocksTableTableManager(
      $_db,
      $_db.paddocks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toPaddockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LivestockClassesTable _toClassIdTable(_$AppDatabase db) => db
      .livestockClasses
      .createAlias('movements__to_class_id__livestock_classes__id');

  $$LivestockClassesTableProcessedTableManager? get toClassId {
    final $_column = $_itemColumn<String>('to_class_id');
    if ($_column == null) return null;
    final manager = $$LivestockClassesTableTableManager(
      $_db,
      $_db.livestockClasses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toClassIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MovementsTableFilterComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MovementKind, MovementKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get head => $composableBuilder(
    column: $table.head,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EndState?, EndState, String> get endState =>
      $composableBuilder(
        column: $table.endState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  $$PaddocksTableFilterComposer get fromPaddockId {
    final $$PaddocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromPaddockId,
      referencedTable: $db.paddocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaddocksTableFilterComposer(
            $db: $db,
            $table: $db.paddocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LivestockClassesTableFilterComposer get fromClassId {
    final $$LivestockClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromClassId,
      referencedTable: $db.livestockClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivestockClassesTableFilterComposer(
            $db: $db,
            $table: $db.livestockClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaddocksTableFilterComposer get toPaddockId {
    final $$PaddocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toPaddockId,
      referencedTable: $db.paddocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaddocksTableFilterComposer(
            $db: $db,
            $table: $db.paddocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LivestockClassesTableFilterComposer get toClassId {
    final $$LivestockClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toClassId,
      referencedTable: $db.livestockClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivestockClassesTableFilterComposer(
            $db: $db,
            $table: $db.livestockClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get head => $composableBuilder(
    column: $table.head,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endState => $composableBuilder(
    column: $table.endState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PaddocksTableOrderingComposer get fromPaddockId {
    final $$PaddocksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromPaddockId,
      referencedTable: $db.paddocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaddocksTableOrderingComposer(
            $db: $db,
            $table: $db.paddocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LivestockClassesTableOrderingComposer get fromClassId {
    final $$LivestockClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromClassId,
      referencedTable: $db.livestockClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivestockClassesTableOrderingComposer(
            $db: $db,
            $table: $db.livestockClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaddocksTableOrderingComposer get toPaddockId {
    final $$PaddocksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toPaddockId,
      referencedTable: $db.paddocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaddocksTableOrderingComposer(
            $db: $db,
            $table: $db.paddocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LivestockClassesTableOrderingComposer get toClassId {
    final $$LivestockClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toClassId,
      referencedTable: $db.livestockClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivestockClassesTableOrderingComposer(
            $db: $db,
            $table: $db.livestockClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MovementKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get head =>
      $composableBuilder(column: $table.head, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EndState?, String> get endState =>
      $composableBuilder(column: $table.endState, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  $$PaddocksTableAnnotationComposer get fromPaddockId {
    final $$PaddocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromPaddockId,
      referencedTable: $db.paddocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaddocksTableAnnotationComposer(
            $db: $db,
            $table: $db.paddocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LivestockClassesTableAnnotationComposer get fromClassId {
    final $$LivestockClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromClassId,
      referencedTable: $db.livestockClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivestockClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.livestockClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaddocksTableAnnotationComposer get toPaddockId {
    final $$PaddocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toPaddockId,
      referencedTable: $db.paddocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaddocksTableAnnotationComposer(
            $db: $db,
            $table: $db.paddocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LivestockClassesTableAnnotationComposer get toClassId {
    final $$LivestockClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toClassId,
      referencedTable: $db.livestockClasses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LivestockClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.livestockClasses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovementsTable,
          Movement,
          $$MovementsTableFilterComposer,
          $$MovementsTableOrderingComposer,
          $$MovementsTableAnnotationComposer,
          $$MovementsTableCreateCompanionBuilder,
          $$MovementsTableUpdateCompanionBuilder,
          (Movement, $$MovementsTableReferences),
          Movement,
          PrefetchHooks Function({
            bool fromPaddockId,
            bool fromClassId,
            bool toPaddockId,
            bool toClassId,
          })
        > {
  $$MovementsTableTableManager(_$AppDatabase db, $MovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<MovementKind> kind = const Value.absent(),
                Value<String?> fromPaddockId = const Value.absent(),
                Value<String?> fromClassId = const Value.absent(),
                Value<String?> toPaddockId = const Value.absent(),
                Value<String?> toClassId = const Value.absent(),
                Value<int> head = const Value.absent(),
                Value<EndState?> endState = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> actorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovementsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                occurredAt: occurredAt,
                kind: kind,
                fromPaddockId: fromPaddockId,
                fromClassId: fromClassId,
                toPaddockId: toPaddockId,
                toClassId: toClassId,
                head: head,
                endState: endState,
                note: note,
                actorId: actorId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime occurredAt,
                required MovementKind kind,
                Value<String?> fromPaddockId = const Value.absent(),
                Value<String?> fromClassId = const Value.absent(),
                Value<String?> toPaddockId = const Value.absent(),
                Value<String?> toClassId = const Value.absent(),
                required int head,
                Value<EndState?> endState = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String actorId,
                Value<int> rowid = const Value.absent(),
              }) => MovementsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                occurredAt: occurredAt,
                kind: kind,
                fromPaddockId: fromPaddockId,
                fromClassId: fromClassId,
                toPaddockId: toPaddockId,
                toClassId: toClassId,
                head: head,
                endState: endState,
                note: note,
                actorId: actorId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MovementsTable, Movement>(table),
                  $$MovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                fromPaddockId = false,
                fromClassId = false,
                toPaddockId = false,
                toClassId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (fromPaddockId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromPaddockId,
                                    referencedTable: $$MovementsTableReferences
                                        ._fromPaddockIdTable(db),
                                    referencedColumn: $$MovementsTableReferences
                                        ._fromPaddockIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (fromClassId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromClassId,
                                    referencedTable: $$MovementsTableReferences
                                        ._fromClassIdTable(db),
                                    referencedColumn: $$MovementsTableReferences
                                        ._fromClassIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (toPaddockId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toPaddockId,
                                    referencedTable: $$MovementsTableReferences
                                        ._toPaddockIdTable(db),
                                    referencedColumn: $$MovementsTableReferences
                                        ._toPaddockIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (toClassId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toClassId,
                                    referencedTable: $$MovementsTableReferences
                                        ._toClassIdTable(db),
                                    referencedColumn: $$MovementsTableReferences
                                        ._toClassIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$MovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovementsTable,
      Movement,
      $$MovementsTableFilterComposer,
      $$MovementsTableOrderingComposer,
      $$MovementsTableAnnotationComposer,
      $$MovementsTableCreateCompanionBuilder,
      $$MovementsTableUpdateCompanionBuilder,
      (Movement, $$MovementsTableReferences),
      Movement,
      PrefetchHooks Function({
        bool fromPaddockId,
        bool fromClassId,
        bool toPaddockId,
        bool toClassId,
      })
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PropertiesTableTableManager get properties =>
      $$PropertiesTableTableManager(_db, _db.properties);
  $$PaddocksTableTableManager get paddocks =>
      $$PaddocksTableTableManager(_db, _db.paddocks);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$LivestockClassesTableTableManager get livestockClasses =>
      $$LivestockClassesTableTableManager(_db, _db.livestockClasses);
  $$MovementsTableTableManager get movements =>
      $$MovementsTableTableManager(_db, _db.movements);
}
