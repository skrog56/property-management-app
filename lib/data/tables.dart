import 'package:drift/drift.dart';

/// All four kinds share one row shape, so the Activity view is this table
/// rendered, and one form serves every operation.
enum MovementKind { intake, move, age, endState }

enum EndState { meatworks, sold, died, lost, other }

/// UUID keys and soft deletes, because sync lands later and neither can be
/// retrofitted: independently generated integer ids collide, and a hard delete
/// cannot be replicated to a device that never saw the row.
mixin SyncSafe on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Properties extends Table with SyncSafe {
  TextColumn get name => text()();

  /// Property Identification Code, for if compliance reporting ever lands.
  TextColumn get pic => text().nullable()();
}

class Paddocks extends Table with SyncSafe {
  TextColumn get propertyId => text().references(Properties, #id)();
  TextColumn get name => text()();
  RealColumn get hectares => real().withDefault(const Constant(0))();

  /// GeoJSON polygon, filled in when map drawing lands.
  TextColumn get boundary => text().nullable()();
}

class Templates extends Table with SyncSafe {
  TextColumn get name => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
}

@DataClassName('LivestockClass')
class LivestockClasses extends Table with SyncSafe {
  TextColumn get templateId => text().references(Templates, #id)();
  TextColumn get kind => text()();
  TextColumn get breed => text().nullable()();
  TextColumn get ageBand => text()();

  /// Makes aging one tap instead of a class picker.
  TextColumn get agesIntoClassId => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Append-only. Paddock head counts are derived from this table, never stored.
class Movements extends Table with SyncSafe {
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get kind => textEnum<MovementKind>()();

  /// Null on intake.
  @ReferenceName('movementsOut')
  TextColumn get fromPaddockId => text().nullable().references(Paddocks, #id)();
  @ReferenceName('movementsOut')
  TextColumn get fromClassId =>
      text().nullable().references(LivestockClasses, #id)();

  /// Null on endState.
  @ReferenceName('movementsIn')
  TextColumn get toPaddockId => text().nullable().references(Paddocks, #id)();
  @ReferenceName('movementsIn')
  TextColumn get toClassId =>
      text().nullable().references(LivestockClasses, #id)();

  IntColumn get head => integer()();
  TextColumn get endState => textEnum<EndState>().nullable()();
  TextColumn get note => text().nullable()();

  /// Local placeholder until accounts exist.
  TextColumn get actorId => text()();
}
