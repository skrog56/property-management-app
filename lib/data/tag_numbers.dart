import 'app_database.dart';
import 'tables.dart';

final _whitespace = RegExp(r'\s');
final _nlisId = RegExp(r'^[0-9A-Z]{16}$');
final _rfid = RegExp(r'^[0-9]{15}$');

/// Spaces are not separators: RFIDs are commonly written `982 000123456789`.
final _separators = RegExp(r'[,;\t\r\n]+');

/// A tag number as stored: no whitespace and uppercase, so the same number
/// typed, pasted or sent by a reader always matches itself.
class TagNumber {
  const TagNumber._(this.scheme, this.value);

  /// Null when [raw] is empty, or is not an NLIS ID or RFID under
  /// [TagScheme.nlis].
  static TagNumber? tryParse(TagScheme scheme, String raw) {
    final value = tagSearchKey(raw);
    if (value.isEmpty) return null;
    if (scheme == TagScheme.nlis &&
        !_nlisId.hasMatch(value) &&
        !_rfid.hasMatch(value)) {
      return null;
    }
    return TagNumber._(scheme, value);
  }

  final TagScheme scheme;
  final String value;

  String get display => scheme == TagScheme.nlis && _rfid.hasMatch(value)
      ? '${value.substring(0, 3)} ${value.substring(3)}'
      : value;

  @override
  bool operator ==(Object other) =>
      other is TagNumber && other.scheme == scheme && other.value == value;

  @override
  int get hashCode => Object.hash(scheme, value);

  @override
  String toString() => display;
}

extension LivestockTagNumber on LivestockTag {
  TagNumber get tagNumber => TagNumber._(scheme, number);
}

/// [raw] as a search over stored numbers, which match it by substring.
String tagSearchKey(String raw) =>
    raw.replaceAll(_whitespace, '').toUpperCase();

/// The numbers in a paste, or in a reader's output, in the order given.
List<String> splitTagInput(String raw) => [
  for (final part in raw.split(_separators))
    if (part.trim().isNotEmpty) part.trim(),
];
