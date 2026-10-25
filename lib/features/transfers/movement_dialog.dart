import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/tables.dart';
import '../../shell/form_dialog.dart';
import '../tags/tag_field.dart';

Future<void> showMovementDialog(
  BuildContext context, {
  required LivestockRepository repository,
  String? propertyId,
  String? fromPaddockId,
}) {
  return showFormDialog<void>(
    context,
    builder: (context) => _MovementDialog(
      repository: repository,
      propertyId: propertyId,
      fromPaddockId: fromPaddockId,
    ),
  );
}

/// Tag events start from a mob or a tag instead.
const _recordable = [
  MovementKind.intake,
  MovementKind.move,
  MovementKind.age,
  MovementKind.endState,
];

extension on MovementKind {
  String get label => switch (this) {
    MovementKind.intake => 'Intake',
    MovementKind.move => 'Move',
    MovementKind.age => 'Age',
    MovementKind.endState => 'End',
    MovementKind.tag => 'Tag',
  };

  IconData get icon => switch (this) {
    MovementKind.intake => Icons.add_circle_outline,
    MovementKind.move => Icons.swap_horiz,
    MovementKind.age => Icons.cake_outlined,
    MovementKind.endState => Icons.local_shipping_outlined,
    MovementKind.tag => Icons.sell_outlined,
  };

  String get tagsLabel => switch (this) {
    MovementKind.move => 'Tags to move',
    MovementKind.age => 'Tags to age',
    _ => 'Tags to remove',
  };

  bool get takesFrom => this != MovementKind.intake;
  bool get takesTo => this != MovementKind.endState;
}

class _MovementDialog extends StatefulWidget {
  const _MovementDialog({
    required this.repository,
    this.propertyId,
    this.fromPaddockId,
  });

  final LivestockRepository repository;

  /// Left out, as from Activity, the form asks which property first.
  final String? propertyId;

  /// Opened from a paddock, the origin is already known.
  final String? fromPaddockId;

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  final _head = TextEditingController();
  final _note = TextEditingController();
  late final _tags = TagSelection(widget.repository)..addListener(_onTags);

  MovementKind _kind = MovementKind.move;
  List<Property> _properties = const [];
  String? _propertyId;
  List<Paddock> _paddocks = const [];
  List<LivestockClass> _classes = const [];
  List<MobLine> _mobs = const [];
  List<TagStatus> _paddockTags = const [];

  String? _fromPaddockId;
  String? _toPaddockId;
  String? _fromClassId;
  String? _toClassId;
  EndState _endState = EndState.meatworks;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _head.dispose();
    _note.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _onTags() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final classes = await widget.repository.allClasses();
    // A property without paddocks has nothing to record against.
    final properties = widget.propertyId == null
        ? [
            for (final s in await widget.repository
                .watchPropertySummaries()
                .first)
              if (s.paddockCount > 0) s.property,
          ]
        : const <Property>[];
    final propertyId =
        widget.propertyId ??
        (properties.length == 1 ? properties.single.id : null);
    final paddocks = propertyId == null
        ? const <Paddock>[]
        : await widget.repository.paddocksIn(propertyId);
    if (!mounted) return;
    setState(() {
      _properties = properties;
      _propertyId = propertyId;
      _paddocks = paddocks;
      _classes = classes;
      _loading = false;
    });
    if (widget.fromPaddockId != null) {
      await _selectFromPaddock(widget.fromPaddockId);
    }
  }

  Future<void> _selectProperty(String? id) async {
    if (id == null || id == _propertyId) return;
    setState(() {
      _propertyId = id;
      _paddocks = const [];
      _toPaddockId = null;
    });
    await _selectFromPaddock(null);
    final paddocks = await widget.repository.paddocksIn(id);
    if (!mounted || _propertyId != id) return;
    setState(() => _paddocks = paddocks);
  }

  Future<void> _selectFromPaddock(String? id) async {
    setState(() {
      _fromPaddockId = id;
      _fromClassId = null;
      _mobs = const [];
      _paddockTags = const [];
    });
    _tags.mob = const [];
    if (id == null) return;
    final mobs = await widget.repository.mobsIn(id);
    final tags = await widget.repository.tagsIn(id);
    if (!mounted) return;
    setState(() {
      _mobs = mobs;
      _paddockTags = tags;
    });
  }

  /// Aging keeps the mob where it is and follows the template's chain, so the
  /// destination is implied rather than asked for.
  void _selectFromClass(String? id) {
    setState(() {
      _fromClassId = id;
      if (_kind == MovementKind.age) {
        _toPaddockId = _fromPaddockId;
        _toClassId = _classes
            .where((c) => c.id == id)
            .map((c) => c.agesIntoClassId)
            .firstOrNull;
      } else if (_kind == MovementKind.move) {
        _toClassId = id;
      }
    });
    _tags.mob = _mobTags;
    _chooseWholeMobIfNeeded();
  }

  void _selectKind(MovementKind kind) {
    // Intake's tags are new and the others' come from the mob, so neither
    // carries over to the other.
    if (kind.takesFrom != _kind.takesFrom) {
      _tags
        ..clear()
        ..draft = '';
    }
    setState(() {
      _kind = kind;
      _toClassId = kind == MovementKind.move ? _fromClassId : null;
      _toPaddockId = kind == MovementKind.age ? _fromPaddockId : null;
    });
    _tags.mob = kind.takesFrom ? _mobTags : const [];
    _chooseWholeMobIfNeeded();
  }

  List<TagStatus> get _mobTags => [
    for (final status in _paddockTags)
      if (status.livestockClass?.id == _fromClassId) status,
  ];

  /// Moving more head than the mob has untagged takes some of its tags along.
  /// When that is all of them, there is nothing to choose.
  void _chooseWholeMobIfNeeded() {
    final head = int.tryParse(_head.text.trim());
    if (!_kind.takesFrom || head == null || _tags.mob.isEmpty) return;
    if (head - _untagged >= _tags.mob.length) _tags.chooseWholeMob();
  }

  int get _available =>
      _mobs.where((m) => m.livestockClass.id == _fromClassId).firstOrNull?.head ??
      0;

  int get _untagged => _available - _tags.mob.length;

  /// Left blank, the head is one per tag.
  int? get _headValue =>
      int.tryParse(_head.text.trim()) ??
      (_tags.chosen.isEmpty ? null : _tags.chosen.length);

  String? get _headHelper {
    final parts = [
      if (_kind.takesFrom && _fromClassId != null) '$_available available',
      if (_kind.takesFrom && _tags.mob.isNotEmpty) '${_tags.mob.length} tagged',
      if (_head.text.trim().isEmpty && _tags.chosen.isNotEmpty)
        'blank means ${_tags.chosen.length}, one per tag',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? get _blocker {
    if (_propertyId == null) return 'Choose a property';
    final head = _headValue;
    if (head == null || head <= 0) return 'Enter a head count';
    if (_kind.takesFrom && _fromPaddockId == null) return 'Choose a paddock';
    if (_kind.takesFrom && _fromClassId == null) return 'Choose a mob';
    if (_kind.takesFrom && head > _available) {
      return 'Only $_available head available';
    }
    if (_kind.takesTo && _toPaddockId == null) return 'Choose a destination';
    if (_kind.takesTo && _toClassId == null) return 'Choose a class';
    if (_kind == MovementKind.move && _fromPaddockId == _toPaddockId) {
      return 'Pick a different destination paddock';
    }
    if (_kind == MovementKind.age && _fromClassId == _toClassId) {
      return 'Pick a different class to age into';
    }
    if (_tags.draft.trim().isNotEmpty) return 'Finish the typed tag';
    if (_tags.pending) return 'Checking tags…';
    if (_tags.hasElsewhere) return 'Remove tags recorded elsewhere';
    if (_tags.chosen.length > head) return 'More tags than head';
    if (_kind.takesFrom) {
      final short = head - _tags.carried - _untagged;
      if (short > 0) return 'Select $short more ${short == 1 ? 'tag' : 'tags'}';
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repository.record(
        kind: _kind,
        head: _headValue!,
        fromPaddockId: _kind.takesFrom ? _fromPaddockId : null,
        fromClassId: _kind.takesFrom ? _fromClassId : null,
        toPaddockId: _kind.takesTo ? _toPaddockId : null,
        toClassId: _kind.takesTo ? _toClassId : null,
        endState: _kind == MovementKind.endState ? _endState : null,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        tags: _tags.chosen,
      );
      if (mounted) Navigator.of(context).pop();
    } on LedgerConflict catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const FormDialog(
        title: 'Record movement',
        actionLabel: 'Record',
        children: [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    final blocker = _blocker;

    return FormDialog(
      title: 'Record movement',
      actionLabel: blocker ?? 'Record',
      onAction: blocker == null && !_saving ? _save : null,
      children: [
        if (widget.propertyId == null) ...[
          _Dropdown<String>(
            label: 'Property',
            value: _propertyId,
            onChanged: _selectProperty,
            items: [
              for (final p in _properties)
                DropdownMenuItem(value: p.id, child: Text(p.name)),
            ],
            emptyHint: 'No paddocks yet',
          ),
          const SizedBox(height: 16),
        ],
        SegmentedButton<MovementKind>(
          segments: [
            for (final kind in _recordable)
              ButtonSegment(
                value: kind,
                label: Text(kind.label),
                icon: Icon(kind.icon),
              ),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => _selectKind(s.first),
        ),
        const SizedBox(height: 16),

        if (_kind.takesFrom) ...[
          _PaddockField(
            label: _kind == MovementKind.intake ? 'Paddock' : 'From paddock',
            paddocks: _paddocks,
            value: _fromPaddockId,
            onChanged: _selectFromPaddock,
          ),
          const SizedBox(height: 12),
          _Dropdown<String>(
            label: 'Mob',
            value: _fromClassId,
            onChanged: _selectFromClass,
            items: [
              for (final mob in _mobs)
                DropdownMenuItem(
                  value: mob.livestockClass.id,
                  child: Text(
                    '${mob.head} × ${mob.label} (${mob.livestockClass.ageBand})',
                  ),
                ),
            ],
            emptyHint: _fromPaddockId == null
                ? 'Choose a paddock first'
                : 'This paddock is empty',
          ),
          const SizedBox(height: 12),
        ],

        if (_kind == MovementKind.intake || _kind == MovementKind.age) ...[
          _Dropdown<String>(
            label: _kind == MovementKind.age ? 'Ages into' : 'Class',
            value: _toClassId,
            onChanged: (id) => setState(() => _toClassId = id),
            items: [
              for (final c in _classes)
                DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.kind} (${c.ageBand})'),
                ),
            ],
            emptyHint: 'No templates seeded',
          ),
          const SizedBox(height: 12),
        ],

        if (_kind == MovementKind.intake || _kind == MovementKind.move) ...[
          _PaddockField(
            label: _kind == MovementKind.intake ? 'Into' : 'To paddock',
            paddocks: _paddocks,
            value: _toPaddockId,
            onChanged: (id) => setState(() => _toPaddockId = id),
          ),
          const SizedBox(height: 12),
        ],

        if (_kind == MovementKind.endState) ...[
          _Dropdown<EndState>(
            label: 'Destination',
            value: _endState,
            onChanged: (v) => setState(() => _endState = v!),
            items: [
              for (final state in EndState.values)
                DropdownMenuItem(value: state, child: Text(state.name)),
            ],
            emptyHint: '',
          ),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: _head,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Head',
            helperText: _headHelper,
          ),
          onChanged: (_) {
            setState(() {});
            _chooseWholeMobIfNeeded();
          },
        ),
        const SizedBox(height: 12),
        if (!_kind.takesFrom) ...[
          TagField(selection: _tags, label: 'Tags to add (optional)'),
          const SizedBox(height: 12),
        ] else if (_tags.mob.isNotEmpty) ...[
          TagPicker(selection: _tags, label: _kind.tagsLabel),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
      ],
    );
  }
}

class _PaddockField extends StatelessWidget {
  const _PaddockField({
    required this.label,
    required this.paddocks,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Paddock> paddocks;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Dropdown<String>(
      label: label,
      value: value,
      onChanged: onChanged,
      items: [
        for (final p in paddocks)
          DropdownMenuItem(value: p.id, child: Text(p.name)),
      ],
      emptyHint: 'No paddocks yet',
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.emptyHint,
  });

  final String label;
  final T? value;
  final ValueChanged<T?> onChanged;
  final List<DropdownMenuItem<T>> items;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: Text(emptyHint),
      items: items,
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}
