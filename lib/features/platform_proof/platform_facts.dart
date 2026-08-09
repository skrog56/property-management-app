import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A single labelled reading shown on the proof screen.
@immutable
class Fact {
  const Fact(this.label, this.value);

  final String label;
  final String value;
}

/// Everything the app can learn about the platform it woke up on.
///
/// Deliberately contains **no `dart:io` import**. `dart:io` does not exist in a
/// browser, and its absence is a *compile-time* failure on the web target — so
/// a runtime `if (!kIsWeb)` guard around `Platform.operatingSystem` does not
/// save you; the build simply never gets that far. Reaching for `dart:io` is
/// the single most common way a Flutter app quietly stops being
/// cross-platform, so this pilot establishes the correct pattern up front:
/// [defaultTargetPlatform] for identity, `device_info_plus` for detail.
@immutable
class PlatformFacts {
  const PlatformFacts({
    required this.platformLabel,
    required this.runtimeLabel,
    required this.deviceFacts,
    required this.appFacts,
  });

  /// Human-readable target: `Web`, `Android`, `Linux`, …
  final String platformLabel;

  /// How the Dart code is actually executing on this target.
  final String runtimeLabel;

  final List<Fact> deviceFacts;
  final List<Fact> appFacts;

  static Future<PlatformFacts> gather() async {
    // Both plugins are federated: each has a distinct native implementation per
    // platform behind one Dart API. That they resolve at all on six targets is
    // itself part of what this pilot demonstrates.
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;

    return PlatformFacts(
      platformLabel: platformName,
      runtimeLabel: _runtimeLabel(),
      deviceFacts: _deviceFacts(deviceInfo),
      appFacts: [
        Fact('App name', _orUnknown(packageInfo.appName)),
        Fact('Package ID', _orUnknown(packageInfo.packageName)),
        Fact(
          'Version',
          '${_orUnknown(packageInfo.version)}+${_orUnknown(packageInfo.buildNumber)}',
        ),
        Fact('Build mode', buildMode),
      ],
    );
  }

  /// The current target, resolved in the only order that is correct.
  ///
  /// [kIsWeb] **must** be tested before [defaultTargetPlatform]. In a browser
  /// `defaultTargetPlatform` reports the *host* operating system — it returns
  /// `TargetPlatform.linux` for Chrome on Linux and `TargetPlatform.macOS` for
  /// Safari — and there is no `TargetPlatform.web` value at all. Switching on
  /// it alone therefore misidentifies every single web session, silently.
  static String get platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  static String get buildMode {
    if (kDebugMode) return 'debug';
    if (kProfileMode) return 'profile';
    return 'release';
  }

  static String _runtimeLabel() {
    if (kIsWeb) {
      // kIsWasm distinguishes a WebAssembly build from the JavaScript one.
      return kIsWasm
          ? 'Browser — compiled to WebAssembly'
          : 'Browser — compiled to JavaScript';
    }
    return kDebugMode
        ? 'Native — Dart VM, JIT (hot reload available)'
        : 'Native — ahead-of-time compiled machine code';
  }

  /// Pattern-matches the platform-specific subclass returned by the plugin.
  ///
  /// The `_` fallback is not dead code: it catches Fuchsia and any target added
  /// to the plugin in future, so a new platform degrades to a dull row rather
  /// than an exception.
  static List<Fact> _deviceFacts(BaseDeviceInfo info) {
    return switch (info) {
      WebBrowserInfo i => [
        Fact('Browser', i.browserName.name),
        Fact('Browser version', _orUnknown(i.appVersion)),
        Fact('Vendor', _orUnknown(i.vendor)),
        Fact('Host platform', _orUnknown(i.platform)),
        Fact('Logical cores', '${i.hardwareConcurrency ?? 0}'),
        Fact('Max touch points', '${i.maxTouchPoints ?? 0}'),
      ],
      AndroidDeviceInfo i => [
        Fact('Device', '${i.manufacturer} ${i.model}'),
        Fact('Android', '${i.version.release} (API ${i.version.sdkInt})'),
        Fact('Board', i.board),
        Fact('Supported ABIs', i.supportedAbis.join(', ')),
        Fact('Security patch', _orUnknown(i.version.securityPatch)),
        Fact('Hardware', i.isPhysicalDevice ? 'physical device' : 'emulator'),
      ],
      IosDeviceInfo i => [
        Fact('Device', i.modelName),
        Fact('System', '${i.systemName} ${i.systemVersion}'),
        Fact('Machine', i.utsname.machine),
        Fact('Hardware', i.isPhysicalDevice ? 'physical device' : 'simulator'),
      ],
      LinuxDeviceInfo i => [
        Fact('Distribution', i.prettyName),
        Fact('Version', _orUnknown(i.versionId ?? i.version)),
        Fact('Codename', _orUnknown(i.versionCodename)),
        Fact('Build ID', _orUnknown(i.buildId)),
      ],
      MacOsDeviceInfo i => [
        Fact('Model', i.modelName),
        Fact('macOS', '${i.majorVersion}.${i.minorVersion}.${i.patchVersion}'),
        Fact('Architecture', i.arch),
        Fact('Kernel', i.kernelVersion),
        Fact('Active cores', '${i.activeCPUs}'),
      ],
      WindowsDeviceInfo i => [
        Fact('Edition', i.productName),
        Fact('Version', '${i.displayVersion} (build ${i.buildNumber})'),
        Fact('Computer name', i.computerName),
        Fact('Cores', '${i.numberOfCores}'),
        Fact('Memory', '${i.systemMemoryInMegabytes} MB'),
      ],
      _ => const [Fact('Device', 'Unrecognised platform')],
    };
  }

  /// `package_info_plus` returns empty strings rather than nulls for fields a
  /// platform cannot supply (notably the package ID on web).
  static String _orUnknown(String? value) =>
      (value == null || value.isEmpty) ? 'not reported' : value;
}
