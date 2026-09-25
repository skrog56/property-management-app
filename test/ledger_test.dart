import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';

/// `drift/native.dart` reaches `dart:io`, which is fine here: tests run on the
/// Dart VM and are never compiled for web. The rule this repo enforces is about
/// `lib/`, where a `dart:io` import would break the web build.
void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late String property;
  late String north;
  late String creek;
  late String calves;
  late String weaners;

  Future<String> addClass(
    String templateId,
    String kind,
    String ageBand, {
    int sortOrder = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final id = '$kind-$ageBand';
    await db
        .into(db.livestockClasses)
        .insert(
          LivestockClassesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            templateId: templateId,
            kind: kind,
            ageBand: ageBand,
            sortOrder: Value(sortOrder),
          ),
        );
    return id;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);

    final now = DateTime.now().toUtc();
    property = await repo.createProperty('Skrog Downs');
    north = await repo.createPaddock(property, 'North Ridge');
    creek = await repo.createPaddock(property, 'Creek Flat');

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
    calves = await addClass('beef', 'Calves', 'under 6 months');
    weaners = await addClass('beef', 'Weaners', '6-12 months', sortOrder: 1);
  });

  tearDown(() => db.close());

  Future<void> intake(String paddock, String cls, int head) => repo.record(
    kind: MovementKind.intake,
    head: head,
    toPaddockId: paddock,
    toClassId: cls,
  );

  test('intake adds head to a paddock', () async {
    await intake(north, calves, 40);

    expect(await repo.headIn(north, calves), 40);
    expect(await repo.headIn(creek, calves), 0);
  });

  test('a move leaves the combined total unchanged', () async {
    await intake(north, calves, 40);
    await repo.record(
      kind: MovementKind.move,
      head: 15,
      fromPaddockId: north,
      fromClassId: calves,
      toPaddockId: creek,
      toClassId: calves,
    );

    expect(await repo.headIn(north, calves), 25);
    expect(await repo.headIn(creek, calves), 15);
  });

  test('aging changes class but not the paddock total', () async {
    await intake(north, calves, 40);
    await repo.record(
      kind: MovementKind.age,
      head: 40,
      fromPaddockId: north,
      fromClassId: calves,
      toPaddockId: north,
      toClassId: weaners,
    );

    expect(await repo.headIn(north, calves), 0);
    expect(await repo.headIn(north, weaners), 40);

    final summaries = await repo.watchPaddockSummaries(property).first;
    final ridge = summaries.firstWhere((s) => s.paddock.id == north);
    expect(ridge.head, 40);
  });

  test('an end state removes head from the system', () async {
    await intake(north, weaners, 30);
    await repo.record(
      kind: MovementKind.endState,
      head: 30,
      fromPaddockId: north,
      fromClassId: weaners,
      endState: EndState.meatworks,
    );

    expect(await repo.headIn(north, weaners), 0);

    final summaries = await repo.watchPaddockSummaries(property).first;
    expect(summaries.firstWhere((s) => s.paddock.id == north).isEmpty, isTrue);
  });

  test('a movement that would drive a count negative is rejected', () async {
    await intake(north, calves, 10);

    await expectLater(
      repo.record(
        kind: MovementKind.move,
        head: 11,
        fromPaddockId: north,
        fromClassId: calves,
        toPaddockId: creek,
        toClassId: calves,
      ),
      throwsA(isA<InsufficientHead>()),
    );

    expect(await repo.headIn(north, calves), 10);
  });

  test('zero and negative head are rejected', () async {
    await expectLater(
      repo.record(
        kind: MovementKind.intake,
        head: 0,
        toPaddockId: north,
        toClassId: calves,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('an emptied paddock reports no mobs, not a zero row', () async {
    await intake(north, calves, 5);
    await repo.record(
      kind: MovementKind.endState,
      head: 5,
      fromPaddockId: north,
      fromClassId: calves,
      endState: EndState.sold,
    );

    final summaries = await repo.watchPaddockSummaries(property).first;
    expect(summaries.firstWhere((s) => s.paddock.id == north).mobs, isEmpty);
  });

  test('a paddock with no movements still appears, empty', () async {
    final summaries = await repo.watchPaddockSummaries(property).first;

    expect(summaries, hasLength(2));
    expect(summaries.every((s) => s.isEmpty), isTrue);
  });

  test('summaries list mobs of different classes separately', () async {
    await intake(north, calves, 12);
    await intake(north, weaners, 7);

    final summaries = await repo.watchPaddockSummaries(property).first;
    final ridge = summaries.firstWhere((s) => s.paddock.id == north);

    expect(ridge.mobs, hasLength(2));
    expect(ridge.head, 19);
    expect(ridge.mobs.first.livestockClass.kind, 'Calves');
  });

  test('the ledger keeps every movement as history', () async {
    await intake(north, calves, 40);
    await repo.record(
      kind: MovementKind.move,
      head: 10,
      fromPaddockId: north,
      fromClassId: calves,
      toPaddockId: creek,
      toClassId: calves,
    );

    final activity = await repo.watchActivity().first;
    expect(activity, hasLength(2));
    expect(activity.first.kind, MovementKind.move);
  });
}
