# Skrog Property Management — Platform Pilot

A Flutter pilot proving that **one codebase reaches all six platforms** Skrog
needs, ahead of building livestock transfer tracking on top of it.

This is deliberately a _shell_. It has no livestock functionality and no
persistence. Its job is to answer one question — "can we actually ship this
everywhere?" — with evidence rather than a vendor claim.

## What it demonstrates

- **Platform proof screen** — each target reports its own OS, version, device,
  renderer and build mode. Screenshot it on six platforms and the set of
  screenshots is the deliverable.
- **One responsive layout** — navigation switches between a bottom bar, a
  collapsed rail and an extended rail purely on window width, so a phone, a
  tablet, a desktop window and a browser tab are all served by the same code.
- **Both input models** — mouse hover, physical keyboard shortcuts and
  pull-to-refresh, because desktop and mobile fail in different ways.
- **Federated plugins resolve everywhere** — `device_info_plus` and
  `package_info_plus` each have a distinct native implementation per platform
  behind a single Dart API.

## Requirements

Flutter **3.44.9** (stable). Everything else is per-platform.

## Running it

| Target  | Command                   | Host needed                                |
| ------- | ------------------------- | ------------------------------------------ |
| Web     | `flutter run -d chrome`   | any                                        |
| Linux   | `flutter run -d linux`    | Linux + GTK toolchain                      |
| Android | `flutter run -d <device>` | any + Android SDK, JDK 17                  |
| Windows | `flutter run -d windows`  | Windows + Visual Studio 2022 (Desktop C++) |
| macOS   | `flutter run -d macos`    | macOS + Xcode                              |
| iOS     | `flutter run -d <device>` | macOS + Xcode                              |

Flutter compiles to native binaries, so **each target must be built on its own
OS**. There is no cross-compiling to Windows from Linux, or to iOS/macOS from
anything but a Mac. The CI matrix exists precisely to cover that.

### Linux build dependencies

```bash
sudo apt install -y clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev
```

### Android

Needs JDK 17 — Gradle rejects JDK 8. If Java 17 is not your system default,
point Flutter at it without disturbing the rest of your system:

```bash
flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk-amd64
```

### iOS on a physical device

Open `ios/Runner.xcworkspace` in Xcode and select a team under
Signing & Capabilities. A free Apple ID is sufficient for development builds.

## Checks

```bash
flutter analyze
flutter test
```

## Versioning and history

- [`CHANGELOG.md`](CHANGELOG.md) — what changed, in Keep a Changelog format,
  plus the semver and build-number policy. The version lives in `pubspec.yaml`
  and is displayed in the running app, so any build is identifiable from a
  screenshot.
- [`JOURNAL.md`](JOURNAL.md) — a dated narrative of what happened and why:
  decisions, dead ends and open questions.

## CI

`.github/workflows/ci.yml` builds all six targets on `ubuntu`, `windows` and
`macos` runners and uploads each artifact. iOS builds with `--no-codesign`, so
no Apple Developer account is required to prove the target compiles.

> On a **private** repository GitHub bills Windows minutes at 2x and macOS at
> **10x**. A public repository is free. The workflow gates every build behind a
> passing `analyze` job and cancels superseded runs to limit the damage either
> way.

## Layout

```
lib/
  app/          MaterialApp, theme, shell wiring
  shell/        Adaptive scaffold and Material 3 breakpoints
  features/
    platform_proof/   The evidence screen and fact gathering
    paddocks/         Placeholder domain screen (static data)
    about/            What the pilot covers and what it does not
```

### One rule worth knowing

`lib/features/platform_proof/platform_facts.dart` contains **no `dart:io`
import**, by design. `dart:io` does not exist in a browser and its absence is a
_compile-time_ failure on web — so a runtime `if (!kIsWeb)` guard around
`Platform.operatingSystem` does not help; the build never gets that far.
Reaching for `dart:io` is the most common way a Flutter app quietly stops being
cross-platform. Use `defaultTargetPlatform` and `device_info_plus` instead.

Related: on web, `defaultTargetPlatform` reports the _host_ OS — it returns
`TargetPlatform.linux` for Chrome on Linux. Always test `kIsWeb` first.

## Not yet proven

Offline-first local storage, camera and QR tag scanning, and GPS. These are the
parts most likely to differ per platform — notably, the usual SQLite package
does **not** work on web or Linux desktop — and should be the next things
piloted before committing to the architecture.
