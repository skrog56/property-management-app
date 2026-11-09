import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';
import '../../data/tag_numbers.dart';
import '../../shell/action_button.dart';
import '../../shell/tier_route.dart';
import '../activity/activity_page.dart';
import '../tags/add_tags_dialog.dart';
import '../tags/paths.dart';
import '../tags/tag_page.dart';
import '../transfers/movement_dialog.dart';

/// The bottom tier: everything standing in one paddock, and how it got there.
class PaddockPage extends StatelessWidget {
  const PaddockPage({super.key, required this.paddockId, this.propertyId});

  final String paddockId;

  /// When given, a paddock belonging to another property counts as gone, so a
  /// hand-edited URL cannot show it under the wrong parent.
  final String? propertyId;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);

    return StreamBuilder<PaddockSummary?>(
      initialData: repository.latestPaddockSummary(paddockId),
      stream: repository.watchPaddockSummary(paddockId),
      builder: (context, snapshot) {
        final summary = switch (snapshot.data) {
          final s?
              when propertyId == null || s.paddock.propertyId == propertyId =>
            s,
          _ => null,
        };

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: summary == null
              ? null
              : ActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Record movement',
                  onPressed: () => showMovementDialog(
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

const _recentActivity = 25;
const _recentDeaths = 10;

Future<void> preloadPaddock(LivestockRepository repository, String id) =>
    repository.warm([
      repository.watchPaddockSummary(id),
      repository.watchActivityEntries(paddockId: id, limit: _recentActivity),
      _watchDeaths(repository, id),
      repository.watchTagsIn(id),
    ]);

Stream<List<ActivityEntry>> _watchDeaths(
  LivestockRepository repository,
  String paddockId,
) => repository.watchActivityEntries(
  paddockId: paddockId,
  endState: EndState.died,
  limit: _recentDeaths,
);

class _PaddockDetail extends StatelessWidget {
  const _PaddockDetail({required this.summary, required this.repository});

  final PaddockSummary summary;
  final LivestockRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paddock = summary.paddock;

    return StreamBuilder<List<TagStatus>>(
      initialData: repository.latestTagsIn(paddock.id),
      stream: repository.watchTagsIn(paddock.id),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <TagStatus>[];
        int taggedIn(MobLine mob) =>
            tags.where((t) => t.stockClass?.id == mob.stockClass.id).length;

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
              for (final mob in summary.mobs)
                _MobTile(
                  mob: mob,
                  paddock: paddock,
                  tagged: taggedIn(mob),
                  repository: repository,
                ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Tags', style: theme.textTheme.titleMedium),
              const Divider(),
              _TagChips(tags: tags),
            ],
            _Deaths(summary: summary, repository: repository),
            const SizedBox(height: 16),
            Text('Recent activity', style: theme.textTheme.titleMedium),
            const Divider(),
            StreamBuilder<List<ActivityEntry>>(
              initialData: repository.latestActivityEntries(
                paddockId: paddock.id,
                limit: _recentActivity,
              ),
              stream: repository.watchActivityEntries(
                paddockId: paddock.id,
                limit: _recentActivity,
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
                    for (final entry in entries)
                      ActivityTile(entry: entry, currentPaddockId: paddock.id),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

enum _MobAction { readyToSell, death, addTags }

class _MobTile extends StatelessWidget {
  const _MobTile({
    required this.mob,
    required this.paddock,
    required this.tagged,
    required this.repository,
  });

  final MobLine mob;
  final Paddock paddock;
  final int tagged;
  final LivestockRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockClass = mob.stockClass;

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
      subtitle: tagged > 0 ? Text('$tagged tagged') : null,
      trailing: PopupMenuButton<_MobAction>(
        tooltip: 'Actions for ${mob.label}',
        onSelected: (action) => switch (action) {
          _MobAction.readyToSell => showReadyToSellDialog(
            context,
            repository: repository,
            paddock: paddock,
            mob: mob,
          ),
          _MobAction.death => showDeathDialog(
            context,
            repository: repository,
            paddock: paddock,
            mob: mob,
          ),
          _MobAction.addTags => showAddTagsDialog(
            context,
            repository: repository,
            paddock: paddock,
            mob: mob,
            tagged: tagged,
          ),
        },
        itemBuilder: (context) => [
          if (stockClass.isReadyToSell)
            const PopupMenuItem(
              value: _MobAction.readyToSell,
              child: Text('No longer ready to sell'),
            )
          else if (stockClass.readyToSellClassId != null)
            const PopupMenuItem(
              value: _MobAction.readyToSell,
              child: Text('Mark ready to sell'),
            ),
          const PopupMenuItem(
            value: _MobAction.death,
            child: Text('Record death'),
          ),
          PopupMenuItem(
            value: _MobAction.addTags,
            enabled: tagged < mob.head,
            child: const Text('Add tags'),
          ),
        ],
      ),
    );
  }
}

/// The deaths recorded here, with a way to record another while anything is
/// standing. Hidden for a paddock that has had neither.
class _Deaths extends StatelessWidget {
  const _Deaths({required this.summary, required this.repository});

  final PaddockSummary summary;
  final LivestockRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paddock = summary.paddock;

    return StreamBuilder<List<ActivityEntry>>(
      initialData: repository.latestActivityEntries(
        paddockId: paddock.id,
        endState: EndState.died,
        limit: _recentDeaths,
      ),
      stream: _watchDeaths(repository, paddock.id),
      builder: (context, snapshot) {
        final deaths = snapshot.data ?? const <ActivityEntry>[];
        if (summary.isEmpty && deaths.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Deaths', style: theme.textTheme.titleMedium),
                ),
                if (!summary.isEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => showDeathDialog(
                      context,
                      repository: repository,
                      paddock: paddock,
                    ),
                    icon: const Icon(Icons.heart_broken_outlined),
                    label: const Text('Record death'),
                  ),
              ],
            ),
            const Divider(),
            if (deaths.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No deaths recorded here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final entry in deaths)
                ActivityTile(entry: entry, currentPaddockId: paddock.id),
          ],
        );
      },
    );
  }
}

/// Each tag standing here, linking to its own page. A big mob's are cut
/// short until asked for.
class _TagChips extends StatefulWidget {
  const _TagChips({required this.tags});

  final List<TagStatus> tags;

  @override
  State<_TagChips> createState() => _TagChipsState();
}

class _TagChipsState extends State<_TagChips> {
  static const _shown = 24;
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final tags = widget.tags;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final status in _all ? tags : tags.take(_shown))
          ActionChip(
            avatar: const Icon(Icons.sell_outlined, size: 18),
            label: Text(status.tag.tagNumber.display),
            tooltip: status.stockClass?.label,
            onPressed: () => openTier(
              context,
              tagPath(status.tag.id),
              preload: preloadTag(RepositoryScope.of(context), status.tag.id),
            ),
          ),
        if (!_all && tags.length > _shown)
          TextButton(
            onPressed: () => setState(() => _all = true),
            child: Text('Show all ${tags.length}'),
          ),
      ],
    );
  }
}
