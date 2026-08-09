import 'package:flutter/material.dart';

import '../../shell/breakpoints.dart';

/// Placeholder domain screen.
///
/// This exists so the pilot looks like the app it will become, and so the
/// adaptive shell has more than one destination to switch between. It holds
/// **no state and no persistence** — the livestock transfer model is
/// deliberately out of scope for a platform-reach pilot.
class PaddocksPage extends StatelessWidget {
  const PaddocksPage({super.key});

  static const List<_Paddock> _paddocks = [
    _Paddock('North Ridge', 42.4, 128, 'Angus steers'),
    _Paddock('Creek Flat', 18.1, 64, 'Hereford cows'),
    _Paddock('Woolshed', 61.7, 0, 'Empty — resting'),
    _Paddock('Boundary East', 33.9, 210, 'Merino wethers'),
    _Paddock('Home Block', 12.5, 47, 'Mixed weaners'),
    _Paddock('Back Springs', 88.2, 156, 'Angus heifers'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = WindowSizeClass.fromWidth(constraints.maxWidth);
        final columns = sizeClass.contentColumns;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _PlaceholderBanner(),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 108,
              ),
              itemCount: _paddocks.length,
              itemBuilder: (context, index) =>
                  _PaddockCard(paddock: _paddocks[index]),
            ),
          ],
        );
      },
    );
  }
}

class _PlaceholderBanner extends StatelessWidget {
  const _PlaceholderBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.construction_outlined,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Placeholder data. This pilot proves platform reach — '
                'livestock transfer logic comes next.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaddockCard extends StatelessWidget {
  const _PaddockCard({required this.paddock});

  final _Paddock paddock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = paddock.head == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: empty
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.primaryContainer,
              child: Text(
                '${paddock.head}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: empty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(paddock.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    paddock.mob,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${paddock.hectares} ha',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _Paddock {
  const _Paddock(this.name, this.hectares, this.head, this.mob);

  final String name;
  final double hectares;
  final int head;
  final String mob;
}
