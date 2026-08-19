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

## Going to production

**None of this is configured.** The pilot builds release binaries but nothing
here is distributable: CI uploads raw build output, and the Android release type
is still signed with debug keys. This section is the map, not a pipeline — it
exists so the cost of shipping is visible before anyone commits to it.

Worth being blunt about the shape of the problem: "deploy" is six independent
channels, not one. Each has its own account, its own signing story and its own
review queue. Nothing about proving the app *builds* everywhere makes shipping
it everywhere a single step.

### What every target needs first

- **A build number that moves.** `pubspec.yaml` is `0.1.0+1` and has never been
  incremented. Play and TestFlight both reject an upload whose build number does
  not exceed the last one accepted — see the versioning policy in
  [`CHANGELOG.md`](CHANGELOG.md).
- **A display name.** Every target still shows the Dart package name —
  `property_management_app` in the Android manifest label, the window titles,
  `web/manifest.json` and the macOS `PRODUCT_NAME`. That string is what users
  and store listings see.
- **Application ID.** All six now share `com.skrog.propertyManagementApp`. On
  Android and Apple platforms this is **permanent from first publication**; it
  cannot be changed later without becoming a separate listing.

### Accounts and costs

| Channel                | Requires                                     |
| ---------------------- | -------------------------------------------- |
| Google Play            | Play Console account, one-off registration fee |
| App Store / TestFlight | Apple Developer Program, billed annually     |
| macOS outside the store| Same Apple membership, for a Developer ID cert |
| Windows                | Code-signing certificate (optional but see below) |
| Linux / web            | No account; hosting or a repository only     |

The Apple membership is unavoidable for iOS in any form — including handing a
build to a tester. CI builds iOS with `--no-codesign` precisely because that
proves compilation without one, but that artifact cannot be installed anywhere.

### Android → Play

Release builds currently use the debug keystore
(`android/app/build.gradle.kts`), which Play rejects. Shipping needs an upload
keystore, kept out of git:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Reference it from `android/key.properties` (gitignored), and replace the debug
`signingConfig` with one reading that file. Then build an **app bundle**, not an
APK — Play requires `.aab`:

```bash
flutter build appbundle --release
```

Enrol in Play App Signing when creating the listing. Without it, losing the
keystore permanently ends your ability to update the app; with it, Google holds
the app-signing key and only the upload key is yours to lose.

### iOS → App Store / TestFlight

Needs a team selected under Signing & Capabilities in `ios/Runner.xcworkspace`,
then:

```bash
flutter build ipa --release
```

Upload the `.ipa` via Xcode or Transporter. TestFlight review is lighter than
App Store review but is still a review. Distributing to devices you own without
any of this is possible only through a free personal team, whose builds expire
after seven days.

### macOS

Two routes, and they differ more than they look:

- **Outside the store** — sign with a Developer ID certificate, then
  **notarize** with `xcrun notarytool`. Unnotarized apps are refused by
  Gatekeeper on any machine that did not build them.
- **Mac App Store** — a separate provisioning profile and full review.

One thing already relevant: `macos/Runner/Release.entitlements` enables the app
sandbox but **not** `com.apple.security.network.client`. The pilot needs no
network, so this is currently correct — but the first release build that talks
to a server will fail silently until that entitlement is added.

### Windows

No store account is required; `build/windows/x64/runner/Release/` can be zipped
and shipped. Two caveats:

- The folder is the unit — `.exe` plus its DLLs and `data/`. The executable
  alone does not run.
- Unsigned binaries trigger SmartScreen warnings until the download builds
  reputation. A code-signing certificate avoids that; an EV certificate avoids
  the reputation-building period as well.

For a real installer, `msix` (pub package) or MSI tooling wraps the same output.

### Linux

`build/linux/x64/release/bundle/` is likewise a directory, not a single binary.
Packaging options in rough order of effort: tarball, `.deb`, then Flatpak or
Snap if you want sandboxed distribution and automatic updates. The GTK
application ID in `linux/CMakeLists.txt` is what desktop integration keys off.

### Web

The simplest target by a wide margin — `build/web/` is static files, servable
from any static host with no runtime.

```bash
flutter build web --release                      # served from the domain root
flutter build web --release --base-href /app/    # served from a subpath
```

`web/index.html` carries a `$FLUTTER_BASE_HREF` placeholder, so getting the
base href wrong is the usual cause of a blank page behind a reverse proxy.
Flutter also emits a service worker, so a stale cache is the second usual cause
— serve `flutter_service_worker.js` and `index.html` with no-cache headers and
let the fingerprinted assets cache normally.

### What CI would need

`.github/workflows/ci.yml` builds and uploads artifacts on push to `main`. It
has no tag trigger, no release job and no secrets. Turning it into a release
pipeline means at minimum: a `push: tags:` trigger, the Android keystore and
Apple certificates as encrypted secrets, and a build-number source — commonly
`--build-number=${{ github.run_number }}` so uploads are monotonic without
hand-editing `pubspec.yaml`.

None of that is worth building until there is something to ship.

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
