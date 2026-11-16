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

- **Export.** Settings has two tabs, *Settings* and *Data*, and *Data*
  saves the farm's records as an Excel workbook, CSV, a PDF report or a JSON
  backup. *Export* in the bar on Home and Activity opens it. From a
  paddock's history in Activity, it starts with that paddock's property. It
  shows the name of the file it will save before saving it.
  The lists are movements, stock on hand, tags, properties and paddocks, and
  templates and classes. All are ticked to begin with, and any can be left
  out. An export can be narrowed to one property, and its movements to a
  range of days. A JSON backup always holds everything recorded, exactly as
  stored, deleted rows and settings included. Desktop and phones ask where to
  save; a browser downloads the file.
- **A paddock's whole history.** *View all* beside a paddock's Recent
  activity, which shows its latest 25, opens Activity narrowed to the
  movements in or out of that paddock. A chip at the top names it, and
  removing the chip shows everything again.
- **Settings**, under More on a phone and in the rail elsewhere. Each choice
  is kept on the device and applies at once, and is still there after a
  restart.
- **How long ended stock stays visible.** Stock that is sold, sent to the
  meatworks, dies or is lost leaves its paddock's count at once. Settings
  now sets how long it still shows: 7, 30 or 90 days, a year, always, or a
  custom number of days, weeks, months or years. It is 30 days to begin
  with. Home's totals of what came and went, a paddock's Deaths and Recently
  left, and the Tags list all follow it. Activity always keeps everything.
- **Recently left**, a section on each paddock listing the stock sold, sent to
  the meatworks, lost or otherwise ended from it, beside Deaths. It shows only
  once something has left.
- **A theme choice**: system, light or dark, in Settings.
- **Templates can remember its view.** With *Remember the view* on in
  Settings, as it is to begin with, Group by animal and the sort chosen are
  kept between launches. Turned off, Templates opens grouped by animal in
  custom order, and the view kept so far is forgotten.
- **Tags can be turned off.** With *Use tags* off in Settings, the Tags page
  leaves the navigation, Home drops its Tagged count, an intake stops asking
  for tags and a mob's menu stops offering *Add tags*. Tags already recorded
  are kept: a mob's tags are still asked for when its tagged head moves, and
  a link to a tag still opens it.
- **A default tag type**, NLIS or Other ID, in Settings, for a station whose
  tags are mostly its own.
- **A default movement type.** Settings chooses whether the movement form
  opens on intake, move, age or end. It is move to begin with, as before.
- **A default property.** Recording a movement from Home or Activity starts
  on the property chosen in Settings, rather than asking which. It is chosen
  by searching, by name or PIC, and a clear button beside it goes back to
  *Ask each time*, which is where it starts. The form also asks once that
  property has no paddocks. Recording from a property or paddock always uses
  that one.
- **A default end destination.** Settings chooses the destination the
  movement form's End opens on: the meatworks, as before, or sold, died, lost
  or other.
- **Acres.** Settings shows areas in hectares or acres, on paddock cards and
  pages, and a new paddock's area is entered in the same unit. Areas are
  still stored in hectares, so switching changes nothing recorded.
- **Home**, the page the app now opens on. It shows the head on hand across
  every property, with a count for each animal once there are two, then the
  number of properties, paddocks (and how many are empty), head ready to sell
  and tags in use. Below are the mobs ready to sell and where they stand, a
  card for each property, the head in each class with a bar against the
  largest, what was brought in, sold, sent to the meatworks or died in the
  last 30 days, and the latest movements. Each opens the page it summarises,
  and the head ready to sell scrolls to the mobs. The 30 days are whole days,
  today the last, and move on at midnight even with Home left open.
  *Record movement* is on Home as on Activity. On a new install every section
  is already there, at zero or saying what it will hold, and Properties offers
  to create the first property.

- **The real livestock templates.** Breeder (cows, calves and weaners),
  Backgrounders (steers and heifers), Feeders (steers and heifers) and Fats
  (bullocks and cows) replace the provisional Beef and Dairy lists, in that
  order. Calves age into weaners, and backgrounder steers and heifers into
  feeders.
- **Ready to sell.** Each Feeders and Fats class has a twin for its stock that
  is ready to sell, such as *Steers (Feeders) · ready to sell*. *Mark ready to
  sell* on a mob moves head into the twin without leaving the paddock, and *No
  longer ready to sell* moves them back. Both are kept in the ledger like any
  movement, so what is ready to sell is counted from it, and selling them is
  an ordinary end.
- **Record death on every mob.** It starts at one head, takes the date the
  death was found and a cause or note, and asks for the tags of tagged animals
  as an end does. Each paddock lists its deaths in a Deaths section, which has
  its own *Record death*.
- **Templates can be edited.** Add templates and change their name or
  animal, and add, edit or remove classes: a name, an optional breed and age
  band, the class it ages into, and whether it can be marked ready to sell.
  Nothing with head still in it can be removed until they are moved or aged
  out, and each class shows the head standing in it.
- **Put templates and classes in your own order.** Drag a template's card by
  its handle into another's place, or a class within its card, or move either
  a step at a time from its menu. Grouped by animal, a template moves among
  that animal's. The order sets where mobs sit on a paddock page and where
  classes appear in the movement form, and a ready-to-sell twin moves with its
  class.
- **Each template is for one animal**: cattle, sheep, goats, pigs, horses,
  alpacas, deer, poultry or other. A new template has to be given one, and its
  card shows that animal's icon. So does each mob on a paddock card and a
  paddock page, and each mob and class to choose from when recording a
  movement or editing a class. The four defaults are cattle.
- **Search as you choose.** The property, paddock, mob and class lists in
  Record movement, Record death and Mark ready to sell, and Ages into in the
  class editor, narrow as you type: every word typed must appear in what is
  listed, in any order, so "feed hei" finds Heifers (Feeders). A class or mob
  is found by its animal too, and a property by its PIC. Enter takes the first
  match. Each list shows about seven at a time and scrolls, rather than
  filling the window as a station's paddocks and templates grow. Ages into is
  cleared by emptying it. Short fixed lists, such as where stock ended up,
  are still plain dropdowns.
- **Search, group and sort templates.** The Templates page finds templates by
  their name or by any of their classes, and picks out the words that matched.
  Its cards are grouped under a heading for each animal, which can be turned
  off, and shown in their own order, or sorted by most or fewest head, by name
  either way, or newest or oldest first. Templates can be moved only in their
  own order and while nothing is searched for, as only then is it clear where
  one will land; otherwise a card's handle is greyed out, and says why. They
  sit in a grid, from one column on a phone to four on a wide screen, and the
  cards in a row share one height, so their Add class buttons line up.
- **Wrong values are outlined in red.** In Record movement and Add tags, the
  field at fault turns red: more head than the mob has, a destination that is
  the paddock being left, a class that ages into itself, a tag already
  recorded elsewhere, a typed tag not yet added, more tags than head. A field
  that is only empty stays as it is, so a new form does not open in red.
- **Record movement from Activity.** Activity has the same *Record movement*
  button as an open paddock, shown once some property has a paddock. Opened
  from there, the form asks which property first, and chooses it already when
  only one has paddocks.

- **Tag numbers on movements, for those who want them.** An intake, move, age
  or end state can name the tags of the animals in it: NLIS, as the
  16-character NLIS ID or the 15-digit RFID, or any other identifier. Each tag
  is one of its mob's head and goes where its animal goes. Where a tag is now is
  worked out from the ledger, like head counts, so it cannot drift from the
  history. An intake only adds tags, typed, pasted as a list, or sent by a
  reader that acts as a keyboard. A move, age or end instead lists the mob's
  tags to choose from, with Select all, and a scan or the last few digits of a
  number selects its tag; the list is hidden when the mob has none. Moving a
  whole mob takes its tags with it. When some but not all of a mob's tagged
  animals must be moving, the form asks which before it will record.
- **Tag events.** Animals already standing in a paddock can be tagged from their
  mob on the paddock page. A tag can be replaced (lost, damaged, or recorded in
  error) or cancelled from its own page. None of these changes a head count, and
  each is kept in the ledger like any movement.
- **Licences on the About page.** A *Licences* entry lists the licences of the
  bundled Roboto font, the animal icons and the packages the app uses.
- **Tags screen.** Every tag recorded, searchable by number, with those still on
  the property first. Each tag has its own page and address, showing where it
  is now and everything that has happened to it. Wide windows show the list
  beside the tag.
- Paddock pages say how many of each mob are tagged and list the tags standing
  there.
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

- **Home's "Last 30 days" follows the setting**, and is titled for it, as
  *Last 6 weeks* or *All time*.
- **A paddock's Deaths lists only those within the setting**, still at most
  ten, and says so when there are none, as *No deaths recorded here in the
  last 30 days*.
- **The Tags list leaves out tags whose animal left before the setting's
  start**, and says how many and that a search finds them. A search still
  looks through every tag. Cancelled and replaced tags stay listed. On a
  device upgraded to this version these take effect at the 30-day default;
  choosing Always in Settings shows everything as before.
- **Every page's bar is a breadcrumb trail from Home**, each step led by its
  icon, as in *Home › Properties › Riverbend Downs › North Ridge*. Each step
  before the page is a link back to it. Where the trail is short of room, the
  longest steps before the page shorten first, so the page's own name stays
  whole. On a phone the bar shows the page alone, with a back arrow below a
  destination's top. Tags now shows the trail to a tag, where it showed only
  *Tags* on a wide window.

- **The app opens on Home**, not Properties, and so does an address it doesn't
  know. On a phone the bottom bar holds Home, Properties, Activity, Tags and
  More, every label still whole on a 320 dp screen.

- **Built with Flutter 3.47.9**, up from 3.44.9, locally and in CI.

- **A class is named with its template**, as in *Steers (Feeders)*, since
  Feeders and Backgrounders both have steers. Its age band, now optional,
  follows after a dot. Activity also puts the class after a dot rather than in
  brackets, and an end now says which class left.
- **A mob's actions are in a menu.** Mark ready to sell, Record death and Add
  tags sit behind ⋮ on each mob.
- Navigation is now Properties, Activity, Tags, Templates, About.
- **The phone's navigation bar is Properties, Activity, Tags and More.**
  More lists Templates and About, and shows as selected while either is open.
  With every destination in the bar, the labels had too little room and broke
  mid-word ("Properti/es"). Wider windows still list them all in the rail.
- **Action buttons are a circle on a phone, a pill elsewhere.** Record
  movement, Add property and Add paddock show only their icon on a narrow
  window, so they cover less of the page. Hovering one, or holding a finger on
  it, opens it out to show its label. Wider windows keep the label, on a fully
  rounded button.
- **Every column of Properties keeps its own action button.** With properties,
  paddocks and a paddock side by side, Add property, Add paddock and Record
  movement each sit in the bottom-right corner of their own column, rather than
  only the deepest column's button showing in the corner of the page.
- **One look for every form and dialog.** Record movement, Add tags, new
  property and paddock, Replace tag and Cancel tag all rise from the bottom edge
  and come to rest centred, at the same width, with the title above and Cancel
  beside the main button below. Record movement and Add tags gain that Cancel
  button, having lost the drag handle they were closed by. Where a button is
  disabled, a line above it says what is missing. The new property and paddock
  fields are outlined, like every other field.
- **What stops a form sits above its buttons, not on one.** Record movement
  and Add tags used to put the reason in the main button's label, which kept
  changing width. On a phone the longer reasons stacked the button under
  Cancel, and at 320 dp they ran out of the button. The button now keeps its
  own label.
- **Movement kinds are icons.** The four labels no longer fit the form on a
  phone, so Intake, Move, Age and End are icons alone, named on hover or long
  press. Age is now a clock turning forward rather than a cake, in the form
  and in Activity.
- **Activity names tags.** Entries list the tags a movement carried, each
  linking to its page, and tag events read as what happened to the tags.
- **The local database upgrades itself** the first time this version opens it,
  to make room for tags. Existing properties, paddocks and movements carry over
  untouched, in the browser as on every other target.
- Developer → Data seeds a few tagged animals with the sample farm, and Check
  ledger also reports any mob holding more tags than head.
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

### Removed

- **The theme override on the Developer page**, replaced by the one in
  Settings, which is kept between launches.

- **The provisional Beef and Dairy templates.** Nobody uses the app yet, so
  the first launch of this version replaces them rather than carrying them
  over. Every movement names a class, so the movements and tags recorded
  against them go too. Properties and paddocks stay.

### Fixed

- **Activity reaches every movement.** It listed only the latest 200, with
  no way further back. *Show older movements* at the foot of the list now
  adds 200 more at a time.
- **A paddock's Deaths and Recently left show more on asking.** Each stopped
  at ten, even with ended stock kept always. *Show more* now adds ten at a
  time.
- **Dates are typed day first.** Typing a date into the death form's
  calendar expected month first, the US order, unlike every date the app
  shows. The app now uses Australian English throughout, so the calendar
  takes dd/mm/yyyy.
- **Breadcrumbs no longer jump as they become links.** Opening a property or
  paddock turned the crumb before it into a link and nudged its text sideways;
  every crumb now keeps its place.
- **Linux shows the same font on every machine.** The app now carries Roboto,
  the font Material asks for on Linux, instead of falling back to whatever the
  distro has installed (Ubuntu, Cantarell, DejaVu Sans…). Android and web were
  already in Roboto and look the same; web no longer fetches it from Google
  Fonts. Windows and Apple platforms keep their system fonts.
- **The movement form no longer calls a full list empty.** Before anything was
  chosen, *Mob* read "This paddock is empty" and *To paddock* "No paddocks yet",
  whatever the paddock held. They now read "Choose…", and say a list is empty
  only when it is.
- **A property's action button is *Add paddock*, however many it has.** Once a
  property had one paddock, the button became *Record movement* and adding
  another fell to a bare `+` in the far corner of the app bar, easy to miss.
  *Record movement* now belongs to an open paddock, and the `+` is gone.
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
