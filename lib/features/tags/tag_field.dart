import 'package:flutter/material.dart';

import '../../data/livestock_repository.dart';
import '../../data/tables.dart';
import '../../data/tag_numbers.dart';
import 'tag_labels.dart';

final _separator = RegExp(r'[,;\t\r\n]');

/// The tags chosen for one entry: picked from the source mob with a
/// [TagPicker], or typed into a [TagField]. Each typed number is looked up, so
/// the form can say where it already is before the repository refuses it.
class TagSelection extends ChangeNotifier {
  TagSelection(this.repository);

  final LivestockRepository repository;

  final _chosen = <TagNumber>[];
  final _status = <TagNumber, TagStatus?>{};
  List<TagStatus> _mob = const [];
  String _draft = '';
  int _pending = 0;
  bool _disposed = false;

  List<TagNumber> get chosen => List.unmodifiable(_chosen);

  /// Typed but not yet added, which a form should not silently drop.
  String get draft => _draft;

  set draft(String text) {
    if (text == _draft) return;
    _draft = text;
    _notify();
  }

  /// The tags standing in the source mob, which can be carried.
  List<TagStatus> get mob => _mob;

  /// Drops chosen tags that belonged to the last mob and not to this one.
  set mob(List<TagStatus> tags) {
    final kept = {for (final s in tags) s.tag.tagNumber};
    _chosen.removeWhere((n) => _inMob(n) && !kept.contains(n));
    _mob = tags;
    for (final s in tags) {
      _status[s.tag.tagNumber] = s;
    }
    _notify();
  }

  bool get pending => _pending > 0;

  int get carried => _chosen.where(_inMob).length;

  bool get hasElsewhere => _chosen.any((n) => elsewhere(n) != null);

  bool isChosen(TagNumber number) => _chosen.contains(number);

  /// Where a chosen tag already is, when that is not the source mob.
  TagStatus? elsewhere(TagNumber number) {
    final status = _status[number];
    if (status == null || !status.isActive || _inMob(number)) return null;
    return status;
  }

  bool _inMob(TagNumber number) => _mob.any((s) => s.tag.tagNumber == number);

  void toggle(TagNumber number) {
    if (!_chosen.remove(number)) _chosen.add(number);
    _notify();
  }

  void remove(TagNumber number) {
    _chosen.remove(number);
    _notify();
  }

  void clear() {
    _chosen.clear();
    _notify();
  }

  void chooseWholeMob() {
    for (final s in _mob) {
      if (!_chosen.contains(s.tag.tagNumber)) _chosen.add(s.tag.tagNumber);
    }
    _notify();
  }

  Future<void> add(TagNumber number) async {
    if (_chosen.contains(number)) return;
    _chosen.add(number);
    _notify();
    if (_status.containsKey(number)) return;

    _pending++;
    _notify();
    try {
      _status[number] = await repository.tagStatusByNumber(number);
    } finally {
      _pending--;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// New tag numbers, typed, pasted or scanned. A reader in keyboard mode types
/// the number and presses Enter, so it works here on every platform without a
/// plugin.
class TagField extends StatefulWidget {
  const TagField({
    super.key,
    required this.selection,
    this.label = 'Tags (optional)',
  });

  final TagSelection selection;
  final String label;

  @override
  State<TagField> createState() => _TagFieldState();
}

class _TagFieldState extends State<TagField> {
  final _input = TextEditingController();

  TagScheme _scheme = TagScheme.nlis;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Bad numbers stay in the box to be corrected; good ones become chips.
  void _submit(String raw) {
    final rejected = <String>[];
    for (final part in splitTagInput(raw)) {
      final number = TagNumber.tryParse(_scheme, part);
      if (number == null) {
        rejected.add(part);
      } else {
        widget.selection.add(number);
      }
    }
    setState(() {
      _error = rejected.isEmpty ? null : nlisFormat;
      _input.text = rejected.join(', ');
    });
    widget.selection.draft = _input.text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selection = widget.selection;

    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        final typed = selection.chosen;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _input,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: 'Type or scan, then Enter',
                errorText: _error,
                errorMaxLines: 3,
                prefixIcon: _SchemeMenu(
                  scheme: _scheme,
                  onChanged: (scheme) => setState(() {
                    _scheme = scheme;
                    _error = null;
                  }),
                ),
              ),
              // Multi-line so that Enter, from a keyboard or a scanner, and
              // a pasted column of numbers all arrive as newlines, which a
              // single-line field would strip. Each one adds what precedes it.
              keyboardType: TextInputType.multiline,
              maxLines: null,
              onChanged: (text) {
                if (text.contains(_separator)) {
                  _submit(text);
                } else {
                  widget.selection.draft = text;
                  if (_error != null) setState(() => _error = null);
                }
              },
            ),
            if (typed.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${typed.length} to add',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: selection.clear,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final number in typed)
                    InputChip(
                      label: Text(number.display),
                      avatar: selection.elsewhere(number) == null
                          ? null
                          : Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                            ),
                      onDeleted: () => selection.remove(number),
                    ),
                ],
              ),
            ],
            for (final number in typed)
              if (selection.elsewhere(number) case final status?)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${number.display} is already in '
                    '${status.paddock?.name ?? 'another paddock'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// The source mob's tags, to choose which go with the head. A scanned or typed
/// number selects its tag, and part of one narrows the list, so a mob walking
/// through a race can be scanned in.
class TagPicker extends StatefulWidget {
  const TagPicker({super.key, required this.selection, required this.label});

  final TagSelection selection;
  final String label;

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  static const _shown = 30;

  final _input = TextEditingController();

  String? _error;
  bool _expanded = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<TagStatus> _matching(String raw) {
    final key = tagSearchKey(raw);
    return [
      for (final s in widget.selection.mob)
        if (s.tag.number.contains(key)) s,
    ];
  }

  /// A whole number, or a part only one tag has, selects that tag. Selecting
  /// never deselects, so a beast scanned twice stays chosen.
  void _submit(String raw) {
    final selection = widget.selection;
    final problems = <String>[];
    for (final part in splitTagInput(raw)) {
      final key = tagSearchKey(part);
      final matches = _matching(part);
      final match =
          matches.where((s) => s.tag.number == key).firstOrNull ??
          (matches.length == 1 ? matches.single : null);
      if (match != null) {
        selection.add(match.tag.tagNumber);
      } else if (matches.isEmpty) {
        problems.add('$part is not in this mob');
      } else {
        problems.add('$part matches ${matches.length} tags');
      }
    }
    setState(() {
      _error = problems.isEmpty ? null : problems.join('\n');
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selection = widget.selection;

    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        final mob = selection.mob;
        final chosen = mob.where((s) => selection.isChosen(s.tag.tagNumber));
        final matching = _matching(_input.text);
        final shown = _expanded ? matching : matching.take(_shown);
        final allChosen = chosen.length == mob.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.label} · ${chosen.length} of ${mob.length}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: allChosen
                      ? selection.clear
                      : selection.chooseWholeMob,
                  child: Text(allChosen ? 'Clear' : 'Select all'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _input,
              decoration: InputDecoration(
                labelText: 'Scan or find',
                hintText: 'A whole number, or the end of one',
                prefixIcon: const Icon(Icons.search),
                errorText: _error,
                errorMaxLines: 3,
              ),
              // Multi-line for the same reason as TagField's.
              keyboardType: TextInputType.multiline,
              maxLines: null,
              onChanged: (text) {
                if (text.contains(_separator)) {
                  _submit(text);
                } else {
                  setState(() => _error = null);
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final status in shown)
                  FilterChip(
                    label: Text(status.tag.tagNumber.display),
                    selected: selection.isChosen(status.tag.tagNumber),
                    onSelected: (_) => selection.toggle(status.tag.tagNumber),
                  ),
              ],
            ),
            if (matching.isEmpty)
              Text('No tag here matches', style: theme.textTheme.bodySmall)
            else if (shown.length < matching.length)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = true),
                  child: Text('Show all ${matching.length}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SchemeMenu extends StatelessWidget {
  const _SchemeMenu({required this.scheme, required this.onChanged});

  final TagScheme scheme;
  final ValueChanged<TagScheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TagScheme>(
      tooltip: 'Tag type',
      initialValue: scheme,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final s in TagScheme.values)
          PopupMenuItem(value: s, child: Text(s.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(scheme.label), const Icon(Icons.arrow_drop_down)],
        ),
      ),
    );
  }
}
