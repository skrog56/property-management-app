import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/features/export/export_data.dart';
import 'package:property_management_app/features/export/export_formats.dart';

void main() {
  final when = DateTime(2026, 11, 16, 9, 5);
  final sheet = ExportSheet(
    ExportList.movements,
    const ['Date', 'Head', 'Note'],
    [
      [when, 12, 'plain'],
      [when, 2.5, 'a, b'],
      [null, 0, 'said "hi"\nthen left'],
      [null, null, '=SUM(A1)'],
      [null, -3, 'Tom & <Jerry>'],
    ],
  );

  String text(Uint8List bytes) => utf8.decode(bytes);

  group('CSV', () {
    late List<String> lines;

    setUp(() {
      final bytes = csvBytes(sheet);
      // The byte-order mark, which tells Excel the file is UTF-8.
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      lines = utf8.decode(bytes.sublist(3)).split('\r\n');
    });

    test('writes a header, then a line a row', () {
      expect(lines.first, 'Date,Head,Note');
      expect(lines[1], '2026-11-16 09:05,12,plain');
      expect(lines.last, isEmpty);
    });

    test('quotes commas, quotes and line breaks', () {
      expect(lines[2], '2026-11-16 09:05,2.5,"a, b"');
      expect(lines[3], ',0,"said ""hi""\nthen left"');
    });

    test('keeps text from running as a formula, but not numbers', () {
      expect(lines[4], ",,'=SUM(A1)");
      expect(lines[5], ',-3,Tom & <Jerry>');
    });

    test('several lists zip as one file each', () {
      final zip = ZipDecoder().decodeBytes(
        csvZipBytes([
          sheet,
          ExportSheet(ExportList.tags, const ['Number'], const []),
        ]),
      );
      expect(zip.files.map((f) => f.name), ['movements.csv', 'tags.csv']);
    });
  });

  group('Excel', () {
    late Archive workbook;
    String part(String name) =>
        utf8.decode(workbook.files.firstWhere((f) => f.name == name).content);

    setUp(() {
      workbook = ZipDecoder().decodeBytes(
        xlsxBytes([
          sheet,
          ExportSheet(ExportList.paddocks, const ['Paddock'], const []),
        ]),
      );
    });

    test('has the parts a workbook needs, a sheet a list', () {
      expect(
        workbook.files.map((f) => f.name),
        containsAll([
          '[Content_Types].xml',
          '_rels/.rels',
          'xl/workbook.xml',
          'xl/_rels/workbook.xml.rels',
          'xl/styles.xml',
          'xl/worksheets/sheet1.xml',
          'xl/worksheets/sheet2.xml',
        ]),
      );
      expect(part('xl/workbook.xml'), contains('name="Movements"'));
      expect(
        part('xl/workbook.xml'),
        contains('name="Properties and paddocks"'),
      );
    });

    test('writes numbers, dates and escaped text', () {
      final first = part('xl/worksheets/sheet1.xml');
      expect(first, contains('<c r="B2"><v>12</v></c>'));
      expect(first, contains('<c r="B3"><v>2.5</v></c>'));
      // 16/11/2026 09:05 is day 46342 since 30/12/1899, and 9:05 a fraction.
      expect(first, contains('<c r="A2" s="2"><v>46342.37847222222</v></c>'));
      expect(first, contains('Tom &amp; &lt;Jerry&gt;'));
      expect(first, contains('<c r="A1" t="inlineStr" s="1">'));
      expect(first, contains('state="frozen"'));
    });
  });

  test('a PDF report takes any text in the bundled font', () async {
    ByteData font(String weight) => ByteData.sublistView(
      File('assets/fonts/Roboto-$weight.ttf').readAsBytesSync(),
    );
    final bytes = await pdfBytes(
      [
        sheet,
        ExportSheet(ExportList.tags, const ['Number'], const []),
        ExportSheet(
          ExportList.paddocks,
          const ['Paddock'],
          [
            for (var i = 0; i < 200; i++) ['Ŵestern Flat №$i · Ωmega'],
          ],
        ),
      ],
      description: 'All properties · all movements',
      exportedAt: when,
      regular: font('Regular'),
      bold: font('Bold'),
    );
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('a JSON backup says what it holds', () {
    final json =
        jsonDecode(
              text(
                jsonBytes(
                  {
                    'settings': [
                      {'id': 'theme', 'value': 'dark'},
                    ],
                  },
                  schemaVersion: 5,
                  exportedAt: when,
                ),
              ),
            )
            as Map<String, Object?>;
    expect(json['format'], 'livestock-export');
    expect(json['formatVersion'], 1);
    expect(json['schemaVersion'], 5);
    expect(json['exportedAt'], when.toUtc().toIso8601String());
    expect((json['tables'] as Map)['settings'], [
      {'id': 'theme', 'value': 'dark'},
    ]);
  });
}
