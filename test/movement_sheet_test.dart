import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/features/transfers/movement_sheet.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late String property;
  late String north;
  late String creek;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await seedBeefTemplate(db);
    property = await repo.createProperty('Skrog Downs');
    north = await repo.createPaddock(property, 'North Ridge');
    creek = await repo.createPaddock(property, 'Creek Flat');
  });

  tearDown(() => db.close());

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMovementSheet(
                context,
                repository: repo,
                propertyId: property,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await drain(tester);
  }

  Future<void> pick(
    WidgetTester tester,
    String fieldLabel,
    String itemText,
  ) async {
    await tester.tap(
      find
          .ancestor(
            of: find.text(fieldLabel),
            matching: find.byType(DropdownButtonFormField<String>),
          )
          .first,
    );
    await drain(tester);
    await tester.tap(find.text(itemText).last);
    await drain(tester);
  }

  testPage('records an intake and closes', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Intake'));
    await drain(tester);

    await pick(tester, 'Class', 'Calves (under 6 months)');
    await pick(tester, 'Into', 'North Ridge');
    await tester.enterText(find.widgetWithText(TextField, 'Head'), '40');
    await drain(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Record'));
    await drain(tester);

    expect(await repo.headIn(north, 'calves'), 40);
    expect(find.text('Record movement'), findsNothing);
  });

  testPage('blocks a move of more head than the paddock holds', (tester) async {
    await repo.record(
      kind: MovementKind.intake,
      head: 10,
      toPaddockId: north,
      toClassId: 'calves',
    );

    await openSheet(tester);
    await pick(tester, 'From paddock', 'North Ridge');
    await pick(tester, 'Mob', '10 × Calves (under 6 months)');
    await pick(tester, 'To paddock', 'Creek Flat');
    await tester.enterText(find.widgetWithText(TextField, 'Head'), '11');
    await drain(tester);

    expect(find.text('Only 10 head available'), findsOneWidget);
    expect(await repo.headIn(creek, 'calves'), 0);
  });

  testPage('ageing preselects the class from the template chain', (
    tester,
  ) async {
    await repo.record(
      kind: MovementKind.intake,
      head: 20,
      toPaddockId: north,
      toClassId: 'calves',
    );

    await openSheet(tester);
    await tester.tap(find.text('Age'));
    await drain(tester);

    await pick(tester, 'From paddock', 'North Ridge');
    await pick(tester, 'Mob', '20 × Calves (under 6 months)');

    // The chain says calves age into weaners, so no destination is asked for.
    expect(find.text('Weaners (6-12 months)'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Head'), '20');
    await drain(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Record'));
    await drain(tester);

    expect(await repo.headIn(north, 'calves'), 0);
    expect(await repo.headIn(north, 'weaners'), 20);
  });
}
