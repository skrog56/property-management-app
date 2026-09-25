// `dart:io` and `path_provider` exist only in the native branch, which the web
// build never resolves. This is the one sanctioned way to reach them: a runtime
// `kIsWeb` guard would not help, because the web build fails at compile time
// before any guard could run.
export 'connection_unsupported.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
