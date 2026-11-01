import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// A page's floating action: a labelled pill, or on a compact window a circle
/// that opens into the pill while hovered or long-pressed. The shapes come
/// from the theme.
class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _reveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _reveal = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  var _hovered = false;
  var _held = false;

  // Tracked apart, so releasing a mouse button over the pill leaves it open.
  void _update({bool? hovered, bool? held}) {
    _hovered = hovered ?? _hovered;
    _held = held ?? _held;
    _hovered || _held ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The window, not the pane: two panes side by side are each narrow, but
    // the window still has room for a label.
    final sizeClass = WindowSizeClass.fromWidth(
      MediaQuery.sizeOf(context).width,
    );

    if (!sizeClass.usesIconOnlyActions) {
      return FloatingActionButton.extended(
        icon: Icon(widget.icon),
        label: Text(widget.label),
        onPressed: widget.onPressed,
      );
    }

    // Long press stands in for hover on touch, where a tooltip would only
    // repeat the label the button is about to show.
    return MouseRegion(
      onEnter: (_) => _update(hovered: true),
      onExit: (_) => _update(hovered: false),
      // A long press the system takes over, for a pulled-down shade or a call,
      // ends in a pointer cancel, and once started it reports no end.
      child: Listener(
        onPointerCancel: (_) => _update(held: false),
        child: GestureDetector(
          onLongPressStart: (_) => _update(held: true),
          onLongPressEnd: (_) => _update(held: false),
          child: AnimatedBuilder(
            animation: _reveal,
            builder: (context, _) {
              final t = _reveal.value;
              return FloatingActionButton.extended(
                isExtended: t > 0,
                // Equal padding either side of the icon makes the closed
                // button 56 square, which the stadium shape draws as a circle.
                extendedPadding: EdgeInsetsDirectional.only(
                  start: 16,
                  end: lerpDouble(16, 20, t)!,
                ),
                extendedIconLabelSpacing: 8 * t,
                icon: Icon(
                  widget.icon,
                  semanticLabel: t > 0 ? null : widget.label,
                ),
                label: ClipRect(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: t,
                    child: Text(widget.label),
                  ),
                ),
                onPressed: widget.onPressed,
              );
            },
          ),
        ),
      ),
    );
  }
}
