import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';
import '../properties/paddock_page.dart';
import '../properties/paths.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);
    final theme = Theme.of(context);

    return StreamBuilder<List<ActivityEntry>>(
      stream: repository.watchActivityEntries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Nothing recorded yet. Every movement you record appears here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => ActivityTile(entry: entries[index]),
        );
      },
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.entry, this.currentPaddockId});

  final ActivityEntry entry;

  /// The paddock this tile is shown on, which it names without linking.
  final String? currentPaddockId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movement = entry.movement;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          switch (movement.kind) {
            MovementKind.intake => Icons.add_circle_outline,
            MovementKind.move => Icons.swap_horiz,
            MovementKind.age => Icons.cake_outlined,
            MovementKind.endState => Icons.local_shipping_outlined,
          },
          size: 20,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${movement.head} head · '),
            ..._summary(movement),
          ],
        ),
      ),
      subtitle: Text(
        [
          _timestamp(movement.occurredAt),
          if (movement.note != null) movement.note!,
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  List<InlineSpan> _summary(Movement movement) => switch (movement.kind) {
    MovementKind.intake => [
      const TextSpan(text: 'intake to '),
      _paddock(entry.toPaddock),
      TextSpan(text: ' as ${entry.toClass}'),
    ],
    MovementKind.move => [
      _paddock(entry.fromPaddock),
      const TextSpan(text: ' → '),
      _paddock(entry.toPaddock),
      TextSpan(text: ' (${entry.fromClass})'),
    ],
    MovementKind.age => [
      TextSpan(text: '${entry.fromClass} → ${entry.toClass} in '),
      _paddock(entry.fromPaddock),
    ],
    MovementKind.endState => [
      _paddock(entry.fromPaddock),
      TextSpan(text: ' → ${movement.endState?.name ?? 'removed'}'),
    ],
  };

  InlineSpan _paddock(Paddock? paddock) {
    if (paddock == null ||
        paddock.deletedAt != null ||
        paddock.id == currentPaddockId) {
      return TextSpan(text: paddock?.name ?? 'a removed paddock');
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _PaddockLink(paddock),
    );
  }

  String _timestamp(DateTime at) {
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} $h:$min';
  }
}

class _PaddockLink extends StatelessWidget {
  const _PaddockLink(this.paddock);

  final Paddock paddock;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => openTier(
          context,
          paddockPath(paddock.propertyId, paddock.id),
          preload: preloadPaddock(RepositoryScope.of(context), paddock.id),
        ),
        child: Text(
          paddock.name,
          style: TextStyle(
            color: colors.primary,
            decoration: TextDecoration.underline,
            decorationColor: colors.primary,
          ),
        ),
      ),
    );
  }
}
