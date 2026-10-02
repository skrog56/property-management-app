# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter app for livestock transfers, reaching **web, Android, iOS,
Linux, macOS and Windows** from one codebase.

It began as a platform-reach pilot — a shell with no persistence and no domain
logic — and that question is now settled and demonstrated. The app has since
grown a real local domain: properties, paddocks, livestock templates, and a
movement ledger stored in SQLite on all six targets.

It is still early. There is **no backend**: no accounts, no roles, no sync, no
admin approvals. Everything is single-user and local to the device. That is a
deliberate staging decision, not an oversight — see `JOURNAL.md`.

## Commands

```bash
flutter analyze                              # must be clean
flutter test                                 # full suite
flutter test test/ledger_test.dart           # one file
flutter test --plain-name "extends the rail" # one test by name
flutter pub get

dart run build_runner build                  # after editing lib/data/tables.dart
```

Run and build (see README for host-OS requirements per target):

```bash
flutter run   -d chrome | linux | windows | macos | <device-id>
flutter build web | linux | apk | windows | macos --release
flutter build ios --release --no-codesign    # iOS without an Apple account
flutter devices
```

## Repo rules

**Update `CHANGELOG.md` in the same commit as any user-visible change.** Add an
entry under `## [Unreleased]` using Keep a Changelog headings (Added, Changed,
Fixed, Removed). Do not create a new version heading unless explicitly asked to
cut a release — bumping `version:` in `pubspec.yaml` is a deliberate act, not a
side effect. Internal refactors that change nothing observable need no entry.

**Append to `JOURNAL.md` at the end of a substantive work session.** Newest
entry first, `## YYYY-MM-DD — short title`. Record what was done, what was
decided and why, and what remains open. It is a narrative record for humans, not
a duplicate of the changelog: the changelog says *what changed*, the journal says
*what happened and why*.

**Keep inline commentary sparse.** Comment what the code cannot say for itself —
a constraint, a rejected alternative, why a line exists at all. Reasoning that
justifies a design belongs in `JOURNAL.md`, not in a header comment.

## Architecture

```
lib/
  app/         MaterialApp, seeded M3 theme, shell wiring
  shell/       AdaptiveScaffold + WindowSizeClass breakpoints
  data/        Drift schema, repository, platform-specific connection
  features/
    properties/       Three tiers: properties → paddocks → one paddock's livestock
    transfers/        The movement form — one sheet, four kinds
    activity/         The ledger, rendered
    templates/        Livestock classes (read-only for now)
    platform_proof/   The evidence screen and fact gathering
    about/            Target checklist
```

Three invariants carry the project. Each is easy to break without noticing, and
breaking any of them costs either a platform or the data model.

### 1. Layout keys off window width, never the operating system

`WindowSizeClass.fromWidth` (`lib/shell/breakpoints.dart`) drives every layout
decision — navigation affordance, column count. A phone in landscape, a tablet,
a resized desktop window and a narrow browser tab must all get the same
treatment, and they only do if width is the sole input.

Never branch layout on `defaultTargetPlatform`. If you find yourself wanting to,
the breakpoint model is the thing to extend.

### 2. `dart:io` only behind a conditional import

`dart:io` does not exist in a browser, and its absence fails the **web build at
compile time** — a runtime `if (!kIsWeb)` guard does not help, because the build
never gets that far. This is the most common way a Flutter app quietly stops
being cross-platform.

It may therefore appear **only** inside a conditional-import branch the web
build cannot reach, never in shared code. `lib/data/connection/` is the pattern
to copy:

```dart
export 'connection_unsupported.dart'
    if (dart.library.io)         'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
```

`path_provider` is subject to the same rule — its API returns `dart:io`
`Directory` objects, so importing it in shared code breaks the web build just as
surely.

Prefer `defaultTargetPlatform` for identity and `device_info_plus` for detail,
as `lib/features/platform_proof/platform_facts.dart` does. Tests are exempt:
they only ever run on the Dart VM, so `drift/native.dart` is fine there.

Related trap, encoded in that same file: **test `kIsWeb` before
`defaultTargetPlatform`.** In a browser `defaultTargetPlatform` reports the
*host* OS — `TargetPlatform.linux` for Chrome on Linux — and there is no
`TargetPlatform.web` value. Switching on it alone misidentifies every web
session.

**`flutter build web` is the gate.** Run it before believing any change to
`lib/data/` is safe; it is the only check that catches a `dart:io` leak.

### 3. Head counts are derived, never stored

`movements` is an append-only ledger. A paddock's count is a fold over it:

```
head(paddock, class) = Σ(movements in) − Σ(movements out)
```

All four movement kinds — intake, move, age, end state — are the same row shape,
which is why one form and one Activity view serve all of them. Ageing is a
movement whose paddock does not change and whose class does; a move is the
reverse.

Never add a `head` column to `paddocks` and never update a movement in place. The
ledger is what makes the eventual offline sync tractable: append-only logs merge
without conflict, and the only genuine conflict — a count driven negative by two
offline edits — is the single check in `LivestockRepository.record`.

For the same reason, rows use **client-generated UUIDs** and **soft deletes**.
Neither can be retrofitted once devices are syncing.

## Data layer

`lib/data/tables.dart` is the schema; `app_database.g.dart` is generated, so run
`dart run build_runner build` after touching it. `build.yaml` stores timestamps
as ISO-8601 text rather than drift's default unix seconds — the ledger orders by
time and whole seconds are not precise enough.

**Web needs two files in `web/`**: `sqlite3.wasm` and `drift_worker.js`, taken
from the [drift release](https://github.com/simolus3/drift/releases) matching
the pinned version. Without them the web build compiles and then fails at
runtime. Re-download both when upgrading drift.

Native builds keep the database in the **application support** directory, not
drift's default of documents — documents is user-visible and often cloud-synced,
and a sync client copying a live SQLite file can corrupt it.

### Dependencies

`device_info_plus`, `package_info_plus`, `drift` + `drift_flutter`,
`path_provider`, `uuid`. Before adding any dependency, verify on pub.dev that it
supports all six targets — a plugin that misses one silently removes a target
from the matrix.

Two obvious choices are already rejected on exactly those grounds, so do not
reach for them without reopening the decision:

- **`cloud_firestore`** does not support Linux.
- **`google_maps_flutter`** does not support Linux, macOS or Windows. Use
  `flutter_map`, which is pure Dart, when the map screen lands.

## Tests

Tests avoid platform-channel mocking entirely by testing widgets directly rather
than booting the full app, and by running the database in memory via
`AppDatabase(NativeDatabase.memory())`.

Shared helpers live in `test/support.dart`. Two gotchas are encoded there:

- **Never `pumpAndSettle` a page that shows a `CircularProgressIndicator`** — a
  running animation means the tree never goes idle and the test hangs. Use
  `drain(tester)`, which pumps a bounded number of frames.
- **Use `testPage` rather than `testWidgets` for any page holding a drift
  stream.** Disposing a drift `StreamBuilder` schedules a zero-duration timer,
  and `testWidgets` fails a body that ends with one pending. `testPage` unmounts
  the tree and pumps once more, inside the body, to drain it.

Window size is set through `tester.view.physicalSize` with
`addTearDown(tester.view.reset)`, which `pumpPage` handles. It also mounts
`RepositoryScope` **above** `MaterialApp`, as `app.dart` does — a scope inside
the home page is invisible to routes pushed by a drill-down, which build from
the navigator.

If you add a test that boots `PropertyManagementApp`, it will need
`device_info_plus` and `package_info_plus` channel mocks — prefer testing the
widget under it instead.

## Toolchain

Flutter **3.44.9** stable, pinned in `.github/workflows/ci.yml`. Keep the
workflow's `FLUTTER_VERSION` in step with any local upgrade.

Flutter compiles natively, so **each target must be built on its own OS**. There
is no cross-compiling to Windows from Linux, or to Apple platforms from anything
but a Mac — the CI matrix exists to cover the hosts a given developer lacks.
`flutter create` does generate `ios/`, `macos/` and `windows/` scaffolding from
templates on any host, so those directories are committed and buildable
elsewhere without a Mac or PC present.

Android needs JDK 17 (Gradle rejects 8). Flutter is pinned via
`flutter config --jdk-dir`, independent of the system `java` alternative.

## CI

`.github/workflows/ci.yml` builds all six targets and uploads each artifact.
Every build is gated behind a passing `analyze` job, and superseded runs are
cancelled — both to limit runner spend, since macOS bills at 10x and Windows at
2x on private repositories.
