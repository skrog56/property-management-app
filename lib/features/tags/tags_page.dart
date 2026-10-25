import 'package:flutter/material.dart';

import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';
import '../../data/tag_numbers.dart';
import '../../shell/tier_route.dart';
import 'paths.dart';
import 'tag_labels.dart';
import 'tag_page.dart';

/// Every tag recorded, those still on the property first, searchable by
/// number.
class TagsPage extends StatefulWidget {
  const TagsPage({super.key, this.selectedId, this.query = ''});

  final String? selectedId;

  /// The search to open with, carried over from the page before.
  final String query;

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  late final _search = TextEditingController(text: widget.query);

  // Watched once rather than per build, which typing triggers on every key.
  LivestockRepository? _repository;
  late Stream<List<TagStatus>> _tags;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = RepositoryScope.of(context);
    if (repository != _repository) {
      _repository = repository;
      _tags = repository.watchTags();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<TagStatus>>(
      stream: _tags,
      builder: (context, snapshot) {
        final all = snapshot.data;
        if (all == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (all.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No tags yet. Record them on a movement, or add them to a '
                'mob from its paddock.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final query = _search.text.trim();
        final needle = tagSearchKey(query);
        final matches = [
          for (final status in all)
            if (status.tag.number.contains(needle)) status,
        ];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search tag numbers',
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(child: Text('No tags match "$query".'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: matches.length,
                      itemBuilder: (context, index) => _TagTile(
                        status: matches[index],
                        selected: matches[index].tag.id == widget.selectedId,
                        query: query,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({
    required this.status,
    required this.selected,
    required this.query,
  });

  final TagStatus status;
  final bool selected;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tag = status.tag;

    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.secondaryContainer,
      selectedColor: theme.colorScheme.onSecondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        status.isActive ? Icons.sell_outlined : Icons.label_off_outlined,
      ),
      title: Text(
        tag.tagNumber.display,
        style: status.isActive
            ? null
            : TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      subtitle: Text(
        [
          if (tag.scheme != TagScheme.nlis) tag.scheme.label,
          tagWhereabouts(status),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => openTier(
        context,
        tagPath(tag.id, query: query),
        preload: preloadTag(RepositoryScope.of(context), tag.id),
      ),
    );
  }
}
