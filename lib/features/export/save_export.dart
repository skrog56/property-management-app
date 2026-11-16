import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show immutable;

import '../../data/livestock_repository.dart';
import 'export_data.dart';
import 'export_formats.dart';

@immutable
class ExportFile {
  const ExportFile(this.name, this.mimeType, this.bytes);

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

/// Hands [ExportFile] to the user, and says whether it was kept: false when
/// they cancelled. Tests pass their own, so no platform channel is reached.
typedef ExportSaver = Future<bool> Function(ExportFile file);

/// A save dialog on desktop and phones, which writes the file itself; a
/// download in a browser.
Future<bool> saveWithPicker(ExportFile file) async =>
    await FilePicker.saveFile(
      fileName: file.name,
      bytes: file.bytes,
      mimeType: file.mimeType,
      dialogTitle: 'Save export',
    ) !=
    null;

typedef FontPair = ({ByteData regular, ByteData bold});

Future<FontPair> bundledRoboto() async => (
  regular: await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  bold: await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
);

/// [lists] of [repository] narrowed to [range], written as [format]. A JSON
/// backup is always the whole farm, so it ignores both.
Future<ExportFile> buildExport(
  LivestockRepository repository, {
  required ExportFormat format,
  Set<ExportList> lists = const {...ExportList.values},
  ExportRange range = ExportRange.everything,
  String? propertyName,
  DateTime? now,
  Future<FontPair> Function() fonts = bundledRoboto,
}) async {
  final at = now ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${at.year}-${two(at.month)}-${two(at.day)}';
  String named(String stem, String extension) => '$stem-$day.$extension';
  const stem = 'livestock-export';

  Future<List<ExportSheet>> sheets() =>
      repository.exportSheets(lists, range: range);

  switch (format) {
    case ExportFormat.json:
      return ExportFile(
        named(stem, 'json'),
        'application/json',
        jsonBytes(
          await repository.exportTables(),
          schemaVersion: repository.db.schemaVersion,
          exportedAt: at,
        ),
      );
    case ExportFormat.csv:
      final all = await sheets();
      return all.length == 1
          ? ExportFile(
              named(all.single.list.slug, 'csv'),
              'text/csv',
              csvBytes(all.single),
            )
          : ExportFile(named(stem, 'zip'), 'application/zip', csvZipBytes(all));
    case ExportFormat.xlsx:
      return ExportFile(
        named(stem, 'xlsx'),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        xlsxBytes(await sheets()),
      );
    case ExportFormat.pdf:
      final font = await fonts();
      return ExportFile(
        named(stem, 'pdf'),
        'application/pdf',
        await pdfBytes(
          await sheets(),
          description: describeRange(range, propertyName: propertyName),
          exportedAt: at,
          regular: font.regular,
          bold: font.bold,
        ),
      );
  }
}
