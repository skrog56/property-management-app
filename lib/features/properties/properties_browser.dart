import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../shell/breakpoints.dart';
import 'paddock_page.dart';
import 'paths.dart';
import 'properties_page.dart';
import 'property_page.dart';

/// The three tiers as list-detail panes: the deepest tier alone on a narrow
/// window, with its parents beside it as the window widens.
class PropertiesBrowser extends StatelessWidget {
  const PropertiesBrowser({super.key, this.propertyId, this.paddockId})
    : assert(paddockId == null || propertyId != null);

  final String? propertyId;
  final String? paddockId;

  static const _listPaneWidth = 360.0;

  int get _depth => switch ((propertyId, paddockId)) {
    (null, _) => 0,
    (_, null) => 1,
    _ => 2,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panes = WindowSizeClass.fromWidth(constraints.maxWidth).panes;
        final depth = _depth;

        final tiers = <Widget>[
          PropertiesPage(selectedId: propertyId, primary: depth == 0),
          if (propertyId case final pid?)
            PropertyPage(
              propertyId: pid,
              selectedPaddockId: paddockId,
              primary: depth == 1,
            ),
          if (paddockId case final kid?)
            PaddockPage(paddockId: kid, propertyId: propertyId, primary: true),
        ];

        final visible = tiers.sublist(max(0, tiers.length - panes));
        if (visible.length < panes) {
          visible.add(
            _Placeholder(depth == 0 ? 'Select a property' : 'Select a paddock'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: panes == 1 && depth > 0
                ? BackButton(onPressed: () => _up(context))
                : null,
            title: panes == 1
                ? _title(depth)
                : _Breadcrumbs(propertyId: propertyId, paddockId: paddockId),
            actions: [
              if (depth == 1)
                IconButton(
                  onPressed: () => addPaddock(
                    context,
                    RepositoryScope.of(context),
                    propertyId!,
                  ),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add paddock',
                ),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, pane) in visible.indexed)
                if (i < visible.length - 1) ...[
                  SizedBox(width: _listPaneWidth, child: pane),
                  const VerticalDivider(width: 1, thickness: 1),
                ] else
                  Expanded(child: pane),
            ],
          ),
        );
      },
    );
  }

  Widget _title(int depth) => switch (depth) {
    0 => const Text('Properties'),
    1 => _PropertyName(propertyId!),
    _ => _PaddockName(paddockId!),
  };

  /// A deep link arrives with nothing beneath it to pop back to.
  void _up(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        paddockId == null ? propertiesPath : propertyPath(propertyId!),
      );
    }
  }
}

/// Slides only when one pane is showing. Side by side, the incoming page
/// already draws its parents, so a transition would just move them about.
class PropertiesBrowserPage extends Page<void> {
  const PropertiesBrowserPage({super.key, this.propertyId, this.paddockId});

  final String? propertyId;
  final String? paddockId;

  @override
  Route<void> createRoute(BuildContext context) => _BrowserRoute(this);
}

class _BrowserRoute extends PageRoute<void>
    with MaterialRouteTransitionMixin<void> {
  _BrowserRoute(PropertiesBrowserPage page) : super(settings: page);

  PropertiesBrowserPage get _page => settings as PropertiesBrowserPage;

  @override
  Widget buildContent(BuildContext context) => PropertiesBrowser(
    propertyId: _page.propertyId,
    paddockId: _page.paddockId,
  );

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

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({this.propertyId, this.paddockId});

  final String? propertyId;
  final String? paddockId;

  @override
  Widget build(BuildContext context) {
    final crumbs = <(Widget, String?)>[
      (const Text('Properties'), propertiesPath),
      if (propertyId case final pid?) (_PropertyName(pid), propertyPath(pid)),
      if (paddockId case final kid?) (_PaddockName(kid), null),
    ];

    final theme = Theme.of(context);
    final linkStyle = TextButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurfaceVariant,
      textStyle: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );

    return Row(
      children: [
        for (final (i, (label, _)) in crumbs.indexed) ...[
          if (i > 0)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          Flexible(
            child: i == crumbs.length - 1
                ? Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    child: label,
                  )
                : TextButton(
                    style: linkStyle,
                    onPressed: () => context.go(crumbs[i].$2!),
                    child: label,
                  ),
          ),
        ],
      ],
    );
  }
}

class _PropertyName extends StatelessWidget {
  const _PropertyName(this.propertyId);

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);
    return StreamBuilder<Property?>(
      initialData: repository.latestProperty(propertyId),
      stream: repository.watchProperty(propertyId),
      builder: (context, snapshot) => Text(
        snapshot.data?.name ?? 'Property',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PaddockName extends StatelessWidget {
  const _PaddockName(this.paddockId);

  final String paddockId;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);
    return StreamBuilder<PaddockSummary?>(
      initialData: repository.latestPaddockSummary(paddockId),
      stream: repository.watchPaddockSummary(paddockId),
      builder: (context, snapshot) => Text(
        snapshot.data?.paddock.name ?? 'Paddock',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.message);

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
