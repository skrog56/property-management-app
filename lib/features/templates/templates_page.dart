import 'package:flutter/material.dart';

import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../data/tables.dart';
import '../../shell/action_button.dart';
import '../../shell/breakpoints.dart';
import '../../shell/card_grid.dart';
import '../../shell/pill_controls.dart';
import '../../shell/form_dialog.dart';
import 'class_dialog.dart';
import 'species.dart';
import 'template_dialog.dart';

/// The classes livestock is counted in, grouped by template, all of them
/// editable. Searchable by template and class, and sortable, with the cards
/// grouped by animal or not. Templates and their classes are dragged, or moved
/// from their menus, into an order of their own, which the page keeps unless
/// sorted otherwise.
class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

enum _Sort {
  custom('Custom order'),
  mostHead('Most head'),
  fewestHead('Fewest head'),
  nameAscending('Name (A–Z)'),
  nameDescending('Name (Z–A)'),
  newest('Newest first'),
  oldest('Oldest first');

  const _Sort(this.label);

  final String label;

  int compare(TemplateSummary a, TemplateSummary b) {
    int alphabetical() =>
        a.template.name.toLowerCase().compareTo(b.template.name.toLowerCase());
    final order = switch (this) {
      custom => 0,
      mostHead => b.totalHead.compareTo(a.totalHead),
      fewestHead => a.totalHead.compareTo(b.totalHead),
      nameAscending => alphabetical(),
      nameDescending => -alphabetical(),
      newest => b.template.createdAt.compareTo(a.template.createdAt),
      oldest => a.template.createdAt.compareTo(b.template.createdAt),
    };
    if (order != 0) return order;
    // The custom order, and ties in the others, as List.sort is not stable.
    final listed = a.template.sortOrder.compareTo(b.template.sortOrder);
    return listed != 0 ? listed : alphabetical();
  }
}

class _TemplatesPageState extends State<TemplatesPage> {
  final _search = TextEditingController();
  var _grouped = true;
  var _sort = _Sort.custom;

  /// The template being dragged, dimmed where it was.
  String? _dragging;

  /// An order just dropped, and the templates it was dropped on, shown until
  /// the database reports it.
  (List<TemplateSummary>, List<String>)? _dropped;

  // Watched once rather than per build, which typing triggers on every key.
  LivestockRepository? _repository;
  late Stream<List<TemplateSummary>> _templates;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = RepositoryScope.of(context);
    if (repository != _repository) {
      _repository = repository;
      _templates = repository.watchTemplates();
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

    return StreamBuilder<List<TemplateSummary>>(
      stream: _templates,
      builder: (context, snapshot) {
        final templates = snapshot.data;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: templates == null
              ? null
              : ActionButton(
                  icon: Icons.add,
                  label: 'Add template',
                  onPressed: () => showTemplateDialog(
                    context,
                    repository: RepositoryScope.of(context),
                    templates: [for (final t in templates) t.template],
                  ),
                ),
          body: switch (templates) {
            null => const Center(child: CircularProgressIndicator()),
            [] => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No templates. Add one to start counting livestock.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            final templates => LayoutBuilder(
              builder: (context, constraints) => _body(
                templates,
                WindowSizeClass.fromWidth(constraints.maxWidth),
              ),
            ),
          },
        );
      },
    );
  }

  Widget _body(List<TemplateSummary> reported, WindowSizeClass sizeClass) {
    var templates = reported;
    if (_dropped case (final on, final order)) {
      if (identical(on, reported)) {
        templates = [
          for (final id in order)
            reported.firstWhere((t) => t.template.id == id),
        ];
      } else {
        _dropped = null;
      }
    }

    final query = _search.text.trim();
    final terms = _searchTerms(query);
    final shown = [
      for (final t in templates)
        if (_matches(t, terms)) t,
    ]..sort(_sort.compare);
    // Only the whole list, in its own order, shows where a template will go.
    final reorderable = _sort == _Sort.custom && terms.isEmpty;

    Widget card(TemplateSummary summary, List<TemplateSummary> group) {
      final id = summary.template.id;
      final at = group.indexOf(summary);
      void moveTo(int to) =>
          _moveTemplate(reported, templates, id, group[to].template.id);

      return DragTarget<String>(
        key: ValueKey(id),
        // Within its group, the only templates beside it.
        onWillAcceptWithDetails: (drag) =>
            drag.data != id && group.any((t) => t.template.id == drag.data),
        onAcceptWithDetails: (drag) =>
            _moveTemplate(reported, templates, drag.data, id),
        builder: (context, over, _) => Opacity(
          opacity: _dragging == id ? 0.4 : 1,
          child: _TemplateCard(
            summary: summary,
            templates: templates,
            terms: terms,
            dropTarget: over.isNotEmpty,
            moves: reorderable
                ? _TemplateMoves(
                    earlier: at == 0 ? null : () => moveTo(at - 1),
                    later: at == group.length - 1 ? null : () => moveTo(at + 1),
                    onDragStarted: () => setState(() => _dragging = id),
                    onDragEnded: () => setState(() => _dragging = null),
                  )
                : null,
          ),
        ),
      );
    }

    Widget grid(List<TemplateSummary> summaries) => CardGrid(
      columns: sizeClass.cardColumns,
      children: [for (final summary in summaries) card(summary, summaries)],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _toolbar(),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(child: Text('No templates match "$query".'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    if (!_grouped)
                      grid(shown)
                    else
                      for (final species in Species.values)
                        if (_ofSpecies(shown, species) case final group
                            when group.isNotEmpty) ...[
                          _GroupHeading(species: species, count: group.length),
                          grid(group),
                          const SizedBox(height: 16),
                        ],
                  ],
                ),
        ),
      ],
    );
  }

  /// Puts [moved] where [target] is, the templates between them making room.
  Future<void> _moveTemplate(
    List<TemplateSummary> reported,
    List<TemplateSummary> templates,
    String moved,
    String target,
  ) async {
    final order = [for (final t in templates) t.template.id];
    final to = order.indexOf(target);
    order
      ..remove(moved)
      ..insert(to, moved);
    setState(() => _dropped = (reported, order));
    try {
      await RepositoryScope.of(context).reorderTemplates(order);
    } catch (_) {
      if (mounted) setState(() => _dropped = null);
      rethrow;
    }
  }

  static List<TemplateSummary> _ofSpecies(
    List<TemplateSummary> templates,
    Species species,
  ) => [
    for (final t in templates)
      if (t.template.species == species) t,
  ];

  Widget _toolbar() {
    final search = PillSearchField(
      controller: _search,
      hintText: 'Search templates and classes',
      onChanged: (_) => setState(() {}),
    );

    // Neither chip changes width with its state, so nothing beside it moves.
    final controls = PillChips(
      children: [
        FilterChip(
          // An icon in both states, rather than a check that appears.
          showCheckmark: false,
          avatar: Icon(_grouped ? Icons.check : Icons.workspaces_outlined),
          label: const Text('Group by animal'),
          selected: _grouped,
          onSelected: (grouped) => setState(() => _grouped = grouped),
        ),
        MenuAnchor(
          menuChildren: [
            for (final sort in _Sort.values)
              MenuItemButton(
                leadingIcon: Icon(sort == _sort ? Icons.check : null),
                onPressed: () => setState(() => _sort = sort),
                child: Text(sort.label),
              ),
          ],
          builder: (context, menu, _) => ActionChip(
            side: pillOutline(
              Theme.of(context).colorScheme,
              inUse: menu.isOpen,
            ),
            avatar: const Icon(Icons.sort),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // As wide as the longest choice, whichever is showing.
                IndexedStack(
                  index: _sort.index,
                  alignment: AlignmentDirectional.centerStart,
                  children: [for (final sort in _Sort.values) Text(sort.label)],
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
            tooltip: 'Sort templates',
            onPressed: () => menu.isOpen ? menu.close() : menu.open(),
          ),
        ),
      ],
    );

    return PillToolbar(search: search, chips: controls);
  }
}

/// The words searched for, each of which a template must contain somewhere:
/// in its own name or in one of its classes.
List<String> _searchTerms(String query) => [
  for (final term in query.toLowerCase().split(RegExp(r'\s+')))
    if (term.isNotEmpty) term,
];

/// What a search reads of a class: its own words, not its template's.
String _classText(StockClass c) => [
  ?c.row.breed,
  c.row.kind,
  ?c.row.ageBand,
  if (c.isReadyToSell) 'ready to sell',
].join(' ');

bool _matches(TemplateSummary summary, List<String> terms) {
  final texts = [
    summary.template.name.toLowerCase(),
    for (final c in summary.classes) _classText(c).toLowerCase(),
  ];
  return terms.every((term) => texts.any((text) => text.contains(term)));
}

/// [text] with every search term in it picked out, case aside.
TextSpan _highlight(String text, List<String> terms, TextStyle style) {
  final lower = text.toLowerCase();
  // Lowercasing a few letters changes their length, which would put the
  // marks in the wrong place.
  if (terms.isEmpty || lower.length != text.length) return TextSpan(text: text);

  final marked = List.filled(text.length, false);
  for (final term in terms) {
    for (
      var at = lower.indexOf(term);
      at >= 0;
      at = lower.indexOf(term, at + 1)
    ) {
      marked.fillRange(at, at + term.length, true);
    }
  }
  final spans = <TextSpan>[];
  var start = 0;
  for (var i = 1; i <= text.length; i++) {
    if (i == text.length || marked[i] != marked[start]) {
      spans.add(
        TextSpan(
          text: text.substring(start, i),
          style: marked[start] ? style : null,
        ),
      );
      start = i;
    }
  }
  return TextSpan(children: spans);
}

TextStyle _highlightStyle(ThemeData theme) => TextStyle(
  backgroundColor: theme.colorScheme.tertiaryContainer,
  color: theme.colorScheme.onTertiaryContainer,
);

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.species, required this.count});

  final Species species;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          SpeciesIcon(species, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(species.label, style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'template' : 'templates'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Action { edit, moveUp, moveDown, remove }

/// How far a card's classes sit inside its header, at both ends. At the start
/// that lines them up with the icon of Add class, which then reads as the last
/// line of the list.
const _classInset = 16.0;

/// How a card moves among the others: dragged by its handle, or a step at a
/// time from its menu, where a step that isn't there is null.
class _TemplateMoves {
  const _TemplateMoves({
    required this.earlier,
    required this.later,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  final VoidCallback? earlier;
  final VoidCallback? later;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.summary,
    required this.templates,
    required this.terms,
    this.moves,
    this.dropTarget = false,
    this.lifted = false,
  });

  final TemplateSummary summary;
  final List<TemplateSummary> templates;
  final List<String> terms;

  /// Null where the card can't move, as while the page is searched or sorted.
  final _TemplateMoves? moves;

  /// Outlined, as a card dragged over it would be dropped there.
  final bool dropTarget;

  /// The card as it is dragged.
  final bool lifted;

  List<StockClass> get _allClasses => [for (final t in templates) ...t.classes];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = RepositoryScope.of(context);
    final template = summary.template;
    final muted = theme.colorScheme.onSurfaceVariant;
    final moves = this.moves;

    return Card(
      elevation: lifted ? 6 : null,
      shape: dropTarget
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
        // Spread, so in a row of cards their Add class buttons line up.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: SpeciesIcon(template.species),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            _highlight(
                              template.name,
                              terms,
                              _highlightStyle(theme),
                            ),
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${template.species.label} · '
                            '${summary.totalHead} head',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (moves != null)
                      _CardHandle(
                        id: template.id,
                        card: context,
                        moves: moves,
                        lifted: (size) => SizedBox.fromSize(
                          size: size,
                          child: _TemplateCard(
                            summary: summary,
                            templates: templates,
                            terms: terms,
                            lifted: true,
                          ),
                        ),
                      ),
                    PopupMenuButton<_Action>(
                      tooltip: 'Actions for ${template.name}',
                      onSelected: (action) => switch (action) {
                        _Action.edit => showTemplateDialog(
                          context,
                          repository: repository,
                          templates: [for (final t in templates) t.template],
                          editing: template,
                        ),
                        _Action.moveUp => moves?.earlier?.call(),
                        _Action.moveDown => moves?.later?.call(),
                        _Action.remove => _remove(context),
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: _Action.edit,
                          child: Text('Edit'),
                        ),
                        if (moves != null) ...[
                          PopupMenuItem(
                            value: _Action.moveUp,
                            enabled: moves.earlier != null,
                            child: const Text('Move earlier'),
                          ),
                          PopupMenuItem(
                            value: _Action.moveDown,
                            enabled: moves.later != null,
                            child: const Text('Move later'),
                          ),
                        ],
                        const PopupMenuItem(
                          value: _Action.remove,
                          child: Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (summary.classes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _classInset,
                      vertical: 12,
                    ),
                    child: Text(
                      'No classes yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  )
                else
                  _ClassList(
                    summary: summary,
                    allClasses: _allClasses,
                    terms: terms,
                  ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => showClassDialog(
                  context,
                  repository: repository,
                  template: template,
                  classes: _allClasses,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add class'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context) {
    final repository = RepositoryScope.of(context);
    final template = summary.template;
    return _confirmRemoval(
      context,
      title: 'Remove ${template.name}?',
      body:
          'Its classes will no longer be offered for new livestock. '
          'Activity keeps their history.',
      head: summary.totalHead,
      remove: () => repository.removeTemplate(template.id),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => const MouseRegion(
    cursor: SystemMouseCursors.grab,
    child: Tooltip(
      message: 'Drag to reorder',
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.drag_indicator),
      ),
    ),
  );
}

/// Drags a template's whole [card], lifted from under the pointer, and
/// scrolls the page while it is held near either end.
class _CardHandle extends StatefulWidget {
  const _CardHandle({
    required this.id,
    required this.card,
    required this.moves,
    required this.lifted,
  });

  final String id;
  final BuildContext card;
  final _TemplateMoves moves;
  final Widget Function(Size size) lifted;

  @override
  State<_CardHandle> createState() => _CardHandleState();
}

class _CardHandleState extends State<_CardHandle> {
  EdgeDraggingAutoScroller? _scroller;
  var _size = Size.zero;

  @override
  void dispose() {
    _scroller?.stopAutoScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Draggable<String>(
    data: widget.id,
    // Held where it was picked up, so the card lifts in place.
    dragAnchorStrategy: (_, _, position) {
      final card = widget.card.findRenderObject()! as RenderBox;
      _size = card.size;
      return card.globalToLocal(position);
    },
    feedback: Builder(builder: (_) => widget.lifted(_size)),
    onDragStarted: () {
      _scroller = EdgeDraggingAutoScroller(
        Scrollable.of(context),
        velocityScalar: 50,
      );
      widget.moves.onDragStarted();
    },
    // The pointer, not the card, which may be taller than the page.
    onDragUpdate: (drag) => _scroller?.startAutoScrollIfNecessary(
      Rect.fromCenter(center: drag.globalPosition, width: 1, height: 96),
    ),
    onDragEnd: (_) {
      _scroller?.stopAutoScroll();
      _scroller = null;
      widget.moves.onDragEnded();
    },
    child: const _DragHandle(),
  );
}

/// A card's classes, dragged by their handles into the order they are listed
/// in everywhere. Twins follow their classes, so only the classes move.
class _ClassList extends StatefulWidget {
  const _ClassList({
    required this.summary,
    required this.allClasses,
    required this.terms,
  });

  final TemplateSummary summary;
  final List<StockClass> allClasses;
  final List<String> terms;

  @override
  State<_ClassList> createState() => _ClassListState();
}

class _ClassListState extends State<_ClassList> {
  /// An order just dropped, shown until the database reports it.
  List<StockClass>? _dropped;

  @override
  void didUpdateWidget(_ClassList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.summary, oldWidget.summary)) _dropped = null;
  }

  Future<void> _reorder(List<StockClass> order) async {
    setState(() => _dropped = order);
    try {
      await RepositoryScope.of(context).reorderClasses(
        widget.summary.template.id,
        [for (final c in order) c.id],
      );
    } catch (_) {
      if (mounted) setState(() => _dropped = null);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final classes =
        _dropped ??
        [
          for (final c in summary.classes)
            if (!c.isReadyToSell) c,
        ];
    int place(StockClass twin) =>
        classes.indexWhere((c) => c.id == twin.row.readyToSellOfClassId);
    final twins = [
      for (final c in summary.classes)
        if (c.isReadyToSell) c,
    ]..sort((a, b) => place(a).compareTo(place(b)));

    void move(int from, int to) {
      final order = [...classes];
      order.insert(to, order.removeAt(from));
      _reorder(order);
    }

    _ClassRow row(StockClass c, {int? index}) => _ClassRow(
      key: ValueKey(c.id),
      stockClass: c,
      summary: summary,
      allClasses: widget.allClasses,
      terms: widget.terms,
      index: index,
      moveUp: index == null || index == 0 ? null : () => move(index, index - 1),
      moveDown: index == null || index == classes.length - 1
          ? null
          : () => move(index, index + 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          buildDefaultDragHandles: false,
          onReorderItem: move,
          children: [for (final (i, c) in classes.indexed) row(c, index: i)],
        ),
        for (final c in twins) row(c),
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    super.key,
    required this.stockClass,
    required this.summary,
    required this.allClasses,
    required this.terms,
    this.index,
    this.moveUp,
    this.moveDown,
  });

  final StockClass stockClass;
  final TemplateSummary summary;
  final List<StockClass> allClasses;
  final List<String> terms;

  /// Where a class sits in its list, for its handle. Null for a twin.
  final int? index;
  final VoidCallback? moveUp;
  final VoidCallback? moveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = RepositoryScope.of(context);
    final highlight = _highlightStyle(theme);
    final row = stockClass.row;
    final name = [row.breed, row.kind].whereType<String>().join(' ');
    final head = summary.headIn(stockClass.id);

    // Shown, but set from the class it belongs to.
    final index = this.index;
    if (index == null) {
      final muted = theme.colorScheme.onSurfaceVariant;
      return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: _classInset),
        title: Text.rich(
          _highlight('$name · ready to sell', terms, highlight),
          style: TextStyle(color: muted),
        ),
        subtitle: head > 0
            ? Text('$head head', style: TextStyle(color: muted))
            : null,
      );
    }

    final next = allClasses
        .where((c) => c.id == row.agesIntoClassId)
        .firstOrNull;
    // Only the age band is the class's own words, which a search reads.
    final details = [
      if (row.ageBand case final ageBand?)
        _highlight(ageBand, terms, highlight),
      if (next != null) TextSpan(text: 'ages into ${next.label}'),
      if (head > 0) TextSpan(text: '$head head'),
    ];

    void edit() => showClassDialog(
      context,
      repository: repository,
      template: summary.template,
      classes: allClasses,
      editing: stockClass,
      twinHead: summary.headIn(stockClass.readyToSellClassId),
    );

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: _classInset),
      title: Text.rich(_highlight(name, terms, highlight)),
      subtitle: details.isEmpty
          ? null
          : Text.rich(
              TextSpan(
                children: [
                  for (final (i, detail) in details.indexed) ...[
                    if (i > 0) const TextSpan(text: ' · '),
                    detail,
                  ],
                ],
              ),
            ),
      onTap: edit,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const _DragHandle(),
          ),
          PopupMenuButton<_Action>(
            tooltip: 'Actions for ${stockClass.label}',
            onSelected: (action) => switch (action) {
              _Action.edit => edit(),
              _Action.moveUp => moveUp?.call(),
              _Action.moveDown => moveDown?.call(),
              _Action.remove => _remove(context),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: _Action.edit, child: Text('Edit')),
              PopupMenuItem(
                value: _Action.moveUp,
                enabled: moveUp != null,
                child: const Text('Move up'),
              ),
              PopupMenuItem(
                value: _Action.moveDown,
                enabled: moveDown != null,
                child: const Text('Move down'),
              ),
              const PopupMenuItem(value: _Action.remove, child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context) {
    final repository = RepositoryScope.of(context);
    final twin = stockClass.readyToSellClassId;
    return _confirmRemoval(
      context,
      title: 'Remove ${stockClass.label}?',
      body: [
        'It will no longer be offered for new livestock. Activity keeps its '
            'history.',
        if (twin != null) 'Its ready-to-sell class goes with it.',
      ].join(' '),
      head: summary.headIn(stockClass.id) + summary.headIn(twin),
      remove: () => repository.removeClass(stockClass.id),
    );
  }
}

/// Removal waits until no head stand in what is removed, so none are left in
/// a class that is no longer offered.
Future<void> _confirmRemoval(
  BuildContext context, {
  required String title,
  required String body,
  required int head,
  required Future<void> Function() remove,
}) {
  return showFormDialog<void>(
    context,
    builder: (dialogContext) => FormDialog(
      title: title,
      actionLabel: 'Remove',
      blocker: head > 0 ? 'Move or age its $head head out first' : null,
      onAction: () async {
        await remove();
        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      },
      children: [Text(body)],
    ),
  );
}
