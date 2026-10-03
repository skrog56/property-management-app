import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const propertiesPath = '/properties';

String propertyPath(String propertyId) => '$propertiesPath/$propertyId';

String paddockPath(String propertyId, String paddockId) =>
    '${propertyPath(propertyId)}/paddocks/$paddockId';

/// Navigates once [preload] has warmed the next tier's queries, so it opens
/// drawn rather than on a spinner. A slow or failed preload only costs that.
Future<void> openTier(
  BuildContext context,
  String path, {
  required Future<void> preload,
}) async {
  try {
    await preload.timeout(const Duration(milliseconds: 300));
  } on Object {
    // The page loads for itself regardless.
  }
  if (context.mounted) context.go(path);
}
