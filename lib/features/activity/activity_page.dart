import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';

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
  const ActivityTile({super.key, required this.entry});

  final ActivityEntry entry;

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
      title: Text('${movement.head} head · ${_summary(movement)}'),
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

  String _summary(Movement movement) => switch (movement.kind) {
    MovementKind.intake =>
      'intake to ${entry.toPaddock} as ${entry.toClass}',
    MovementKind.move =>
      '${entry.fromPaddock} → ${entry.toPaddock} (${entry.fromClass})',
    MovementKind.age =>
      '${entry.fromClass} → ${entry.toClass} in ${entry.fromPaddock}',
    MovementKind.endState =>
      '${entry.fromPaddock} → ${movement.endState?.name ?? 'removed'}',
  };

  String _timestamp(DateTime at) {
    final local = at.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} $h:$min';
  }
}
