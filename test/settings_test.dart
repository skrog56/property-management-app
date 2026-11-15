import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/app_database.dart';
import 'package:property_management_app/data/app_settings.dart';

void main() {
  group('Retention', () {
    final now = DateTime(2026, 3, 31, 14, 20);

    test('starts at the midnight that makes today the last day', () {
      expect(
        const Retention(1, RetentionUnit.days).since(now),
        DateTime(2026, 3, 31),
      );
      expect(Retention.standard.since(now), DateTime(2026, 3, 2));
      expect(
        const Retention(2, RetentionUnit.weeks).since(now),
        DateTime(2026, 3, 18),
      );
    });

    test('counts calendar months and years', () {
      expect(
        const Retention(1, RetentionUnit.months).since(DateTime(2026, 11, 15)),
        DateTime(2026, 10, 16),
      );
      expect(
        const Retention(1, RetentionUnit.years).since(DateTime(2026, 11, 15)),
        DateTime(2025, 11, 16),
      );
    });

    test('a month back from the 31st stops at a shorter month\'s end', () {
      // February 2026 has 28 days, so the stretch starts on 1 March.
      expect(
        const Retention(1, RetentionUnit.months).since(now),
        DateTime(2026, 3, 1),
      );
      // A leap year's 29 February, a year back from the next.
      expect(
        const Retention(1, RetentionUnit.years).since(DateTime(2029, 2, 28)),
        DateTime(2028, 2, 29),
      );
    });

    test('always has no start', () {
      expect(Retention.always.since(now), isNull);
      expect(Retention.always.isAlways, isTrue);
    });

    test('names itself for a list, a heading and a sentence', () {
      expect(Retention.standard.label, '30 days');
      expect(Retention.standard.title, 'Last 30 days');
      expect(Retention.standard.within, 'in the last 30 days');

      const year = Retention(1, RetentionUnit.years);
      expect(year.label, '1 year');
      expect(year.title, 'Past year');
      expect(year.within, 'in the past year');

      const today = Retention(1, RetentionUnit.days);
      expect(today.title, 'Today');
      expect(today.within, 'today');

      expect(Retention.always.label, 'Always');
      expect(Retention.always.title, 'All time');
      expect(Retention.always.within, isNull);
    });

    test('reads back what it writes, and nothing else', () {
      for (final retention in [
        ...Retention.presets,
        const Retention(6, RetentionUnit.weeks),
        const Retention(3, RetentionUnit.months),
        const Retention(999, RetentionUnit.years),
      ]) {
        expect(Retention.parse(retention.code), retention);
      }
      expect(Retention.standard.code, 'P30D');
      expect(Retention.always.code, 'always');
      for (final bad in [null, '', 'P0D', 'P1000D', 'P3X', '30', 'p30d']) {
        expect(Retention.parse(bad), isNull, reason: bad);
      }
    });
  });

  group('AppSettings', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('holds the defaults until something is chosen', () async {
      final settings = AppSettings(db);
      await settings.load();

      expect(settings.retention, Retention.standard);
      expect(settings.themeMode, ThemeMode.system);
      expect(settings['templates.sort'], isNull);
    });

    test('keeps what is chosen for the next launch', () async {
      final first = AppSettings(db);
      await first.setRetention(const Retention(6, RetentionUnit.weeks));
      await first.setThemeMode(ThemeMode.dark);
      await first.put('templates.sort', 'newest');
      await first.setThemeMode(ThemeMode.light);

      final next = AppSettings(db);
      await next.load();

      expect(next.retention, const Retention(6, RetentionUnit.weeks));
      expect(next.themeMode, ThemeMode.light);
      expect(next['templates.sort'], 'newest');
      // One row a setting, however often it changes.
      expect(await db.select(db.settings).get(), hasLength(3));
    });

    test('tells its listeners of a change, and only of a change', () async {
      final settings = AppSettings(db);
      var told = 0;
      settings.addListener(() => told++);

      await settings.setThemeMode(ThemeMode.dark);
      await settings.setThemeMode(ThemeMode.dark);

      expect(told, 1);
    });

    test('remembers the Templates view until told not to', () async {
      final settings = AppSettings(db);
      expect(settings.remembersTemplatesView, isTrue);

      await settings.put(AppSettings.templatesGrouped, 'false');
      await settings.put(AppSettings.templatesSort, 'newest');
      await settings.setRemembersTemplatesView(false);

      expect(settings[AppSettings.templatesGrouped], isNull);
      expect(settings[AppSettings.templatesSort], isNull);

      final next = AppSettings(db);
      await next.load();
      expect(next.remembersTemplatesView, isFalse);
      expect(next[AppSettings.templatesSort], isNull);

      // Kept again from the next choice, in the row it had.
      await next.setRemembersTemplatesView(true);
      await next.put(AppSettings.templatesSort, 'oldest');
      final third = AppSettings(db);
      await third.load();
      expect(third[AppSettings.templatesSort], 'oldest');
      expect(third[AppSettings.templatesGrouped], isNull);
    });

    test('falls back to the default for a value it cannot read', () async {
      final settings = AppSettings(db);
      await settings.put('retention', 'fortnightly');
      await settings.put('theme', 'sepia');

      expect(settings.retention, Retention.standard);
      expect(settings.themeMode, ThemeMode.system);
    });
  });
}
