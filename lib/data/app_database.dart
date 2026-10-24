import 'package:drift/drift.dart';

import 'app_database.steps.dart';
import 'connection/connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Properties,
    Paddocks,
    Templates,
    LivestockClasses,
    Movements,
    LivestockTags,
    MovementTags,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.livestockTags);
        await m.createTable(schema.movementTags);
        // createTable leaves out indexes, which are separate entities.
        await m.create(schema.livestockTagsNumber);
        await m.create(schema.movementTagsTag);
        await m.create(schema.movementTagsMovement);
      },
    ),
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
