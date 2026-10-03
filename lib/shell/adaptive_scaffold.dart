import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// A navigation target in the app shell.
@immutable
class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Scaffold that swaps its navigation affordance based on window width alone.
///
/// The same widget tree serves a phone, a tablet, a desktop window and a
/// browser tab — resize a desktop window across 600 dp and 840 dp and the
/// navigation visibly changes, which is the cheapest way to demonstrate that
/// responsiveness is real rather than asserted.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.actions = const <Widget>[],
    this.showAppBar = true,
    this.title,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget> actions;

  /// Off for a destination whose body draws its own bar.
  final bool showAppBar;

  /// The app's name, in a header across the rail layouts. Phones go without:
  /// the page's own bar already holds the top of a small screen.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = WindowSizeClass.fromWidth(constraints.maxWidth);

        final appBar = showAppBar
            ? AppBar(
                title: Text(destinations[selectedIndex].label),
                actions: actions,
              )
            : null;

        if (sizeClass.usesBottomBar) {
          return Scaffold(
            appBar: appBar,
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          );
        }

        final appTitle = title;
        return Scaffold(
          appBar: appTitle == null ? null : _Header(appTitle),
          body: Row(
            children: [
              if (sizeClass.usesExtendedRail)
                ExtendedRail(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                )
              else
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
              const VerticalDivider(width: 1, thickness: 1),
              // The bar sits beside the rail, over the content only, matching
              // pages that draw their own.
              Expanded(
                child: appBar == null
                    ? body
                    : Scaffold(appBar: appBar, body: body),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A rail with labels beside the icons, where the indicator and hover cover
/// the whole destination. `NavigationRail(extended: true)` keeps both to the
/// icon, and has no setting to widen them.
class ExtendedRail extends StatelessWidget {
  const ExtendedRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        width: 256,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final (i, d) in destinations.indexed)
              _ExtendedRailDestination(
                destination: d,
                selected: i == selectedIndex,
                onTap: () => onDestinationSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExtendedRailDestination extends StatelessWidget {
  const _ExtendedRailDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Semantics(
        selected: selected,
        child: Material(
          color: selected ? colors.secondaryContainer : Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    color: foreground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destination.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget implements PreferredSizeWidget {
  const _Header(this.title);

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: theme.colorScheme.surfaceContainer,
      scrolledUnderElevation: 0,
      title: Text(title),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1),
      ),
    );
  }
}
