import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'breakpoints.dart';

/// One tier of a drill-down. Slides only when one pane is showing. Side by
/// side, the incoming page already draws its parents, so a transition would
/// just move them about.
class TierPage extends Page<void> {
  const TierPage({super.key, required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _TierRoute(this);
}

class _TierRoute extends PageRoute<void>
    with MaterialRouteTransitionMixin<void> {
  _TierRoute(TierPage page) : super(settings: page);

  @override
  Widget buildContent(BuildContext context) => (settings as TierPage).child;

  @override
  bool get maintainState => true;

  // A tier's first frame is blank while its query is in flight, and a snapshot
  // would freeze the forward transition on it.
  @override
  bool get allowSnapshotting => false;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          WindowSizeClass.fromWidth(constraints.maxWidth).panes > 1
          ? child
          : super.buildTransitions(
              context,
              animation,
              secondaryAnimation,
              child,
            ),
    );
  }
}

/// Holds the detail pane's place until something is selected.
class TierPlaceholder extends StatelessWidget {
  const TierPlaceholder(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Navigates once [preload] has warmed the next tier's queries, so it opens
/// drawn rather than on a spinner. A slow or failed preload only costs that.
Future<void> openTier(
  BuildContext context,
  String path, {
  required Future<void> preload,
}) async {
  try {
    await preload.timeout(const Duration(milliseconds: 300));
  } on Object {
    // The page loads for itself regardless.
  }
  if (context.mounted) context.go(path);
}
