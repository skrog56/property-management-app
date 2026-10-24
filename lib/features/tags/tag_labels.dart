import '../../data/livestock_repository.dart';
import '../../data/tables.dart';
import '../../data/tag_numbers.dart';

const nlisFormat =
    'Not an NLIS number: expected a 16-character NLIS ID or a 15-digit '
    'RFID. Use Other ID for anything else.';

extension TagSchemeLabel on TagScheme {
  String get label => switch (this) {
    TagScheme.nlis => 'NLIS',
    TagScheme.other => 'Other ID',
  };
}

extension TagReasonLabel on TagReason {
  String get label => switch (this) {
    TagReason.lost => 'lost',
    TagReason.damaged => 'damaged or faulty',
    TagReason.error => 'recorded in error',
    TagReason.other => 'other',
  };
}

String shortDate(DateTime at) {
  final local = at.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}

/// Where a tag is, or how it left, on one line.
String tagWhereabouts(TagStatus status) {
  if (status.isActive) {
    return [
      status.paddock!.name,
      if (status.livestockClass case final c?) c.kind,
    ].join(' · ');
  }
  final when = shortDate(status.occurredAt);
  if (status.replacedBy case final next?) {
    return 'Replaced by ${next.tagNumber.display} · $when';
  }
  if (status.role == TagRole.removed) {
    return ['Cancelled', ?status.reason?.label, when].join(' · ');
  }
  final state = status.endState?.name ?? 'removed';
  return '${state[0].toUpperCase()}${state.substring(1)} · $when';
}
