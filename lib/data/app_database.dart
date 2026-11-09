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
  int get schemaVersion => 4;

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
      // Replaced rather than converted: nobody uses the app yet, and every
      // movement names a class, so the ledger goes with the old templates.
      from2To3: (m, schema) async {
        for (final table in ['movement_tags', 'livestock_tags', 'movements']) {
          await customStatement('DELETE FROM $table');
        }
        await m.deleteTable('livestock_classes');
        await m.deleteTable('templates');
        await m.createTable(schema.templates);
        await m.createTable(schema.livestockClasses);
      },
      from3To4: (m, schema) =>
          m.addColumn(schema.templates, schema.templates.species),
    ),
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
