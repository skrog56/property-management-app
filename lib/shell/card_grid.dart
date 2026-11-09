import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Cards in rows of [columns], each row as tall as its tallest card, so what
/// sits at the foot of each card lines up across the row.
///
/// Not `IntrinsicHeight`: `ListTile` underestimates its intrinsic height once
/// its text wraps, and a card sized from that overflows.
class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.columns,
    this.spacing = 12,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing,
      children: [
        for (var start = 0; start < children.length; start += columns)
          _Row(
            columns: columns,
            spacing: spacing,
            children: children.sublist(
              start,
              math.min(start + columns, children.length),
            ),
          ),
      ],
    );
  }
}

class _Row extends MultiChildRenderObjectWidget {
  const _Row({
    required this.columns,
    required this.spacing,
    required super.children,
  });

  final int columns;
  final double spacing;

  @override
  _RenderRow createRenderObject(BuildContext context) => _RenderRow(
    columns: columns,
    spacing: spacing,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderRow renderObject) {
    renderObject
      ..columns = columns
      ..spacing = spacing
      ..textDirection = Directionality.of(context);
  }
}

class _RowParentData extends ContainerBoxParentData<RenderBox> {}

/// Lays each child out at the width of a column, then again at least as tall
/// as the tallest. A short last row keeps the columns of the rows above it.
class _RenderRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowParentData> {
  _RenderRow({
    required this._columns,
    required this._spacing,
    required this._textDirection,
  });

  int _columns;
  set columns(int value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowParentData) {
      child.parentData = _RowParentData();
    }
  }

  double _columnWidth(double width) =>
      math.max(0, (width - _spacing * (_columns - 1)) / _columns);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = _columnWidth(constraints.maxWidth);
    var height = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final size = child.getDryLayout(BoxConstraints.tightFor(width: width));
      height = math.max(height, size.height);
    }
    return constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  void performLayout() {
    final width = _columnWidth(constraints.maxWidth);
    var height = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      height = math.max(height, child.size.height);
    }

    var x = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      // A minimum rather than a tight height: a child with tight constraints
      // relays itself out alone when its content changes, and never grows.
      child.layout(
        BoxConstraints(minWidth: width, maxWidth: width, minHeight: height),
        parentUsesSize: true,
      );
      (child.parentData! as _RowParentData).offset = Offset(
        _textDirection == TextDirection.ltr
            ? x
            : constraints.maxWidth - x - width,
        0,
      );
      x += width + _spacing;
    }
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
