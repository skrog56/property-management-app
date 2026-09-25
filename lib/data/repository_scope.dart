import 'package:flutter/widgets.dart';

import 'livestock_repository.dart';

/// Passed down the tree rather than reached for globally, so widgets stay
/// testable against an in-memory database.
class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final LivestockRepository repository;

  static LivestockRepository of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'No RepositoryScope above this widget');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
