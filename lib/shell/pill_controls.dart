import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The height a [PillSearchField] and the [PillChips] beside it share: a touch
/// target, or less where the theme's density is compact.
double _pillHeight(ThemeData theme) =>
    kMinInteractiveDimension + theme.visualDensity.baseSizeAdjustment.dy;

/// The search field's outline, for the chips beside it, in each of its states.
/// [inUse] marks a chip as in use, as the field is while focused, such as one
/// whose menu is open.
///
/// It is drawn outside a chip, which would otherwise grow by the 2 px of a
/// focused outline.
WidgetStateBorderSide pillOutline(ColorScheme colors, {bool inUse = false}) =>
    WidgetStateBorderSide.resolveWith((states) {
      if (inUse || states.contains(WidgetState.focused)) {
        return BorderSide(
          color: colors.primary,
          width: 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        );
      }
      return BorderSide(
        color: states.contains(WidgetState.hovered)
            ? colors.onSurface
            : colors.outline,
        strokeAlign: BorderSide.strokeAlignOutside,
      );
    });

/// A search field shaped as a pill. Its clear button appears once there is
/// something to clear, and reports the cleared text to [onChanged].
class PillSearchField extends StatelessWidget {
  const PillSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge!;

    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        decoration: InputDecoration(
          // Past half of any height the field takes, so its ends stay round.
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: (_pillHeight(theme) - body.fontSize! * body.height!) / 2,
          ),
          // As far in from the end as the hint is from the icon.
          prefixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(start: 16, end: 12),
            child: Icon(Icons.search),
          ),
          hintText: hintText,
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  // Material 3 icon buttons keep standard density, and the
                  // field would grow to fit one where the theme's is compact.
                  visualDensity: theme.visualDensity,
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Chips that sit beside a [PillSearchField], wrapped as space requires. They
/// take its height and its outline, and hovering one changes only the outline,
/// as it does the field's.
class PillChips extends StatelessWidget {
  const PillChips({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final density = theme.visualDensity.baseSizeAdjustment.dy;
    final label = theme.textTheme.labelLarge!;

    return ChipTheme(
      data: ChipTheme.of(context).copyWith(
        shape: const StadiumBorder(),
        side: pillOutline(theme.colorScheme),
        // A chip is as tall as its label line and vertical padding, plus half
        // the density adjustment. Its outline is drawn outside that, so 1 px
        // comes off each side for the outline to finish level with the field's.
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical:
              (_pillHeight(theme) -
                      label.fontSize! * label.height! -
                      density / 2) /
                  2 -
              1,
        ),
        // A chip given any colour leaves out its hover tint. This one gives
        // none, so the chip keeps its usual colours.
        color: const WidgetStatePropertyAll(null),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

/// A [PillSearchField] with [PillChips] beside it, or above them where beside
/// them the field would be too narrow for its whole hint. The hint never
/// changes, so typing never moves the chips.
class PillToolbar extends StatelessWidget {
  const PillToolbar({super.key, required this.search, required this.chips});

  final PillSearchField search;
  final PillChips chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = TextPainter(
      text: TextSpan(text: search.hintText, style: theme.textTheme.bodyLarge),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    // The icon with its insets either side, the hint, and the same 16 px
    // clear of the far end as the icon is of the near one.
    final searchWidth = 16 + 24 + 12 + hint.width + 16;
    hint.dispose();

    return _PillToolbarLayout(
      searchWidth: searchWidth,
      textDirection: Directionality.of(context),
      children: [search, chips],
    );
  }
}

class _PillToolbarLayout extends MultiChildRenderObjectWidget {
  const _PillToolbarLayout({
    required this.searchWidth,
    required this.textDirection,
    required super.children,
  });

  final double searchWidth;
  final TextDirection textDirection;

  @override
  _RenderPillToolbar createRenderObject(BuildContext context) =>
      _RenderPillToolbar(
        searchWidth: searchWidth,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPillToolbar renderObject,
  ) {
    renderObject
      ..searchWidth = searchWidth
      ..textDirection = textDirection;
  }
}

class _PillToolbarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderPillToolbar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PillToolbarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PillToolbarParentData> {
  _RenderPillToolbar({
    required this._searchWidth,
    required this._textDirection,
  });

  static const _besideGap = 16.0;
  static const _belowGap = 8.0;

  double _searchWidth;
  set searchWidth(double value) {
    if (value == _searchWidth) return;
    _searchWidth = value;
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
    if (child.parentData is! _PillToolbarParentData) {
      child.parentData = _PillToolbarParentData();
    }
  }

  RenderBox get _search => firstChild!;
  RenderBox get _chips => lastChild!;

  /// Where each child goes, and how big the toolbar is, laying the children
  /// out with [layoutChild].
  (Size, Offset, Offset) _arrange(
    BoxConstraints constraints,
    ChildLayouter layoutChild,
  ) {
    final width = constraints.maxWidth;
    final chipsWidth = _chips.getMaxIntrinsicWidth(double.infinity);

    if (width - _besideGap - chipsWidth >= _searchWidth) {
      // Wide enough that the chips keep to one line beside the search.
      final chips = layoutChild(
        _chips,
        BoxConstraints(maxWidth: width - _besideGap - _searchWidth),
      );
      final searchWidth = width - _besideGap - chips.width;
      final search = layoutChild(
        _search,
        BoxConstraints.tightFor(width: searchWidth),
      );
      final height = search.height > chips.height
          ? search.height
          : chips.height;
      final ltr = _textDirection == TextDirection.ltr;
      return (
        constraints.constrain(Size(width, height)),
        Offset(ltr ? 0 : width - searchWidth, (height - search.height) / 2),
        Offset(ltr ? width - chips.width : 0, (height - chips.height) / 2),
      );
    }

    final search = layoutChild(_search, BoxConstraints.tightFor(width: width));
    final chips = layoutChild(_chips, BoxConstraints(maxWidth: width));
    return (
      constraints.constrain(
        Size(width, search.height + _belowGap + chips.height),
      ),
      Offset.zero,
      Offset(
        _textDirection == TextDirection.ltr ? 0 : width - chips.width,
        search.height + _belowGap,
      ),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _arrange(constraints, ChildLayoutHelper.dryLayoutChild).$1;

  @override
  void performLayout() {
    final (toolbar, search, chips) = _arrange(
      constraints,
      ChildLayoutHelper.layoutChild,
    );
    size = toolbar;
    (_search.parentData! as _PillToolbarParentData).offset = search;
    (_chips.parentData! as _PillToolbarParentData).offset = chips;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
