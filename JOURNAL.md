# Journal

A dated record of work on this project. Newest entry first.

The changelog says *what changed*; this says *what happened and why* — decisions,
dead ends, surprises and open questions, so context survives between sessions.

---

## 2026-09-25 — Properties become the top tier

The paddock screen was built as though there were one property. The dropdown in
its header admitted otherwise but buried it: a second property was reachable
only by noticing that the title had become a menu, and nothing above paddock
level had a place to live.

The screen is now three tiers, each drilling into the next — properties, the
paddocks of one property, then one paddock's livestock. The navigation
destination is renamed to match, since the top tier is what it lands on.

Each tier answers a different question, which is what makes the split worth the
extra screens rather than merely tidier:

- **Properties** — where is the herd, across the business. Paddock count and
  total head per property.
- **Property** — how is one place stocked. The paddock cards that used to be
  the whole screen, unchanged.
- **Paddock** — what is actually standing here, mob by mob with its age band,
  and how it got here. The last part is the ledger filtered to one paddock,
  which cost one `where` clause: the same table that serves the Activity view
  serves a paddock's own history.

Two consequences worth recording:

- Drilling down pushes full-screen routes on the root navigator, so the
  navigation rail is not visible inside a property or paddock. That is the
  conventional pattern and back works everywhere, but on a wide desktop window
  a list-detail pane would use the space better. Deferred — it is a layout
  change against the same three widgets, and the width-based breakpoints are
  already there to drive it.
- `pumpPage` in `test/support.dart` now puts `RepositoryScope` **above**
  `MaterialApp`, as the real app does. Pushed routes build from the navigator,
  so a scope inside the home page's body is invisible to them, and every
  drill-down test would have failed on a missing repository rather than on
  anything real.

The movement sheet gained an optional origin paddock, so recording from inside
a paddock starts with that paddock already chosen. Properties gained an
optional PIC field at creation, which the schema already had a column for.

Still open: the specification's "Priorities:" heading remains blank, so what
follows this — template editor, settings, export, the map — is still a guess.

---

## 2026-09-25 — The pilot becomes an application: persistence and the movement ledger

### What prompted it

A specification arrived — a stakeholder brainstorm covering paddocks and
transfers, a drawable map, admin and user roles, cattle templates with age
bands, offline sync with admin approval, activity and reporting views, and an
onboarding wizard. Its final heading, "Priorities:", was left blank.

That is a much larger app than this repo was chartered for. Four decisions were
settled before any code was written:

- **Livestock is tracked as head counts by class**, not as individual animals.
  The notes point this way throughout — "numbers in them", templates by type and
  age — and never mention ear tags or NLIS. Individual tracking would have meant
  tag scanning hardware and far more sync volume for a benefit nobody asked for.
- **No backend yet.** Roles, approvals, sync and notifications are all deferred.
  The app is single-user and local.
- **The map will be georeferenced** when it lands, not a schematic diagram.
- **First milestone is a vertical slice**: properties, paddocks, templates and
  transfers, persisted, on all six targets.

Deferring the backend defers most of the specification, so the job became
building the local model such that sync can be *added* rather than retrofitted.

### The line in the notes that decided the data model

> For aging → can do transfer within paddocks

Ageing is expressed as a transfer that does not change paddock. Follow that
through and a single movement primitive covers every event in the app: a move
changes paddock and not class, ageing changes class and not paddock, intake has
no origin, and an end state has no destination. One table, one form, one audit
trail — which is why the admin "Activity" view the notes ask for cost nothing
extra. It is the movements table, rendered.

The corollary is that **paddock counts are derived, never stored**. That was the
most consequential decision of the session and it was made for the backend that
does not exist yet: an append-only log merges trivially, so two devices
appending different movements never conflict at the row level. The only genuine
conflict is semantic — a count driven negative because two people each moved
cattle out of the same paddock while offline — which reduces the notes'
"notifications to admin for conflicts" from a general merge problem to one
well-defined check. Storing mutable counts instead would have made that
unrecoverable.

For the same reason, rows carry client-generated UUIDs and soft deletes from the
first migration. Both are nearly free now and neither can be retrofitted once
devices are syncing.

### Storage: drift, and two rejections that mattered more

The 0.1.0 entry flagged that "the usual SQLite package works on neither web nor
Linux desktop" — that is `sqflite`, which declares Android, iOS and macOS only.
`drift` declares all six and is the direct answer.

Every candidate was checked against the six-target rule before adoption, and two
obvious choices failed it:

- **`cloud_firestore` does not support Linux.** It has the best offline story of
  anything available, and choosing it would have silently cost a platform this
  project exists to prove.
- **`google_maps_flutter` supports only Android, iOS and web** — it would cost
  three. `flutter_map` is pure Dart, declares all six, and is what the map
  screen should use.

Both are the default choice in their category, which is precisely the trap. Worth
re-reading before anyone reaches for either.

One wrinkle accepted rather than fought: `drift_flutter` pulls
`sqlite3_flutter_libs`, which pub.dev marks end-of-life pending a `sqlite3` 3.x
migration. It is the drift maintainer's own pinned combination, so it is the
sanctioned path today. Revisit on the next drift upgrade.

### The `dart:io` rule needed amending, not obeying

CLAUDE.md said, flatly, "never import `dart:io`". Taken literally, drift is
unusable — its native connection reaches `dart:io`, and so does `path_provider`,
whose API returns `Directory` objects.

The rule is now stated precisely: `dart:io` may appear **only** inside a
conditional-import branch the web build cannot reach. `lib/data/connection/` is
the worked example. The original reasoning — that this is a compile-time failure,
so a runtime `kIsWeb` guard cannot save you — survives intact and is exactly why
the conditional import is the only mechanism that works.

That distinction also drove a late refactor. The database location wanted
`path_provider`, which meant the whole connection had to move behind the
conditional import rather than just a diagnostic label.

### Four things that were not obvious

- **Drift stores `DateTime` as whole unix seconds by default.** Sub-second
  precision and the UTC flag are simply lost. The ledger orders by time, so two
  movements recorded in the same second sorted arbitrarily — caught by a test
  asserting the newest entry first. `build.yaml` now sets
  `store_date_time_values_as_text`. Changing this after data exists needs a
  migration; the schema was still at version 1, so it was free.
- **The database landed in `~/Documents`.** That is drift's default, and it is a
  poor one: user-visible clutter, and Documents is commonly cloud-synced, where a
  sync client copying a live SQLite file risks corrupting it. Now overridden to
  the application support directory —
  `~/.local/share/com.skrog.propertyManagementApp/` on Linux.
- **`pumpAndSettle` hangs on any page that shows a spinner.** A
  `CircularProgressIndicator` schedules frames forever, so the tree never goes
  idle. Every page here shows one while its stream is cold. Bounded pumping
  replaces it.
- **Disposing a drift `StreamBuilder` schedules a zero-duration timer**, and
  `testWidgets` fails a body that ends with one pending. The fix has to happen
  *inside* the test body, because that check runs before `addTearDown` does —
  hence the `testPage` wrapper in `test/support.dart`.

The drift documentation also names the web worker `drift_worker.dart.js`; the
actual release asset for 2.35.0 is `drift_worker.js`. Both it and `sqlite3.wasm`
are committed under `web/` and must be re-downloaded when drift is upgraded.

### Verification

Analyze clean, 36 tests passing, up from 17. The new ones cover balance
derivation across all four movement kinds, ageing leaving a paddock total
unchanged, rejection of a movement that would go negative, and the movement form
recording end-to-end.

`flutter build web` succeeded, which is the only real check on the `dart:io`
boundary — it fails at compile time if native code leaks into shared imports.
The WASM dry run passed too.

Persistence was verified on the Linux release build rather than assumed: the app
was run, the database inspected directly with `sqlite3`, a row inserted
underneath it, and the app restarted — the seeded templates kept their original
UUIDs (so the file was read, not rewritten) and the injected row came back. A
screenshot confirmed derived counts agree with the ledger: North Ridge showing
73 after an intake of 128, a move of 30 out and 25 to meatworks.

### Open

- **The seeded templates are provisional.** The real lists of cattle types were
  promised by Alex and have not arrived. `assets/templates/default_templates.json`
  is a placeholder; replacing it is a content change.
- **"Priorities:" in the specification is still blank.** The order after this
  slice is a guess: template editor, settings and export next, then the map, then
  the backend.
- **"Better signup than email/password ???"** — the notes' own question mark.
  Still open, and deferred with the rest of the backend.
- `macos/Runner/Release.entitlements` still lacks
  `com.apple.security.network.client`. Harmless while nothing touches the
  network, but map tiles will be the first thing that does — and it fails
  silently, not loudly.
- The app has still never run on a physical Android device.

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
