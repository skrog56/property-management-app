# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Versioning policy

The version lives in `pubspec.yaml` as `version: <major>.<minor>.<patch>+<build>`
and is surfaced in the running app on the platform-proof screen, so any build can
be identified from a screenshot.

The project is on **0.x** — pre-alpha, nothing is stable, and anything may
change without ceremony. Under semver, 0.x explicitly carries no compatibility
promise, so while we remain here:

- **Minor** (`0.1.0` → `0.2.0`) — new capability, or any breaking change. In
  0.x, breaking changes ride the minor slot rather than the major one.
- **Patch** (`0.1.0` → `0.1.1`) — fixes and internal work with no new capability.
- **Major** stays at `0` until the data model and interfaces are ones we intend
  to keep. Moving to `1.0.0` is a deliberate commitment to compatibility, not a
  measure of how finished the app feels.
- **Build number** — the `+N` suffix. Increment on every build published to
  anyone else, even when the version is unchanged. Android uses it as
  `versionCode` and iOS as `CFBundleVersion`; both **must** increase for a store
  or TestFlight upload to be accepted.

Entries accumulate under **Unreleased** as work lands. Cutting a release means
renaming that heading to the version and date, and bumping `pubspec.yaml` in the
same commit — a deliberate act, never a side effect of another change.

## [Unreleased]

### Added

- `docs/proof/` — platform proof screenshots for Linux desktop and web, each
  captured wide and narrow to show the layout re-flowing across the 600 dp
  breakpoint, with an index explaining what each image demonstrates and how to
  reproduce it. Windows, macOS, iOS and Android remain outstanding; each must be
  captured on its own hardware.

## [0.1.0] - 2026-08-09

Initial six-platform pilot. Establishes that a single Flutter codebase builds
and runs on every target Skrog needs, ahead of designing livestock transfer
tracking on top of it.

### Added

- Flutter 3.44.9 project scaffolded for all six targets — web, Android, iOS,
  Linux, macOS and Windows — under the `com.skrog.propertyManagementApp`
  bundle ID.
- Platform-proof screen reporting each target's own OS, device, runtime, build
  mode and live display metrics, so a screenshot per platform serves as evidence.
- Adaptive shell driven by Material 3 window size classes: bottom navigation bar
  under 600 dp, collapsed rail to 840 dp, extended rail beyond. Layout keys off
  window width only, never the operating system.
- Input-modality probes for mouse hover, `Ctrl`/`Cmd+R` keyboard refresh and
  pull-to-refresh, covering desktop and touch alike.
- Placeholder paddocks screen with static data, and an about screen listing the
  six targets and marking the current one.
- `device_info_plus` and `package_info_plus`, both verified as supporting all
  six platforms.
- Test suite covering breakpoint boundaries, navigation switching across size
  classes and page rendering, without requiring platform-channel mocks.
- GitHub Actions matrix building all six targets on `ubuntu`, `windows` and
  `macos` runners, gated behind analyze and uploading every artifact. iOS builds
  with `--no-codesign`, so no Apple Developer account is required.

### Notes

Platform fact gathering deliberately avoids `dart:io`, whose absence breaks the
web build at compile time rather than at runtime, and tests `kIsWeb` before
`defaultTargetPlatform` because the latter reports the host OS in a browser.

Offline-first storage, camera and QR tag scanning, and GPS remain unproven and
out of scope.

<!-- No release tags exist yet, so these point at commits. Once v0.1.0 is
     tagged, switch them to the conventional compare/tag URLs. -->

[unreleased]: https://github.com/skrog56/property-management-app/compare/920aa0e...HEAD
[0.1.0]: https://github.com/skrog56/property-management-app/commit/920aa0e
