import 'package:flutter/material.dart';

import 'form_dialog.dart';

/// One choice in a [SearchPicker].
class SearchEntry<T> {
  const SearchEntry(this.value, this.label, {this.icon, this.alsoFoundBy});

  final T value;
  final String label;

  /// Leads the entry in the list, and in the field once it is chosen.
  final Widget? icon;

  /// Words that find the entry besides its label, as a class's animal.
  final String? alsoFoundBy;
}

/// Chooses one of [entries], a list that may run long, so typing narrows it:
/// each word typed must appear in an entry's label or [SearchEntry.alsoFoundBy],
/// in any order, as "feed hei" finds Heifers (Feeders). Enter takes the first
/// match.
///
/// The field always shows what is chosen. Editing its text away from the
/// chosen label unchooses it, and [onChanged] reports null; typing another
/// entry's label exactly chooses that one.
class SearchPicker<T> extends StatefulWidget {
  const SearchPicker({
    super.key,
    required this.label,
    required this.entries,
    required this.value,
    required this.onChanged,
    required this.emptyHint,
    this.hint = 'Choose or search…',
    this.wrong = false,
  });

  final String label;
  final List<SearchEntry<T>> entries;
  final T? value;
  final ValueChanged<T?> onChanged;

  /// Shown, with the field disabled, while there is nothing to choose.
  final String emptyHint;

  /// Shown while nothing is chosen.
  final String hint;
  final bool wrong;

  @override
  State<SearchPicker<T>> createState() => _SearchPickerState<T>();
}

/// About seven entries, the eighth cut through so the list plainly scrolls.
const _menuHeight = 360.0;

class _SearchPickerState<T> extends State<SearchPicker<T>> {
  late final _text = TextEditingController(text: _chosen?.label ?? '')
    ..addListener(_edited);

  /// The value last reported or given, so neither is reported twice.
  T? _reported;

  @override
  void initState() {
    super.initState();
    _reported = widget.value;
  }

  SearchEntry<T>? get _chosen =>
      widget.entries.where((e) => e.value == widget.value).firstOrNull;

  @override
  void didUpdateWidget(SearchPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chosen by the form itself, as Age preselects where a class ages into,
    // rather than echoing what was typed.
    if (widget.value != _reported) {
      _reported = widget.value;
      final label = _chosen?.label ?? '';
      if (_text.text != label) _text.text = label;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _report(T? value) {
    if (value == _reported) return;
    _reported = value;
    widget.onChanged(value);
  }

  void _edited() {
    final matches = widget.entries.where((e) => e.label == _text.text);
    if (matches.any((e) => e.value == _reported)) return;
    _report(matches.firstOrNull?.value);
  }

  static List<String> _terms(String text) => [
    for (final term in text.toLowerCase().split(RegExp(r'\s+')))
      if (term.isNotEmpty) term,
  ];

  @override
  Widget build(BuildContext context) {
    // A DropdownButton's text throughout, rather than the menu's smaller
    // labels and a text field's lighter weight, so a picker and a plain
    // dropdown in one form read alike.
    final text = Theme.of(context).textTheme.titleMedium;
    final entryStyle = ButtonStyle(textStyle: WidgetStatePropertyAll(text));
    final searched = [
      for (final e in widget.entries)
        '${e.label} ${e.alsoFoundBy ?? ''}'.toLowerCase(),
    ];
    final chosen = _chosen;
    final empty = widget.entries.isEmpty;

    return DropdownMenu<int>(
      controller: _text,
      enabled: !empty,
      expandedInsets: EdgeInsets.zero,
      menuHeight: _menuHeight,
      textStyle: text,
      // On a phone too, where the default is to only choose.
      requestFocusOnTap: true,
      enableFilter: true,
      filterCallback: (entries, text) {
        // Not narrowed while the field still shows what is chosen.
        if (chosen != null && text == chosen.label) return entries;
        final terms = _terms(text);
        return [
          for (final e in entries)
            if (terms.every(searched[e.value].contains)) e,
        ];
      },
      searchCallback: (entries, text) =>
          entries.isEmpty || _terms(text).isEmpty ? null : 0,
      decorationBuilder: (context, _) => InputDecoration(
        labelText: widget.label,
        hintText: empty ? widget.emptyHint : widget.hint,
        error: widget.wrong ? wrongField : null,
        prefixIcon: switch (chosen?.icon) {
          final icon? => Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
            child: icon,
          ),
          null => null,
        },
        prefixIconConstraints: const BoxConstraints(),
      ),
      onSelected: (i) {
        if (i != null) _report(widget.entries[i].value);
      },
      // Keyed by position, so a value of any type, null among them, can't
      // be confused with the menu's own null for no choice.
      dropdownMenuEntries: [
        for (final (i, e) in widget.entries.indexed)
          DropdownMenuEntry(
            value: i,
            label: e.label,
            style: entryStyle,
            leadingIcon: switch (e.icon) {
              final icon? => Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: icon,
              ),
              null => null,
            },
          ),
      ],
    );
  }
}
