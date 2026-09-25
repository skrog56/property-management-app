import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../shell/breakpoints.dart';
import '../transfers/movement_sheet.dart';
import 'name_dialog.dart';
import 'paddock_page.dart';

/// The middle tier: the paddocks of one property, with head counts derived
/// from the ledger.
class PropertyPage extends StatelessWidget {
  const PropertyPage({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);

    return StreamBuilder<List<PaddockSummary>>(
      stream: repository.watchPaddockSummaries(property.id),
      builder: (context, snapshot) {
        final summaries = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(property.name),
            actions: [
              IconButton(
                onPressed: () => _addPaddock(context, repository),
                icon: const Icon(Icons.add),
                tooltip: 'Add paddock',
              ),
            ],
          ),
          floatingActionButton: switch (summaries) {
            null => null,
            [] => FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Add paddock'),
              onPressed: () => _addPaddock(context, repository),
            ),
            _ => FloatingActionButton.extended(
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Record movement'),
              onPressed: () => showMovementSheet(
                context,
                repository: repository,
                propertyId: property.id,
              ),
            ),
          },
          body: summaries == null
              ? const Center(child: CircularProgressIndicator())
              : _PaddockGrid(property: property, summaries: summaries),
        );
      },
    );
  }

  Future<void> _addPaddock(
    BuildContext context,
    LivestockRepository repository,
  ) async {
    final name = await promptForName(
      context,
      title: 'New paddock',
      hint: 'North Ridge',
      askForHectares: true,
    );
    if (name == null) return;
    await repository.createPaddock(
      property.id,
      name.value,
      hectares: name.hectares ?? 0,
    );
  }
}

class _PaddockGrid extends StatelessWidget {
  const _PaddockGrid({required this.property, required this.summaries});

  final Property property;
  final List<PaddockSummary> summaries;

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
                itemBuilder: (context, index) =>
                    _PaddockCard(summary: summaries[index]),
              ),
          ],
        );
      },
    );
  }
}

class _PaddockCard extends StatelessWidget {
  const _PaddockCard({required this.summary});

  final PaddockSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = summary.isEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PaddockPage(paddockId: summary.paddock.id),
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
