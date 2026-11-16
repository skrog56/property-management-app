import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'export_data.dart';

/// The ways an export can be written.
enum ExportFormat {
  xlsx('Excel workbook', 'xlsx'),
  csv('CSV', 'csv'),
  pdf('PDF report', 'pdf'),
  json('JSON backup', 'json');

  const ExportFormat(this.label, this.extension);

  final String label;
  final String extension;
}

// ---------------------------------------------------------------- CSV

/// [sheet] as CSV: UTF-8 with a byte-order mark, which Excel needs to read
/// it as UTF-8, and CRLF line ends, as RFC 4180 has them.
Uint8List csvBytes(ExportSheet sheet) {
  final out = StringBuffer('\uFEFF');
  for (final row in [sheet.columns, ...sheet.rows]) {
    out
      ..writeAll(row.map(_csvCell), ',')
      ..write('\r\n');
  }
  return Uint8List.fromList(utf8.encode(out.toString()));
}

String _csvCell(Object? value) {
  var text = switch (value) {
    null => '',
    DateTime() => _isoMinute(value),
    num() => _number(value),
    _ => value.toString(),
  };
  // A spreadsheet opening the file would run these as formulas.
  if (value is String && text.startsWith(RegExp(r'[=+\-@\t\r]'))) {
    text = "'$text";
  }
  return text.contains(RegExp('[",\r\n]'))
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

/// Several sheets as one CSV each, zipped.
Uint8List csvZipBytes(List<ExportSheet> sheets) {
  final archive = Archive();
  for (final sheet in sheets) {
    archive.addFile(
      ArchiveFile.bytes('${sheet.list.slug}.csv', csvBytes(sheet)),
    );
  }
  return ZipEncoder().encodeBytes(archive);
}

String _isoMinute(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${at.year}-${two(at.month)}-${two(at.day)} '
      '${two(at.hour)}:${two(at.minute)}';
}

String _number(num value) =>
    value is double && value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

// ---------------------------------------------------------------- XLSX

/// A workbook with a sheet for each of [sheets]: numbers as numbers, times as
/// dates, and a bold header row that stays in view.
Uint8List xlsxBytes(List<ExportSheet> sheets) {
  final archive = Archive();
  void add(String name, String xml) =>
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(_xmlHeader + xml)));

  final count = sheets.length;
  add(
    '[Content_Types].xml',
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '${[for (var i = 1; i <= count; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
        '</Types>',
  );
  add(
    '_rels/.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
  );
  add(
    'xl/workbook.xml',
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets>'
        '${[for (var i = 1; i <= count; i++) '<sheet name="${_xml(sheets[i - 1].title)}" sheetId="$i" r:id="rId$i"/>'].join()}'
        '</sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '${[for (var i = 1; i <= count; i++) '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>'].join()}'
        '<Relationship Id="rId${count + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>',
  );
  add('xl/styles.xml', _styles);
  for (var i = 0; i < count; i++) {
    add('xl/worksheets/sheet${i + 1}.xml', _worksheet(sheets[i]));
  }
  return ZipEncoder().encodeBytes(archive);
}

const _xmlHeader = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';

/// Style 1 is the bold header, style 2 a date and time.
const _styles =
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<numFmts count="1"><numFmt numFmtId="164" formatCode="dd/mm/yyyy hh:mm"/></numFmts>'
    '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
    '<fills count="2"><fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill></fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    '</styleSheet>';

String _worksheet(ExportSheet sheet) {
  final widths = [
    for (var c = 0; c < sheet.columns.length; c++)
      [
            sheet.columns[c].length,
            for (final row in sheet.rows)
              switch (row[c]) {
                null => 0,
                DateTime() => 16,
                final value => value.toString().length,
              },
          ].reduce((a, b) => a > b ? a : b).clamp(6, 50) +
          2,
  ];

  final out = StringBuffer(
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<sheetViews><sheetView workbookViewId="0">'
    '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
    '</sheetView></sheetViews><cols>',
  );
  for (var c = 0; c < widths.length; c++) {
    out.write(
      '<col min="${c + 1}" max="${c + 1}" width="${widths[c]}" customWidth="1"/>',
    );
  }
  out.write('</cols><sheetData>');

  void row(int r, List<Object?> cells, {bool header = false}) {
    out.write('<row r="$r">');
    for (var c = 0; c < cells.length; c++) {
      final ref = '${_column(c)}$r';
      out.write(switch (cells[c]) {
        null => '',
        num() && final n => '<c r="$ref"><v>${_number(n)}</v></c>',
        DateTime() && final at => '<c r="$ref" s="2"><v>${_serial(at)}</v></c>',
        final value =>
          '<c r="$ref" t="inlineStr"${header ? ' s="1"' : ''}>'
              '<is><t xml:space="preserve">${_xml(value.toString())}</t></is></c>',
      });
    }
    out.write('</row>');
  }

  row(1, sheet.columns, header: true);
  for (var r = 0; r < sheet.rows.length; r++) {
    row(r + 2, sheet.rows[r]);
  }
  out.write('</sheetData></worksheet>');
  return out.toString();
}

/// A, B, … Z, AA, AB, …
String _column(int index) {
  var name = '';
  for (var n = index + 1; n > 0; n = (n - 1) ~/ 26) {
    name = String.fromCharCode(65 + (n - 1) % 26) + name;
  }
  return name;
}

/// Days since 30/12/1899, as spreadsheets count them, of the wall-clock time
/// [at] shows.
double _serial(DateTime at) {
  final wall = DateTime.utc(
    at.year,
    at.month,
    at.day,
    at.hour,
    at.minute,
    at.second,
  );
  return wall.difference(DateTime.utc(1899, 12, 30)).inSeconds / 86400;
}

/// Escaped, and without the control characters XML 1.0 cannot carry.
String _xml(String text) => text
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// ---------------------------------------------------------------- PDF

/// A printable report: a heading, then a table for each of [sheets].
/// [regular] and [bold] are TrueType fonts, as the PDF standard fonts cover
/// Latin-1 alone and a name or note may hold anything.
Future<Uint8List> pdfBytes(
  List<ExportSheet> sheets, {
  required String description,
  required DateTime exportedAt,
  required ByteData regular,
  required ByteData bold,
}) {
  final doc = pw.Document(
    title: 'Livestock export',
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    ),
  );
  final muted = PdfColors.grey700;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: muted),
        ),
      ),
      build: (context) => [
        pw.Text(
          'Livestock export',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$description · exported ${_dayMinute(exportedAt)}',
          style: pw.TextStyle(fontSize: 9, color: muted),
        ),
        for (final sheet in sheets) ...[
          pw.SizedBox(height: 18),
          pw.Text(
            sheet.title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (sheet.rows.isEmpty)
            pw.Text('Nothing to list.', style: pw.TextStyle(color: muted))
          else
            pw.TableHelper.fromTextArray(
              headers: sheet.columns,
              data: [
                for (final row in sheet.rows)
                  [for (final v in row) _pdfCell(v)],
              ],
              border: null,
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              headerAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.75)),
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 2,
              ),
              cellAlignments: {
                for (var c = 0; c < sheet.columns.length; c++)
                  if (sheet.rows.first[c] is num) c: pw.Alignment.topRight,
              },
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              columnWidths: _pdfWidths(sheet),
            ),
        ],
      ],
    ),
  );
  return doc.save();
}

/// Each column as wide as its longest cell, within limits, so a date or a
/// head count is not wrapped to share the page equally with a note.
Map<int, pw.TableColumnWidth> _pdfWidths(ExportSheet sheet) => {
  for (var c = 0; c < sheet.columns.length; c++)
    c: pw.FlexColumnWidth(
      [
        // Headings are bold, so a little wider.
        for (final word in sheet.columns[c].split(' ')) word.length + 2,
        for (final row in sheet.rows) _pdfCell(row[c]).length,
      ].reduce((a, b) => a > b ? a : b).clamp(7, 28).toDouble(),
    ),
};

String _pdfCell(Object? value) => switch (value) {
  null => '',
  DateTime() => _dayMinute(value),
  num() => _number(value),
  _ => value.toString(),
};

String _dayMinute(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(at.day)}/${two(at.month)}/${at.year} '
      '${two(at.hour)}:${two(at.minute)}';
}

// ---------------------------------------------------------------- JSON

/// Every table as stored, with what a restore would need to read it.
Uint8List jsonBytes(
  Map<String, List<Map<String, Object?>>> tables, {
  required int schemaVersion,
  required DateTime exportedAt,
}) => Uint8List.fromList(
  utf8.encode(
    const JsonEncoder.withIndent('  ').convert({
      'format': 'livestock-export',
      'formatVersion': 1,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'tables': tables,
    }),
  ),
);
