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

## Installation

### 1. Flutter

Pinned to **3.44.9** stable (Dart 3.12.2) — the same version
`.github/workflows/ci.yml` installs. Other versions will likely work, but CI is
the arbiter, so match it before investigating anything strange. Upgrading is a
deliberate change: bump `FLUTTER_VERSION` in the workflow in the same commit.

Use [Flutter's install guide](https://docs.flutter.dev/get-started/install) for
your OS, or on Linux take the tarball directly:

```bash
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.9-stable.tar.xz
mkdir -p ~/development
tar -xf flutter_linux_3.44.9-stable.tar.xz -C ~/development
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

`flutter --version` should report `3.44.9 • channel stable`.

### 2. The project

```bash
git clone https://github.com/skrog56/property-management-app.git
cd property-management-app
flutter pub get
```

At this point `flutter run -d chrome` already works — web needs nothing beyond
Flutter and a Chrome install. Every other target needs its host toolchain.

### 3. Toolchain, per target you intend to build

Run `flutter doctor -v` and fix what it reports. Targets your OS cannot build at
all are simply **absent** from its output rather than listed as failures — no
Xcode section on Linux is correct, not a problem to solve.

Install only what you need:

#### Linux desktop

```bash
sudo apt install -y clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev
```

#### Android

Two pieces: the SDK, and **JDK 17** — Gradle rejects JDK 8.

Android Studio bundles both and is the easy path. For a CLI-only install, take
`commandlinetools-linux-*.zip` from
[developer.android.com/studio](https://developer.android.com/studio#command-line-tools-only),
then:

```bash
mkdir -p ~/Android/Sdk/cmdline-tools
unzip commandlinetools-linux-*.zip -d ~/Android/Sdk/cmdline-tools
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest

# Add both to ~/.bashrc — Flutter looks for ANDROID_HOME, and the second
# puts adb and sdkmanager on PATH.
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
sdkmanager --licenses    # must be accepted or builds fail
```

If JDK 17 is not your system default, point Flutter at it rather than switching
the default and disturbing other tooling:

```bash
sudo apt install -y openjdk-17-jdk
flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk-amd64
```

This setting is global to your Flutter install, not to this repo, and is what to
check first if Gradle ever complains about a Java version.

#### Windows desktop

Visual Studio 2022 with the **Desktop development with C++** workload. The
Build Tools edition is enough; the full IDE is not required.

#### macOS and iOS

Xcode from the App Store, then:

```bash
sudo xcodebuild -runFirstLaunch
sudo gem install cocoapods
```

First build of either target runs a CocoaPods step and takes noticeably longer
than later ones.

To run on a **physical** iPhone or iPad, open `ios/Runner.xcworkspace` in Xcode
and select a team under Signing & Capabilities. A free Apple ID is sufficient
for development builds — the CI iOS build uses `--no-codesign` precisely so that
no paid Developer account is needed just to prove the target compiles.

## Running it

| Target  | Command                   | Host needed                                |
| ------- | ------------------------- | ------------------------------------------ |
| Web     | `flutter run -d chrome`   | any                                        |
| Linux   | `flutter run -d linux`    | Linux + GTK toolchain                      |
| Android | `flutter run -d <device>` | any + Android SDK, JDK 17                  |
| Windows | `flutter run -d windows`  | Windows + Visual Studio 2022 (Desktop C++) |
| macOS   | `flutter run -d macos`    | macOS + Xcode                              |
| iOS     | `flutter run -d <device>` | macOS + Xcode                              |

`flutter devices` lists what is currently attached and its device ID.

Flutter compiles to native binaries, so **each target must be built on its own
OS**. There is no cross-compiling to Windows from Linux, or to iOS/macOS from
anything but a Mac. The CI matrix exists precisely to cover that.

Release builds, should you want the artefacts locally:

```bash
flutter build web | linux | apk | windows | macos --release
flutter build ios --release --no-codesign
```

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
