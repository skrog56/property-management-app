import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/app/router.dart';
import 'package:property_management_app/shell/adaptive_scaffold.dart';

// Widget tests draw text in a font whose every glyph is a full square, so
// widths mean nothing until the real one is loaded: the copy the app bundles.
Future<void> _loadRoboto() async {
  final file = File('assets/fonts/Roboto-Medium.ttf');
  final bytes = await file.readAsBytes();
  await (FontLoader(
    'Roboto',
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

Future<List<RenderParagraph>> _labelsAt(
  WidgetTester tester,
  double width,
  List<AppDestination> destinations,
) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: AdaptiveScaffold(
        destinations: destinations,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        body: const SizedBox(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return [
    for (final e
        in find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.byType(RichText),
            )
            .evaluate())
      if (e.renderObject! case final RenderParagraph p
          when p.text.style?.fontFamily != 'MaterialIcons')
        p,
  ];
}

void main() {
  setUpAll(_loadRoboto);

  testWidgets('every label fits whole on one line on a 320 dp phone', (
    tester,
  ) async {
    final labels = await _labelsAt(tester, 320, [
      for (final e in homeDestinations(developer: true)) e.destination,
    ]);

    expect(labels, hasLength(4));
    for (final p in labels) {
      final text = p.text.toPlainText();
      expect(
        p.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(p.constraints.maxWidth),
        reason: text,
      );
      expect(
        p.size.height,
        p.getMaxIntrinsicHeight(double.infinity),
        reason: text,
      );
    }
  });

  testWidgets('a label too long for its slot truncates rather than wraps', (
    tester,
  ) async {
    final labels = await _labelsAt(tester, 320, [
      for (final label in ['Extraordinarily long', 'Two', 'Three', 'Four'])
        AppDestination(
          label: label,
          icon: Icons.circle_outlined,
          selectedIcon: Icons.circle,
        ),
    ]);

    final long = labels.first;
    expect(long.didExceedMaxLines, isTrue);
    expect(long.size.height, long.getMaxIntrinsicHeight(double.infinity));
  });
}
