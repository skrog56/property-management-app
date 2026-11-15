import 'package:flutter/material.dart';

import '../../data/livestock_repository.dart';
import '../../shell/search_picker.dart';
import 'species.dart';

/// A class's label, or [text] about it, led by the icon of its animal, which
/// the label leaves out.
class ClassLine extends StatelessWidget {
  const ClassLine(
    this.stockClass, {
    super.key,
    this.text,
    this.iconSize = 20,
    this.style,
    this.maxLines,
  });

  final StockClass stockClass;
  final String? text;
  final double iconSize;
  final TextStyle? style;

  /// Ellipsised past this many lines, rather than wrapped.
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClassAnimal(stockClass, size: iconSize),
      SizedBox(width: iconSize * 0.4),
      Flexible(
        child: Text(
          text ?? stockClass.label,
          style: style,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// The icon of a class's animal, named on hover or long press.
class ClassAnimal extends StatelessWidget {
  const ClassAnimal(this.stockClass, {super.key, this.size = 20});

  final StockClass stockClass;
  final double size;

  @override
  Widget build(BuildContext context) {
    final species = stockClass.template.species;
    return Tooltip(
      message: species.label,
      child: SpeciesIcon(
        species,
        size: size,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A class to choose in a [SearchPicker], led by its animal, which finds it
/// too, labelled [label] if given.
SearchEntry<String> classEntry(StockClass c, {String? label}) => SearchEntry(
  c.id,
  label ?? c.label,
  icon: ClassAnimal(c),
  alsoFoundBy: c.template.species.label,
);
