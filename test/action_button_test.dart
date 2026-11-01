import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/app/theme.dart';
import 'package:property_management_app/shell/action_button.dart';

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        floatingActionButton: ActionButton(
          icon: Icons.swap_horiz,
          label: 'Record movement',
          onPressed: () {},
        ),
      ),
    ),
  );
}

final _button = find.byType(FloatingActionButton);

void _expectCircle(WidgetTester tester) {
  final size = tester.getSize(_button);
  expect(size.width, size.height);
  expect(find.text('Record movement'), findsNothing);
}

void _expectPill(WidgetTester tester) {
  final size = tester.getSize(_button);
  expect(size.width, greaterThan(size.height));
  expect(find.text('Record movement'), findsOneWidget);
}

void main() {
  testWidgets('a compact window shows a circle that names itself', (
    tester,
  ) async {
    await _pump(tester, 420);

    _expectCircle(tester);
    expect(find.bySemanticsLabel('Record movement'), findsOneWidget);
    expect(
      tester.widget<RawMaterialButton>(find.byType(RawMaterialButton)).shape,
      isA<StadiumBorder>(),
    );
  });

  testWidgets('hovering the circle opens it into the pill', (tester) async {
    await _pump(tester, 420);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(_button));
    await tester.pumpAndSettle();
    _expectPill(tester);

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    _expectCircle(tester);
  });

  testWidgets('a long press opens the circle until it is released', (
    tester,
  ) async {
    await _pump(tester, 420);

    final finger = await tester.startGesture(tester.getCenter(_button));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    _expectPill(tester);

    await finger.up();
    await tester.pumpAndSettle();
    _expectCircle(tester);
  });

  testWidgets('a long press the system takes over still closes', (
    tester,
  ) async {
    await _pump(tester, 420);

    final finger = await tester.startGesture(tester.getCenter(_button));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    _expectPill(tester);

    await finger.cancel();
    await tester.pumpAndSettle();
    _expectCircle(tester);
  });

  testWidgets('holding a mouse button down does not close the hovered pill', (
    tester,
  ) async {
    await _pump(tester, 420);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(_button));
    await tester.pumpAndSettle();

    await mouse.down(tester.getCenter(_button));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await mouse.up();
    await tester.pumpAndSettle();
    _expectPill(tester);
  });

  testWidgets('anything wider shows a labelled pill', (tester) async {
    await _pump(tester, 700);

    _expectPill(tester);
    expect(
      tester.widget<RawMaterialButton>(find.byType(RawMaterialButton)).shape,
      isA<StadiumBorder>(),
    );
  });
}
