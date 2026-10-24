import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'tables.dart';
import 'tag_numbers.dart';

const _uuid = Uuid();

/// Stands in for the signed-in user until accounts exist.
const localActorId = 'local';

/// What the repository refuses to record: the conflicts an admin will
/// arbitrate once offline edits merge.
sealed class LedgerConflict implements Exception {
  const LedgerConflict();
}

class InsufficientHead extends LedgerConflict {
  const InsufficientHead({required this.available, required this.requested});

  final int available;
  final int requested;

  @override
  String toString() =>
      'Only $available head available, but $requested were requested';
}

class TagElsewhere extends LedgerConflict {
  const TagElsewhere(this.number, this.status);

  final TagNumber number;

  /// Where the tag already is.
  final TagStatus status;

  @override
  String toString() =>
      'Tag ${number.display} is already in '
      '${status.paddock?.name ?? 'another paddock'}';
}

class UntaggedShortfall extends LedgerConflict {
  const UntaggedShortfall({required this.untagged, required this.needed});

  final int untagged;
  final int needed;

  @override
  String toString() =>
      'Only $untagged untagged head here, but this needs $needed';
}

class MobLine {
  const MobLine({required this.livestockClass, required this.head});

  final LivestockClass livestockClass;
  final int head;

  String get label => [
    livestockClass.breed,
    livestockClass.kind,
  ].whereType<String>().join(' ');
}

class ActivityEntry {
  const ActivityEntry({
    required this.movement,
    this.fromPaddock,
    this.toPaddock,
    this.fromClass,
    this.toClass,
    this.tags = const [],
  });

  final Movement movement;
  final Paddock? fromPaddock;
  final Paddock? toPaddock;
  final String? fromClass;
  final String? toClass;

  /// Removed tags first, so a replacement reads old then new.
  final List<TagRef> tags;
}

/// A tag as one movement touched it.
class TagRef {
  const TagRef({required this.tag, required this.role, this.reason});

  final LivestockTag tag;
  final TagRole role;
  final TagReason? reason;
}

/// A tag and its latest movement, which says where it is or how it left.
class TagStatus {
  const TagStatus({
    required this.tag,
    required this.role,
    required this.occurredAt,
    this.reason,
    this.endState,
    this.paddock,
    this.property,
    this.livestockClass,
    this.replacedBy,
  });

  final LivestockTag tag;
  final TagRole role;
  final TagReason? reason;
  final EndState? endState;
  final DateTime occurredAt;

  /// Where that movement took the animal. An end state has nowhere.
  final Paddock? paddock;
  final Property? property;
  final LivestockClass? livestockClass;

  /// The tag that took this one's place, when that movement replaced it.
  final LivestockTag? replacedBy;

  bool get isActive => role != TagRole.removed && paddock != null;
}

typedef _Resolved = ({TagNumber number, LivestockTag? tag, TagStatus? status});

typedef _Link = ({
  TagNumber number,
  LivestockTag? tag,
  TagRole role,
  TagReason? reason,
});

class PaddockSummary {
  const PaddockSummary({required this.paddock, required this.mobs});

  final Paddock paddock;
  final List<MobLine> mobs;

  int get head => mobs.fold(0, (sum, mob) => sum + mob.head);
  bool get isEmpty => head == 0;
}

class PropertySummary {
  const PropertySummary({
    required this.property,
    required this.paddockCount,
    required this.head,
  });

  final Property property;
  final int paddockCount;
  final int head;
}

/// Every head count in the app comes out of here, folded from [Movements].
class LivestockRepository {
  LivestockRepository(this.db);

  final AppDatabase db;

  /// What each drill-down watch last emitted, so a page can open already drawn.
  final _latest = <String, Object?>{};

  Stream<T> _remembered<T>(String key, Stream<T> source) => source.map((value) {
    _latest[key] = value;
    return value;
  });

  /// Completes once every watch has emitted, so [_latest] holds it. Unlike
  /// `Stream.first`, it does not also wait for the subscription to cancel.
  Future<void> warm(Iterable<Stream<Object?>> watches) {
    return Future.wait([
      for (final watch in watches)
        () {
          final first = Completer<void>();
          late final StreamSubscription<Object?> subscription;
          subscription = watch.listen(
            (_) {
              if (first.isCompleted) return;
              first.complete();
              subscription.cancel();
            },
            onError: (Object error, StackTrace stack) {
              if (!first.isCompleted) first.completeError(error, stack);
            },
          );
          return first.future;
        }(),
    ]);
  }

  Property? latestProperty(String id) => _latest['property:$id'] as Property?;

  List<PaddockSummary>? latestPaddockSummaries(String propertyId) =>
      _latest['paddocks:$propertyId'] as List<PaddockSummary>?;

  PaddockSummary? latestPaddockSummary(String paddockId) =>
      _latest['paddock:$paddockId'] as PaddockSummary?;

  List<ActivityEntry>? latestActivityEntries({
    int limit = 200,
    String? paddockId,
    String? tagId,
  }) => _latest['activity:$paddockId:$tagId:$limit'] as List<ActivityEntry>?;

  List<TagStatus>? latestTagsIn(String paddockId) =>
      _latest['tags:$paddockId'] as List<TagStatus>?;

  TagStatus? latestTag(String id) => _latest['tag:$id'] as TagStatus?;

  /// Signed deltas per (paddock, class). Each movement contributes at most one
  /// row to each half: intake has no `from`, endState has no `to`, and an age
  /// contributes to both halves of the same paddock under different classes.
  static const _balances = '''
    SELECT to_paddock_id AS paddock_id, to_class_id AS class_id, head AS delta
      FROM movements WHERE deleted_at IS NULL AND to_paddock_id IS NOT NULL
    UNION ALL
    SELECT from_paddock_id, from_class_id, -head
      FROM movements WHERE deleted_at IS NULL AND from_paddock_id IS NOT NULL
  ''';

  /// Each tag's latest link: where it is now, or how it left. Unlike a head
  /// count this depends on order, which is why [record] will not date a
  /// movement before a tag's latest one.
  static const _tagLatest = '''
    SELECT tag_id, role, reason, movement_id, end_state,
           to_paddock_id, to_class_id, occurred_at
      FROM (
        SELECT mt.tag_id, mt.role, mt.reason, m.id AS movement_id,
               m.end_state, m.to_paddock_id, m.to_class_id, m.occurred_at,
               ROW_NUMBER() OVER (
                 PARTITION BY mt.tag_id
                 ORDER BY m.occurred_at DESC, m.created_at DESC, m.rowid DESC
               ) AS rn
          FROM movement_tags mt JOIN movements m ON m.id = mt.movement_id
         WHERE mt.deleted_at IS NULL AND m.deleted_at IS NULL
      )
     WHERE rn = 1
  ''';

  static const _isActive =
      "l.role <> 'removed' AND l.to_paddock_id IS NOT NULL";

  /// The top tier: one row per property, with the paddocks under it and the
  /// head standing across all of them.
  Stream<List<PropertySummary>> watchPropertySummaries() {
    return db
        .customSelect(
          '''
          SELECT pr.id AS pid,
                 COUNT(DISTINCT pa.id) AS paddocks,
                 COALESCE(SUM(b.delta), 0) AS head
            FROM properties pr
            LEFT JOIN paddocks pa
              ON pa.property_id = pr.id AND pa.deleted_at IS NULL
            LEFT JOIN ($_balances) b ON b.paddock_id = pa.id
           WHERE pr.deleted_at IS NULL
           GROUP BY pr.id
          ''',
          readsFrom: {db.properties, db.paddocks, db.movements},
        )
        .watch()
        .asyncMap((rows) async {
          final properties = {for (final p in await this.properties()) p.id: p};

          final summaries = <PropertySummary>[];
          for (final row in rows) {
            final property = properties[row.read<String>('pid')];
            if (property == null) continue;
            summaries.add(
              PropertySummary(
                property: property,
                paddockCount: row.read<int>('paddocks'),
                head: row.read<int>('head'),
              ),
            );
          }
          summaries.sort((a, b) => a.property.name.compareTo(b.property.name));
          return summaries;
        });
  }

  Stream<List<PaddockSummary>> watchPaddockSummaries(String propertyId) {
    final summaries = db
        .customSelect(
          '''
          SELECT p.id AS pid, b.class_id AS cid, SUM(b.delta) AS head
            FROM paddocks p
            LEFT JOIN ($_balances) b ON b.paddock_id = p.id
           WHERE p.deleted_at IS NULL AND p.property_id = ?1
           GROUP BY p.id, b.class_id
          HAVING b.class_id IS NULL OR SUM(b.delta) <> 0
          ''',
          variables: [Variable<String>(propertyId)],
          readsFrom: {db.paddocks, db.movements},
        )
        .watch()
        .asyncMap((rows) => _assemble(propertyId, rows));
    return _remembered('paddocks:$propertyId', summaries);
  }

  Future<List<PaddockSummary>> _assemble(
    String propertyId,
    List<QueryRow> rows,
  ) async {
    final paddocks = await (db.select(db.paddocks)
          ..where((p) => p.propertyId.equals(propertyId))
          ..where((p) => p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.name)]))
        .get();

    final classes = await _classesById();

    final mobs = <String, List<MobLine>>{};
    for (final row in rows) {
      final classId = row.read<String?>('cid');
      final livestockClass = classId == null ? null : classes[classId];
      if (livestockClass == null) continue;
      mobs.putIfAbsent(row.read<String>('pid'), () => []).add(
        MobLine(livestockClass: livestockClass, head: row.read<int>('head')),
      );
    }

    for (final lines in mobs.values) {
      lines.sort(
        (a, b) =>
            a.livestockClass.sortOrder.compareTo(b.livestockClass.sortOrder),
      );
    }

    return [
      for (final paddock in paddocks)
        PaddockSummary(paddock: paddock, mobs: mobs[paddock.id] ?? const []),
    ];
  }

  /// The bottom tier: one paddock and the mobs standing in it. Emits null once
  /// the paddock is gone, so a detail view can close itself.
  Stream<PaddockSummary?> watchPaddockSummary(String paddockId) {
    final summary = db
        .customSelect(
          '''
          SELECT class_id AS cid, SUM(delta) AS head FROM ($_balances)
           WHERE paddock_id = ?1
           GROUP BY class_id HAVING SUM(delta) <> 0
          ''',
          variables: [Variable<String>(paddockId)],
          readsFrom: {db.paddocks, db.movements},
        )
        .watch()
        .asyncMap((rows) async {
          final paddock =
              await (db.select(db.paddocks)
                    ..where((p) => p.id.equals(paddockId))
                    ..where((p) => p.deletedAt.isNull()))
                  .getSingleOrNull();
          if (paddock == null) return null;

          final classes = await _classesById();
          final mobs = <MobLine>[];
          for (final row in rows) {
            final livestockClass = classes[row.read<String>('cid')];
            if (livestockClass == null) continue;
            mobs.add(
              MobLine(
                livestockClass: livestockClass,
                head: row.read<int>('head'),
              ),
            );
          }
          mobs.sort(
            (a, b) =>
                a.livestockClass.sortOrder.compareTo(b.livestockClass.sortOrder),
          );

          return PaddockSummary(paddock: paddock, mobs: mobs);
        });
    return _remembered('paddock:$paddockId', summary);
  }

  Future<Map<String, LivestockClass>> _classesById() async => {
    for (final c in await db.select(db.livestockClasses).get()) c.id: c,
  };

  Future<int> headIn(String paddockId, String classId) async {
    final row = await db
        .customSelect(
          '''
          SELECT COALESCE(SUM(delta), 0) AS head FROM ($_balances)
           WHERE paddock_id = ?1 AND class_id = ?2
          ''',
          variables: [Variable<String>(paddockId), Variable<String>(classId)],
          readsFrom: {db.movements},
        )
        .getSingle();
    return row.read<int>('head');
  }

  Stream<List<Movement>> watchActivity({
    int limit = 200,
    String? paddockId,
    String? tagId,
  }) {
    return (db.select(db.movements)
          ..where((m) => m.deletedAt.isNull())
          ..where(
            (m) => paddockId == null
                ? const Constant(true)
                : m.fromPaddockId.equals(paddockId) |
                      m.toPaddockId.equals(paddockId),
          )
          ..where(
            (m) => tagId == null
                ? const Constant(true)
                : m.id.isInQuery(
                    db.selectOnly(db.movementTags)
                      ..addColumns([db.movementTags.movementId])
                      ..where(
                        db.movementTags.tagId.equals(tagId) &
                            db.movementTags.deletedAt.isNull(),
                      ),
                  ),
          )
          ..orderBy([
            (m) => OrderingTerm(
              expression: m.occurredAt,
              mode: OrderingMode.desc,
            ),
            (m) =>
                OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<ActivityEntry>> watchActivityEntries({
    int limit = 200,
    String? paddockId,
    String? tagId,
  }) {
    final entries =
        watchActivity(
          limit: limit,
          paddockId: paddockId,
          tagId: tagId,
        ).asyncMap((movements) async {
          final paddocks = {
            for (final p in await db.select(db.paddocks).get()) p.id: p,
          };
          final classes = {
            for (final c in (await _classesById()).values)
              c.id: '${c.kind} (${c.ageBand})',
          };
          final tags = await _tagRefs({for (final m in movements) m.id});

          return [
            for (final m in movements)
              ActivityEntry(
                movement: m,
                fromPaddock: paddocks[m.fromPaddockId],
                toPaddock: paddocks[m.toPaddockId],
                fromClass: classes[m.fromClassId],
                toClass: classes[m.toClassId],
                tags: tags[m.id] ?? const [],
              ),
          ];
        });
    return _remembered('activity:$paddockId:$tagId:$limit', entries);
  }

  Future<Map<String, List<TagRef>>> _tagRefs(Set<String> movementIds) async {
    if (movementIds.isEmpty) return const {};
    final rows =
        await (db.select(db.movementTags).join([
                innerJoin(
                  db.livestockTags,
                  db.livestockTags.id.equalsExp(db.movementTags.tagId),
                ),
              ])
              ..where(db.movementTags.movementId.isIn(movementIds))
              ..where(db.movementTags.deletedAt.isNull()))
            .get();

    final refs = <String, List<TagRef>>{};
    for (final row in rows) {
      final link = row.readTable(db.movementTags);
      refs
          .putIfAbsent(link.movementId, () => [])
          .add(
            TagRef(
              tag: row.readTable(db.livestockTags),
              role: link.role,
              reason: link.reason,
            ),
          );
    }
    for (final list in refs.values) {
      list.sort((a, b) {
        final byRole = (a.role == TagRole.removed ? 0 : 1).compareTo(
          b.role == TagRole.removed ? 0 : 1,
        );
        return byRole != 0 ? byRole : a.tag.number.compareTo(b.tag.number);
      });
    }
    return refs;
  }

  /// Rejects anything that would drive a paddock's count negative, or leave a
  /// mob with more tags than head. Those are the conflicts an admin will
  /// arbitrate after offline sync, which is why the checks live here rather
  /// than in the form.
  ///
  /// Each of [tags] is carried if it is standing in the source mob, and added
  /// if it is standing nowhere.
  Future<String> record({
    required MovementKind kind,
    required int head,
    String? fromPaddockId,
    String? fromClassId,
    String? toPaddockId,
    String? toClassId,
    EndState? endState,
    String? note,
    DateTime? occurredAt,
    List<TagNumber> tags = const [],
  }) async {
    if (kind == MovementKind.tag) {
      throw ArgumentError.value(kind, 'kind', 'has its own methods');
    }
    if (head <= 0) {
      throw ArgumentError.value(head, 'head', 'must be greater than zero');
    }
    _checkTags(tags, head);
    final at = occurredAt?.toUtc() ?? DateTime.now().toUtc();

    return db.transaction(() async {
      var untagged = 0;
      if (fromPaddockId != null && fromClassId != null) {
        final available = await headIn(fromPaddockId, fromClassId);
        if (available < head) {
          throw InsufficientHead(available: available, requested: head);
        }
        untagged = available - await _taggedIn(fromPaddockId, fromClassId);
      }

      final links = <_Link>[];
      for (final r in await _resolve(tags)) {
        _checkOrder(r.number, r.status, at);
        final status = r.status;
        final TagRole role;
        if (status == null || !status.isActive) {
          role = TagRole.added;
        } else if (status.paddock?.id == fromPaddockId &&
            status.livestockClass?.id == fromClassId) {
          role = TagRole.carried;
        } else {
          throw TagElsewhere(r.number, status);
        }
        links.add((number: r.number, tag: r.tag, role: role, reason: null));
      }

      if (fromPaddockId != null && fromClassId != null) {
        final carried = links.where((l) => l.role == TagRole.carried).length;
        if (head - carried > untagged) {
          throw UntaggedShortfall(untagged: untagged, needed: head - carried);
        }
      }

      return _append(
        kind: kind,
        head: head,
        at: at,
        fromPaddockId: fromPaddockId,
        fromClassId: fromClassId,
        toPaddockId: toPaddockId,
        toClassId: toClassId,
        endState: endState,
        note: note,
        links: links,
      );
    });
  }

  /// Tags head already standing in a mob, as a tag event.
  Future<String> applyTags({
    required String paddockId,
    required String classId,
    required List<TagNumber> tags,
    String? note,
    DateTime? occurredAt,
  }) async {
    if (tags.isEmpty) {
      throw ArgumentError.value(tags, 'tags', 'must not be empty');
    }
    _checkTags(tags, tags.length);
    final at = occurredAt?.toUtc() ?? DateTime.now().toUtc();

    return db.transaction(() async {
      final links = <_Link>[];
      for (final r in await _resolve(tags)) {
        _checkOrder(r.number, r.status, at);
        if (r.status case final s? when s.isActive) {
          throw TagElsewhere(r.number, s);
        }
        links.add((
          number: r.number,
          tag: r.tag,
          role: TagRole.added,
          reason: null,
        ));
      }

      final untagged =
          await headIn(paddockId, classId) -
          await _taggedIn(paddockId, classId);
      if (tags.length > untagged) {
        throw UntaggedShortfall(untagged: untagged, needed: tags.length);
      }

      return _append(
        kind: MovementKind.tag,
        head: tags.length,
        at: at,
        fromPaddockId: paddockId,
        fromClassId: classId,
        toPaddockId: paddockId,
        toClassId: classId,
        note: note,
        links: links,
      );
    });
  }

  /// [replacement] goes on the same animal, so the mob's tagged count holds.
  Future<String> replaceTag(
    String tagId,
    TagNumber replacement, {
    required TagReason reason,
    String? note,
    DateTime? occurredAt,
  }) async {
    final at = occurredAt?.toUtc() ?? DateTime.now().toUtc();

    return db.transaction(() async {
      final old = await _activeStatus(tagId);
      _checkOrder(old.tag.tagNumber, old, at);
      if (old.tag.tagNumber == replacement) {
        throw ArgumentError.value(
          replacement,
          'replacement',
          'is the same tag',
        );
      }
      final r = (await _resolve([replacement])).single;
      _checkOrder(r.number, r.status, at);
      if (r.status case final s? when s.isActive) {
        throw TagElsewhere(replacement, s);
      }

      return _append(
        kind: MovementKind.tag,
        head: 1,
        at: at,
        fromPaddockId: old.paddock!.id,
        fromClassId: old.livestockClass!.id,
        toPaddockId: old.paddock!.id,
        toClassId: old.livestockClass!.id,
        note: note,
        links: [
          (
            number: old.tag.tagNumber,
            tag: old.tag,
            role: TagRole.removed,
            reason: reason,
          ),
          (number: replacement, tag: r.tag, role: TagRole.added, reason: null),
        ],
      );
    });
  }

  /// The animal stays in its mob's head count, untagged.
  Future<String> cancelTag(
    String tagId, {
    required TagReason reason,
    String? note,
    DateTime? occurredAt,
  }) async {
    final at = occurredAt?.toUtc() ?? DateTime.now().toUtc();

    return db.transaction(() async {
      final status = await _activeStatus(tagId);
      _checkOrder(status.tag.tagNumber, status, at);
      return _append(
        kind: MovementKind.tag,
        head: 1,
        at: at,
        fromPaddockId: status.paddock!.id,
        fromClassId: status.livestockClass!.id,
        toPaddockId: status.paddock!.id,
        toClassId: status.livestockClass!.id,
        note: note,
        links: [
          (
            number: status.tag.tagNumber,
            tag: status.tag,
            role: TagRole.removed,
            reason: reason,
          ),
        ],
      );
    });
  }

  Future<TagStatus> _activeStatus(String tagId) async {
    final status = (await _statusesOf([tagId]))[tagId];
    if (status == null || !status.isActive) {
      throw StateError('Tag $tagId is not on the property');
    }
    return status;
  }

  static void _checkTags(List<TagNumber> tags, int head) {
    if (tags.length > head) {
      throw ArgumentError.value(tags.length, 'tags', 'outnumber the head');
    }
    if (tags.toSet().length < tags.length) {
      throw ArgumentError.value(tags, 'tags', 'name a tag twice');
    }
  }

  static void _checkOrder(TagNumber number, TagStatus? status, DateTime at) {
    if (status != null && status.occurredAt.isAfter(at)) {
      throw ArgumentError.value(
        at,
        'occurredAt',
        'is before $number last moved',
      );
    }
  }

  /// One movement and its tag links, in one batch. A tag seen for the first
  /// time gets its row here.
  Future<String> _append({
    required MovementKind kind,
    required int head,
    required DateTime at,
    String? fromPaddockId,
    String? fromClassId,
    String? toPaddockId,
    String? toClassId,
    EndState? endState,
    String? note,
    List<_Link> links = const [],
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    await db.batch((batch) {
      batch.insert(
        db.movements,
        MovementsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          occurredAt: at,
          kind: kind,
          head: head,
          actorId: localActorId,
          fromPaddockId: Value(fromPaddockId),
          fromClassId: Value(fromClassId),
          toPaddockId: Value(toPaddockId),
          toClassId: Value(toClassId),
          endState: Value(endState),
          note: Value(note),
        ),
      );

      for (final link in links) {
        var tagId = link.tag?.id;
        if (tagId == null) {
          tagId = _uuid.v4();
          batch.insert(
            db.livestockTags,
            LivestockTagsCompanion.insert(
              id: tagId,
              createdAt: now,
              updatedAt: now,
              scheme: link.number.scheme,
              number: link.number.value,
            ),
          );
        }
        batch.insert(
          db.movementTags,
          MovementTagsCompanion.insert(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            movementId: id,
            tagId: tagId,
            role: link.role,
            reason: Value(link.reason),
          ),
        );
      }
    });

    return id;
  }

  /// Each number's tag row, if it has one, and where that tag is.
  Future<List<_Resolved>> _resolve(List<TagNumber> numbers) async {
    if (numbers.isEmpty) return const [];
    final rows = await (db.select(
      db.livestockTags,
    )..where((t) => t.number.isIn({for (final n in numbers) n.value}))).get();
    final tags = {for (final t in rows) t.tagNumber: t};
    final statuses = await _statusesOf([for (final t in tags.values) t.id]);

    return [
      for (final n in numbers)
        (number: n, tag: tags[n], status: statuses[tags[n]?.id]),
    ];
  }

  Future<int> _taggedIn(String paddockId, String classId) async {
    final row = await db
        .customSelect(
          '''
          SELECT COUNT(*) AS c FROM ($_tagLatest)
           WHERE role <> 'removed' AND to_paddock_id = ?1 AND to_class_id = ?2
          ''',
          variables: [Variable<String>(paddockId), Variable<String>(classId)],
          readsFrom: {db.movementTags, db.movements},
        )
        .getSingle();
    return row.read<int>('c');
  }

  /// Tags with their latest link, narrowed by [filter] on `t` (the tag) and
  /// `l` (the link).
  Selectable<QueryRow> _tagRows([
    String filter = '',
    List<Variable> variables = const [],
  ]) => db.customSelect(
    '''
    SELECT t.*, l.role, l.reason, l.movement_id, l.end_state,
           l.to_paddock_id, l.to_class_id, l.occurred_at
      FROM livestock_tags t JOIN ($_tagLatest) l ON l.tag_id = t.id
     WHERE t.deleted_at IS NULL $filter
    ''',
    variables: variables,
    readsFrom: {db.livestockTags, db.movementTags, db.movements},
  );

  Future<List<TagStatus>> _statuses(List<QueryRow> rows) async {
    if (rows.isEmpty) return [];

    final paddocks = {
      for (final p in await db.select(db.paddocks).get()) p.id: p,
    };
    final properties = {
      for (final p in await db.select(db.properties).get()) p.id: p,
    };
    final classes = await _classesById();
    final successors = await _addedIn({
      for (final row in rows)
        if (row.read<String>('role') == TagRole.removed.name)
          row.read<String>('movement_id'),
    });

    final statuses = <TagStatus>[];
    for (final row in rows) {
      final role = TagRole.values.byName(row.read<String>('role'));
      final paddock = paddocks[row.read<String?>('to_paddock_id')];
      statuses.add(
        TagStatus(
          tag: db.livestockTags.map(row.data),
          role: role,
          reason: _byName(TagReason.values, row.read<String?>('reason')),
          endState: _byName(EndState.values, row.read<String?>('end_state')),
          occurredAt: row.read<DateTime>('occurred_at'),
          paddock: paddock,
          property: properties[paddock?.propertyId],
          livestockClass: classes[row.read<String?>('to_class_id')],
          replacedBy: role == TagRole.removed
              ? successors[row.read<String>('movement_id')]
              : null,
        ),
      );
    }
    return statuses;
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) =>
      name == null ? null : values.byName(name);

  /// The tag each movement added, which for a replacement is the new tag.
  Future<Map<String, LivestockTag>> _addedIn(Set<String> movementIds) async {
    if (movementIds.isEmpty) return const {};
    final rows =
        await (db.select(db.movementTags).join([
                innerJoin(
                  db.livestockTags,
                  db.livestockTags.id.equalsExp(db.movementTags.tagId),
                ),
              ])
              ..where(db.movementTags.movementId.isIn(movementIds))
              ..where(db.movementTags.role.equalsValue(TagRole.added))
              ..where(db.movementTags.deletedAt.isNull()))
            .get();
    return {
      for (final row in rows)
        row.readTable(db.movementTags).movementId: row.readTable(
          db.livestockTags,
        ),
    };
  }

  Future<Map<String, TagStatus>> _statusesOf(List<String> tagIds) async {
    if (tagIds.isEmpty) return const {};
    final rows = await _tagRows(
      'AND t.id IN (${[for (var i = 1; i <= tagIds.length; i++) '?$i'].join(', ')})',
      [for (final id in tagIds) Variable<String>(id)],
    ).get();
    return {for (final s in await _statuses(rows)) s.tag.id: s};
  }

  /// The tagged head standing in a paddock, by class and then number.
  Stream<List<TagStatus>> watchTagsIn(String paddockId) => _remembered(
    'tags:$paddockId',
    _tagsIn(paddockId).watch().asyncMap(_mobOrder),
  );

  Future<List<TagStatus>> tagsIn(String paddockId) async =>
      _mobOrder(await _tagsIn(paddockId).get());

  Selectable<QueryRow> _tagsIn(String paddockId) => _tagRows(
    'AND $_isActive AND l.to_paddock_id = ?1',
    [Variable<String>(paddockId)],
  );

  Future<List<TagStatus>> _mobOrder(List<QueryRow> rows) async {
    final statuses = await _statuses(rows);
    return statuses..sort((a, b) {
      final byClass = (a.livestockClass?.sortOrder ?? 0).compareTo(
        b.livestockClass?.sortOrder ?? 0,
      );
      return byClass != 0 ? byClass : a.tag.number.compareTo(b.tag.number);
    });
  }

  /// Every tag ever recorded, those still on the property first.
  Stream<List<TagStatus>> watchTags() =>
      _tagRows().watch().asyncMap((rows) async {
        final statuses = await _statuses(rows);
        return statuses..sort((a, b) {
          if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
          return a.tag.number.compareTo(b.tag.number);
        });
      });

  /// Emits null for an unknown tag, which a deep link can name.
  Stream<TagStatus?> watchTag(String id) => _remembered(
    'tag:$id',
    _tagRows('AND t.id = ?1', [
      Variable<String>(id),
    ]).watch().asyncMap((rows) async => (await _statuses(rows)).firstOrNull),
  );

  /// What a typed or scanned number already is, or null if it is new here.
  Future<TagStatus?> tagStatusByNumber(TagNumber number) async =>
      (await _resolve([number])).single.status;

  Future<String> createProperty(String name, {String? pic}) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            name: name,
            pic: Value(pic),
          ),
        );
    return id;
  }

  Future<String> createPaddock(
    String propertyId,
    String name, {
    double hectares = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await db
        .into(db.paddocks)
        .insert(
          PaddocksCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            propertyId: propertyId,
            name: name,
            hectares: Value(hectares),
          ),
        );
    return id;
  }

  Future<List<Property>> properties() => (db.select(
    db.properties,
  )..where((p) => p.deletedAt.isNull())).get();

  Stream<List<Property>> watchProperties() => (db.select(
    db.properties,
  )..where((p) => p.deletedAt.isNull())).watch();

  /// Emits null for an unknown or deleted property, which a deep link can name.
  Stream<Property?> watchProperty(String id) => _remembered(
    'property:$id',
    (db.select(db.properties)
          ..where((p) => p.id.equals(id))
          ..where((p) => p.deletedAt.isNull()))
        .watchSingleOrNull(),
  );

  Future<String> sqliteVersion() async {
    final row = await db
        .customSelect('SELECT sqlite_version() AS v')
        .getSingle();
    return row.read<String>('v');
  }

  Future<int> movementCount() async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM movements WHERE deleted_at IS NULL',
          readsFrom: {db.movements},
        )
        .getSingle();
    return row.read<int>('c');
  }

  /// Every (paddock, class) the ledger has driven below zero. `record` refuses
  /// to create one locally, so a non-empty result means a merge or a bug.
  Future<List<({String paddockId, String? classId, int head})>>
  negativeBalances() async {
    final rows = await db
        .customSelect(
          '''
          SELECT paddock_id AS pid, class_id AS cid, SUM(delta) AS head
            FROM ($_balances)
           GROUP BY paddock_id, class_id HAVING SUM(delta) < 0
          ''',
          readsFrom: {db.movements},
        )
        .get();
    return [
      for (final row in rows)
        (
          paddockId: row.read<String>('pid'),
          classId: row.read<String?>('cid'),
          head: row.read<int>('head'),
        ),
    ];
  }

  /// Every (paddock, class) holding more tags than head. `record` refuses to
  /// create one locally, so a non-empty result means a merge or a bug.
  Future<List<({String paddockId, String classId, int tagged, int head})>>
  overTaggedMobs() async {
    final rows = await db
        .customSelect(
          '''
          SELECT t.pid, t.cid, t.tagged, COALESCE(SUM(b.delta), 0) AS head
            FROM (SELECT to_paddock_id AS pid, to_class_id AS cid,
                         COUNT(*) AS tagged
                    FROM ($_tagLatest)
                   WHERE role <> 'removed' AND to_paddock_id IS NOT NULL
                   GROUP BY to_paddock_id, to_class_id) t
            LEFT JOIN ($_balances) b
              ON b.paddock_id = t.pid AND b.class_id = t.cid
           GROUP BY t.pid, t.cid, t.tagged
          HAVING t.tagged > COALESCE(SUM(b.delta), 0)
          ''',
          readsFrom: {db.movementTags, db.movements},
        )
        .get();
    return [
      for (final row in rows)
        (
          paddockId: row.read<String>('pid'),
          classId: row.read<String>('cid'),
          tagged: row.read<int>('tagged'),
          head: row.read<int>('head'),
        ),
    ];
  }

  Future<List<Paddock>> paddocksIn(String propertyId) =>
      (db.select(db.paddocks)
            ..where((p) => p.propertyId.equals(propertyId))
            ..where((p) => p.deletedAt.isNull())
            ..orderBy([(p) => OrderingTerm(expression: p.name)]))
          .get();

  Future<List<LivestockClass>> allClasses() => (db.select(db.livestockClasses)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
      .get();

  /// What is actually standing in a paddock right now, for pickers that must
  /// not offer livestock that is not there.
  Future<List<MobLine>> mobsIn(String paddockId) async {
    final rows = await db
        .customSelect(
          '''
          SELECT class_id AS cid, SUM(delta) AS head FROM ($_balances)
           WHERE paddock_id = ?1
           GROUP BY class_id HAVING SUM(delta) > 0
          ''',
          variables: [Variable<String>(paddockId)],
          readsFrom: {db.movements},
        )
        .get();

    final classes = await _classesById();

    final mobs = <MobLine>[];
    for (final row in rows) {
      final livestockClass = classes[row.read<String>('cid')];
      if (livestockClass == null) continue;
      mobs.add(
        MobLine(livestockClass: livestockClass, head: row.read<int>('head')),
      );
    }
    mobs.sort(
      (a, b) =>
          a.livestockClass.sortOrder.compareTo(b.livestockClass.sortOrder),
    );
    return mobs;
  }

  Future<List<LivestockClass>> classesIn(String templateId) =>
      (db.select(db.livestockClasses)
            ..where((c) => c.templateId.equals(templateId))
            ..where((c) => c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
          .get();

  Future<List<Template>> templates() => (db.select(
    db.templates,
  )..where((t) => t.deletedAt.isNull())).get();

  /// Seeds the built-in templates. The lists themselves are provisional and
  /// awaiting Alex; replacing the asset is a content change, not a code one.
  Future<void> seedTemplatesIfEmpty() async {
    final existing = await db.select(db.templates).get();
    if (existing.isNotEmpty) return;

    final raw = await rootBundle.loadString(
      'assets/templates/default_templates.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      for (final entry in decoded.cast<Map<String, dynamic>>()) {
        final templateId = _uuid.v4();
        await db
            .into(db.templates)
            .insert(
              TemplatesCompanion.insert(
                id: templateId,
                createdAt: now,
                updatedAt: now,
                name: entry['name'] as String,
                isBuiltIn: const Value(true),
              ),
            );

        final classes = (entry['classes'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        // Ids are allocated up front so `agesInto` can point at a class that
        // has not been inserted yet.
        final ids = [for (final _ in classes) _uuid.v4()];

        for (var i = 0; i < classes.length; i++) {
          final agesInto = classes[i]['agesInto'] as int?;
          await db
              .into(db.livestockClasses)
              .insert(
                LivestockClassesCompanion.insert(
                  id: ids[i],
                  createdAt: now,
                  updatedAt: now,
                  templateId: templateId,
                  kind: classes[i]['kind'] as String,
                  ageBand: classes[i]['ageBand'] as String,
                  breed: Value(classes[i]['breed'] as String?),
                  agesIntoClassId: Value(
                    agesInto == null ? null : ids[agesInto],
                  ),
                  sortOrder: Value(i),
                ),
              );
        }
      }
    });
  }
}
