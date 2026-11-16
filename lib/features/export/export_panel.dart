import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/repository_scope.dart';
import '../../shell/breakpoints.dart';
import '../../shell/card_grid.dart';
import '../../shell/form_dialog.dart';
import '../../shell/search_picker.dart';
import '../tags/tag_labels.dart';
import 'export_data.dart';
import 'export_formats.dart';
import 'save_export.dart';

/// Chooses what to export and how, then hands the file to [save]: the Data
/// tab of Settings.
class ExportPanel extends StatefulWidget {
  const ExportPanel({super.key, this.save = saveWithPicker, this.paddockId});

  final ExportSaver save;

  /// Chooses this paddock's property, as when arriving from its history.
  final String? paddockId;

  @override
  State<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends State<ExportPanel> {
  var _format = ExportFormat.xlsx;
  final _lists = {...ExportList.values};
  String? _propertyId;
  String? _paddockId;
  DateTime? _from;
  DateTime? _to;
  var _busy = false;
  String? _error;

  // Watched, not read once: the tab is kept while others are used, and a
  // property added meanwhile must still be offered.
  LivestockRepository? _repository;
  StreamSubscription<List<Property>>? _propertyWatch;
  StreamSubscription<List<Paddock>>? _paddockWatch;
  List<Property> _properties = const [];
  List<Paddock> _paddocks = const [];

  /// A paddock asked for before the paddocks have loaded.
  String? _pendingPaddock;

  @override
  void initState() {
    super.initState();
    _pendingPaddock = widget.paddockId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = RepositoryScope.of(context);
    if (repository == _repository) return;
    _repository = repository;
    _propertyWatch?.cancel();
    _paddockWatch?.cancel();
    _propertyWatch = repository.watchProperties().listen(
      (properties) => setState(
        () =>
            _properties = [...properties]
              ..sort((a, b) => a.name.compareTo(b.name)),
      ),
    );
    _paddockWatch = repository.watchPaddocks().listen((paddocks) {
      setState(() {
        _paddocks = paddocks;
        _choosePending();
      });
    });
  }

  @override
  void didUpdateWidget(ExportPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paddockId != null && widget.paddockId != oldWidget.paddockId) {
      _pendingPaddock = widget.paddockId;
      _choosePending();
    }
  }

  @override
  void dispose() {
    _propertyWatch?.cancel();
    _paddockWatch?.cancel();
    super.dispose();
  }

  void _choosePending() {
    final paddock = _paddocks.where((p) => p.id == _pendingPaddock).firstOrNull;
    if (paddock == null) return;
    _pendingPaddock = null;
    _propertyId = paddock.propertyId;
    _paddockId = paddock.id;
  }

  bool get _backup => _format == ExportFormat.json;

  bool get _datesClash => _from != null && _to != null && _from!.isAfter(_to!);

  String? get _blocker {
    if (_busy) return 'Exporting…';
    if (_backup) return null;
    if (_lists.isEmpty) return 'Choose at least one list';
    if (_datesClash) return 'From is after To';
    return null;
  }

  Future<void> _pick({required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => from ? _from = picked : _to = picked);
  }

  Future<void> _export() async {
    final repository = RepositoryScope.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await buildExport(
        repository,
        format: _format,
        lists: _lists,
        range: ExportRange(
          propertyId: _propertyId,
          paddockId: _paddockId,
          from: _from,
          to: _to,
        ),
        propertyName: _properties
            .where((p) => p.id == _propertyId)
            .firstOrNull
            ?.name,
        paddockName: _paddocks
            .where((p) => p.id == _paddockId)
            .firstOrNull
            ?.name,
      );
      final kept = await widget.save(file);
      if (kept) {
        messenger?.showSnackBar(
          SnackBar(content: Text('Exported ${file.name}')),
        );
      }
    } catch (e) {
      _error = 'Could not export: $e';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = WindowSizeClass.fromWidth(constraints.maxWidth);
        final format = _Card(
          title: 'Format',
          children: [
            CardGrid(
              columns: size.tileColumns,
              spacing: 8,
              children: [
                for (final format in ExportFormat.values)
                  _FormatChoice(
                    format,
                    chosen: format == _format,
                    onTap: _busy
                        ? null
                        : () => setState(() => _format = format),
                  ),
              ],
            ),
          ],
        );
        final action = _Action(
          icon: _format.icon,
          fileName: exportFileName(_format, _lists, DateTime.now()),
          blocker: _blocker,
          error: _error,
          onExport: _export,
        );

        final List<Widget> body;
        if (_backup) {
          body = [format, const _Backup(), action];
        } else if (size.contentColumns == 1) {
          body = [format, _listsCard(), _rangeCard(), action];
        } else {
          body = [
            format,
            CardGrid(
              columns: 2,
              spacing: 8,
              children: [_listsCard(), _rangeCard()],
            ),
            action,
          ];
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (i, section) in body.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              section,
            ],
          ],
        );
      },
    );
  }

  Widget _listsCard() => _Card(
    title: 'Lists',
    children: [
      for (final list in ExportList.values)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(list.title),
          subtitle: Text(list.description),
          value: _lists.contains(list),
          onChanged: _busy
              ? null
              : (on) => setState(
                  () => on! ? _lists.add(list) : _lists.remove(list),
                ),
        ),
    ],
  );

  Widget _rangeCard() {
    final theme = Theme.of(context);
    return _Card(
      title: 'Narrow to',
      children: [
        SearchPicker<String>(
          label: 'Property',
          hint: 'All properties',
          optional: true,
          searchIcon: true,
          value: _propertyId,
          onChanged: (id) => setState(() {
            if (id != _propertyId) _paddockId = null;
            _propertyId = id;
          }),
          entries: [
            for (final p in _properties)
              SearchEntry(p.id, p.name, alsoFoundBy: p.pic),
          ],
          emptyHint: 'No properties yet',
        ),
        const SizedBox(height: 16),
        SearchPicker<String>(
          // Rebuilt for each property, so it starts from that one's list.
          key: ValueKey(_propertyId),
          label: 'Paddock',
          hint: 'All paddocks',
          optional: true,
          searchIcon: true,
          value: _paddockId,
          onChanged: (id) => setState(() => _paddockId = id),
          entries: [
            for (final p in _paddocks)
              if (p.propertyId == _propertyId) SearchEntry(p.id, p.name),
          ],
          emptyHint: _propertyId == null
              ? 'Choose a property first'
              : 'No paddocks on this property',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            'Templates are shared by every property, so they are always '
            'exported whole.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _DateField(
                label: 'From',
                day: _from,
                wrong: _datesClash,
                onTap: () => _pick(from: true),
                onClear: () => setState(() => _from = null),
              ),
            ),
            Expanded(
              child: _DateField(
                label: 'To',
                day: _to,
                wrong: _datesClash,
                onTap: () => _pick(from: false),
                onClear: () => setState(() => _to = null),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            'Movements recorded on these days, both included. Every other '
            'list is as it stands today.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

extension on ExportFormat {
  IconData get icon => switch (this) {
    ExportFormat.xlsx => Icons.table_chart_outlined,
    ExportFormat.csv => Icons.description_outlined,
    ExportFormat.pdf => Icons.picture_as_pdf_outlined,
    ExportFormat.json => Icons.data_object,
  };

  String get purpose => switch (this) {
    ExportFormat.xlsx => 'A sheet for each list, to sort and total.',
    ExportFormat.csv => 'Plain tables any program can read.',
    ExportFormat.pdf => 'A report to print or send.',
    ExportFormat.json => 'Everything recorded, exactly as stored.',
  };
}

extension on ExportList {
  String get description => switch (this) {
    ExportList.movements => 'Every movement, newest first, as Activity has it',
    ExportList.stock => 'The head of each class in each paddock',
    ExportList.tags => 'Each tag, and where it is or how it left',
    ExportList.paddocks => 'Each property, its paddocks, their areas and head',
    ExportList.templates => 'Each template and its classes',
  };
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FormatChoice extends StatelessWidget {
  const _FormatChoice(this.format, {required this.chosen, this.onTap});

  final ExportFormat format;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = chosen ? colors.onSecondaryContainer : colors.onSurface;

    return Semantics(
      selected: chosen,
      button: true,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: chosen ? colors.secondaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: chosen ? colors.secondary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(format.icon, color: ink),
                    const Spacer(),
                    if (chosen)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: colors.secondary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  format.label,
                  style: theme.textTheme.titleSmall?.copyWith(color: ink),
                ),
                const SizedBox(height: 2),
                Text(
                  format.purpose,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: chosen ? ink : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stands in for the lists and range, which a backup does not take.
class _Backup extends StatelessWidget {
  const _Backup();

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'What a backup holds',
      children: [
        Text(
          'Every property, paddock, movement, tag, template and setting on '
          'this device, exactly as stored, including what was deleted. It is '
          'always the whole farm, so there is nothing to choose or narrow.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// The file to be saved, what stops it, and the button that saves it.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.fileName,
    required this.blocker,
    required this.error,
    required this.onExport,
  });

  /// The chosen format's.
  final IconData icon;
  final String fileName;
  final String? blocker;
  final String? error;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: muted),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        fileName,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    if (blocker case final blocker?)
                      Flexible(
                        child: Text(
                          blocker,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: blocker == null ? onExport : null,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Export'),
                    ),
                  ],
                ),
              ],
            ),
            if (error case final error?) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.day,
    required this.wrong,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? day;
  final bool wrong;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        isEmpty: day == null,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Any',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          error: wrong ? wrongField : null,
          suffixIcon: day == null
              ? const Icon(Icons.calendar_today_outlined)
              : IconButton(
                  tooltip: 'Clear $label',
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
        ),
        child: Text(day == null ? '' : shortDate(day!)),
      ),
    );
  }
}
