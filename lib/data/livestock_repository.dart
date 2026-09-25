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

/// Every head count in the app comes out of here, folded from [Movements].
class LivestockRepository {
  LivestockRepository(this.db);

  final AppDatabase db;

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

  Stream<List<PaddockSummary>> watchPaddockSummaries(String propertyId) {
    return db
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

    final classes = {
      for (final c in await db.select(db.livestockClasses).get()) c.id: c,
    };

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

  Stream<List<Movement>> watchActivity({int limit = 200}) {
    return (db.select(db.movements)
          ..where((m) => m.deletedAt.isNull())
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

  Stream<List<ActivityEntry>> watchActivityEntries({int limit = 200}) {
    return watchActivity(limit: limit).asyncMap((movements) async {
      final paddocks = {
        for (final p in await db.select(db.paddocks).get()) p.id: p.name,
      };
      final classes = {
        for (final c in await db.select(db.livestockClasses).get())
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

    final classes = {
      for (final c in await db.select(db.livestockClasses).get()) c.id: c,
    };

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
