import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/livestock_repository.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';

import 'support.dart';

void main() {
  late AppDatabase db;
  late LivestockRepository repo;
  late String north;
  late String creek;

  TagNumber nlis(String raw) => TagNumber.tryParse(TagScheme.nlis, raw)!;
  final a = nlis('999000000000001');
  final b = nlis('999000000000002');
  final c = nlis('999000000000003');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LivestockRepository(db);
    await seedBeefTemplate(db);
    final property = await repo.createProperty('Riverbend Downs');
    north = await repo.createPaddock(property, 'North Ridge');
    creek = await repo.createPaddock(property, 'Creek Flat');
  });

  tearDown(() => db.close());

  Future<String> intake(
    int head, {
    List<TagNumber> tags = const [],
    String? into,
  }) => repo.record(
    kind: MovementKind.intake,
    head: head,
    toPaddockId: into ?? north,
    toClassId: 'calves',
    tags: tags,
  );

  Future<String> move(int head, {List<TagNumber> tags = const []}) =>
      repo.record(
        kind: MovementKind.move,
        head: head,
        fromPaddockId: north,
        fromClassId: 'calves',
        toPaddockId: creek,
        toClassId: 'calves',
        tags: tags,
      );

  Future<List<TagNumber>> tagsIn(String paddock) async => [
    for (final s in await repo.tagsIn(paddock)) s.tag.tagNumber,
  ];

  Future<TagStatus> status(TagNumber number) async =>
      (await repo.tagStatusByNumber(number))!;

  group('tags travel with movements', () {
    test('tags recorded at intake stand in the paddock', () async {
      await intake(5, tags: [a, b]);

      expect(await tagsIn(north), [a, b]);
      expect((await status(a)).role, TagRole.added);
      expect((await status(a)).livestockClass?.id, 'calves');
    });

    test('a move carries the tags it names and leaves the rest', () async {
      await intake(5, tags: [a, b]);
      await move(2, tags: [a]);

      expect(await tagsIn(north), [b]);
      expect(await tagsIn(creek), [a]);
      expect((await status(a)).role, TagRole.carried);
    });

    test('a tag not seen before is added as it moves', () async {
      await intake(5, tags: [a]);
      await move(2, tags: [a, b]);

      expect(await tagsIn(creek), [a, b]);
      expect((await status(b)).role, TagRole.added);
    });

    test('ageing takes its tags into the new class', () async {
      await intake(3, tags: [a]);
      await repo.record(
        kind: MovementKind.age,
        head: 3,
        fromPaddockId: north,
        fromClassId: 'calves',
        toPaddockId: north,
        toClassId: 'weaners',
        tags: [a],
      );

      expect((await status(a)).livestockClass?.id, 'weaners');
    });

    test('an end state takes its tags off the property', () async {
      await intake(3, tags: [a]);
      await repo.record(
        kind: MovementKind.endState,
        head: 1,
        fromPaddockId: north,
        fromClassId: 'calves',
        endState: EndState.sold,
        tags: [a],
      );

      final sold = await status(a);
      expect(await tagsIn(north), isEmpty);
      expect(sold.isActive, isFalse);
      expect(sold.endState, EndState.sold);
    });

    test('a tag that left can come back', () async {
      await intake(3, tags: [a]);
      await repo.record(
        kind: MovementKind.endState,
        head: 1,
        fromPaddockId: north,
        fromClassId: 'calves',
        endState: EndState.sold,
        tags: [a],
      );
      await intake(1, tags: [a], into: creek);

      expect(await tagsIn(creek), [a]);
      final history = await repo
          .watchActivityEntries(tagId: (await status(a)).tag.id)
          .first;
      expect(history, hasLength(3));
    });

    test('a number is the same tag however it was typed', () async {
      await intake(1, tags: [nlis('999 000000000001')]);

      expect((await status(a)).isActive, isTrue);
      expect(await db.select(db.livestockTags).get(), hasLength(1));
    });
  });

  group('tags stay where their animals are', () {
    test('a tag cannot be in two places', () async {
      await intake(3, tags: [a]);

      await expectLater(
        intake(2, tags: [a], into: creek),
        throwsA(isA<TagElsewhere>()),
      );
      await intake(2, into: creek);
      await expectLater(
        repo.record(
          kind: MovementKind.move,
          head: 1,
          fromPaddockId: creek,
          fromClassId: 'calves',
          toPaddockId: north,
          toClassId: 'calves',
          tags: [a],
        ),
        throwsA(isA<TagElsewhere>()),
      );
      expect(await tagsIn(north), [a]);
    });

    test('more tags than head, or a tag twice, is refused', () async {
      expect(() => intake(1, tags: [a, b]), throwsArgumentError);
      expect(() => intake(2, tags: [a, a]), throwsArgumentError);
    });

    test('a fully tagged mob must say which tags moved', () async {
      await intake(2, tags: [a, b]);

      await expectLater(move(1), throwsA(isA<UntaggedShortfall>()));
      await move(1, tags: [a]);
      expect(await tagsIn(creek), [a]);
    });

    test('untagged head can move without naming anyone', () async {
      await intake(5, tags: [a, b]);
      await move(3);

      expect(await tagsIn(north), [a, b]);
      await expectLater(move(1), throwsA(isA<UntaggedShortfall>()));
    });

    test('a movement cannot be dated before a tag last moved', () async {
      await intake(3, tags: [a]);

      expect(
        () => repo.record(
          kind: MovementKind.move,
          head: 1,
          fromPaddockId: north,
          fromClassId: 'calves',
          toPaddockId: creek,
          toClassId: 'calves',
          tags: [a],
          occurredAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        throwsArgumentError,
      );
    });

    test('a tag event cannot be recorded as a movement', () async {
      expect(
        () => repo.record(
          kind: MovementKind.tag,
          head: 1,
          fromPaddockId: north,
          fromClassId: 'calves',
          toPaddockId: north,
          toClassId: 'calves',
        ),
        throwsArgumentError,
      );
    });
  });

  group('tag events', () {
    test('adding tags to a mob nets to zero', () async {
      await intake(5);
      await repo.applyTags(paddockId: north, classId: 'calves', tags: [a, b]);

      expect(await repo.headIn(north, 'calves'), 5);
      expect(await tagsIn(north), [a, b]);

      final latest = (await repo.watchActivity().first).first;
      expect(latest.kind, MovementKind.tag);
      expect(latest.head, 2);
    });

    test('adding tags needs untagged head to put them on', () async {
      await intake(3, tags: [a, b]);

      await expectLater(
        repo.applyTags(
          paddockId: north,
          classId: 'calves',
          tags: [c, nlis('999000000000004')],
        ),
        throwsA(isA<UntaggedShortfall>()),
      );
      await expectLater(
        repo.applyTags(paddockId: north, classId: 'calves', tags: [a]),
        throwsA(isA<TagElsewhere>()),
      );
    });

    test('replacing a tag keeps the animal tagged', () async {
      await intake(3, tags: [a]);
      await repo.replaceTag(
        (await status(a)).tag.id,
        b,
        reason: TagReason.lost,
      );

      final old = await status(a);
      expect(await tagsIn(north), [b]);
      expect(old.isActive, isFalse);
      expect(old.reason, TagReason.lost);
      expect(old.replacedBy?.tagNumber, b);
      expect((await status(b)).replacedBy, isNull);
      expect(await repo.headIn(north, 'calves'), 3);

      final entry = (await repo.watchActivityEntries().first).first;
      expect(
        [for (final t in entry.tags) (t.tag.tagNumber, t.role)],
        [(a, TagRole.removed), (b, TagRole.added)],
      );
    });

    test('a replacement must be a different tag that is free', () async {
      await intake(3, tags: [a, b]);
      final id = (await status(a)).tag.id;

      expect(
        () => repo.replaceTag(id, a, reason: TagReason.lost),
        throwsArgumentError,
      );
      await expectLater(
        repo.replaceTag(id, b, reason: TagReason.lost),
        throwsA(isA<TagElsewhere>()),
      );
    });

    test('cancelling a tag leaves the head where it was', () async {
      await intake(3, tags: [a]);
      await repo.cancelTag((await status(a)).tag.id, reason: TagReason.error);

      final cancelled = await status(a);
      expect(await tagsIn(north), isEmpty);
      expect(await repo.headIn(north, 'calves'), 3);
      expect(cancelled.reason, TagReason.error);
      expect(cancelled.replacedBy, isNull);
      expect(
        () => repo.cancelTag(cancelled.tag.id, reason: TagReason.error),
        throwsStateError,
      );
    });

    test('tag events never move a count', () async {
      await intake(4, tags: [a]);
      await repo.applyTags(paddockId: north, classId: 'calves', tags: [b]);
      await repo.replaceTag(
        (await status(a)).tag.id,
        c,
        reason: TagReason.damaged,
      );
      await repo.cancelTag((await status(b)).tag.id, reason: TagReason.other);

      expect(await repo.headIn(north, 'calves'), 4);
      expect(await repo.negativeBalances(), isEmpty);
      expect(await repo.overTaggedMobs(), isEmpty);
    });
  });

  test('Activity can be narrowed to one tag', () async {
    await intake(5, tags: [a, b]);
    await move(1, tags: [b]);
    await move(1);

    final entries = await repo
        .watchActivityEntries(tagId: (await status(a)).tag.id)
        .first;
    expect(entries, hasLength(1));
    expect(entries.single.movement.kind, MovementKind.intake);
  });

  test('overTaggedMobs flags a merge that left more tags than head', () async {
    await intake(2, tags: [a, b]);
    final now = DateTime.now().toUtc();

    // Bypasses `record`, as a merged offline edit would.
    await db
        .into(db.movements)
        .insert(
          MovementsCompanion.insert(
            id: 'merged',
            createdAt: now,
            updatedAt: now,
            occurredAt: now,
            kind: MovementKind.endState,
            head: 1,
            actorId: localActorId,
            fromPaddockId: Value(north),
            fromClassId: const Value('calves'),
          ),
        );

    final over = await repo.overTaggedMobs();
    expect(over, hasLength(1));
    expect(over.single.paddockId, north);
    expect((over.single.tagged, over.single.head), (2, 1));
  });
}
