import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/livestock_repository.dart';
import '../../data/tables.dart';
import '../../shell/form_dialog.dart';
import 'species.dart';

/// Adds a template, or edits [editing]'s name and animal. [templates] is
/// every live template, whose names are taken.
Future<void> showTemplateDialog(
  BuildContext context, {
  required LivestockRepository repository,
  required List<Template> templates,
  Template? editing,
}) {
  return showFormDialog<void>(
    context,
    builder: (context) => _TemplateDialog(
      repository: repository,
      templates: templates,
      editing: editing,
    ),
  );
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({
    required this.repository,
    required this.templates,
    required this.editing,
  });

  final LivestockRepository repository;
  final List<Template> templates;
  final Template? editing;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  late final _name = TextEditingController(text: widget.editing?.name);

  /// Not preset for a new template, so cattle is never assumed.
  late Species? _species = widget.editing?.species;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// [wrong] when the name is at fault, not merely empty. Template names are
  /// what every class label brackets, so no two may match.
  ({String reason, bool wrong})? get _blocker {
    final name = _name.text.trim();
    if (name.isEmpty) return (reason: 'Enter a name', wrong: false);
    final taken = widget.templates.any(
      (t) =>
          t.id != widget.editing?.id &&
          t.name.toLowerCase() == name.toLowerCase(),
    );
    if (taken) {
      return (reason: 'There is already a template called $name', wrong: true);
    }
    if (_species == null) return (reason: 'Choose an animal', wrong: false);
    return null;
  }

  Future<void> _save() async {
    if (_blocker != null) return;
    setState(() => _saving = true);
    final name = _name.text.trim();
    final species = _species!;
    final editing = widget.editing;
    if (editing == null) {
      await widget.repository.createTemplate(name, species: species);
    } else {
      await widget.repository.updateTemplate(
        editing.id,
        name: name,
        species: species,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.editing;
    final blocker = _blocker;

    return FormDialog(
      title: editing == null ? 'New template' : 'Edit template',
      subtitle: editing?.name,
      actionLabel: editing == null ? 'Create' : 'Save',
      onAction: _saving ? null : _save,
      blocker: blocker?.reason,
      children: [
        TextField(
          controller: _name,
          autofocus: editing == null,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Trade cattle',
            error: blocker?.wrong ?? false ? wrongField : null,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _saving ? null : _save(),
        ),
        const SizedBox(height: 16),
        Text('Animal', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final species in Species.values)
              ChoiceChip(
                avatar: SpeciesIcon(species),
                label: Text(species.label),
                selected: _species == species,
                // The animal's icon stays, rather than a tick replacing it.
                showCheckmark: false,
                onSelected: (_) => setState(() => _species = species),
              ),
          ],
        ),
      ],
    );
  }
}
