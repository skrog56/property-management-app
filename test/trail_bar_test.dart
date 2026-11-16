import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';
import 'package:property_management_app/shell/trail_bar.dart';

import 'support.dart';

const _home = Crumb(
  icon: Icons.space_dashboard_outlined,
  label: Text('Home'),
  path: '/',
);
const _farm = Crumb(
  icon: Icons.home_work_outlined,
  label: Text('Properties'),
  path: '/farm',
);
const _paddock = Crumb(
  icon: Icons.grass,
  label: Text('North Ridge'),
  path: '/farm/north',
);

/// Three pages, each with the trail to it, at [location].
Future<void> _pumpTrail(
  WidgetTester tester, {
  required double width,
  String location = '/farm/north',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 600);
  addTearDown(tester.view.reset);

  GoRoute page(
    String path,
    List<Crumb> trail, [
    List<RouteBase> routes = const [],
  ]) => GoRoute(
    path: path,
    builder: (_, _) =>
        Scaffold(appBar: TrailBar(trail), body: Text('at $path')),
    routes: routes,
  );
  final router = GoRouter(
    initialLocation: location,
    routes: [
      page(
        '/',
        [_home],
        [
          page(
            'farm',
            [_home, _farm],
            [
              page('north', [_home, _farm, _paddock]),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

Finder _inBar(Finder finder) =>
    find.descendant(of: find.byType(TrailBar), matching: finder);

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(_inBar(find.text(text)));

void main() {
  group('TrailBar', () {
    testWidgets('names every step, each before the page a link', (
      tester,
    ) async {
      await _pumpTrail(tester, width: 900);

      for (final icon in [
        Icons.space_dashboard_outlined,
        Icons.home_work_outlined,
        Icons.grass,
      ]) {
        expect(_inBar(find.byIcon(icon)), findsOneWidget, reason: '$icon');
      }
      expect(_inBar(find.widgetWithText(TextButton, 'Home')), findsOneWidget);
      expect(
        _inBar(find.widgetWithText(TextButton, 'Properties')),
        findsOneWidget,
      );
      expect(
        _inBar(find.widgetWithText(TextButton, 'North Ridge')),
        findsNothing,
      );
      expect(find.byType(BackButton), findsNothing);

      await tester.tap(find.text('Properties'));
      await tester.pumpAndSettle();
      expect(find.text('at farm'), findsOneWidget);
    });

    testWidgets('a phone shows only the page, and goes back from it', (
      tester,
    ) async {
      await _pumpTrail(tester, width: 360);

      expect(_inBar(find.text('North Ridge')), findsOneWidget);
      expect(_inBar(find.byIcon(Icons.grass)), findsOneWidget);
      expect(_inBar(find.text('Properties')), findsNothing);
      expect(_inBar(find.text('Home')), findsNothing);

      // A deep link, with nothing to pop: back goes up the trail instead.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('at farm'), findsOneWidget);
    });

    testWidgets('a phone goes back no further than a destination', (
      tester,
    ) async {
      await _pumpTrail(tester, width: 360, location: '/farm');

      expect(_inBar(find.text('Properties')), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('where it is short of room, the widest step before the page '
        'gives way first', (tester) async {
      // Every glyph of the test font is a square as wide as the text is tall,
      // so the whole trail needs about 760 px here.
      await _pumpTrail(tester, width: 640);

      expect(_paragraph(tester, 'North Ridge').didExceedMaxLines, isFalse);
      expect(_paragraph(tester, 'Home').didExceedMaxLines, isFalse);
      expect(_paragraph(tester, 'Properties').didExceedMaxLines, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a narrow bar without overflow', (tester) async {
      for (final width in [600.0, 520.0, 360.0, 320.0]) {
        await _pumpTrail(tester, width: width);
        expect(tester.takeException(), isNull, reason: 'at ${width}px');
      }
    });
  });

  group('Every page', () {
    late AppDatabase db;
    late LivestockRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = LivestockRepository(db);
      await seedBeefTemplate(db);
    });

    tearDown(() => db.close());

    Future<({String property, String paddock, String tag})> seed() async {
      final property = await repo.createProperty('Riverbend Downs');
      final paddock = await repo.createPaddock(property, 'North Ridge');
      await repo.record(
        kind: MovementKind.intake,
        head: 5,
        toPaddockId: paddock,
        toClassId: 'calves',
        tags: [TagNumber.tryParse(TagScheme.nlis, '999000000000001')!],
      );
      final tag = (await repo.watchTags().first).single.tag.id;
      return (property: property, paddock: paddock, tag: tag);
    }

    // The bar's title alone, not its actions.
    List<String> trail(WidgetTester tester) {
      final title = tester
          .widget<NavigationToolbar>(_inBar(find.byType(NavigationToolbar)))
          .middle!;
      return [
        for (final text in tester.widgetList<Text>(
          find.descendant(
            of: find.byWidget(title),
            matching: find.byType(Text),
          ),
        ))
          ?text.data,
      ];
    }

    testPage('starts its trail at Home', (tester) async {
      final ids = await seed();

      for (final (location, expected) in [
        ('/', ['Home']),
        ('/activity', ['Home', 'Activity']),
        ('/templates', ['Home', 'Templates']),
        ('/settings', ['Home', 'Settings']),
        ('/about', ['Home', 'About']),
        ('/properties', ['Home', 'Properties']),
        (
          '/properties/${ids.property}/paddocks/${ids.paddock}',
          ['Home', 'Properties', 'Riverbend Downs', 'North Ridge'],
        ),
        ('/tags/${ids.tag}', ['Home', 'Tags', '999 000000000001']),
      ]) {
        await pumpRouted(
          tester,
          repository: repo,
          location: location,
          width: 1900,
        );
        expect(trail(tester), expected, reason: location);
      }
    });

    testPage('leads each step with its icon', (tester) async {
      final ids = await seed();
      await pumpRouted(
        tester,
        repository: repo,
        location: '/properties/${ids.property}/paddocks/${ids.paddock}',
        width: 1900,
      );

      expect(
        [
          for (final icon in tester.widgetList<Icon>(_inBar(find.byType(Icon))))
            icon.icon,
        ],
        [
          Icons.space_dashboard_outlined,
          Icons.chevron_right,
          Icons.home_work_outlined,
          Icons.chevron_right,
          Icons.home_work_outlined,
          Icons.chevron_right,
          Icons.grass,
        ],
      );
    });

    testPage('Home in a trail goes home', (tester) async {
      await seed();
      await pumpRouted(
        tester,
        repository: repo,
        location: '/activity',
        width: 1000,
      );

      await tester.tap(_inBar(find.text('Home')));
      await settle(tester);

      expect(find.text('Head on hand'), findsOneWidget);
    });

    testPage('a phone names only the page', (tester) async {
      final ids = await seed();
      for (final (location, expected, back) in [
        ('/activity', 'Activity', false),
        ('/properties/${ids.property}', 'Riverbend Downs', true),
        ('/tags/${ids.tag}', '999 000000000001', true),
      ]) {
        await pumpRouted(
          tester,
          repository: repo,
          location: location,
          width: 360,
        );
        expect(trail(tester), [expected], reason: location);
        expect(
          find.byType(BackButton),
          back ? findsOneWidget : findsNothing,
          reason: location,
        );
      }
    });
  });
}
