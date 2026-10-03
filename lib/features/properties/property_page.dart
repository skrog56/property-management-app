import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../shell/breakpoints.dart';
import '../transfers/movement_sheet.dart';
import 'name_dialog.dart';
import 'paddock_page.dart';
import 'paths.dart';

/// The middle tier: the paddocks of one property, with head counts derived
/// from the ledger.
class PropertyPage extends StatelessWidget {
  const PropertyPage({
    super.key,
    required this.propertyId,
    this.selectedPaddockId,
    this.primary = true,
  });

  final String propertyId;
  final String? selectedPaddockId;

  /// Whether this is the deepest tier on screen, and so owns the action button.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);

    return StreamBuilder<Property?>(
      initialData: repository.latestProperty(propertyId),
      stream: repository.watchProperty(propertyId),
      builder: (context, propertySnapshot) {
        final property = propertySnapshot.data;
        if (property == null) {
          return propertySnapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : const Center(child: Text('This property is gone.'));
        }

        return StreamBuilder<List<PaddockSummary>>(
          initialData: repository.latestPaddockSummaries(propertyId),
          stream: repository.watchPaddockSummaries(propertyId),
          builder: (context, snapshot) {
            final summaries = snapshot.data;

            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: switch (summaries) {
                _ when !primary => null,
                null => null,
                [] => FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text('Add paddock'),
                  onPressed: () => addPaddock(context, repository, propertyId),
                ),
                _ => FloatingActionButton.extended(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Record movement'),
                  onPressed: () => showMovementSheet(
                    context,
                    repository: repository,
                    propertyId: propertyId,
                  ),
                ),
              },
              body: summaries == null
                  ? const Center(child: CircularProgressIndicator())
                  : _PaddockGrid(
                      property: property,
                      summaries: summaries,
                      selectedId: selectedPaddockId,
                    ),
            );
          },
        );
      },
    );
  }
}

Future<void> preloadProperty(LivestockRepository repository, String id) =>
    repository.warm([
      repository.watchProperty(id),
      repository.watchPaddockSummaries(id),
    ]);

Future<void> addPaddock(
  BuildContext context,
  LivestockRepository repository,
  String propertyId,
) async {
  final name = await promptForName(
    context,
    title: 'New paddock',
    hint: 'North Ridge',
    askForHectares: true,
  );
  if (name == null) return;
  await repository.createPaddock(
    propertyId,
    name.value,
    hectares: name.hectares ?? 0,
  );
}

class _PaddockGrid extends StatelessWidget {
  const _PaddockGrid({
    required this.property,
    required this.summaries,
    required this.selectedId,
  });

  final Property property;
  final List<PaddockSummary> summaries;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = summaries.fold(0, (sum, s) => sum + s.head);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = WindowSizeClass.fromWidth(constraints.maxWidth);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                title: Text(
                  '${summaries.length} '
                  '${summaries.length == 1 ? 'paddock' : 'paddocks'} · '
                  '$total head',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                subtitle: property.pic == null
                    ? null
                    : Text(
                        'PIC ${property.pic}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (summaries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No paddocks yet. Add one to get started.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: sizeClass.contentColumns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 132,
                ),
                itemCount: summaries.length,
                itemBuilder: (context, index) => _PaddockCard(
                  summary: summaries[index],
                  selected: summaries[index].paddock.id == selectedId,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PaddockCard extends StatelessWidget {
  const _PaddockCard({required this.summary, required this.selected});

  final PaddockSummary summary;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = summary.isEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: () => openTier(
          context,
          paddockPath(summary.paddock.propertyId, summary.paddock.id),
          preload: preloadPaddock(
            RepositoryScope.of(context),
            summary.paddock.id,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: empty
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primaryContainer,
                child: Text(
                  '${summary.head}',
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
                    Text(
                      summary.paddock.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (empty)
                      Text(
                        'Empty',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      for (final mob in summary.mobs)
                        Text(
                          '${mob.head} × ${mob.label} '
                          '(${mob.livestockClass.ageBand})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    const Spacer(),
                    Text(
                      '${summary.paddock.hectares.toStringAsFixed(1)} ha',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
