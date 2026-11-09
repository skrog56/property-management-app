import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/features/templates/species.dart';

void main() {
  test('every animal has an icon drawn within its 24-unit grid', () {
    const grid = Rect.fromLTRB(0, 0, 24, 24);

    for (final species in Species.values) {
      final strokes = speciesStrokes(species);
      final lines = strokes.lines.getBounds();
      expect(lines.isEmpty, isFalse, reason: species.name);
      expect(grid.intersect(lines), lines, reason: species.name);
      // Eyes, where the animal has them.
      final dots = strokes.dots.getBounds();
      if (!dots.isEmpty) {
        expect(grid.intersect(dots), dots, reason: species.name);
      }
    }
  });

  testWidgets('an animal icon takes its size and colour from the icon theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      const IconTheme(
        data: IconThemeData(size: 18, color: Color(0xFF336699)),
        child: Center(child: SpeciesIcon(Species.goat)),
      ),
    );

    expect(tester.getSize(find.byType(SpeciesIcon)), const Size(18, 18));
    expect(
      tester.renderObject(
        find.descendant(
          of: find.byType(SpeciesIcon),
          matching: find.byType(CustomPaint),
        ),
      ),
      paints..path(color: const Color(0xFF336699), style: PaintingStyle.stroke),
    );
  });
}
