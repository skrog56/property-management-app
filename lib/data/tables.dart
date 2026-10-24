import 'package:drift/drift.dart';

/// Every kind shares one row shape, so the Activity view is this table
/// rendered. A [tag] event moves nothing: its from and to are the same mob, so
/// it nets to zero, and it exists to carry its [MovementTags].
enum MovementKind { intake, move, age, endState, tag }

enum EndState { meatworks, sold, died, lost, other }

/// An NLIS device carries two numbers, the 16-character NLIS ID printed on it
/// and the 15-digit RFID it transmits. Either may be recorded under [nlis].
enum TagScheme { nlis, other }

/// What a movement did to a tag. A tag is wherever its latest link left it,
/// unless that link removed it.
enum TagRole { added, carried, removed }

enum TagReason { lost, damaged, error, other }

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

/// One identifier, standing for one of its mob's head. Where it is now is
/// derived from [MovementTags], never stored. Not named `Tags`, which
/// `flutter_test` also exports.
@DataClassName('LivestockTag')
@TableIndex(
  name: 'livestock_tags_number',
  columns: {#scheme, #number},
  unique: true,
)
class LivestockTags extends Table with SyncSafe {
  TextColumn get scheme => textEnum<TagScheme>()();

  /// Normalised by `TagNumber`: uppercase, no whitespace.
  TextColumn get number => text()();
}

/// Which tags each movement touched. Append-only, like [Movements].
@TableIndex(name: 'movement_tags_tag', columns: {#tagId})
@TableIndex(name: 'movement_tags_movement', columns: {#movementId})
class MovementTags extends Table with SyncSafe {
  TextColumn get movementId => text().references(Movements, #id)();
  TextColumn get tagId => text().references(LivestockTags, #id)();
  TextColumn get role => textEnum<TagRole>()();

  /// Set only when [role] is removed.
  TextColumn get reason => textEnum<TagReason>().nullable()();
}
