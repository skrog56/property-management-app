import 'dart:collection';

import 'package:flutter/foundation.dart';

enum DevLogKind { error, async, print }

@immutable
class DevLogEntry {
  const DevLogEntry({
    required this.time,
    required this.kind,
    required this.message,
    this.stack,
  });

  final DateTime time;
  final DevLogKind kind;
  final String message;
  final String? stack;

  @override
  String toString() =>
      ['[${time.toIso8601String()}] ${kind.name}: $message', ?stack].join('\n');
}

/// Recent errors and prints, newest first, capped so a noisy loop cannot grow
/// it without bound.
class DevLog extends ChangeNotifier {
  DevLog({this.capacity = 200});

  static final instance = DevLog();

  final int capacity;
  final _entries = ListQueue<DevLogEntry>();
  bool _installed = false;

  List<DevLogEntry> get entries => List.unmodifiable(_entries);

  void add(DevLogKind kind, String message, [StackTrace? stack]) {
    _entries.addFirst(
      DevLogEntry(
        time: DateTime.now(),
        kind: kind,
        message: message,
        stack: stack?.toString(),
      ),
    );
    while (_entries.length > capacity) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Chains onto the existing handlers, so console output is unchanged.
  void install() {
    if (_installed) return;
    _installed = true;

    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      add(DevLogKind.error, details.exceptionAsString(), details.stack);
      previousFlutter?.call(details);
    };

    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      add(DevLogKind.async, '$error', stack);
      return previousPlatform?.call(error, stack) ?? false;
    };

    final previousPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) add(DevLogKind.print, message);
      previousPrint(message, wrapWidth: wrapWidth);
    };
  }
}
