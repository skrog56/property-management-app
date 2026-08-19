# Journal

A dated record of work on this project. Newest entry first.

The changelog says *what changed*; this says *what happened and why* — decisions,
dead ends, surprises and open questions, so context survives between sessions.

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
