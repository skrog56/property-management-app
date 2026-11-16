import 'package:flutter/foundation.dart' show immutable;

import '../../data/livestock_repository.dart';
import '../../data/tables.dart';
import '../../data/tag_numbers.dart';
import '../tags/tag_labels.dart';
import '../templates/species.dart';
import '../transfers/movement_dialog.dart' show MovementKindLabel;

/// The lists an export can hold, in the order they are written.
enum ExportList {
  movements('Movements', 'movements'),
  stock('Stock on hand', 'stock-on-hand'),
  tags('Tags', 'tags'),
  paddocks('Properties and paddocks', 'properties-and-paddocks'),
  templates('Templates and classes', 'templates-and-classes');

  const ExportList(this.title, this.slug);

  final String title;

  /// Its file name, where a list is a file of its own.
  final String slug;
}

/// What an export is narrowed to. Dates are whole local days, both included,
/// and narrow only the movements.
@immutable
class ExportRange {
  const ExportRange({this.propertyId, this.from, this.to});

  static const everything = ExportRange();

  final String? propertyId;
  final DateTime? from;
  final DateTime? to;

  DateTime? get since => from == null ? null : _midnight(from!);

  /// The midnight after [to], which the movements must come before.
  DateTime? get until =>
      to == null ? null : _midnight(to!).copyWith(day: to!.day + 1);

  static DateTime _midnight(DateTime day) {
    final local = day.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

/// One list, as rows of text, numbers and times under its column names. A
/// cell is a [String], [num], [DateTime] or null.
@immutable
class ExportSheet {
  const ExportSheet(this.list, this.columns, this.rows);

  final ExportList list;
  final List<String> columns;
  final List<List<Object?>> rows;

  String get title => list.title;
}

extension ExportData on LivestockRepository {
  /// Each of [lists] as it stands now, in [ExportList] order, narrowed to
  /// [range].
  Future<List<ExportSheet>> exportSheets(
    Set<ExportList> lists, {
    ExportRange range = ExportRange.everything,
  }) async {
    final overview = await watchOverview().first;
    final properties = [
      for (final stock in overview.properties)
        if (range.propertyId == null || stock.property.id == range.propertyId)
          stock,
    ];

    return [
      for (final list in ExportList.values)
        if (lists.contains(list))
          switch (list) {
            ExportList.movements => await _movementSheet(range),
            ExportList.stock => await _stockSheet(properties),
            ExportList.tags => await _tagSheet(range),
            ExportList.paddocks => _paddockSheet(properties),
            ExportList.templates => await _templateSheet(),
          },
    ];
  }

  /// Every row of every table as stored, deleted rows and settings with them,
  /// for a backup a later restore could read.
  Future<Map<String, List<Map<String, Object?>>>> exportTables() async => {
    for (final table in db.allTables)
      table.actualTableName: [
        for (final row
            in await db
                .customSelect(
                  'SELECT * FROM "${table.actualTableName}" ORDER BY rowid',
                  readsFrom: {table},
                )
                .get())
          row.data,
      ],
  };

  String get _area => 'Area (${settings.areaUnit.symbol})';

  double _inUnit(double hectares) =>
      double.parse(settings.areaUnit.fromHectares(hectares).toStringAsFixed(2));

  Future<ExportSheet> _movementSheet(ExportRange range) async {
    final entries = await activityEntries(
      propertyId: range.propertyId,
      since: range.since,
      until: range.until,
    );
    final propertyNames = {for (final p in await properties()) p.id: p.name};
    String numbers(Iterable<TagRef> refs) =>
        [for (final ref in refs) ref.tag.tagNumber.display].join(', ');

    return ExportSheet(
      ExportList.movements,
      const [
        'Date',
        'Type',
        'Head',
        'Property',
        'From paddock',
        'From class',
        'To paddock',
        'To class',
        'End destination',
        'Tags',
        'Tags removed',
        'Reason',
        'Note',
      ],
      [
        for (final e in entries)
          [
            e.movement.occurredAt.toLocal(),
            e.movement.kind.label,
            e.movement.head,
            propertyNames[(e.fromPaddock ?? e.toPaddock)?.propertyId],
            e.fromPaddock?.name,
            e.fromClass?.label,
            e.toPaddock?.name,
            e.toClass?.label,
            e.movement.endState?.label,
            numbers(e.tags.where((t) => t.role != TagRole.removed)),
            numbers(e.tags.where((t) => t.role == TagRole.removed)),
            {
              for (final t in e.tags)
                if (t.reason case final reason?) reason.label,
            }.join(', '),
            e.movement.note,
          ],
      ],
    );
  }

  Future<ExportSheet> _stockSheet(List<PropertyStock> properties) async {
    final tagged = <(String, String), int>{};
    for (final status in await watchTags().first) {
      if (!status.isActive || status.stockClass == null) continue;
      final mob = (status.paddock!.id, status.stockClass!.id);
      tagged[mob] = (tagged[mob] ?? 0) + 1;
    }

    return ExportSheet(
      ExportList.stock,
      [
        'Property',
        'PIC',
        'Paddock',
        _area,
        'Class',
        'Animal',
        'Head',
        'Tagged',
      ],
      [
        for (final stock in properties)
          for (final paddock in stock.paddocks)
            for (final mob in paddock.mobs)
              [
                stock.property.name,
                stock.property.pic,
                paddock.paddock.name,
                _inUnit(paddock.paddock.hectares),
                mob.label,
                mob.stockClass.template.species.label,
                mob.head,
                tagged[(paddock.paddock.id, mob.stockClass.id)] ?? 0,
              ],
      ],
    );
  }

  Future<ExportSheet> _tagSheet(ExportRange range) async {
    final statuses = await watchTags().first;

    return ExportSheet(
      ExportList.tags,
      const [
        'Number',
        'Type',
        'Status',
        'Property',
        'Paddock',
        'Class',
        'Since',
        'Reason',
        'Replaced by',
      ],
      [
        for (final s in statuses)
          if (range.propertyId == null || s.property?.id == range.propertyId)
            [
              s.tag.tagNumber.display,
              s.tag.scheme.label,
              _tagState(s),
              s.property?.name,
              s.paddock?.name,
              s.stockClass?.label,
              s.occurredAt.toLocal(),
              s.reason?.label,
              s.replacedBy?.tagNumber.display,
            ],
      ],
    );
  }

  static String _tagState(TagStatus s) {
    if (s.isActive) return 'On hand';
    if (s.replacedBy != null) return 'Replaced';
    if (s.role == TagRole.removed) return 'Cancelled';
    return s.endState?.label ?? 'Ended';
  }

  ExportSheet _paddockSheet(List<PropertyStock> properties) => ExportSheet(
    ExportList.paddocks,
    ['Property', 'PIC', 'Paddock', _area, 'Head'],
    [
      for (final stock in properties)
        if (stock.paddocks.isEmpty)
          [stock.property.name, stock.property.pic, null, null, 0]
        else
          for (final paddock in stock.paddocks)
            [
              stock.property.name,
              stock.property.pic,
              paddock.paddock.name,
              _inUnit(paddock.paddock.hectares),
              paddock.head,
            ],
    ],
  );

  Future<ExportSheet> _templateSheet() async {
    final templates = await watchTemplates().first;
    final labels = {
      for (final t in templates)
        for (final c in t.classes) c.id: c.label,
    };

    return ExportSheet(
      ExportList.templates,
      const [
        'Template',
        'Animal',
        'Class',
        'Breed',
        'Age band',
        'Ages into',
        'Ready to sell',
        'Head',
      ],
      [
        for (final t in templates)
          for (final c in t.classes)
            [
              t.template.name,
              t.template.species.label,
              c.row.kind,
              c.row.breed,
              c.row.ageBand,
              labels[c.row.agesIntoClassId],
              c.isReadyToSell ? 'Yes' : 'No',
              t.headIn(c.id),
            ],
      ],
    );
  }
}

extension on EndState {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

/// What a list holds and where it came from, for a report's heading.
String describeRange(ExportRange range, {String? propertyName}) {
  final where = propertyName ?? 'All properties';
  final (from, to) = (range.from, range.to);
  final when = switch ((from, to)) {
    (null, null) => 'all movements',
    (final from?, null) => 'movements from ${shortDate(from)}',
    (null, final to?) => 'movements to ${shortDate(to)}',
    (final from?, final to?) =>
      'movements ${shortDate(from)} to ${shortDate(to)}',
  };
  return '$where · $when';
}
