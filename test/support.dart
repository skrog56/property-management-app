import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/app/router.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/repository_scope.dart';

/// Disposing a drift `StreamBuilder` schedules a zero-duration timer, and
/// `testWidgets` fails a body that ends with one pending. Tearing the tree down
/// here — inside the body, before that check runs — drains it.
void testPage(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget child, {
  double width = 420,
  LivestockRepository? repository,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  // The scope sits above the navigator, as it does in the real app, so pages
  // pushed by a drill-down can still reach it.
  final app = MaterialApp(home: Scaffold(body: child));

  await tester.pumpWidget(
    repository == null
        ? app
        : RepositoryScope(repository: repository, child: app),
  );

  // Not pumpAndSettle: these pages show a CircularProgressIndicator while their
  // stream is still cold, and a running animation means the tree never goes
  // idle. Bounded pumping lets the database queries land instead.
  await drain(tester);
}

/// The real shell and routes, starting at [location], for anything that
/// navigates.
Future<void> pumpRouted(
  WidgetTester tester, {
  required LivestockRepository repository,
  String location = '/properties',
  double width = 420,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  final router = buildRouter(initialLocation: location, developer: false);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    RepositoryScope(
      repository: repository,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await settle(tester);
}

/// Long enough for a page transition to finish, so the page beneath it is
/// offstage again.
Future<void> settle(WidgetTester tester) => drain(tester, frames: 50);

Future<void> drain(WidgetTester tester, {int frames = 20}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// A template with two classes, the first ageing into the second.
Future<void> seedBeefTemplate(AppDatabase db) async {
  final now = DateTime.now().toUtc();

  await db
      .into(db.templates)
      .insert(
        TemplatesCompanion.insert(
          id: 'beef',
          createdAt: now,
          updatedAt: now,
          name: 'Beef',
        ),
      );

  for (final (id, kind, age, next, order) in [
    ('calves', 'Calves', 'under 6 months', 'weaners', 0),
    ('weaners', 'Weaners', '6-12 months', null, 1),
  ]) {
    await db
        .into(db.livestockClasses)
        .insert(
          LivestockClassesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            templateId: 'beef',
            kind: kind,
            ageBand: age,
            agesIntoClassId: Value(next),
            sortOrder: Value(order),
          ),
        );
  }
}
