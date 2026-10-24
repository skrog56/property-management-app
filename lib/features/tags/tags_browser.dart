import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tag_numbers.dart';
import '../../shell/breakpoints.dart';
import '../../shell/tier_route.dart';
import 'paths.dart';
import 'tag_page.dart';
import 'tags_page.dart';

/// The tag list and one tag's page, side by side when the content area has
/// room for two panes, as `PropertiesBrowser` does with its tiers.
class TagsBrowser extends StatelessWidget {
  const TagsBrowser({super.key, this.tagId, this.query = ''});

  final String? tagId;
  final String query;

  static const _listPaneWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panes = WindowSizeClass.fromWidth(constraints.maxWidth).panes;
        final id = tagId;
        final list = TagsPage(selectedId: id, query: query);
        final detail = id == null
            ? const TierPlaceholder('Select a tag')
            : TagPage(tagId: id);
        final single = panes == 1;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: single && id != null
                ? BackButton(onPressed: () => _up(context))
                : null,
            title: single && id != null ? _TagNumber(id) : const Text('Tags'),
          ),
          body: single
              ? (id == null ? list : detail)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: _listPaneWidth, child: list),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: detail),
                  ],
                ),
        );
      },
    );
  }

  /// A deep link arrives with nothing beneath it to pop back to.
  void _up(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(tagsPath);
    }
  }
}

class _TagNumber extends StatelessWidget {
  const _TagNumber(this.tagId);

  final String tagId;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.of(context);
    return StreamBuilder<TagStatus?>(
      initialData: repository.latestTag(tagId),
      stream: repository.watchTag(tagId),
      builder: (context, snapshot) => Text(
        snapshot.data?.tag.tagNumber.display ?? 'Tag',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
