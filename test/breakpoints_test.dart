import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/shell/breakpoints.dart';

void main() {
  group('WindowSizeClass.fromWidth', () {
    test('maps widths to the Material 3 size classes', () {
      expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(839.9), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1199.9), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1200), WindowSizeClass.large);
      expect(WindowSizeClass.fromWidth(1599.9), WindowSizeClass.large);
      expect(WindowSizeClass.fromWidth(1600), WindowSizeClass.extraLarge);
      expect(WindowSizeClass.fromWidth(4000), WindowSizeClass.extraLarge);
    });

    test('only the compact class uses a bottom bar', () {
      for (final sizeClass in WindowSizeClass.values) {
        expect(
          sizeClass.usesBottomBar,
          sizeClass == WindowSizeClass.compact,
          reason: '$sizeClass',
        );
      }
    });

    test('rail labels appear from expanded upwards', () {
      expect(WindowSizeClass.compact.usesExtendedRail, isFalse);
      expect(WindowSizeClass.medium.usesExtendedRail, isFalse);
      expect(WindowSizeClass.expanded.usesExtendedRail, isTrue);
      expect(WindowSizeClass.large.usesExtendedRail, isTrue);
      expect(WindowSizeClass.extraLarge.usesExtendedRail, isTrue);
    });

    test('content columns grow with available width', () {
      expect(WindowSizeClass.compact.contentColumns, 1);
      expect(WindowSizeClass.medium.contentColumns, 1);
      expect(WindowSizeClass.expanded.contentColumns, 2);
      expect(WindowSizeClass.large.contentColumns, 2);
      expect(WindowSizeClass.extraLarge.contentColumns, 3);
    });

    test('every size class has a label', () {
      for (final sizeClass in WindowSizeClass.values) {
        expect(sizeClass.label, isNotEmpty);
      }
    });
  });
}
