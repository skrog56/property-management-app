# Journal

A dated record of work on this project. Newest entry first.

The changelog says *what changed*; this says *what happened and why* — decisions,
dead ends, surprises and open questions, so context survives between sessions.

---

## 2026-08-19 — Display name across all six targets

Closes the loose end from the deployment review below: every target except iOS
was showing the raw Dart package name, `property_management_app`, in launchers,
window titles and browser tabs.

Settled on **Property Management App**, uniform everywhere. Brand-prefixed and
short-form variants were both considered — phone launchers truncate at roughly
twelve characters, so a longer name is cut off there — and the uniform name was
chosen anyway, on the grounds that one string is easier to reason about than a
per-platform split and this is still a pilot nobody is installing from a store.

### Where a display name actually lives

Seven places, and no two platforms agree:

- Android — `android:label` in the manifest.
- iOS — `CFBundleDisplayName` (already correct; `flutter create` title-cases it,
  which is why iOS was the only target that looked right) and `CFBundleName`.
- macOS — `PRODUCT_NAME` in `AppInfo.xcconfig`, which feeds `CFBundleName`.
- Linux — two literals in `my_application.cc`, one per titlebar branch.
- Windows — the `Win32Window::Create` title, plus `FileDescription` and
  `ProductName` in `Runner.rc`.
- Web — `<title>`, the `apple-mobile-web-app-title` meta tag, and both name
  fields in `manifest.json`.
- In-app — `MaterialApp.title`, which is what Android's task switcher reads.

### The one that needed care

macOS `PRODUCT_NAME` is not only the display name — it is also the `.app`
filename and the executable inside it. Changing it strands the `TEST_HOST`
paths, the product file reference and five `BuildableName` entries in the Xcode
project and scheme, which all hardcode `property_management_app.app`. Those were
updated in step; CI does not run macOS unit tests, so a stale `TEST_HOST` would
have gone unnoticed until someone did.

Executable filenames on Linux and Windows were deliberately *not* renamed.
`BINARY_NAME` is a path, and spaces in a binary name are hostile to shells and
scripts for no user-visible gain — the window title is what people read.

### Verification

Analyze clean, 17/17 tests passing. Read the name back out of built artifacts
rather than trusting the source: `aapt2 dump badging` reports
`application-label:'Property Management App'`, the web build's `<title>` and
manifest carry it, and it is present in the compiled Linux binary. macOS and
Windows rest on CI, since neither builds here.

---

## 2026-08-19 — Deployment gap, and one identifier that had to be settled now

### What prompted it

A question with a short answer: are there deployment instructions? There were
not. The README ran clone → install → run → `flutter build --release`, and CI
uploaded the results, but nothing said what happens after an artifact exists.

Looking into that turned up something with a deadline attached, which is the
part worth recording.

### The application ID was never actually unified

`flutter create` derives platform identifiers differently per target. Apple
platforms got `com.skrog.propertyManagementApp`; Android and Linux got
`com.skrog.property_management_app`, straight from the Dart package name. The
0.1.0 changelog entry claimed a single bundle ID across all six, which was true
of Apple only.

Normally cosmetic. Not here: on Android and Apple platforms the application ID
is **permanent from first publication** — changing it later means a new store
listing with no upgrade path for existing installs. So this was a free fix today
and an unfixable one after a first release.

Settled on `com.skrog.propertyManagementApp` everywhere, because it was already
in the most places and is legal in every ecosystem. Underscores were the other
candidate and were rejected: Apple documents bundle identifiers as alphanumerics,
hyphens and periods, so `property_management_app` is outside the sanctioned set
even where Xcode tolerates it. Hyphens are worse — illegal in an Android
identifier.

Android's Kotlin `namespace` was deliberately left as
`com.skrog.property_management_app`. It is the source package, tied to the
directory holding `MainActivity.kt`, and is not required to match the
`applicationId` — changing it would mean moving source for no benefit.

Verified rather than assumed: rebuilt the APK and read the ID back out with
`aapt2 dump badging`, which reports `com.skrog.propertyManagementApp`. Linux
rebuilt clean, analyze clean, 17/17 tests passing.

### What the deployment section says, and what it deliberately does not

A new "Going to production" section covers each target's channel, signing story
and packaging, plus what CI would need to become a release pipeline.

It documents the gap rather than closing it. No keystore was generated, no
signing config written, no release workflow added — those need decisions and
money that a pilot has not earned yet. The point of writing it down was to make
the cost of shipping visible, because "it builds on six platforms" reads as
much closer to shippable than it is. Deployment is six independent channels,
each with its own account, review queue and signing regime.

Two findings from that survey are worth flagging on their own:

- **Android release builds are signed with the debug keystore.** The Flutter
  template TODO is untouched, so the APK CI produces is sideload-only.
- **`macos/Runner/Release.entitlements` enables the app sandbox but not
  `com.apple.security.network.client`.** Correct today, since the pilot makes no
  network calls — but the first release build that talks to a server will fail
  silently rather than loudly. Worth remembering when storage syncing lands.

### Open

- Display name is still the Dart package name on every target — Android manifest
  label, window titles, `web/manifest.json`, macOS `PRODUCT_NAME`. Cosmetic for
  a pilot, but it is what a store listing would show.
- The build number has never moved off `+1`. Any real upload path needs it
  incrementing, most cheaply from the CI run number.

---

## 2026-08-19 — Installation instructions

### What prompted it

The README explained per-platform *build dependencies* but assumed a working
Flutter install, so a fresh clone had no path from nothing to a running app. The
dependency sections also sat under "Running it" — after the point at which they
were needed.

### What was added

An Installation section ahead of "Running it", in three steps: install the
pinned Flutter 3.44.9, clone and `flutter pub get`, then the host toolchain for
whichever targets you actually intend to build. Web needs nothing beyond Flutter
and Chrome, which is worth saying explicitly — it means the pilot can be seen
running within a minute of cloning.

Everything was checked against this machine rather than transcribed from the
original plan: Flutter at `~/development/flutter`, SDK at `~/Android/Sdk` with
`android-36` and `build-tools;36.0.0`, `jdk-dir` pinned to
`java-17-openjdk-amd64`, and `FLUTTER_VERSION: '3.44.9'` in CI.

### The gap that mattered

Android was the section that would genuinely have failed someone. It documented
the JDK 17 pin but never said how to obtain the SDK at all, and omitted
`sdkmanager --licenses` — which does not warn, it just fails the build later.

Also now stated explicitly: `flutter config --jdk-dir` is **global to a Flutter
installation, not per-repo**. Anyone following these steps changes Flutter for
every project on their machine, and that deserved to be said rather than
discovered.

### Open

- Flutter is advertising a release newer than the pinned 3.44.9. Upgrading means
  bumping `FLUTTER_VERSION` in the CI workflow in the same commit, so it stays a
  deliberate act rather than drift.

---

## 2026-08-09 — Six-platform pilot: from empty directory to all six targets green

### Goal

Decide nothing about livestock functionality; establish only whether one Flutter
codebase genuinely reaches web, desktop and mobile across every mainstream OS.
The framework choice was already settled by the sibling
`../cross-platform-application-frameworks` chooser, where Flutter is one of only
two entries covering all six targets.

### The constraint that shaped everything

Flutter compiles to native binaries, so each target needs its host OS's
toolchain. The development machine is Ubuntu 24.04 x86_64 and can build only
three of the six: web, Linux desktop and Android. Windows desktop needs a
Windows machine with Visual Studio; macOS and iOS need a Mac with Xcode. There
is no cross-compiling around this.

The plan therefore ran on two tracks — build what this box can build locally,
and stand up a CI matrix on GitHub's `windows-latest` and `macos-latest` runners
for the rest. That turned out to be the right call: it produced downloadable
artifacts for all six from a single commit.

One detail made this much easier than expected: `flutter create` generates
`ios/`, `macos/` and `windows/` scaffolding from templates **regardless of host
OS**. All six platform directories were generated on Linux, committed, and built
elsewhere untouched.

### Decisions

- **Pilot depth: shell only.** Considered a thin vertical slice with a real
  offline database, on the grounds that persistence is the riskiest
  cross-platform assumption. Decided against for now — scope stays a shell, and
  storage becomes its own pilot.
- **Public repository.** Makes all CI runners free. Private would bill macOS at
  10x and Windows at 2x; the workflow still gates builds behind `analyze` and
  cancels superseded runs either way.
- **Two dependencies only**, `device_info_plus` and `package_info_plus`, both
  verified against pub.dev as supporting all six targets. Their resolving at all
  is itself part of the proof, since each is a federated plugin with a distinct
  native implementation per platform.
- **Versioning: changelog and semver policy only.** Build-provenance injection
  (git SHA via `--dart-define`) and tag-triggered release automation were both
  considered and deferred as premature for a pilot.
- **Started at `0.1.0`, not `1.0.0`** — this is barely an alpha, and 0.x is the
  honest signal that nothing is stable. Breaking changes ride the minor slot
  while we stay there; reaching 1.0.0 will be a deliberate commitment to
  compatibility rather than a statement about how finished the app feels.

### The one rule worth carrying forward

`platform_facts.dart` contains no `dart:io` import, by design. `dart:io` does not
exist in a browser and its absence fails the **web build at compile time**, so a
runtime `if (!kIsWeb)` guard does not save you. Related trap: in a browser
`defaultTargetPlatform` reports the *host* OS — `TargetPlatform.linux` for Chrome
on Linux — and there is no `TargetPlatform.web` value, so `kIsWeb` must be tested
first or every web session is misidentified.

Both are encoded in the code and in CLAUDE.md, because either one silently costs
a platform.

### Surprises

- **`sudo` has no TTY in this environment**, including via the `!` prefix.
  `pkexec` works instead, raising a GNOME polkit dialog. Same story for GPG:
  commit signing needs the desktop pinentry prompt.
- **Installing `openjdk-17-jdk` changed the system default Java from 8 to 17**
  via `update-alternatives` auto-promotion — contrary to what the plan promised.
  Flutter is pinned independently through `flutter config --jdk-dir`, so it is
  unaffected, but other Java tooling on the machine may not be. Left as-is,
  flagged, reversible.
- **The `github-skrog` SSH alias authenticates as `skrog56`, not `skrog65`.**
  Caught by running `ssh -T` before creating anything. Worth confirming whether
  `skrog65` exists at all.

### Verification

`flutter doctor` clean. `flutter analyze` clean, 17/17 tests passing.

Built locally: web (41 MB, WASM dry-run passed), Linux desktop, Android APK
(47.8 MB). CI green on all six with artifacts uploaded — web 13 MB, Linux 9 MB,
Android 21 MB, Windows 11 MB, macOS 252 MB, iOS 6 MB.

The genuinely uncertain part was Apple: the `ios/` and `macos/` scaffolding was
template-generated on Linux and had never touched Xcode. Both compiled clean on
first contact, CocoaPods and all.

### Open

- Screenshot pack for `docs/proof/` — Linux and web done, both captured wide and
  narrow. Windows, macOS, iOS and Android outstanding; each needs its own
  hardware.

  Capturing these was fiddlier than expected. GNOME 46 denies
  `org.gnome.Shell.Screenshot` to unsandboxed callers, so the Linux app is run
  under `GDK_BACKEND=x11` and grabbed with ImageMagick `import -window` — which
  also has the virtue of capturing only the app window rather than the whole
  desktop. Headless Chrome needs `--enable-unsafe-swiftshader` or CanvasKit has
  no GPU to render through and the capture comes out blank. Both recipes are
  written down in `docs/proof/README.md`.

  First attempt captured `1.0.0+1` because the web bundle predated the version
  change — worth remembering that these artefacts embed the version, so rebuild
  before capturing.
- No Android phone attached yet, so the APK has not run on real hardware.
- System default Java is 17; revert if anything on the machine needs 8.
- **Next pilot: offline-first storage.** The likeliest thing to invalidate the
  architecture — the usual SQLite package works on neither web nor Linux
  desktop, and paddocks have no signal. Camera/QR tag scanning and GPS follow.
