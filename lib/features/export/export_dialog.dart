import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/repository_scope.dart';
import '../../shell/form_dialog.dart';
import '../../shell/search_picker.dart';
import '../tags/tag_labels.dart';
import 'export_data.dart';
import 'export_formats.dart';
import 'save_export.dart';

/// Chooses what to export and how, then hands the file to [save]. Says what
/// was saved once the dialog has closed.
///
/// Opened from a paddock's history, it starts with that paddock's property.
Future<void> showExportDialog(
  BuildContext context, {
  ExportSaver save = saveWithPicker,
  String? paddockId,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final saved = await showFormDialog<String>(
    context,
    builder: (_) => ExportDialog(save: save, paddockId: paddockId),
  );
  if (saved != null) {
    messenger?.showSnackBar(SnackBar(content: Text('Exported $saved')));
  }
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key, required this.save, this.paddockId});

  final ExportSaver save;

  /// Chooses this paddock's property to begin with.
  final String? paddockId;

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  var _format = ExportFormat.xlsx;
  final _lists = {...ExportList.values};
  String? _propertyId;
  DateTime? _from;
  DateTime? _to;
  List<Property> _properties = const [];
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // After the first frame, where the scope can be read.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProperties());
  }

  Future<void> _loadProperties() async {
    if (!mounted) return;
    final repository = RepositoryScope.of(context);
    final properties = await repository.properties()
      ..sort((a, b) => a.name.compareTo(b.name));
    final paddock = widget.paddockId == null
        ? null
        : await (repository.db.select(
            repository.db.paddocks,
          )..where((p) => p.id.equals(widget.paddockId!))).getSingleOrNull();
    if (!mounted) return;
    setState(() {
      _properties = properties;
      _propertyId ??= paddock?.propertyId;
    });
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

  static String _purpose(ExportFormat format) => switch (format) {
    ExportFormat.xlsx => 'A sheet for each list, to sort and total.',
    ExportFormat.csv =>
      'Plain tables any program can read. More than one list comes as a '
          'zip of one file each.',
    ExportFormat.pdf => 'A report to print or send.',
    ExportFormat.json =>
      'Everything recorded on this device, exactly as stored: every '
          'property, movement, tag, template and setting. It always holds '
          'the whole farm.',
  };

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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await buildExport(
        repository,
        format: _format,
        lists: _lists,
        range: ExportRange(propertyId: _propertyId, from: _from, to: _to),
        propertyName: _properties
            .where((p) => p.id == _propertyId)
            .firstOrNull
            ?.name,
      );
      final kept = await widget.save(file);
      if (!mounted) return;
      if (kept) {
        Navigator.of(context).pop(file.name);
      } else {
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not export: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormDialog(
      title: 'Export',
      actionLabel: 'Export',
      onAction: _export,
      blocker: _blocker,
      children: [
        DropdownButtonFormField<ExportFormat>(
          initialValue: _format,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Format',
            helperText: _purpose(_format),
            helperMaxLines: 4,
          ),
          onChanged: _busy
              ? null
              : (format) => setState(() => _format = format!),
          items: [
            for (final format in ExportFormat.values)
              DropdownMenuItem(value: format, child: Text(format.label)),
          ],
        ),
        if (!_backup) ...[
          const SizedBox(height: 16),
          Text('Lists', style: theme.textTheme.titleSmall),
          for (final list in ExportList.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(list.title),
              value: _lists.contains(list),
              onChanged: _busy
                  ? null
                  : (on) => setState(
                      () => on! ? _lists.add(list) : _lists.remove(list),
                    ),
            ),
          const SizedBox(height: 12),
          SearchPicker<String>(
            label: 'Property',
            hint: 'All properties',
            optional: true,
            searchIcon: true,
            value: _propertyId,
            onChanged: (id) => setState(() => _propertyId = id),
            entries: [
              for (final p in _properties)
                SearchEntry(p.id, p.name, alsoFoundBy: p.pic),
            ],
            emptyHint: 'No properties yet',
          ),
          const SizedBox(height: 16),
          Text(
            'Movements between these days. Each other list is as it stands '
            'today.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
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
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 16),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
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
