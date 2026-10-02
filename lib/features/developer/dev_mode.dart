import 'package:flutter/foundation.dart';

/// The single gate for developer tooling. A const, so release and profile
/// builds tree-shake everything reachable only through it.
const bool devMode = kDebugMode;
