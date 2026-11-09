import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/shell/pill_controls.dart';

void main() {
  Future<TextEditingController> pump(
    WidgetTester tester, {
    VisualDensity density = VisualDensity.standard,
    ValueChanged<String>? onChanged,
  }) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: density),
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: PillSearchField(
                  controller: controller,
                  hintText: 'Search',
                  onChanged: onChanged ?? (_) {},
                ),
              ),
              PillChips(
                children: [
                  FilterChip(
                    label: const Text('Grouped'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  ActionChip(label: const Text('Sort'), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('clears its search, and says so', (tester) async {
    final changes = <String>[];
    await pump(tester, onChanged: changes.add);
    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ewes');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(changes, ['ewes', '']);
    expect(find.text('ewes'), findsNothing);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  for (final density in [VisualDensity.standard, VisualDensity.compact]) {
    testWidgets(
      'gives the search and its chips one height, with or without '
      'its clear button, at ${density.horizontal == 0 ? 'standard' : 'compact'} density',
      (tester) async {
        await pump(tester, density: density);
        final height = kMinInteractiveDimension + density.baseSizeAdjustment.dy;

        List<double> heights() => [
          tester.getSize(find.byType(InputDecorator)).height,
          // A chip's outline is drawn outside its box.
          for (final chip in [FilterChip, ActionChip])
            tester
                    .getSize(
                      find
                          .descendant(
                            of: find.byType(chip),
                            matching: find.byType(Material),
                          )
                          .first,
                    )
                    .height +
                2,
        ];

        // Within a rounding of the chip label's line height.
        expect(heights(), everyElement(closeTo(height, 0.1)));
        await tester.enterText(find.byType(TextField), 'ewes');
        await tester.pump();
        expect(heights(), everyElement(closeTo(height, 0.1)));
      },
    );
  }

  testWidgets('changes only a chip\'s outline on hover, as the search\'s', (
    tester,
  ) async {
    await pump(tester);

    for (final chip in [FilterChip, ActionChip]) {
      final ink = tester.widget<InkWell>(
        find.descendant(of: find.byType(chip), matching: find.byType(InkWell)),
      );
      expect(ink.hoverColor, Colors.transparent, reason: '$chip');
    }
  });

  group('a toolbar', () {
    const hint = 'Search templates and classes';

    Future<TextEditingController> toolbar(
      WidgetTester tester,
      double width,
    ) async {
      // The test font draws every glyph as a square, so the hint is wider than
      // it would be in Roboto.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 400);
      addTearDown(tester.view.reset);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: PillToolbar(
                  search: PillSearchField(
                    controller: controller,
                    hintText: hint,
                    onChanged: (_) {},
                  ),
                  chips: PillChips(
                    children: [
                      FilterChip(
                        label: const Text('Group by animal'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      ActionChip(
                        label: const Text('Most head'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return controller;
    }

    bool beside(WidgetTester tester) =>
        tester.getTopLeft(find.byType(PillChips)).dy <
        tester.getBottomLeft(find.byType(PillSearchField)).dy;

    testWidgets('keeps its chips beside the search only while the whole hint '
        'fits', (tester) async {
      final arrangements = <bool>{};
      for (var width = 300.0; width <= 1200; width += 10) {
        await toolbar(tester, width);
        arrangements.add(beside(tester));
        if (beside(tester)) {
          expect(
            tester
                .renderObject<RenderParagraph>(find.text(hint))
                .didExceedMaxLines,
            isFalse,
            reason: 'at $width',
          );
        }
      }
      expect(arrangements, {true, false});
    });

    testWidgets('moves nothing as text is typed', (tester) async {
      // The narrowest that keeps the chips beside the search.
      var width = 300.0;
      do {
        width += 10;
        await toolbar(tester, width);
      } while (!beside(tester) && width < 1200);
      expect(beside(tester), isTrue);
      final chips = tester.getRect(find.byType(PillChips));

      await tester.enterText(
        find.byType(TextField),
        'a query far longer than the field it is typed into',
      );
      await tester.pump();

      expect(beside(tester), isTrue);
      expect(tester.getRect(find.byType(PillChips)), chips);
    });
  });
}
