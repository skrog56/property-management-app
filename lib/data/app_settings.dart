import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'app_database.dart';

enum RetentionUnit {
  days('day', 'D'),
  weeks('week', 'W'),
  months('month', 'M'),
  years('year', 'Y');

  const RetentionUnit(this.singular, this.letter);

  final String singular;

  /// Its letter in an ISO 8601 duration, as the setting is stored.
  final String letter;

  String counted(int count) => count == 1 ? singular : '${singular}s';
}

/// How long ended stock stays in view: a stretch of whole local days, today
/// the last of them, or always.
@immutable
class Retention {
  const Retention(this.count, this.unit) : assert(count > 0);

  const Retention._always() : count = 0, unit = RetentionUnit.days;

  static const always = Retention._always();
  static const standard = Retention(30, RetentionUnit.days);

  static const presets = [
    Retention(7, RetentionUnit.days),
    standard,
    Retention(90, RetentionUnit.days),
    Retention(1, RetentionUnit.years),
    always,
  ];

  final int count;
  final RetentionUnit unit;

  bool get isAlways => count == 0;

  /// The local midnight the stretch starts at, or null for always. A month
  /// back from the 31st lands on the last day of a shorter month.
  DateTime? since(DateTime now) {
    if (isAlways) return null;
    final local = now.toLocal();
    final (y, m, d) = (local.year, local.month, local.day);
    switch (unit) {
      case RetentionUnit.days:
        return DateTime(y, m, d - (count - 1));
      case RetentionUnit.weeks:
        return DateTime(y, m, d - (count * 7 - 1));
      case RetentionUnit.months:
      case RetentionUnit.years:
        final months = unit == RetentionUnit.years ? count * 12 : count;
        final first = DateTime(y, m - months);
        final lastDay = DateTime(first.year, first.month + 1, 0).day;
        return DateTime(
          first.year,
          first.month,
          (d < lastDay ? d : lastDay) + 1,
        );
    }
  }

  /// As a choice is listed: "30 days", "1 year", "Always".
  String get label => isAlways ? 'Always' : '$count ${unit.counted(count)}';

  /// As a heading: "Last 30 days", "Past year", "All time".
  String get title => switch (this) {
    _ when isAlways => 'All time',
    Retention(count: 1, unit: RetentionUnit.days) => 'Today',
    Retention(count: 1) => 'Past ${unit.singular}',
    _ => 'Last $label',
  };

  /// As the end of a sentence: "in the last 30 days", or null for always.
  String? get within => switch (this) {
    _ when isAlways => null,
    Retention(count: 1, unit: RetentionUnit.days) => 'today',
    Retention(count: 1) => 'in the past ${unit.singular}',
    _ => 'in the last $label',
  };

  String get code => isAlways ? 'always' : 'P$count${unit.letter}';

  static final _code = RegExp(r'^P([1-9]\d{0,2})([DWMY])$');

  /// Null for anything [code] would not have written.
  static Retention? parse(String? code) {
    if (code == 'always') return always;
    final match = _code.firstMatch(code ?? '');
    if (match == null) return null;
    final unit = RetentionUnit.values.firstWhere(
      (u) => u.letter == match.group(2),
    );
    return Retention(int.parse(match.group(1)!), unit);
  }

  @override
  bool operator ==(Object other) =>
      other is Retention && other.count == count && other.unit == unit;

  @override
  int get hashCode => Object.hash(count, unit);

  @override
  String toString() => code;
}

/// The user's settings, read once at launch and kept in memory, each change
/// written through to the `settings` table. Until [load], every setting holds
/// its default.
class AppSettings extends ChangeNotifier {
  AppSettings(this._db);

  final AppDatabase _db;
  final _values = <String, String>{};

  static const _retention = 'retention';
  static const _theme = 'theme';
  static const _rememberTemplatesView = 'templates.remember';

  /// The Templates page's grouping and sort, kept only while
  /// [remembersTemplatesView].
  static const templatesGrouped = 'templates.grouped';
  static const templatesSort = 'templates.sort';

  Future<void> load() async {
    final rows = await (_db.select(
      _db.settings,
    )..where((s) => s.deletedAt.isNull())).get();
    _values
      ..clear()
      ..addAll({for (final row in rows) row.id: row.value});
    notifyListeners();
  }

  /// A setting a feature keeps for itself, by name.
  String? operator [](String name) => _values[name];

  Future<void> put(String name, String value) async {
    if (_values[name] == value) return;
    _values[name] = value;
    notifyListeners();

    final now = DateTime.now().toUtc();
    await _db
        .into(_db.settings)
        .insert(
          SettingsCompanion.insert(
            id: name,
            createdAt: now,
            updatedAt: now,
            value: value,
          ),
          onConflict: DoUpdate(
            (_) => SettingsCompanion(
              value: Value(value),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ),
          ),
        );
  }

  /// Clears a setting, so it reads as its default again.
  Future<void> forget(String name) async {
    if (_values.remove(name) == null) return;
    notifyListeners();

    final now = DateTime.now().toUtc();
    await (_db.update(_db.settings)..where((s) => s.id.equals(name))).write(
      SettingsCompanion(updatedAt: Value(now), deletedAt: Value(now)),
    );
  }

  Retention get retention =>
      Retention.parse(this[_retention]) ?? Retention.standard;

  Future<void> setRetention(Retention retention) =>
      put(_retention, retention.code);

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[this[_theme]] ?? ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) => put(_theme, mode.name);

  bool get remembersTemplatesView => this[_rememberTemplatesView] != 'false';

  /// Turned off, the view kept so far is forgotten too, so turning it back
  /// on starts from the defaults rather than an old view.
  Future<void> setRemembersTemplatesView(bool remember) async {
    await put(_rememberTemplatesView, '$remember');
    if (!remember) {
      await forget(templatesGrouped);
      await forget(templatesSort);
    }
  }
}
