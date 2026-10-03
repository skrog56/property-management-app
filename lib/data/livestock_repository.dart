import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'tables.dart';

const _uuid = Uuid();

/// Stands in for the signed-in user until accounts exist.
const localActorId = 'local';

class InsufficientHead implements Exception {
  const InsufficientHead({required this.available, required this.requested});

  final int available;
  final int requested;

  @override
  String toString() =>
      'Only $available head available, but $requested were requested';
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
  });

  final Movement movement;
  final String? fromPaddock;
  final String? toPaddock;
  final String? fromClass;
  final String? toClass;
}

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
  }) => _latest['activity:$paddockId:$limit'] as List<ActivityEntry>?;

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

  Stream<List<Movement>> watchActivity({int limit = 200, String? paddockId}) {
    return (db.select(db.movements)
          ..where((m) => m.deletedAt.isNull())
          ..where(
            (m) => paddockId == null
                ? const Constant(true)
                : m.fromPaddockId.equals(paddockId) |
                      m.toPaddockId.equals(paddockId),
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
  }) {
    final entries = watchActivity(limit: limit, paddockId: paddockId).asyncMap((
      movements,
    ) async {
      final paddocks = {
        for (final p in await db.select(db.paddocks).get()) p.id: p.name,
      };
      final classes = {
        for (final c in (await _classesById()).values)
          c.id: '${c.kind} (${c.ageBand})',
      };

      return [
        for (final m in movements)
          ActivityEntry(
            movement: m,
            fromPaddock: paddocks[m.fromPaddockId],
            toPaddock: paddocks[m.toPaddockId],
            fromClass: classes[m.fromClassId],
            toClass: classes[m.toClassId],
          ),
      ];
    });
    return _remembered('activity:$paddockId:$limit', entries);
  }

  /// Rejects anything that would drive a paddock's count negative. That check
  /// is the same one an admin will arbitrate after offline sync, which is why
  /// it lives here rather than in the form.
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
  }) async {
    if (head <= 0) {
      throw ArgumentError.value(head, 'head', 'must be greater than zero');
    }

    if (fromPaddockId != null && fromClassId != null) {
      final available = await headIn(fromPaddockId, fromClassId);
      if (available < head) {
        throw InsufficientHead(available: available, requested: head);
      }
    }

    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    await db
        .into(db.movements)
        .insert(
          MovementsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            occurredAt: occurredAt?.toUtc() ?? now,
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

    return id;
  }

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
