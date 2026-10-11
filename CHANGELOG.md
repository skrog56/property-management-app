# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Versioning policy

The version lives in `pubspec.yaml` as `version: <major>.<minor>.<patch>+<build>`
and is surfaced in the running app on the About screen, so any build can be
identified from a screenshot.

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

- **Shareable URLs on the web.** Each property and paddock has its own address
  (`/properties/<id>/paddocks/<id>`), so the browser's back button steps back
  through the tiers, refreshing keeps your place, and a link opens straight to
  a paddock. Hosting now needs unknown paths rewritten to `index.html`; see the
  README. The web build now carries that rule for Vercel (`vercel.json`), so a
  refresh on a deep link there no longer returns 404.
- **Activity links to paddocks.** Each paddock named in an Activity entry
  opens that paddock, including from a paddock's own recent activity, where a
  move links to the other end. Removed paddocks are named but not linked.

- **Developer screen, in debug builds only.** A fifth destination that never
  reaches a release or profile build, with four tabs: **Platform** (the former
  platform-proof screen), **Data** (seed a sample farm, wipe the database,
  check the ledger for negative balances, browse raw table rows including
  soft-deleted ones), **Display** (layout-bounds, repaint-rainbow, performance
  and semantics overlays; theme, text-scale and simulated window-width
  overrides) and **Log** (recent errors, uncaught exceptions and `debugPrint`
  output with stack traces, copyable).
- About shows the platform, version, build number and build mode, so any build
  remains identifiable from a screenshot.
- **Local persistence on all six targets**, via `drift`. The database is real
  SQLite everywhere: a native library on desktop and mobile, WebAssembly in the
  browser. Data survives restarts; nothing is in memory only. This closes the
  question the 0.1.0 notes left open, where storage was called out as the most
  likely thing to invalidate the architecture.
- **Properties and paddocks**, created in-app and persisted, browsed through
  three tiers that each drill into the next: the property list, the paddocks
  under one property, then one paddock's livestock and its own movement
  history. Any number of properties can be added, each with an optional PIC.
  Head counts at every tier are derived live from the ledger, and an empty
  paddock reads as empty rather than as zero.
- **A movement ledger** — the core of the domain. One append-only table records
  all four kinds of event: intake, a move between paddocks, ageing into the next
  class, and an end state such as meatworks or sold. Paddock counts are derived
  from it rather than stored, so history is never lost and cannot disagree with
  the totals. A movement that would drive a count negative is rejected.
- **Movement form**, one sheet serving all four kinds, which offers only
  livestock actually standing in the chosen paddock and preselects the
  destination class from the template's ageing chain. Opened from a paddock, it
  starts with that paddock as the origin.
- **Activity screen**, listing every recorded movement newest first. It is the
  ledger rendered, so it required no separate audit log.
- **Templates screen**, read-only, listing livestock classes and their ageing
  chains. Two provisional templates — Beef and Dairy — are seeded on first run
  from `assets/templates/default_templates.json`; the real lists are still
  awaited, and replacing them is a content change rather than a code one.
- **Storage card on the platform-proof screen**, reporting the database engine,
  SQLite version, location and movement count — so the evidence screenshots now
  prove persistence per platform, not just that the app runs.
- Installation instructions in the README, covering a clone-to-running path:
  installing the pinned Flutter 3.44.9, fetching packages, and the host
  toolchain for each of the six targets. Previously the README documented build
  dependencies but assumed a working Flutter install.
- "Going to production" section in the README, mapping each of the six targets
  to its distribution channel, prerequisites and blockers — signing and
  notarization, store accounts, packaging, and what CI would need to become a
  release pipeline. Documents the gap rather than closing it: nothing about
  deployment is configured.

### Changed

- **Wider sidebar highlights.** When the sidebar shows labels, hovering a
  destination, and the marker on the current one, now covers the label as well
  as the icon, so the whole row is one target.
- **Navigation stays on screen while browsing properties.** Opening a property
  or paddock no longer covers the navigation rail or bottom bar.
- **Wide windows show the tiers side by side.** With room for two panes, the
  parent list stays beside what you opened; with room for three, properties,
  paddocks and one paddock's livestock all show at once. Breadcrumbs in the
  title bar step back up. Narrow windows still show one tier at a time.
- On windows wide enough for the side rail, an app header now runs across the
  top with the app's name, and each page's title bar sits beneath it, beside
  the rail. Phones keep a single bar.

- The Platform destination is gone from navigation. Its screen now lives under
  Developer, so release builds show Properties, Activity, Templates and About.
- The About screen, web manifest and package description no longer carry the
  Skrog name. It remains only where it marks authorship: the `com.skrog`
  application ID, copyright and company fields.
- Navigation now leads with the domain: Properties, Activity, Templates, then
  Platform and About. The platform-proof screen remains, demoted from the
  landing screen but still carrying evidence.
- Display name is **Property Management App** on all six targets, replacing the
  raw Dart package name (`property_management_app`) that every platform except
  iOS was showing in launchers, window titles and browser tabs. Executable and
  bundle filenames on Linux and Windows are unchanged.

### Fixed

- Application ID is now `com.skrog.propertyManagementApp` on all six targets.
  Android was scaffolded as `com.skrog.property_management_app` and Linux
  likewise, so the identity claimed in 0.1.0 held only on Apple platforms.
  Corrected while nothing is published — on Android and Apple platforms this
  identifier is permanent from first release. The Android Kotlin `namespace` is
  deliberately left as-is, being the source package rather than the app ID.

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

[unreleased]: https://github.com/skrog56/property-management-app/compare/bd9a8fb...HEAD
[0.1.0]: https://github.com/skrog56/property-management-app/commit/bd9a8fb
