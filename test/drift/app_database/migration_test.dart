// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('a v1 farm comes through the upgrade to v2 untouched', () async {
    const at = '2026-10-01T00:00:00.000Z';

    final oldPropertiesData = [
      const v1.PropertiesData(
        id: 'riverbend',
        createdAt: at,
        updatedAt: at,
        name: 'Riverbend Downs',
        pic: 'QDEV0001',
      ),
    ];
    final expectedNewPropertiesData = [
      const v2.PropertiesData(
        id: 'riverbend',
        createdAt: at,
        updatedAt: at,
        name: 'Riverbend Downs',
        pic: 'QDEV0001',
      ),
    ];

    final oldPaddocksData = [
      const v1.PaddocksData(
        id: 'north',
        createdAt: at,
        updatedAt: at,
        propertyId: 'riverbend',
        name: 'North Flat',
        hectares: 120,
      ),
    ];
    final expectedNewPaddocksData = [
      const v2.PaddocksData(
        id: 'north',
        createdAt: at,
        updatedAt: at,
        propertyId: 'riverbend',
        name: 'North Flat',
        hectares: 120,
      ),
    ];

    final oldTemplatesData = [
      const v1.TemplatesData(
        id: 'beef',
        createdAt: at,
        updatedAt: at,
        name: 'Beef',
        isBuiltIn: 1,
      ),
    ];
    final expectedNewTemplatesData = [
      const v2.TemplatesData(
        id: 'beef',
        createdAt: at,
        updatedAt: at,
        name: 'Beef',
        isBuiltIn: 1,
      ),
    ];

    final oldLivestockClassesData = [
      const v1.LivestockClassesData(
        id: 'calves',
        createdAt: at,
        updatedAt: at,
        templateId: 'beef',
        kind: 'Calves',
        ageBand: 'under 6 months',
        sortOrder: 0,
      ),
    ];
    final expectedNewLivestockClassesData = [
      const v2.LivestockClassesData(
        id: 'calves',
        createdAt: at,
        updatedAt: at,
        templateId: 'beef',
        kind: 'Calves',
        ageBand: 'under 6 months',
        sortOrder: 0,
      ),
    ];

    final oldMovementsData = [
      const v1.MovementsData(
        id: 'intake',
        createdAt: at,
        updatedAt: at,
        occurredAt: at,
        kind: 'intake',
        toPaddockId: 'north',
        toClassId: 'calves',
        head: 120,
        actorId: 'local',
      ),
    ];
    final expectedNewMovementsData = [
      const v2.MovementsData(
        id: 'intake',
        createdAt: at,
        updatedAt: at,
        occurredAt: at,
        kind: 'intake',
        toPaddockId: 'north',
        toClassId: 'calves',
        head: 120,
        actorId: 'local',
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.properties, oldPropertiesData);
        batch.insertAll(oldDb.paddocks, oldPaddocksData);
        batch.insertAll(oldDb.templates, oldTemplatesData);
        batch.insertAll(oldDb.livestockClasses, oldLivestockClassesData);
        batch.insertAll(oldDb.movements, oldMovementsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewPropertiesData,
          await newDb.select(newDb.properties).get(),
        );
        expect(
          expectedNewPaddocksData,
          await newDb.select(newDb.paddocks).get(),
        );
        expect(
          expectedNewTemplatesData,
          await newDb.select(newDb.templates).get(),
        );
        expect(
          expectedNewLivestockClassesData,
          await newDb.select(newDb.livestockClasses).get(),
        );
        expect(
          expectedNewMovementsData,
          await newDb.select(newDb.movements).get(),
        );
        expect(await newDb.select(newDb.livestockTags).get(), isEmpty);
        expect(await newDb.select(newDb.movementTags).get(), isEmpty);
      },
    );
  });
}
