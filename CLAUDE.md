# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter pilot for Skrog's livestock-transfer property management app. Its
purpose is to prove that one codebase reaches **web, Android, iOS, Linux, macOS
and Windows** — not to implement livestock functionality. Scope is deliberately
a shell: no persistence, no domain logic, no device permissions.

When adding features, check they belong: this repo answers "does it run
everywhere?", and anything that does not serve that question is probably
premature.

## Commands

```bash
flutter analyze                              # must be clean
flutter test                                 # full suite
flutter test test/breakpoints_test.dart      # one file
flutter test --plain-name "extends the rail" # one test by name
flutter pub get
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

## Architecture

```
lib/
  app/         MaterialApp, seeded M3 theme, shell wiring
  shell/       AdaptiveScaffold + WindowSizeClass breakpoints
  features/
    platform_proof/   The evidence screen and fact gathering
    paddocks/         Placeholder domain screen (static data)
    about/            Target checklist
```

Two invariants carry the whole pilot. Both are easy to break without noticing,
and breaking either silently costs a platform.

### 1. Layout keys off window width, never the operating system

`WindowSizeClass.fromWidth` (`lib/shell/breakpoints.dart`) drives every layout
decision — navigation affordance, column count. A phone in landscape, a tablet,
a resized desktop window and a narrow browser tab must all get the same
treatment, and they only do if width is the sole input.

Never branch layout on `defaultTargetPlatform`. If you find yourself wanting to,
the breakpoint model is the thing to extend.

### 2. Never import `dart:io`

`dart:io` does not exist in a browser, and its absence fails the **web build at
compile time** — a runtime `if (!kIsWeb)` guard does not help, because the build
never gets that far. This is the most common way a Flutter app quietly stops
being cross-platform.

Use `defaultTargetPlatform` for identity and `device_info_plus` for detail, as
`lib/features/platform_proof/platform_facts.dart` does.

Related trap, encoded in that same file: **test `kIsWeb` before
`defaultTargetPlatform`.** In a browser `defaultTargetPlatform` reports the
*host* OS — `TargetPlatform.linux` for Chrome on Linux — and there is no
`TargetPlatform.web` value. Switching on it alone misidentifies every web
session.

### Dependencies

Only `device_info_plus` and `package_info_plus`, both chosen because they
support all six targets. Before adding any dependency, verify its pub.dev
platform support covers all six — a plugin that misses one silently removes a
target from the matrix.

## Tests

Tests avoid platform-channel mocking entirely by testing widgets directly rather
than booting the full app: `PaddocksPage` and `AboutPage` need no plugins, and
`AdaptiveScaffold` is exercised in isolation. Window size is set through
`tester.view.physicalSize` with `addTearDown(tester.view.reset)`.

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
