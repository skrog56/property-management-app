import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/tables.dart';

Future<void> showMovementSheet(
  BuildContext context, {
  required LivestockRepository repository,
  required String propertyId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _MovementSheet(repository: repository, propertyId: propertyId),
    ),
  );
}

extension on MovementKind {
  String get label => switch (this) {
    MovementKind.intake => 'Intake',
    MovementKind.move => 'Move',
    MovementKind.age => 'Age',
    MovementKind.endState => 'End',
  };

  IconData get icon => switch (this) {
    MovementKind.intake => Icons.add_circle_outline,
    MovementKind.move => Icons.swap_horiz,
    MovementKind.age => Icons.cake_outlined,
    MovementKind.endState => Icons.local_shipping_outlined,
  };

  bool get takesFrom => this != MovementKind.intake;
  bool get takesTo => this != MovementKind.endState;
}

class _MovementSheet extends StatefulWidget {
  const _MovementSheet({required this.repository, required this.propertyId});

  final LivestockRepository repository;
  final String propertyId;

  @override
  State<_MovementSheet> createState() => _MovementSheetState();
}

class _MovementSheetState extends State<_MovementSheet> {
  final _head = TextEditingController();
  final _note = TextEditingController();

  MovementKind _kind = MovementKind.move;
  List<Paddock> _paddocks = const [];
  List<LivestockClass> _classes = const [];
  List<MobLine> _mobs = const [];

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
    super.dispose();
  }

  Future<void> _load() async {
    final paddocks = await widget.repository.paddocksIn(widget.propertyId);
    final classes = await widget.repository.allClasses();
    if (!mounted) return;
    setState(() {
      _paddocks = paddocks;
      _classes = classes;
      _loading = false;
    });
  }

  Future<void> _selectFromPaddock(String? id) async {
    setState(() {
      _fromPaddockId = id;
      _fromClassId = null;
      _mobs = const [];
    });
    if (id == null) return;
    final mobs = await widget.repository.mobsIn(id);
    if (!mounted) return;
    setState(() => _mobs = mobs);
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
  }

  void _selectKind(MovementKind kind) {
    setState(() {
      _kind = kind;
      _toClassId = kind == MovementKind.move ? _fromClassId : null;
      _toPaddockId = kind == MovementKind.age ? _fromPaddockId : null;
    });
  }

  int get _available =>
      _mobs.where((m) => m.livestockClass.id == _fromClassId).firstOrNull?.head ??
      0;

  String? get _blocker {
    final head = int.tryParse(_head.text.trim());
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
    return null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repository.record(
        kind: _kind,
        head: int.parse(_head.text.trim()),
        fromPaddockId: _kind.takesFrom ? _fromPaddockId : null,
        fromClassId: _kind.takesFrom ? _fromClassId : null,
        toPaddockId: _kind.takesTo ? _toPaddockId : null,
        toClassId: _kind.takesTo ? _toClassId : null,
        endState: _kind == MovementKind.endState ? _endState : null,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on InsufficientHead catch (e) {
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
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final blocker = _blocker;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Record movement', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<MovementKind>(
            segments: [
              for (final kind in MovementKind.values)
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
              border: const OutlineInputBorder(),
              helperText: _kind.takesFrom && _fromClassId != null
                  ? '$_available available'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: blocker == null && !_saving ? _save : null,
            child: Text(blocker ?? 'Record'),
          ),
        ],
      ),
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      hint: Text(emptyHint),
      items: items,
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}
