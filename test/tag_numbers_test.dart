import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_app/data/tables.dart';
import 'package:property_management_app/data/tag_numbers.dart';

void main() {
  TagNumber? nlis(String raw) => TagNumber.tryParse(TagScheme.nlis, raw);
  TagNumber? other(String raw) => TagNumber.tryParse(TagScheme.other, raw);

  group('NLIS numbers', () {
    test('accept a 15-digit RFID, with or without its space', () {
      expect(nlis('982 000123456789')?.value, '982000123456789');
      expect(nlis('982000123456789'), nlis(' 982 000123456789 '));
    });

    test('accept a 16-character NLIS ID in any case', () {
      expect(nlis('3abcd123xbh12345')?.value, '3ABCD123XBH12345');
    });

    test('refuse anything else', () {
      expect(nlis('98200012345678'), isNull, reason: '14 digits');
      expect(nlis('9820001234567890A'), isNull, reason: '17 characters');
      expect(nlis('3ABCD123-BH12345'), isNull, reason: 'punctuation');
      expect(nlis('   '), isNull);
    });

    test('show an RFID with its conventional space', () {
      expect(nlis('982000123456789')!.display, '982 000123456789');
      expect(nlis('3ABCD123XBH12345')!.display, '3ABCD123XBH12345');
    });
  });

  group('Other IDs', () {
    test('accept any text, normalised the same way', () {
      expect(other('y 145')?.value, 'Y145');
      expect(other('Y145'), other('y 145'));
      expect(other(''), isNull);
    });

    test('are a different tag from the same text under NLIS', () {
      expect(other('982000123456789'), isNot(nlis('982000123456789')));
      expect(other('982000123456789')!.display, '982000123456789');
    });
  });

  test('pasted input splits on lines, commas, semicolons and tabs', () {
    expect(splitTagInput('982 000123456789\n982 000123456790,\tY145; ;\r\n'), [
      '982 000123456789',
      '982 000123456790',
      'Y145',
    ]);
  });
}
