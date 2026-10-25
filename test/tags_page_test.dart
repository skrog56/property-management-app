import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';
import 'package:property_management_app/features/tags/tags_page.dart';
import 'package:property_management_app/shell/form_dialog.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late String north;

  TagNumber nlis(String raw) => TagNumber.tryParse(TagScheme.nlis, raw)!;
  final a = nlis('999000000000001');
  final b = nlis('999000000000002');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await seedBeefTemplate(db);
    final property = await repo.createProperty('Riverbend Downs');
    north = await repo.createPaddock(property, 'North Ridge');
  });

  tearDown(() => db.close());

  Future<void> stock() => repo.record(
    kind: MovementKind.intake,
    head: 5,
    toPaddockId: north,
    toClassId: 'calves',
    tags: [a, b],
  );

  Future<String> pathOf(TagNumber number) async =>
      '/tags/${(await repo.tagStatusByNumber(number))!.tag.id}';

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(FormDialog), matching: finder);

  testPage('says how tags get here when there are none', (tester) async {
    await pumpRouted(tester, repository: repo, location: '/tags');

    expect(find.textContaining('No tags yet'), findsOneWidget);
  });

  testPage('lists every tag and narrows to a search', (tester) async {
    await stock();
    await repo.record(
      kind: MovementKind.endState,
      head: 1,
      fromPaddockId: north,
      fromClassId: 'calves',
      endState: EndState.sold,
      tags: [b],
    );
    await pumpRouted(tester, repository: repo, location: '/tags');

    expect(find.text('999 000000000001'), findsOneWidget);
    expect(find.text('North Ridge · Calves'), findsOneWidget);
    expect(find.textContaining('Sold · '), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0002');
    await drain(tester);

    expect(find.text('999 000000000001'), findsNothing);
    expect(find.text('999 000000000002'), findsOneWidget);
  });

  testPage('a tag page says where it is and what happened to it', (
    tester,
  ) async {
    await stock();
    await pumpRouted(tester, repository: repo, location: await pathOf(a));

    expect(findRichText('In North Ridge, Riverbend Downs'), findsOneWidget);
    expect(findRichText('5 head · intake to North Ridge'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('999 000000000002'), findsOneWidget);
  });

  testPage('a tag is replaced from its page', (tester) async {
    await stock();
    await pumpRouted(tester, repository: repo, location: await pathOf(a));

    await tester.tap(find.text('Replace'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'New tag number'),
      '999 000000000003',
    );
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Replace')));
    await settle(tester);

    expect(findRichText('Replaced by 999 000000000003'), findsOneWidget);
    expect(find.text('Replace'), findsNothing);
    expect(
      (await repo.tagStatusByNumber(nlis('999000000000003')))!.isActive,
      isTrue,
    );
  });

  testPage('a replacement already in use is refused in the dialog', (
    tester,
  ) async {
    await stock();
    await pumpRouted(tester, repository: repo, location: await pathOf(a));

    await tester.tap(find.text('Replace'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'New tag number'),
      '999000000000002',
    );
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Replace')));
    await settle(tester);

    expect(
      find.text('Tag 999 000000000002 is already in North Ridge'),
      findsOneWidget,
    );
    expect((await repo.tagStatusByNumber(a))!.isActive, isTrue);
  });

  testPage('a tag is cancelled from its page, leaving the head', (
    tester,
  ) async {
    await stock();
    await pumpRouted(tester, repository: repo, location: await pathOf(a));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel tag'));
    await settle(tester);
    expect(find.text('Keep tag'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<TagReason>));
    await settle(tester);
    await tester.tap(find.text('lost').last);
    await settle(tester);
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Cancel tag')));
    await settle(tester);

    expect(find.textContaining('Cancelled · lost'), findsOneWidget);
    expect(await repo.headIn(north, 'calves'), 5);
  });

  testPage('an unknown tag says it is gone', (tester) async {
    await pumpRouted(tester, repository: repo, location: '/tags/nope');

    expect(find.text('This tag is gone.'), findsOneWidget);
  });

  testPage('a wide window keeps the searched list beside the tag', (
    tester,
  ) async {
    await stock();
    await pumpRouted(tester, repository: repo, location: '/tags', width: 1200);
    expect(find.text('Select a tag'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0001');
    await drain(tester);
    await tester.tap(find.text('999 000000000001'));
    await settle(tester);

    // 0002 still shows in the history, having arrived in the same intake.
    expect(findRichText('In North Ridge, Riverbend Downs'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TagsPage),
        matching: find.text('999 000000000002'),
      ),
      findsNothing,
    );
    expect(find.text('Select a tag'), findsNothing);
  });

  testPage('a tag named in Activity opens its page', (tester) async {
    await stock();
    await pumpRouted(tester, repository: repo, location: '/activity');

    await tester.tap(find.text('999 000000000001'));
    await settle(tester);

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(findRichText('In North Ridge, Riverbend Downs'), findsOneWidget);
  });

  testPage('every tags page lays out without overflow at every width', (
    tester,
  ) async {
    await stock();

    for (final location in ['/tags', await pathOf(a)]) {
      for (final width in [360.0, 700.0, 1000.0, 1300.0, 1900.0]) {
        await pumpRouted(
          tester,
          repository: repo,
          location: location,
          width: width,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '$location at ${width}px',
        );
      }
    }
  });
}
