import 'package:flutter/widgets.dart';

import '../../data/tables.dart';

extension SpeciesLabel on Species {
  String get label => switch (this) {
    Species.cattle => 'Cattle',
    Species.sheep => 'Sheep',
    Species.goat => 'Goats',
    Species.pig => 'Pigs',
    Species.horse => 'Horses',
    Species.alpaca => 'Alpacas',
    Species.deer => 'Deer',
    Species.poultry => 'Poultry',
    Species.other => 'Other',
  };
}

/// The animal's icon, sized and coloured by the surrounding [IconTheme] as an
/// [Icon] is.
///
/// Material Icons has no cattle, sheep or goats, so these are IconOven's
/// stroke icons (MIT; the licence is registered in `main.dart`), drawn from
/// their SVG path data on its 24-unit grid.
class SpeciesIcon extends StatelessWidget {
  const SpeciesIcon(this.species, {super.key, this.size, this.color});

  final Species species;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final color = this.color ?? theme.color ?? const Color(0xFF000000);

    return SizedBox.square(
      dimension: size ?? theme.size ?? 24,
      child: CustomPaint(
        painter: _SpeciesPainter(
          speciesStrokes(species),
          color.withValues(alpha: color.a * (theme.opacity ?? 1)),
        ),
      ),
    );
  }
}

/// The icon's outline, then its eyes, each a dot drawn as a stroke too short
/// to see but for its round caps.
typedef _Drawing = ({String lines, String dots});

const _drawings = <Species, _Drawing>{
  Species.cattle: (
    lines:
        'M6 14.7V8.75a2.5 2.5 0 0 1 2.5-2.5h7a2.5 2.5 0 0 1 2.5 2.5v5.95'
        'M6 9.25H3.75a.75.75 0 0 0-.65 1.1c.6 1.1 1.65 1.65 2.9 1.65Z'
        'M18 9.25h2.25a.75.75 0 0 1 .65 1.1c-.6 1.1-1.65 1.65-2.9 1.65Z'
        'M8.25 6.25C6.25 5.75 5 4.5 4.75 2.75M15.75 6.25c2-.5 3.25-1.75 3.5-3.5'
        'M8.75 13.5h6.5a3.75 3.75 0 0 1 3.75 3.75v.25a3.75 3.75 0 0 1-3.75 '
        '3.75h-6.5A3.75 3.75 0 0 1 5 17.5v-.25a3.75 3.75 0 0 1 3.75-3.75Z',
    dots: 'M9.5 17.5h.01M14.5 17.5h.01M9.5 10.25h.01M14.5 10.25h.01',
  ),
  Species.sheep: (
    lines:
        'M9.25 6.75A2 2 0 0 1 12.63 7.61A2 2 0 0 1 14.72 9.86A2 2 0 0 1 '
        '14.72 12.64A2 2 0 0 1 12.63 14.89A2 2 0 0 1 9.25 15.75A2 2 0 0 1 '
        '5.87 14.89A2 2 0 0 1 3.78 12.64A2 2 0 0 1 3.78 9.86A2 2 0 0 1 '
        '5.87 7.61A2 2 0 0 1 9.25 6.75Z'
        'M6.75 16.5v3.25M11.75 16.5v3.25'
        'M16.38 7.94A2.25 3.25 -30 1 1 19.62 13.56A2.25 3.25 -30 1 1 '
        '16.38 7.94Z'
        'M16 9.25c-1 .25-1.9.85-2.5 1.75',
    dots: 'M18.5 10.25h.01',
  ),
  Species.goat: (
    lines:
        'M8.5 8.5h7c0 3.75-.75 7-1.75 9.25L12 21.25l-1.75-3.5'
        'C9.25 15.5 8.5 12.25 8.5 8.5Z'
        'M8.5 9.75H5.5a.75.75 0 0 0-.6 1.2c.85 1.05 2.15 1.55 3.85 1.55Z'
        'M15.5 9.75h3a.75.75 0 0 1 .6 1.2c-.85 1.05-2.15 1.55-3.85 1.55Z'
        'M10 8.5C9.5 5.5 7.5 3.5 4.25 3.25M14 8.5c.5-3 2.5-5 5.75-5.25',
    dots: 'M10.5 11.75h.01M13.5 11.75h.01',
  ),
  Species.pig: (
    lines:
        'M4.72 10.35L4.25 4l4.47 1.98A7.75 7.75 0 0 1 15.28 5.98L19.75 4'
        'l-.47 6.35A7.75 7.75 0 1 1 4.72 10.35Z'
        'M8.5 15.25a3.5 2.5 0 1 0 7 0 3.5 2.5 0 1 0 -7 0Z'
        'M10.75 14.5v1.5M13.25 14.5v1.5',
    dots: 'M8.75 10.75h.01M15.25 10.75h.01',
  ),
  Species.horse: (
    lines:
        'M17.75 21.25h-7.5c0-2.25.75-4 .75-5.75-1.25.75-3 1.25-4.75 1.5'
        '-1.4.2-2.5-.75-2.5-2 0-.6.25-1.15.7-1.55L10.5 7'
        'c.75-.75 1.75-1.25 2.75-1.5L13.75 3l1.75 2.25'
        'c2.75.75 4.75 3.5 4.75 7 0 3.75-2.5 6-2.5 9Z'
        'M16.25 7.5c1.5 1.5 2 3.25 1.75 5.5',
    dots: 'M12.5 9.75h.01',
  ),
  Species.alpaca: (
    lines:
        'M5 7.25c0-1.5 1-2.5 2.25-2.5l.5-2 1 1.75H9c1 0 1.75.75 1.75 1.75V12'
        'h7.5c1.75 0 3 1.25 3 3v5.25h-2.5V17h-6v3.25h-2.5V15.5'
        'C9 15.5 8 14.5 8 13V9.5H7C5.75 9.5 5 8.5 5 7.25Z',
    dots: 'M7.75 6.75h.01',
  ),
  Species.deer: (
    lines:
        'M8 10.25h8c0 3.25-.9 6.75-2.15 9.6a2 2 0 0 1-3.7 0'
        'C8.9 17 8 13.5 8 10.25Z'
        'M8 11.25c-1.9.6-3.6.2-4.75-1.25 1.5-1 3.25-1.25 4.75-.5Z'
        'M16 11.25c1.9.6 3.6.2 4.75-1.25-1.5-1-3.25-1.25-4.75-.5Z'
        'M9.75 10.25C9 7.5 7.25 5.5 5 4.5M7.25 5.75l.25-3'
        'M14.25 10.25c.75-2.75 2.5-4.75 4.75-5.75M16.75 5.75l-.25-3',
    dots: 'M10.5 13h.01M13.5 13h.01',
  ),
  Species.poultry: (
    lines:
        'M5.45 11.86 3 10.75l2.45-1.11A3.25 3.25 0 0 1 11.7 10.19'
        'C13.5 11.25 17 11.5 20.75 10c.25 5.5-3.25 9-8 9-4.25 0-7-2.5-7-5.5Z'
        'M5.5 4.5a1 1 0 0 1 2 0 1 1 0 0 1 2 0 1 1 0 0 1 2 0'
        'M11 19v2.25M14.5 19v2.25',
    dots: 'M8.5 10.5h.01',
  ),
  Species.other: (
    lines:
        'M12 12.25c-2.75 0-6 3.5-6 6.25 0 1.5 1.25 2.5 2.75 2.5 1.25 0 2-.5 '
        '3.25-.5s2 .5 3.25.5c1.5 0 2.75-1 2.75-2.5 0-2.75-3.25-6.25-6-6.25Z'
        'M2.75 11a2 2 0 1 0 4 0a2 2 0 1 0-4 0Z'
        'M6.75 5.75a2.25 2.25 0 1 0 4.5 0a2.25 2.25 0 1 0-4.5 0Z'
        'M12.75 5.75a2.25 2.25 0 1 0 4.5 0a2.25 2.25 0 1 0-4.5 0Z'
        'M17.25 11a2 2 0 1 0 4 0a2 2 0 1 0-4 0Z',
    dots: '',
  ),
};

final _parsed = <Species, ({Path lines, Path dots})>{};

/// [species]'s icon on the 24-unit grid, parsed once.
@visibleForTesting
({Path lines, Path dots}) speciesStrokes(Species species) =>
    _parsed.putIfAbsent(species, () {
      final drawing = _drawings[species]!;
      return (lines: _svgPath(drawing.lines), dots: _svgPath(drawing.dots));
    });

class _SpeciesPainter extends CustomPainter {
  _SpeciesPainter(this.strokes, this.color);

  final ({Path lines, Path dots}) strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // A quarter unit heavier than IconOven's 1.5 and 2, to sit beside
    // Material's outlined icons.
    canvas
      ..drawPath(strokes.lines, paint..strokeWidth = 1.75)
      ..drawPath(strokes.dots, paint..strokeWidth = 2.25);
  }

  @override
  bool shouldRepaint(_SpeciesPainter old) =>
      old.strokes != strokes || old.color != color;
}

/// SVG path data as a [Path]: every command, absolute and relative, and the
/// shorthand of repeating one without its letter.
Path _svgPath(String data) {
  final reader = _PathReader(data);
  final path = Path();
  var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
  // The control point S and T reflect, from the curve before them.
  var controlX = 0.0, controlY = 0.0;
  String? command;
  String? previous;

  while (!reader.done) {
    command =
        reader.command() ??
        switch (command) {
          'M' => 'L',
          'm' => 'l',
          null || 'Z' || 'z' => throw FormatException(
            'Expected a command',
            data,
            reader.offset,
          ),
          final repeated => repeated,
        };
    final upper = command.toUpperCase();
    final dx = command == upper ? 0.0 : x;
    final dy = command == upper ? 0.0 : y;

    switch (upper) {
      case 'M':
        x = startX = dx + reader.number();
        y = startY = dy + reader.number();
        path.moveTo(x, y);
      case 'L':
        x = dx + reader.number();
        y = dy + reader.number();
        path.lineTo(x, y);
      case 'H':
        x = dx + reader.number();
        path.lineTo(x, y);
      case 'V':
        y = dy + reader.number();
        path.lineTo(x, y);
      case 'C' || 'S':
        final smooth = upper == 'S';
        final reflects = smooth && (previous == 'C' || previous == 'S');
        final x1 = smooth
            ? (reflects ? 2 * x - controlX : x)
            : dx + reader.number();
        final y1 = smooth
            ? (reflects ? 2 * y - controlY : y)
            : dy + reader.number();
        controlX = dx + reader.number();
        controlY = dy + reader.number();
        x = dx + reader.number();
        y = dy + reader.number();
        path.cubicTo(x1, y1, controlX, controlY, x, y);
      case 'Q':
        controlX = dx + reader.number();
        controlY = dy + reader.number();
        x = dx + reader.number();
        y = dy + reader.number();
        path.quadraticBezierTo(controlX, controlY, x, y);
      case 'T':
        final reflects = previous == 'Q' || previous == 'T';
        controlX = reflects ? 2 * x - controlX : x;
        controlY = reflects ? 2 * y - controlY : y;
        x = dx + reader.number();
        y = dy + reader.number();
        path.quadraticBezierTo(controlX, controlY, x, y);
      case 'A':
        final radius = Radius.elliptical(
          reader.number().abs(),
          reader.number().abs(),
        );
        final rotation = reader.number();
        final largeArc = reader.flag();
        final clockwise = reader.flag();
        x = dx + reader.number();
        y = dy + reader.number();
        path.arcToPoint(
          Offset(x, y),
          radius: radius,
          rotation: rotation,
          largeArc: largeArc,
          clockwise: clockwise,
        );
      case 'Z':
        path.close();
        x = startX;
        y = startY;
      default:
        throw FormatException('Unknown command $command', data, reader.offset);
    }
    previous = upper;
  }
  return path;
}

class _PathReader {
  _PathReader(this.data);

  final String data;
  int offset = 0;

  bool get done {
    _skipSeparators();
    return offset >= data.length;
  }

  void _skipSeparators() {
    while (offset < data.length && ' ,\t\n\r'.contains(data[offset])) {
      offset++;
    }
  }

  String? command() {
    _skipSeparators();
    if (offset < data.length && 'MmZzLlHhVvCcSsQqTtAa'.contains(data[offset])) {
      return data[offset++];
    }
    return null;
  }

  bool _digitAt(int i) => i < data.length && '0123456789'.contains(data[i]);

  /// Read to where the number ends, which may be where the next begins, as in
  /// `1.4.2` or `2-.5`.
  double number() {
    _skipSeparators();
    final start = offset;
    if (offset < data.length && '+-'.contains(data[offset])) offset++;
    while (_digitAt(offset)) {
      offset++;
    }
    if (offset < data.length && data[offset] == '.') {
      offset++;
      while (_digitAt(offset)) {
        offset++;
      }
    }
    if (offset < data.length && 'eE'.contains(data[offset])) {
      var end = offset + 1;
      if (end < data.length && '+-'.contains(data[end])) end++;
      if (_digitAt(end)) {
        offset = end;
        while (_digitAt(offset)) {
          offset++;
        }
      }
    }
    return double.tryParse(data.substring(start, offset)) ??
        (throw FormatException('Expected a number', data, start));
  }

  /// One character, so `0 01` reads as two flags and a number.
  bool flag() {
    _skipSeparators();
    final flag = offset < data.length ? data[offset] : '';
    if (flag != '0' && flag != '1') {
      throw FormatException('Expected an arc flag', data, offset);
    }
    offset++;
    return flag == '1';
  }
}
