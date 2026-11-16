import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import 'breakpoints.dart';

/// One step of a page's trail: what it is, by its icon and name, and where.
@immutable
class Crumb {
  const Crumb({required this.icon, required this.label, required this.path});

  final IconData icon;

  /// Usually a [Text]. The bar styles it, and ellipsises it on one line.
  final Widget label;
  final String path;
}

/// Something a page's bar offers besides its trail.
@immutable
class BarAction {
  const BarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onPressed;
}

/// A page's bar: the trail to the page, from Home, each step before it a
/// link. A compact bar shows only the page, with a back arrow below the top of
/// a destination, and its [actions] as icons alone.
class TrailBar extends StatelessWidget implements PreferredSizeWidget {
  TrailBar(this.crumbs, {super.key, this.actions = const []})
    : assert(crumbs.isNotEmpty);

  final List<Crumb> crumbs;
  final List<BarAction> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (WindowSizeClass.fromWidth(constraints.maxWidth).usesFullTrail) {
          return AppBar(
            automaticallyImplyLeading: false,
            // The first crumb's inset makes up the rest, so its icon starts
            // where a compact bar's does.
            titleSpacing: 16 - _inset.left,
            title: _Trail(crumbs),
            actions: [
              for (final action in actions)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: TextButton.icon(
                    onPressed: () => action.onPressed(context),
                    icon: Icon(action.icon),
                    label: Text(action.label),
                  ),
                ),
            ],
          );
        }
        return AppBar(
          automaticallyImplyLeading: false,
          // Home and a destination are each a tap away in the bar below.
          leading: crumbs.length > 2
              ? BackButton(onPressed: () => _up(context))
              : null,
          title: _CrumbContent(crumbs.last, current: true),
          actions: [
            for (final action in actions)
              IconButton(
                tooltip: action.label,
                onPressed: () => action.onPressed(context),
                icon: Icon(action.icon),
              ),
          ],
        );
      },
    );
  }

  /// A deep link arrives with nothing beneath it to pop back to.
  void _up(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(crumbs[crumbs.length - 2].path);
    }
  }
}

// Shared by links and the current crumb, so a crumb keeps its place as it
// turns into a link.
const _inset = EdgeInsets.symmetric(horizontal: 8);

class _Trail extends StatelessWidget {
  const _Trail(this.crumbs);

  final List<Crumb> crumbs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final linkStyle = TextButton.styleFrom(
      foregroundColor: muted,
      textStyle: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge,
      padding: _inset,
    );

    return _TrailLayout(
      textDirection: Directionality.of(context),
      children: [
        for (final (i, crumb) in crumbs.indexed) ...[
          if (i > 0) Icon(Icons.chevron_right, color: muted),
          if (i < crumbs.length - 1)
            TextButton(
              style: linkStyle,
              onPressed: () => context.go(crumb.path),
              child: _CrumbContent(crumb),
            )
          else
            Padding(
              padding: _inset,
              child: _CrumbContent(crumb, current: true),
            ),
        ],
      ],
    );
  }
}

class _CrumbContent extends StatelessWidget {
  const _CrumbContent(this.crumb, {this.current = false});

  final Crumb crumb;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          crumb.icon,
          // Set here, as a button would otherwise shrink it to 18.
          size: 24,
          color: current ? colors.primary : colors.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: DefaultTextStyle.merge(
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: crumb.label,
          ),
        ),
      ],
    );
  }
}

/// Crumbs and the separators between them, in a row. Where they don't fit,
/// the crumbs before the last give way first, the widest of them first, down
/// to [_minCrumb] each; only then does the last crumb, the page itself.
class _TrailLayout extends MultiChildRenderObjectWidget {
  const _TrailLayout({required this.textDirection, required super.children});

  final TextDirection textDirection;

  @override
  _RenderTrail createRenderObject(BuildContext context) =>
      _RenderTrail(textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderTrail renderObject) {
    renderObject.textDirection = textDirection;
  }
}

/// Room for a crumb's icon, its insets and a few letters.
const _minCrumb = 96.0;

class _TrailParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTrail extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TrailParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TrailParentData> {
  _RenderTrail({required this._textDirection});

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TrailParentData) {
      child.parentData = _TrailParentData();
    }
  }

  /// Children alternate crumb, separator, crumb, ending on the current one.
  List<RenderBox> get _children {
    final children = <RenderBox>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      children.add(child);
    }
    return children;
  }

  /// How wide each crumb may be, ancestors first and the current one last.
  static List<double> _widths(List<double> natural, double room) {
    final current = natural.last;
    final ancestors = natural.sublist(0, natural.length - 1);
    final total = natural.fold(0.0, (sum, w) => sum + w);
    if (total <= room) return natural;

    final floors = [for (final w in ancestors) math.min(w, _minCrumb)];
    final floor = floors.fold(0.0, (sum, w) => sum + w);
    final forAncestors = room - current;
    if (forAncestors < floor) {
      return [...floors, math.max(0, room - floor)];
    }

    // The one cap that leaves the ancestors exactly the room they have:
    // narrower ones keep their width, and the rest share what is left.
    final sorted = [...ancestors]..sort();
    var left = forAncestors;
    var cap = double.infinity;
    for (final (i, w) in sorted.indexed) {
      final sharing = sorted.length - i;
      if (w * sharing > left) {
        cap = left / sharing;
        break;
      }
      left -= w;
    }
    return [for (final w in ancestors) math.min(w, cap), current];
  }

  @override
  void performLayout() {
    final children = _children;
    final crumbs = [for (var i = 0; i < children.length; i += 2) children[i]];
    final height = constraints.maxHeight;

    var separators = 0.0;
    for (var i = 1; i < children.length; i += 2) {
      children[i].layout(
        BoxConstraints(maxHeight: height),
        parentUsesSize: true,
      );
      separators += children[i].size.width;
    }

    final widths = _widths([
      for (final crumb in crumbs) crumb.getMaxIntrinsicWidth(height),
    ], math.max(0, constraints.maxWidth - separators));
    for (final (i, crumb) in crumbs.indexed) {
      crumb.layout(
        BoxConstraints(maxWidth: widths[i], maxHeight: height),
        parentUsesSize: true,
      );
    }

    final tallest = children.fold(
      0.0,
      (most, child) => math.max(most, child.size.height),
    );
    final width = children.fold(0.0, (sum, child) => sum + child.size.width);
    size = constraints.constrain(Size(width, tallest));

    var x = 0.0;
    for (final child in children) {
      (child.parentData! as _TrailParentData).offset = Offset(
        _textDirection == TextDirection.ltr
            ? x
            : size.width - x - child.size.width,
        (size.height - child.size.height) / 2,
      );
      x += child.size.width;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
