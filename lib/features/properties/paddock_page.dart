import 'package:flutter/material.dart';

import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../activity/activity_page.dart';
import '../transfers/movement_sheet.dart';

/// The bottom tier: everything standing in one paddock, and how it got there.
class PaddockPage extends StatelessWidget {
  const PaddockPage({super.key, required this.paddockId});

  final String paddockId;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);

    return StreamBuilder<PaddockSummary?>(
      stream: repository.watchPaddockSummary(paddockId),
      builder: (context, snapshot) {
        final summary = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: Text(summary?.paddock.name ?? 'Paddock')),
          floatingActionButton: summary == null
              ? null
              : FloatingActionButton.extended(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Record movement'),
                  onPressed: () => showMovementSheet(
                    context,
                    repository: repository,
                    propertyId: summary.paddock.propertyId,
                    fromPaddockId: paddockId,
                  ),
                ),
          body: switch ((snapshot.connectionState, summary)) {
            (ConnectionState.waiting, null) => const Center(
              child: CircularProgressIndicator(),
            ),
            (_, null) => const Center(child: Text('This paddock is gone.')),
            (_, final s?) => _PaddockDetail(
              summary: s,
              repository: repository,
            ),
          },
        );
      },
    );
  }
}

class _PaddockDetail extends StatelessWidget {
  const _PaddockDetail({required this.summary, required this.repository});

  final PaddockSummary summary;
  final LivestockRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paddock = summary.paddock;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${summary.head} head',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${paddock.hectares.toStringAsFixed(1)} ha'
                        '${summary.isEmpty ? '' : ' · ${summary.mobs.length} '
                              '${summary.mobs.length == 1 ? 'mob' : 'mobs'}'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.grass,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Livestock', style: theme.textTheme.titleMedium),
        const Divider(),
        if (summary.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'This paddock is empty.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final mob in summary.mobs) _MobTile(mob: mob),
        const SizedBox(height: 16),
        Text('Recent activity', style: theme.textTheme.titleMedium),
        const Divider(),
        StreamBuilder<List<ActivityEntry>>(
          stream: repository.watchActivityEntries(
            paddockId: paddock.id,
            limit: 25,
          ),
          builder: (context, snapshot) {
            final entries = snapshot.data;
            if (entries == null) return const SizedBox(height: 48);
            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nothing has moved in or out of here yet.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final entry in entries) ActivityTile(entry: entry),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MobTile extends StatelessWidget {
  const _MobTile({required this.mob});

  final MobLine mob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          '${mob.head}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
      title: Text(mob.label),
      subtitle: Text(mob.livestockClass.ageBand),
    );
  }
}
