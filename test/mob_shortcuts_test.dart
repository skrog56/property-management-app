import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/app/locale.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/app_settings.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';
import 'package:property_management_app/features/transfers/movement_dialog.dart';

import 'support.dart';

/// Record death and ready to sell, the shortcuts on a mob, on the real
/// default templates.
void main() {
  // setUp seeds the defaults from the asset bundle, before any widget test
  // has started the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LivestockRepository repo;
  late String property;
  late String north;
  late Map<String, String> classIds;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await repo.seedTemplatesIfEmpty();
    classIds = {for (final c in await repo.allClasses()) c.label: c.id};
    property = await repo.createProperty('Riverbend Downs');
    north = await repo.createPaddock(property, 'North Ridge');
  });

  tearDown(() => db.close());

  final a = TagNumber.tryParse(TagScheme.nlis, '999000000000001')!;
  final b = TagNumber.tryParse(TagScheme.nlis, '999000000000002')!;

  Future<void> intake(String label, int head, {List<TagNumber>? tags}) =>
      repo.record(
        kind: MovementKind.intake,
        head: head,
        toPaddockId: north,
        toClassId: classIds[label]!,
        tags: tags ?? const [],
      );

  Future<Paddock> paddock() async =>
      (await repo.paddocksIn(property)).singleWhere((p) => p.id == north);

  Future<MobLine> mob(String label) async =>
      (await repo.mobsIn(north)).singleWhere((m) => m.label == label);

  Future<void> open(
    WidgetTester tester,
    Future<void> Function(BuildContext context) show,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: appLocale,
        supportedLocales: const [appLocale],
        localizationsDelegates: appLocalizations,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await drain(tester);
  }

  Finder record() => find.widgetWithText(FilledButton, 'Record');

  bool recordEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(record()).onPressed != null;

  bool isWrong(WidgetTester tester, String label) =>
      tester
          .widget<InputDecorator>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(InputDecorator),
                )
                .first,
          )
          .decoration
          .error !=
      null;

  Future<List<Movement>> deaths() =>
      repo.watchActivity(endStates: {EndState.died}).first;

  /// Through the picker's typed entry, which does not depend on today.
  Future<void> enterDate(WidgetTester tester, String date) async {
    await tester.tap(find.widgetWithText(TextField, 'Date'));
    await drain(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await drain(tester);
    await tester.enterText(find.byType(TextField).last, date);
    await tester.tap(find.text('OK'));
    await drain(tester);
  }

  group('Record death', () {
    testPage('records one head from a mob, with its cause', (tester) async {
      await intake('Steers (Feeders)', 10);
      final paddock_ = await paddock();
      final steers = await mob('Steers (Feeders)');
      await open(
        tester,
        (context) => showDeathDialog(
          context,
          repository: repo,
          paddock: paddock_,
          mob: steers,
        ),
      );

      expect(find.text('Record death'), findsOneWidget);
      expect(find.byType(SegmentedButton<MovementKind>), findsNothing);
      expect(find.text('Destination'), findsNothing);
      expect(find.text('10 × Steers (Feeders)'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Cause or note (optional)'),
        'Snake bite',
      );
      await tester.tap(record());
      await drain(tester);

      expect(await repo.headIn(north, classIds['Steers (Feeders)']!), 9);
      final death = (await deaths()).single;
      expect(death.head, 1);
      expect(death.note, 'Snake bite');
    });

    testPage('from the paddock, chooses the only mob there', (tester) async {
      await intake('Calves (Breeder)', 5);
      final paddock_ = await paddock();
      await open(
        tester,
        (context) =>
            showDeathDialog(context, repository: repo, paddock: paddock_),
      );

      expect(find.text('5 × Calves (Breeder)'), findsOneWidget);
      expect(recordEnabled(tester), isTrue);
    });

    testPage('from the paddock, asks which mob when there are more', (
      tester,
    ) async {
      await intake('Calves (Breeder)', 5);
      await intake('Cows (Breeder)', 5);
      final paddock_ = await paddock();
      await open(
        tester,
        (context) =>
            showDeathDialog(context, repository: repo, paddock: paddock_),
      );

      expect(find.text('Choose a mob'), findsOneWidget);
      expect(recordEnabled(tester), isFalse);
    });

    testPage('dates a death found on an earlier day to the end of it', (
      tester,
    ) async {
      await intake('Calves (Breeder)', 5);
      final paddock_ = await paddock();
      final calves = await mob('Calves (Breeder)');
      await open(
        tester,
        (context) => showDeathDialog(
          context,
          repository: repo,
          paddock: paddock_,
          mob: calves,
        ),
      );

      // Asked for day first, as the app writes dates, not the US order.
      await tester.tap(find.widgetWithText(TextField, 'Date'));
      await drain(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await drain(tester);
      expect(find.text('dd/mm/yyyy'), findsWidgets);
      // The picker's, above the form's own.
      await tester.tap(find.text('Cancel').last);
      await drain(tester);

      await enterDate(tester, '15/01/2001');
      expect(find.text('15/01/2001'), findsOneWidget);
      await tester.tap(record());
      await drain(tester);

      expect(
        (await deaths()).single.occurredAt.toLocal(),
        DateTime(2001, 1, 15, 23, 59, 59),
      );
    });

    testPage('will not date a death before its tag last moved', (tester) async {
      await intake('Calves (Breeder)', 1, tags: [a]);
      final paddock_ = await paddock();
      final calves = await mob('Calves (Breeder)');
      await open(
        tester,
        (context) => showDeathDialog(
          context,
          repository: repo,
          paddock: paddock_,
          mob: calves,
        ),
      );

      // The one head is the one tag, so it is chosen already.
      expect(find.text('Tags to remove · 1 of 1'), findsOneWidget);
      expect(recordEnabled(tester), isTrue);

      await enterDate(tester, '15/01/2001');
      expect(find.textContaining('after that date'), findsOneWidget);
      expect(isWrong(tester, 'Date'), isTrue);
      expect(recordEnabled(tester), isFalse);
    });
  });

  group('Ready to sell', () {
    testPage('marks head of a mob, and takes them off again', (tester) async {
      await intake('Steers (Feeders)', 10);
      final paddock_ = await paddock();
      final steers = await mob('Steers (Feeders)');
      await open(
        tester,
        (context) => showReadyToSellDialog(
          context,
          repository: repo,
          paddock: paddock_,
          mob: steers,
        ),
      );

      expect(find.text('Mark ready to sell'), findsOneWidget);
      expect(find.text('Steers (Feeders) in North Ridge'), findsOneWidget);
      expect(find.text('Mob'), findsNothing);
      await tester.enterText(find.widgetWithText(TextField, 'Head'), '4');
      await drain(tester);
      await tester.tap(record());
      await drain(tester);

      final ready = classIds['Steers (Feeders) · ready to sell']!;
      expect(await repo.headIn(north, ready), 4);

      final readySteers = await mob('Steers (Feeders) · ready to sell');
      await open(
        tester,
        (context) => showReadyToSellDialog(
          context,
          repository: repo,
          paddock: paddock_,
          mob: readySteers,
        ),
      );
      expect(find.text('No longer ready to sell'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Head'), '1');
      await drain(tester);
      await tester.tap(record());
      await drain(tester);

      expect(await repo.headIn(north, ready), 3);
      expect(await repo.headIn(north, classIds['Steers (Feeders)']!), 7);
      final kinds = [for (final m in await repo.watchActivity().first) m.kind];
      expect(kinds.take(2), everyElement(MovementKind.readyToSell));
    });

    testPage('asks which tags are ready when untagged head cannot cover it', (
      tester,
    ) async {
      await intake('Steers (Feeders)', 2, tags: [a, b]);
      final paddock_ = await paddock();
      final steers = await mob('Steers (Feeders)');
      await open(
        tester,
        (context) => showReadyToSellDialog(
          context,
          repository: repo,
          paddock: paddock_,
          mob: steers,
        ),
      );

      await tester.enterText(find.widgetWithText(TextField, 'Head'), '1');
      await drain(tester);
      expect(find.text('Select 1 more tag'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, '999 000000000002'));
      await drain(tester);
      await tester.tap(record());
      await drain(tester);

      final status = await repo.tagStatusByNumber(b);
      expect(status!.stockClass!.label, 'Steers (Feeders) · ready to sell');
      expect(
        (await repo.tagStatusByNumber(a))!.stockClass!.label,
        'Steers (Feeders)',
      );
    });

    testPage('is never an Age target, which follows chains across templates', (
      tester,
    ) async {
      await intake('Steers (Backgrounders)', 10);
      await open(
        tester,
        (context) => showMovementDialog(
          context,
          repository: repo,
          propertyId: property,
          fromPaddockId: north,
        ),
      );
      await tester.tap(find.byTooltip('Age'));
      await drain(tester);
      await tester.tap(find.widgetWithText(TextField, 'Mob'));
      await drain(tester);
      await tester.tap(find.text('10 × Steers (Backgrounders)').last);
      await drain(tester);

      expect(find.text('Steers (Feeders)'), findsOneWidget);

      await tester.tap(find.text('Steers (Feeders)'));
      await drain(tester);
      expect(find.text('Bullocks (Fats)'), findsWidgets);
      expect(find.text('Steers (Feeders) · ready to sell'), findsNothing);
    });
  });

  group('A paddock', () {
    Future<void> openPaddock(WidgetTester tester) => pumpRouted(
      tester,
      repository: repo,
      location: '/properties/$property/paddocks/$north',
    );

    Future<List<String>> menuFor(WidgetTester tester, String label) async {
      await tester.tap(find.byTooltip('Actions for $label'));
      await settle(tester);
      final items = [
        for (final item in tester.widgetList<PopupMenuItem<Object>>(
          find.byWidgetPredicate((w) => w is PopupMenuItem),
        ))
          (item.child! as Text).data!,
      ];
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      return items;
    }

    testPage('offers each mob what its class allows', (tester) async {
      await intake('Calves (Breeder)', 5);
      await intake('Steers (Feeders)', 10);
      await repo.record(
        kind: MovementKind.readyToSell,
        head: 2,
        fromPaddockId: north,
        fromClassId: classIds['Steers (Feeders)']!,
        toPaddockId: north,
        toClassId: classIds['Steers (Feeders) · ready to sell']!,
      );
      await openPaddock(tester);

      expect(await menuFor(tester, 'Calves (Breeder)'), [
        'Record death',
        'Add tags',
      ]);
      expect(await menuFor(tester, 'Steers (Feeders)'), [
        'Mark ready to sell',
        'Record death',
        'Add tags',
      ]);
      expect(await menuFor(tester, 'Steers (Feeders) · ready to sell'), [
        'No longer ready to sell',
        'Record death',
        'Add tags',
      ]);
    });

    testPage('lists its deaths and records another', (tester) async {
      await intake('Calves (Breeder)', 5);
      await openPaddock(tester);

      expect(find.text('Deaths'), findsOneWidget);
      expect(
        find.text('No deaths recorded here in the last 30 days.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Record death'));
      await settle(tester);
      await tester.tap(record());
      await settle(tester);

      expect(
        find.text('No deaths recorded here in the last 30 days.'),
        findsNothing,
      );
      // Once among the deaths, and once in the recent activity below.
      expect(
        findRichText('1 head · North Ridge → died · Calves (Breeder)'),
        findsNWidgets(2),
      );
    });

    testPage('has no Deaths section while it has had neither', (tester) async {
      await openPaddock(tester);

      expect(find.text('This paddock is empty.'), findsOneWidget);
      expect(find.text('Deaths'), findsNothing);
    });

    group('ended stock', () {
      DateTime daysAgo(int days) =>
          DateTime.now().subtract(Duration(days: days));

      Future<void> end(int head, EndState state, {int daysAgo = 0}) =>
          repo.record(
            kind: MovementKind.endState,
            head: head,
            fromPaddockId: north,
            fromClassId: classIds['Calves (Breeder)']!,
            endState: state,
            occurredAt: daysAgo == 0
                ? null
                : DateTime.now().subtract(Duration(days: daysAgo)),
          );

      /// A death and a sale 40 days ago, and a sale today.
      Future<void> history() async {
        await repo.record(
          kind: MovementKind.intake,
          head: 10,
          toPaddockId: north,
          toClassId: classIds['Calves (Breeder)']!,
          occurredAt: daysAgo(60),
        );
        await end(1, EndState.died, daysAgo: 40);
        await end(2, EndState.sold, daysAgo: 40);
        await end(3, EndState.sold);
      }

      const oldDeath = '1 head · North Ridge → died · Calves (Breeder)';
      const oldSale = '2 head · North Ridge → sold · Calves (Breeder)';
      const newSale = '3 head · North Ridge → sold · Calves (Breeder)';

      testPage('are listed only within the duration', (tester) async {
        await history();
        await openPaddock(tester);

        expect(
          find.text('No deaths recorded here in the last 30 days.'),
          findsOneWidget,
        );
        expect(find.text('Recently left'), findsOneWidget);
        // Each in Recently left, then once more in the recent activity.
        expect(findRichText(newSale), findsNWidgets(2));
        expect(findRichText(oldSale), findsOneWidget);
        expect(findRichText(oldDeath), findsOneWidget);
      });

      testPage('are all listed while kept always', (tester) async {
        await history();
        await repo.settings.setRetention(Retention.always);
        await openPaddock(tester);

        expect(find.textContaining('No deaths recorded'), findsNothing);
        expect(findRichText(newSale), findsNWidgets(2));
        expect(findRichText(oldSale), findsNWidgets(2));
        expect(findRichText(oldDeath), findsNWidgets(2));
      });

      testPage('follow a change of duration while open', (tester) async {
        await history();
        await openPaddock(tester);
        expect(findRichText(oldDeath), findsOneWidget);

        await repo.settings.setRetention(
          const Retention(2, RetentionUnit.months),
        );
        await settle(tester);

        expect(findRichText(oldDeath), findsNWidgets(2));
        expect(findRichText(oldSale), findsNWidgets(2));
      });

      testPage('leave no Recently left section when nothing has left', (
        tester,
      ) async {
        await intake('Calves (Breeder)', 5);
        await end(1, EndState.died);
        await openPaddock(tester);

        expect(find.text('Deaths'), findsOneWidget);
        expect(find.text('Recently left'), findsNothing);
      });

      testPage('show ten at a time, and more on asking', (tester) async {
        await intake('Calves (Breeder)', 40);
        // More deaths than the recent activity's 25, so the oldest is
        // nowhere until Deaths shows it.
        for (var i = 0; i < 30; i++) {
          await repo.record(
            kind: MovementKind.endState,
            head: 1,
            fromPaddockId: north,
            fromClassId: classIds['Calves (Breeder)']!,
            endState: EndState.died,
            note: i == 0 ? 'the oldest death' : null,
          );
        }
        await openPaddock(tester);
        // Tall enough that every tile is built, so what is missing is not
        // merely scrolled out of reach.
        tester.view.physicalSize = const Size(420, 8000);
        await settle(tester);

        final more = find.widgetWithText(TextButton, 'Show more');
        final oldest = find.textContaining('the oldest death');
        expect(oldest, findsNothing);

        await tester.tap(more);
        await settle(tester);
        expect(oldest, findsNothing);
        await tester.tap(more);
        await settle(tester);

        expect(oldest, findsOneWidget);
        expect(more, findsNothing);
      });
    });
  });
}
