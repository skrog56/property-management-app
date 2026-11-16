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

/// What an export of [lists] as [format] on [at]'s day is called. One list
/// as CSV is a file of its own; several are a zip of one each.
String exportFileName(ExportFormat format, Set<ExportList> lists, DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${at.year}-${two(at.month)}-${two(at.day)}';
  return switch (format) {
    ExportFormat.csv when lists.length == 1 => '${lists.single.slug}-$day.csv',
    ExportFormat.csv => 'livestock-export-$day.zip',
    _ => 'livestock-export-$day.${format.extension}',
  };
}

/// [lists] of [repository] narrowed to [range], written as [format]. A JSON
/// backup is always the whole farm, so it ignores both.
Future<ExportFile> buildExport(
  LivestockRepository repository, {
  required ExportFormat format,
  Set<ExportList> lists = const {...ExportList.values},
  ExportRange range = ExportRange.everything,
  String? propertyName,
  String? paddockName,
  DateTime? now,
  Future<FontPair> Function() fonts = bundledRoboto,
}) async {
  final at = now ?? DateTime.now();
  final name = exportFileName(format, lists, at);

  switch (format) {
    case ExportFormat.json:
      return ExportFile(
        name,
        'application/json',
        jsonBytes(
          await repository.exportTables(),
          schemaVersion: repository.db.schemaVersion,
          exportedAt: at,
        ),
      );
    case ExportFormat.csv:
      final sheets = await repository.exportSheets(lists, range: range);
      return sheets.length == 1
          ? ExportFile(name, 'text/csv', csvBytes(sheets.single))
          : ExportFile(name, 'application/zip', csvZipBytes(sheets));
    case ExportFormat.xlsx:
      return ExportFile(
        name,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        xlsxBytes(await repository.exportSheets(lists, range: range)),
      );
    case ExportFormat.pdf:
      final font = await fonts();
      return ExportFile(
        name,
        'application/pdf',
        await pdfBytes(
          await repository.exportSheets(lists, range: range),
          description: describeRange(
            range,
            propertyName: propertyName,
            paddockName: paddockName,
          ),
          exportedAt: at,
          regular: font.regular,
          bold: font.bold,
        ),
      );
  }
}
