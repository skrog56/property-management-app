// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

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
  test(
    'a v2 farm keeps its properties and paddocks and loses the rest',
    () async {
      const at = '2026-11-01T00:00:00.000Z';

      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insert(
            oldDb.properties,
            const v2.PropertiesData(
              id: 'riverbend',
              createdAt: at,
              updatedAt: at,
              name: 'Riverbend Downs',
              pic: 'QDEV0001',
            ),
          );
          batch.insert(
            oldDb.paddocks,
            const v2.PaddocksData(
              id: 'north',
              createdAt: at,
              updatedAt: at,
              propertyId: 'riverbend',
              name: 'North Flat',
              hectares: 120,
            ),
          );
          batch.insert(
            oldDb.templates,
            const v2.TemplatesData(
              id: 'beef',
              createdAt: at,
              updatedAt: at,
              name: 'Beef',
              isBuiltIn: 1,
            ),
          );
          batch.insert(
            oldDb.livestockClasses,
            const v2.LivestockClassesData(
              id: 'calves',
              createdAt: at,
              updatedAt: at,
              templateId: 'beef',
              kind: 'Calves',
              ageBand: 'under 6 months',
              sortOrder: 0,
            ),
          );
          batch.insert(
            oldDb.movements,
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
          );
          batch.insert(
            oldDb.livestockTags,
            const v2.LivestockTagsData(
              id: 'tag',
              createdAt: at,
              updatedAt: at,
              scheme: 'nlis',
              number: '999000000000001',
            ),
          );
          batch.insert(
            oldDb.movementTags,
            const v2.MovementTagsData(
              id: 'link',
              createdAt: at,
              updatedAt: at,
              movementId: 'intake',
              tagId: 'tag',
              role: 'added',
            ),
          );
        },
        validateItems: (newDb) async {
          expect(await newDb.select(newDb.properties).get(), [
            const v3.PropertiesData(
              id: 'riverbend',
              createdAt: at,
              updatedAt: at,
              name: 'Riverbend Downs',
              pic: 'QDEV0001',
            ),
          ]);
          expect(await newDb.select(newDb.paddocks).get(), [
            const v3.PaddocksData(
              id: 'north',
              createdAt: at,
              updatedAt: at,
              propertyId: 'riverbend',
              name: 'North Flat',
              hectares: 120,
            ),
          ]);
          expect(await newDb.select(newDb.templates).get(), isEmpty);
          expect(await newDb.select(newDb.livestockClasses).get(), isEmpty);
          expect(await newDb.select(newDb.movements).get(), isEmpty);
          expect(await newDb.select(newDb.livestockTags).get(), isEmpty);
          expect(await newDb.select(newDb.movementTags).get(), isEmpty);
          expect(
            await newDb.customSelect('PRAGMA foreign_key_check').get(),
            isEmpty,
          );
        },
      );
    },
  );

  test('a v3 farm keeps everything, its templates becoming cattle', () async {
    const at = '2026-11-09T00:00:00.000Z';

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.properties,
          const v3.PropertiesData(
            id: 'riverbend',
            createdAt: at,
            updatedAt: at,
            name: 'Riverbend Downs',
          ),
        );
        batch.insert(
          oldDb.paddocks,
          const v3.PaddocksData(
            id: 'north',
            createdAt: at,
            updatedAt: at,
            propertyId: 'riverbend',
            name: 'North Flat',
            hectares: 120,
          ),
        );
        batch.insertAll(oldDb.templates, const [
          v3.TemplatesData(
            id: 'feeders',
            createdAt: at,
            updatedAt: at,
            name: 'Feeders',
            isBuiltIn: 1,
            sortOrder: 2,
          ),
          v3.TemplatesData(
            id: 'retired',
            createdAt: at,
            updatedAt: at,
            deletedAt: at,
            name: 'Retired',
            isBuiltIn: 0,
            sortOrder: 4,
          ),
        ]);
        batch.insert(
          oldDb.livestockClasses,
          const v3.LivestockClassesData(
            id: 'steers',
            createdAt: at,
            updatedAt: at,
            templateId: 'feeders',
            kind: 'Steers',
            sortOrder: 0,
          ),
        );
        batch.insert(
          oldDb.movements,
          const v3.MovementsData(
            id: 'intake',
            createdAt: at,
            updatedAt: at,
            occurredAt: at,
            kind: 'intake',
            toPaddockId: 'north',
            toClassId: 'steers',
            head: 40,
            actorId: 'local',
          ),
        );
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.templates).get(), const [
          v4.TemplatesData(
            id: 'feeders',
            createdAt: at,
            updatedAt: at,
            name: 'Feeders',
            isBuiltIn: 1,
            sortOrder: 2,
            species: 'cattle',
          ),
          v4.TemplatesData(
            id: 'retired',
            createdAt: at,
            updatedAt: at,
            deletedAt: at,
            name: 'Retired',
            isBuiltIn: 0,
            sortOrder: 4,
            species: 'cattle',
          ),
        ]);
        expect(await newDb.select(newDb.properties).get(), hasLength(1));
        expect(await newDb.select(newDb.paddocks).get(), hasLength(1));
        expect(await newDb.select(newDb.livestockClasses).get(), [
          const v4.LivestockClassesData(
            id: 'steers',
            createdAt: at,
            updatedAt: at,
            templateId: 'feeders',
            kind: 'Steers',
            sortOrder: 0,
          ),
        ]);
        expect(await newDb.select(newDb.movements).get(), [
          const v4.MovementsData(
            id: 'intake',
            createdAt: at,
            updatedAt: at,
            occurredAt: at,
            kind: 'intake',
            toPaddockId: 'north',
            toClassId: 'steers',
            head: 40,
            actorId: 'local',
          ),
        ]);
      },
    );
  });
}
