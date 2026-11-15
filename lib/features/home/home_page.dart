import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';
import '../../shell/action_button.dart';
import '../../shell/breakpoints.dart';
import '../../shell/card_grid.dart';
import '../../shell/tier_route.dart';
import '../activity/activity_page.dart';
import '../properties/paddock_page.dart';
import '../properties/paths.dart';
import '../properties/properties_page.dart';
import '../tags/paths.dart';
import '../templates/class_line.dart';
import '../templates/species.dart';
import '../transfers/movement_dialog.dart';

const _recentActivity = 6;

/// Everything at once: what is on hand and where, what is ready to sell, and
/// what has come and gone lately, each leading to where it is worked on.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LivestockRepository? _repository;
  late Stream<Overview> _overview;
  late Stream<List<ActivityEntry>> _activity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = RepositoryScope.of(context);
    if (repository != _repository) {
      _repository = repository;
      _overview = repository.watchOverview();
      _activity = repository.watchActivityEntries(limit: _recentActivity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository!;

    return StreamBuilder<Overview>(
      stream: _overview,
      builder: (context, snapshot) {
        final overview = snapshot.data;
        if (overview == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (overview.properties.isEmpty) {
          return FirstRun(repository: repository);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: overview.paddockCount == 0
              ? null
              : ActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Record movement',
                  onPressed: () =>
                      showMovementDialog(context, repository: repository),
                ),
          body: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              child: _layout(
                overview,
                WindowSizeClass.fromWidth(constraints.maxWidth).contentColumns,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _layout(Overview overview, int columns) {
    final hero = _Hero(overview);
    final tiles = _Tiles(overview);
    final ready = overview.readyToSell.isEmpty
        ? null
        : _ReadyToSell(overview.readyToSell);
    final properties = _Properties(overview);
    final livestock = _Livestock(overview.classes);
    final flows = _FlowsSection(overview.flows);
    final activity = _RecentActivity(_activity, _repository!);

    final dealt = switch (columns) {
      1 => [
        [hero, tiles, ?ready, properties, livestock, flows, activity],
      ],
      2 => [
        [hero, tiles, properties, livestock],
        [?ready, flows, activity],
      ],
      _ => [
        [hero, tiles, properties],
        [?ready, livestock],
        [flows, activity],
      ],
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (final column in dealt)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: column,
            ),
          ),
      ],
    );
  }
}

/// The total on hand: the one large figure.
class _Hero extends StatelessWidget {
  const _Hero(this.overview);

  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    final species = overview.headBySpecies;

    return Card(
      color: theme.colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(propertiesPath),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Head on hand',
                      style: theme.textTheme.titleMedium?.copyWith(color: ink),
                    ),
                    // A big station's count shrinks to fit a small phone
                    // rather than breaking over two lines.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        figure(overview.head),
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'in ${counted(overview.paddockCount, 'paddock')} on '
                      '${counted(overview.properties.length, 'property', 'properties')}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                    ),
                    // An animal's share only tells anything beside another's.
                    if (species.length > 1) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          for (final MapEntry(key: animal, value: head)
                              in species.entries)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SpeciesIcon(animal, size: 20, color: ink),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${figure(head)} '
                                    '${animal.label.toLowerCase()}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.agriculture_outlined, size: 40, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles(this.overview);

  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final ready = overview.readyToSell;
    final empty = overview.emptyPaddocks;

    return LayoutBuilder(
      builder: (context, constraints) => CardGrid(
        columns: WindowSizeClass.fromWidth(constraints.maxWidth).tileColumns,
        // Each card's own margin makes up the rest of the gap.
        spacing: 4,
        children: [
          _Tile(
            icon: Icons.home_work_outlined,
            label: 'Properties',
            value: overview.properties.length,
            onTap: () => context.go(propertiesPath),
          ),
          _Tile(
            icon: Icons.grass,
            label: 'Paddocks',
            value: overview.paddockCount,
            note: empty == 0 ? null : '$empty empty',
            onTap: () => context.go(propertiesPath),
          ),
          _Tile(
            icon: Icons.paid_outlined,
            label: 'Ready to sell',
            value: ready.fold(0, (sum, r) => sum + r.mob.head),
            note: ready.isEmpty ? null : counted(ready.length, 'mob'),
          ),
          _Tile(
            icon: Icons.sell_outlined,
            label: 'Tagged',
            value: overview.activeTags,
            onTap: () => context.go(tagsPath),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final String? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: muted),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(figure(value), style: theme.textTheme.headlineMedium),
              if (note case final note?)
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card with a heading, and a link to the page the rest is on.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    this.link,
    this.linkTo,
    required this.child,
  });

  final String title;
  final String? link;
  final String? linkTo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(title: title, link: link, linkTo: linkTo),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.link, this.linkTo});

  final String title;
  final String? link;
  final String? linkTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      // As tall with a link as without one.
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 8, top: 4),
        child: Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            if ((link, linkTo) case (final label?, final path?))
              TextButton(onPressed: () => context.go(path), child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _ReadyToSell extends StatelessWidget {
  const _ReadyToSell(this.mobs);

  final List<PlacedMob> mobs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Section(
      title: 'Ready to sell',
      child: Column(
        children: [
          for (final (:property, :paddock, :mob) in mobs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  figure(mob.head),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              title: ClassLine(mob.stockClass, maxLines: 2),
              subtitle: Text('${paddock.name} · ${property.name}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openTier(
                context,
                paddockPath(property.id, paddock.id),
                preload: preloadPaddock(
                  RepositoryScope.of(context),
                  paddock.id,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Headed as a section, but its cards stand on the page rather than in one.
class _Properties extends StatelessWidget {
  const _Properties(this.overview);

  final Overview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // Level with the cards' edges, inside their margin.
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _Heading(
            title: 'Properties',
            link: 'View all',
            linkTo: propertiesPath,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => CardGrid(
            columns: WindowSizeClass.fromWidth(
              constraints.maxWidth,
            ).cardColumns,
            spacing: 4,
            children: [
              for (final stock in overview.properties)
                PropertyCard(summary: stock.summary),
            ],
          ),
        ),
      ],
    );
  }
}

/// The head in each class, each against the largest, so the classes compare
/// at a glance and the figures stay exact.
class _Livestock extends StatelessWidget {
  const _Livestock(this.classes);

  final List<MobLine> classes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final largest = classes.fold(0, (most, c) => c.head > most ? c.head : most);

    return _Section(
      title: 'Livestock',
      link: 'Templates',
      linkTo: '/templates',
      child: classes.isEmpty
          ? _Quiet('Nothing on hand. Record an intake to start counting.')
          : Column(
              spacing: 12,
              children: [
                for (final line in classes)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ClassLine(
                              line.stockClass,
                              maxLines: 1,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            figure(line.head),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // The figure says it; the bar only shows it.
                      ExcludeSemantics(
                        child: _Bar(
                          share: largest <= 0 ? 0 : line.head / largest,
                          fill: colors.primary,
                          track: colors.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.share, required this.fill, required this.track});

  final double share;
  final Color fill;
  final Color track;

  static const _radius = BorderRadius.all(Radius.circular(4));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(color: track, borderRadius: _radius),
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: share.clamp(0, 1),
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, borderRadius: _radius),
          ),
        ),
      ),
    );
  }
}

class _FlowsSection extends StatelessWidget {
  const _FlowsSection(this.flows);

  final Flows flows;

  @override
  Widget build(BuildContext context) {
    final lines = <(IconData, String, int)>[
      (Icons.add_circle_outline, 'Brought in', flows.broughtIn),
      for (final state in EndState.values)
        if (_always.contains(state) || flows.endedAs(state) != 0)
          (_icon(state), _label(state), flows.endedAs(state)),
    ];

    return _Section(
      title: 'Last ${flows.days} days',
      link: 'Activity',
      linkTo: '/activity',
      child: Column(
        children: [
          for (final (icon, label, head) in lines) _FlowLine(icon, label, head),
        ],
      ),
    );
  }

  /// Lost and other are rare, and shown only once they happen.
  static const _always = {EndState.meatworks, EndState.sold, EndState.died};

  static IconData _icon(EndState state) => switch (state) {
    EndState.meatworks => Icons.local_shipping_outlined,
    EndState.sold => Icons.storefront_outlined,
    EndState.died => Icons.heart_broken_outlined,
    EndState.lost => Icons.help_outline,
    EndState.other => Icons.more_horiz,
  };

  static String _label(EndState state) => switch (state) {
    EndState.meatworks => 'To the meatworks',
    EndState.sold => 'Sold',
    EndState.died => 'Died',
    EndState.lost => 'Lost',
    EndState.other => 'Otherwise ended',
  };
}

class _FlowLine extends StatelessWidget {
  const _FlowLine(this.icon, this.label, this.head);

  final IconData icon;
  final String label;
  final int head;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            head == 0 ? '—' : '${figure(head)} head',
            style: theme.textTheme.titleSmall?.copyWith(
              color: head == 0 ? muted : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity(this.entries, this.repository);

  final Stream<List<ActivityEntry>> entries;
  final LivestockRepository repository;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent activity',
      link: 'View all',
      linkTo: '/activity',
      child: StreamBuilder<List<ActivityEntry>>(
        initialData: repository.latestActivityEntries(limit: _recentActivity),
        stream: entries,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const SizedBox(height: 48),
          [] => _Quiet('Nothing recorded yet.'),
          final entries => Column(
            children: [for (final entry in entries) ActivityTile(entry: entry)],
          ),
        },
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// [n] with its thousands grouped, as 12,480.
String figure(int n) {
  final grouped = n.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return n < 0 ? '-$grouped' : grouped;
}

/// [n] and the noun for that many of it.
String counted(int n, String one, [String? many]) =>
    '${figure(n)} ${n == 1 ? one : many ?? '${one}s'}';
