# iOS release handoff

**Last verified:** 15 Sep 2026, on
`claude/animal-restaurant-agents-features-9n8hrx` (the privacy work and the
game-data fixes are committed as of `160959e`).

Goal: get the app onto Linda's iPhone over TestFlight, then to App Store review.
No cable is involved at any point.

---

## Read this first

Three separate agent sessions have worked on this. Each has repeated confident
claims that were false at the time. **Verify against the files before acting.**

Claims that keep resurfacing and are wrong:

| Claim | Reality |
|---|---|
| "Enable Anonymous in Firebase or you can't get past the login screen" | Anonymous, Email/Password, Google and Apple are **all already enabled**. Checked in the console directly, twice. |
| "The app icon is the Flutter placeholder" | Replaced in `c5856a9`, redrawn in `b3a5bcd`. Check the pixels, not your memory. |
| "The appiconset PNGs have baked-in shadows, that violates Apple's layered-icon guidance" | Intentional, see **App icon** below. The rule applies to `.icon` layers, not to a classic bitmap set. |
| "pubspec changed, likely flutter_launcher_icons" | It was `crypto`, for the Apple nonce. `flutter_launcher_icons` is not in this project. |
| "The nonce is the only way past the login screen" | The nonce affects Apple sign-in only. "Continue without an account" calls `signInAnonymously()` and never touches it. |

Re-verify current config in one command:

```bash
python3 - <<'PY'
import plistlib
g=plistlib.load(open("ios/Runner/GoogleService-Info.plist","rb"))
i=plistlib.load(open("ios/Runner/Info.plist","rb"))
print("bundle:", g["BUNDLE_ID"])
print("appId :", g["GOOGLE_APP_ID"])
print("url scheme matches REVERSED_CLIENT_ID:",
      i["CFBundleURLTypes"][0]["CFBundleURLSchemes"][0]==g["REVERSED_CLIENT_ID"])
PY
```

---

## Verified state

**Bundle ID is `com.lindamansour.animalRestaurantTracker`** (was
`com.example.animalRestaurantTracker`). Changed in all 6 configs of
`project.pbxproj`, plus `GoogleService-Info.plist`, the `Info.plist` URL scheme,
and the `ios` block of `firebase_options.dart`.

> The `macos` block of `firebase_options.dart` still points at `com.example`
> **on purpose**. The old Firebase iOS app still exists and macOS is out of
> scope. Do not "fix" it.

**Firebase:** a second iOS app is registered under the new bundle ID.
App ID `1:174067290396:ios:65223b309b6cd417c66ad9`, with its own auto-created
OAuth client. The `REVERSED_CLIENT_ID` and the `Info.plist` URL scheme must stay
in sync — if they drift, Google sign-in fails silently with no error.

**Signing:** `DEVELOPMENT_TEAM=ZQUQB39QGN` and `CODE_SIGN_STYLE=Automatic` in
`ios/Flutter/Debug.xcconfig` and `Release.xcconfig`, alongside
`CODE_SIGN_ENTITLEMENTS`. Deliberately via xcconfig, not pbxproj.
`ios/Runner/Runner.entitlements` declares `com.apple.developer.applesignin`.
A build already succeeded with this entitlement present, so it does not break
archiving.

**Also done:** `ITSAppUsesNonExemptEncryption` set; `PrivacyInfo.xcprivacy`
created and confirmed in the Runner target's Resources build phase (clears
ITMS-91053); Apple Sign In nonce implemented properly
(`sha256(rawNonce)` to Apple, `rawNonce` to Firebase); account deletion in
Settings deleting `users/{uid}` before the auth user (guideline 5.1.1(v));
real launch images replacing three 68-byte transparent pixels.

### App icon

Current artwork is `b3a5bcd`: a round cream cat in a chef's hat on a blue
ground. No plate, no outlines, nothing pointed. Source lives in
`design/appicon/` as three SVG layers (`v8-2-ears`, `v8-3-head`, `v8-4-hat`)
plus the Icon Composer document `AppIcon.icon`.

**The two icon formats are deliberately built differently:**

| Target | Contains | Why |
|---|---|---|
| `design/appicon/AppIcon.icon` | flat layers, no shadows | iOS 26 generates shadow, specular and blur per layer. Baking your own doubles them. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset` | 15 PNGs **with depth baked in** | A classic bitmap set gets no system treatment. Flat here would look flat on every iOS before 26. |

Do not "fix" the appiconset by flattening it, and do not add shadows to the
`.icon` SVGs. To change the artwork, edit the three layer SVGs and re-run the
generation; the Icon Composer document already references them by path.

App icons must have no alpha channel — App Store Connect rejects them. Verify
after any regeneration:

```bash
python3 -c "
from PIL import Image; import os
d='ios/Runner/Assets.xcassets/AppIcon.appiconset'
print([f for f in os.listdir(d) if f.endswith('.png') and Image.open(f'{d}/{f}').mode!='RGB'] or 'all clean')"
```

**The IPA on disk is `1.0.0 (3)`,** built 14 Sep 23:26 and **uploaded to App
Store Connect the same night**. Correct bundle id,
`ITSAppUsesNonExemptEncryption=False`, `UIDeviceFamily = [1, 2]`. It carries the
in-app privacy links and every game-data fix. Build 2 was overwritten in place;
there is no longer a stale IPA to confuse anyone.

---

## Outstanding

### An agent can do these

1. ~~`flutter analyze`~~ **Done, 4 Sep 2026: 0 errors, 0 warnings.** 82 remaining
   issues are all `info` lints (`deprecated_member_use` on `withOpacity` and
   Radio `groupValue`/`onChanged`, `unnecessary_underscores`,
   `use_build_context_synchronously` in `timers_page.dart`). None block a build
   or a submission. The old warning that the nonce fix and the deletion flow had
   "never been compiled" is resolved — both analyze clean.

2. ~~`flutter test` has 14 failures~~ **Fixed, 11 Sep 2026: 194 tests pass, 0
   failures.** All fourteen were real user-facing bugs, not flaky tests — see
   **Game data bugs fixed** below for what changed and what was deliberately
   left alone.

3. ~~Add an in-app link to the privacy policy.~~ **Done.** `login_page.dart`
   and `settings_page.dart` both call `openPrivacyPolicy` from
   `lib/features/shared/utils/legal_links.dart`. Note this landed *after* the
   build 2 IPA was cut, so it is not in the binary on disk.

4. ~~**Build 3.**~~ **Done, 14 Sep 2026.** `flutter build ipa --release
   --build-name=1.0.0 --build-number=3` archived in 5m07s, exit 0, and the
   result uploaded to App Store Connect through Xcode Organizer. Automatic
   signing produced a profile carrying the Sign in with Apple entitlement
   without complaint, so the App ID has that capability enabled.

   The upload returned one warning, which is **not** a problem for this
   submission: *"MinimumOSVersion too low. This app has a MinimumOSVersion of
   13.0. Starting in Spring 2027, all iOS apps must have a MinimumOSVersion of
   15.0 or later."* Deadline, not a rejection. When it matters, the target is in
   exactly one file — three occurrences of `IPHONEOS_DEPLOYMENT_TARGET = 13.0`
   in `ios/Runner.xcodeproj/project.pbxproj`. `ios/Podfile`'s
   `platform :ios` line is commented out, so CocoaPods inherits the project's
   value and needs no edit. Raise all three, `pod install`, rebuild.

5. **Builds since build 3.** Build 3 is the one that was uploaded, on 14 Sep.
   Builds 4, 5 and 7 were archived locally and superseded before upload; build
   6 was cancelled mid-archive when two more commits landed. **Build 8 is the
   one to upload** — it carries the UI pass, the contrast fix, the landscape
   inset, the refreshed changelog and redemption codes, and everything from
   the player review below. The IPA on disk is always whatever was built
   last, so check the version in the Organizer before distributing rather
   than trusting the file's date.

6. **Still to do: the App Store Connect listing.** Screenshots, description,
   keywords, category, age rating, pricing, and a **Support URL** (a required
   field — zawmbi.com has a privacy page but no support page yet). Plus the App
   Privacy questionnaire, whose answers are pre-written in
   `docs/PRIVACY_APP_STORE_NOTES.md` sections 3.3 and 3.4.

   `UIDeviceFamily = [1, 2]` means the build targets iPhone **and iPad**, which
   is Flutter's default rather than a decision anyone made. App Store Connect
   will therefore require a 13" iPad screenshot set, and a reviewer will run the
   app on an iPad. Nothing in this repo suggests the layout has ever been looked
   at at that width. Dropping iPad is `TARGETED_DEVICE_FAMILY = "1"` in the same
   three configs plus a rebuild.

---

### UI pass, 15 Sep 2026

A read-only layout audit ran over every collection and detail page, measuring
against a 390x844 iPhone. The agent that did it is committed as
`.claude/agents/ui-density.md` and is available as a subagent type in a fresh
session; it has to back every finding with arithmetic or a named widget, and
is barred from reporting colour, font or wording preferences.

**Fixed.**

- **The grid divisor, in five files.** `(maxWidth / 200).floor().clamp(1, 4)`
  needs a 200pt tile before it allows two columns, and a phone offers 366-390,
  so recipes, customers, booth owners and staff each rendered one column of
  two-thirds-empty rows. 180 now: two columns at 390pt, four on an iPad, one
  on a 320pt SE. Recipes drop from 17,144pt of scroll to 8,568. Facilities
  needed 160 rather than 180, because its grid sits inside two levels of
  padding and sees 350pt.
- **Letters** was a `Wrap` of 257 chips each sized to its own label; names
  average 21 characters, so it packed about 1.2 chips per row. Now a real
  two-column grid, built lazily rather than laying out all 257 on every
  keystroke.
- **Per-row waste**: mementos 80pt -> 68pt over 1,184 rows, courtyard
  descriptions 3 lines -> 1 over a 477-row group, pet subtitles that all
  wrapped into the 88pt three-line tile.
- **The facilities theme rail** went the way of the courtyard one. At 120pt it
  held 31% of the screen, and the grid behind it had 229pt — less than two
  tiles wide however the column count is computed, which is why that grid
  could never widen.
- **321 lines of unreachable `FacilitiesPage`** deleted from
  `facility_detail_page.dart`. Both real callers resolve from
  `facilities_page.dart`; every importer was checked. The dead copy carried
  drifted versions of the same layout bugs, so it was a trap.
- **Contrast.** `kGreen #9EBD7A` was `colorScheme.primary`, which is what
  Flutter paints text button labels, tab labels, links and selected chips in:
  1.91:1 on the cream background, 1.45:1 on a card, against 4.5:1. It was also
  the checkbox fill, so a white tick on a checked box was 2.1:1 — invisible,
  in an app for ticking things off. `kGreenDeep #495F2F` is the same hue and
  saturation darkened, at 6.47:1. `test/theme/contrast_test.dart` computes the
  real WCAG ratios from the themes, so re-lightening the palette fails there.
  The dark theme was already fine and is untouched.
- **Cross-page checked state.** A chip now shows a border, a tick and a 10%
  tint when the thing it points at is already ticked off elsewhere. Three
  copies of an off-palette `Colors.green.withOpacity(0.18)` went with it.

**Found and deliberately not done** — these are real, measured, and each needs
a decision rather than a constant:

- `mementos_page.dart` is a flat 1,184-row list, 94,720pt with no sections, no
  sticky headers and no scrollbar; the only jump affordance is item 0, which
  scrolls away. Entries carry `source`, `customerName` and `event`, so
  grouping is available whenever someone picks one.
- `dishes_page.dart` renders 532 tiles for 268 recipes: 264 of them appear
  both in "All Recipes" and in a category section.
- `dishes_page.dart` and `facilities_page.dart` both nest a `shrinkWrap` grid
  with `NeverScrollableScrollPhysics` inside an outer scrollable, which
  defeats culling — an expanded section lays out every tile at once, and the
  whole body sits under an `AnimatedBuilder`, so one checkbox tap rebuilds all
  of them.
- `staff_detail_page.dart` builds ~8,770pt eagerly for `dori` (71 bordered
  boxes) and auto-expands the player's current raise level without scrolling
  to it, so the row it went out of its way to open is two screens down.
- Detail pages stack one-word facts down a 314-358pt line: a performer's
  customer page spends 336pt — 45% of the fold — on six of them.
- The Open Air Cinema "Check all acts" / "Clear all acts" buttons duplicate
  the row's own checkbox. **Left alone on purpose**: this file already records
  keeping them as a deliberate decision.

---

### Player review, 15 Sep 2026

Five agents played the app as five kinds of player — completionist, economy
optimiser, collector, event chaser, and a two-week-old beginner — each reading
the wiki and the source. The agent is committed as
`.claude/agents/player-persona.md`. Every finding below was verified against
the code before being acted on; the reports were right about all of them, and
wrong about a couple of details noted in passing.

**Fixed, worst first.**

- **Signing in erased guest progress.** The app launches into guest mode, so
  that is how it is normally used. Progress is namespaced per profile, and
  `attachUser` switched the namespace to the Firebase uid and read keys that
  did not exist. You saw zero — and since a new account has no cloud document,
  the sync that followed would have uploaded that empty state as the account's
  starting point. The guest keys were never deleted so it was recoverable by
  signing out, but nothing said so.
- **Search checkboxes did not redraw.** Both search lists wrote to the store
  with nothing listening. The tick appeared not to work, on the one path that
  lets someone check something off without knowing its category.
- **The home search filed courtyard facilities in a dead bucket** — 1,871 of
  4,064 — and it looked fine because the checkbox read back the same wrong
  bucket.
- **Redemption codes were 185 days stale**, leaving exactly one active code,
  the permanent one, whose checkbox is disabled. `scrape_redemption_codes.py`
  now regenerates them: 101 codes, three live today.
- **Cost to Complete** read one bucket for all nine facility areas, so 1,871
  could never read as owned and their price — all of the film cost — stayed in
  Remaining forever.
- **The mementos list reset to the top on every tick**, because its future was
  rebuilt inside `build()`. `MementosIndex` also never cached, so each call
  re-read both assets and re-allocated all 1,184 entries.
- **Eleven performers lost their band**: their rows spell the performer block
  flat. Puff Planet showed 1 of 4 members; two other bands showed none.
- **149 of 155 posters could not be ticked.** There is a Posters page now.
- **Battle passes you never played** put 573 unreachable tiers into the
  denominator. A pass counts once you tick "I took part in this pass".
- **A Missing / Owned / All filter** on the big lists, and memento
  requirements shown inline on the customer page.
- **"What should I buy next"** is answerable: `BankService.bestValue()` joins
  income to price and ranks unowned facilities by return per cod.

**Open, and each needs a decision rather than a patch.**

- **No event calendar.** `updates.json` is the only dated data in the app and
  it is treated as prose, though 29 change lines carry machine-parseable date
  ranges. The event chaser wanted this most; it is a feature, not a fix.
- **Timers cap at 99 hours and do not survive a restart**, while the
  deadlines that matter run 15-65 days.
- **Settings' "Synced Versions" hardcodes v11.15.0g** and presents v11.16.0 as
  upcoming; it shipped in March. The right value is `updates.json[0]`.
- **The Aromatic Acorn data is an annual cycle behind** — the 2nd Annual
  Judgings added in v11.22.0g are missing, 4 stages.
- **Stale content generally** — see `docs/data-freshness-report.md`. The
  scrapers write into a gitignored directory, so refreshing needs the pipeline
  fixed first.

---

### App Store Connect records — read before touching one

Getting build 3 uploaded cost four failed attempts, all on the app record rather
than the build. What was learned, so nobody repeats it:

**Do not let Xcode create the app record** from Distribute App. It prefills
**Name** with the Xcode target name, `Runner`, and App Store names are globally
unique across the entire store, so it fails with *"App Record Creation failed
due to request containing an attribute already in use"*. The message blames the
App Name; it is easy to misread as a bundle-id conflict. Create the record at
**App Store Connect -> Apps -> + -> New App** instead, where the bundle id is a
dropdown and the name is checked as you type.

**Never delete an app record to start over.** A removed record keeps its bundle
id — the id does not return to the pool — so afterwards Xcode can neither see
the old record nor create a new one, and fails with *"App record with bundle
identifier … was previously removed … Go to App Store Connect to restore the
app."* Recovery is **Apps -> the ••• button beside the + -> Removed Apps ->
Restore**. Everything wrong on a record (name, SKU, primary language, even the
bundle id) is editable in place until the first build is uploaded, which is
always cheaper than deleting.

**Two records cannot share a bundle id.** If a stray record is holding the one
you need, move that record to a different bundle id or delete it *before*
setting the id on the record you are keeping — the dropdown will not offer a
claimed id.

---

### Only Linda can do these — do not attempt, ask her

Anything needing Apple credentials: registering the App ID, the Sign in with
Apple capability, the App Store Connect record, app-specific passwords,
Transporter uploads, TestFlight. An agent should tell her exactly what to click,
then stop.

---

## Game data bugs fixed, 11 Sep 2026

`flutter test` went from 14 failures to 194 passing. Every failure was a real
bug a player would hit, so each was fixed in the app or the data rather than by
relaxing the test. Grouped by what a player would have seen:

**Progress that was tracked wrongly**

- **Six facility ids were shared by two different facilities.** Ticking the
  restaurant's "Star Gazing" also ticked the terrace telescope, because both
  were `star_gazing` in one `facility` bucket — and the denominator counted the
  pair once. All six are area-qualified now (`star_gazing_restaurant` /
  `star_gazing_terrace`, and the same for `christmas_long_table`,
  `christmas_tree`, `gift_teddy_bear`, `planetary_orbit`, `jingle_bell_door`).
  `income.json` keyed both facilities' income under the one slug too, so each
  row was credited with the other's earnings; those six entries are split by
  channel (2,788 -> 2,794 facility income keys).
- **535 facilities existed but no screen showed them.** The concert and pet-yard
  shards were loaded — global search found them — but no page rendered them and
  no category counted them. The Courtyard page now has Courtyard / Concert /
  Pet Yard scene tabs, and all three count into `courtyard_facility_purchased`.
- **Ticking a courtyard facility from global search went into the wrong
  bucket.** Search wrote `facility` for every facility hit; courtyard-family
  facilities live in `courtyard_facility_purchased`, so the tick was invisible
  to the Courtyard page and to the percentage. `ProgressTypes.facilityBucketFor`
  is now the one place that decides, used by search and by the shared
  `FacilityDetailPage` (which is reached from customers, the battle pass and
  redemption codes, so it can be showing any area).

**Things that dead-ended when tapped**

- **40 of the 91 redemption codes could not be ticked off.** 38 of them gift a
  facility, and the page looked every gift up in the memento index only, so they
  rendered as plain text with a dead checkbox. The model now keeps `giftKind`
  and `giftRefId` and resolves against both registries.
- **Three staff wearable mementos pointed at ids that do not exist**
  (`sunflower_memento`, `witch_hat`, `crab_memento`). Each target was confirmed
  three ways — the memento's `equips` names that exact staff member, its
  `earnedStars` matches the staff row, and its source matches the row's
  requirement text — and `staff.json` now uses the real ids.
- **Two customer requirement chips opened "Facility not found"** and two letter
  chips did nothing. Requirement chips are resolved before they are drawn now:
  one that resolves shows the entity's real name and opens it, one that does not
  stays as plain text. `deer`'s `star_rating_board` was dropped from the data
  outright — it is the wiki's way of writing the rating requirement, which
  `requirements.rating` already carries.

**Things that displayed the wrong text or nothing at all**

- **The Dress-Up tab was permanently empty.** It filtered on `dress_up` /
  `wearable` tags that no memento has ever carried, while 553 mementos say in
  `equips` exactly which staff can wear them. The tab, the detail page and the
  list subtitle all read `equips` now, and the Dress-Up section says who can
  wear the item.
- **The "hidden" filter chip matched nothing** — hidden is a top-level field,
  not a tag, so the chip filtered 1,184 mementos down to zero. The chip is gone;
  the Hidden dropdown beside it reads the real field.
- **60 of the 61 performers showed a blank show and the wrong currency.** Their
  `performer` blocks were stubs — null duration, null amount, `film` hardcoded
  even for the cod performers — while `performer_income.json` had every number.
  The blocks are backfilled, and a test now holds the two files to the same
  numbers.
- **Ten battle pass rewards read "Info".** The film-fragment rewards parse as
  `movie` now, resolve to '<film> — Act <n>' and open the film.
- **49 battle pass rewards were typed as the wrong kind** — 35 mementos typed
  as facilities and 14 facilities typed as mementos — so their chips answered
  a tap with "Facility not found". Each id resolves in exactly one registry, so
  the correct type was not a judgement call; `scripts/qa_refs.py` now reports
  0 unresolved memento rewards. 35 facility rewards name event items that are
  in no shard at all (`cresting_waves_long`, `flowering_vine_chair`, …); those
  chips are no longer tappable, and adding them needs the wiki.
- **Staff pages titleized memento ids**, printing "Blueberries And Cream Hat"
  and "Artists Wig". They read the real name from the registry now.

**Deliberately left alone — do not "fix" these without new information**

- `sleepy_little_bear` is listed as one of Meow's wearables and is also a
  Fantastical Party reward, where it is typed as a **facility**. It is in neither
  registry. Rather than invent a memento row, that one staff row renders
  untappable. Resolving it needs a look at the wiki, not a guess.
- Two redemption codes are marked `giftKind: "unresolved"` in the data:
  `MOONFESTIVAL -> osmanthus_hanging_ornament` (in no registry) and
  `SWEETLOVEAR -> gift_teddy_bear_2` (ambiguous between a free courtyard item
  and a 9.5M terrace one). Both stay untappable. A test pins that there are
  exactly two, so a third will be noticed.
- `gloomy` needs a Halloween invitation letter and Halloween decorations, and
  `white_shiba` an intro letter; none of the three exists in the registries.
  They render as plain text, which still tells the player what is needed.

### "Check all" is undoable

Ticking a few things by hand, then tapping "Check all", then tapping again used
to wipe the hand-ticked ones along with everything else. The button now
remembers what was checked immediately before a "Check all" and offers **"Undo
check all"**, which puts the group back exactly as it was. The label only
changes when there is something to preserve — with nothing checked beforehand
it still reads "Uncheck all" and still asks before clearing a large group.

The memory is deliberately narrow. It is dropped when the player edits the
group by hand, when the group's ids change under the button (the Courtyard page
swapping tabs), and when the page is left, because after any of those "how it
was" no longer means anything the player would recognise — and in each case the
label goes back to "Uncheck all", which is then the truth.

Eight pages hand-rolled their own copy of this button and are now on the shared
`CheckAllButton`: dishes, letters, customers, booth owners, mementos,
facilities, courtyard and the pets page. They gain the confirmation dialog and
the single-write behaviour too. Two controls are deliberately not converted:
the Open Air Cinema pages have separate "Check all acts" / "Clear all acts"
buttons that already say exactly what they do, and the Aromatic Acorn stage
page's toggle is a stage-level "complete / in progress" flag rather than a list
header.

**Checker notes.** `python3 scripts/qa_refs.py` still reports two things that
are not bugs. "38 mis-slotted" redemption gifts means a facility id sits in a
field named `giftMementoId` — the field name is legacy, the app reads
`giftRefId` first and branches on `giftKind`, and the data is self-consistent.
The unresolved flower item reward `rose` is display-only text ("1x rose"), not
a link, and the flower data has `red_rose` and `white_rose` with nothing saying
which one is meant.

**Note on saved progress.** Renaming those six facility ids changes their
progress keys. Anyone who had already ticked one of them loses that single tick.
Pre-release this is cheap; after a public build it would need a migration.

---

## Known risks

- **The bundle ID freezes** the moment a build reaches a public track. It is
  right now still cheap to change; after that it is not.
- The **old** `com.example` OAuth client was flagged by Google for deletion after
  6 months idle. Irrelevant to the new client, but do not resurrect the old ID.
- ~~`flutter analyze` has never passed~~ — it passes clean as of 4 Sep 2026.
- ~~**Firestore security rules were never in this repo**, and nobody has
  confirmed what the live console rules say~~ — **the live rules were read
  directly from the console on 14 Sep 2026 and they are correct.** The project
  is *not* in test mode and never silently sat there: the starred (live) version
  is `Jan 7, 2026 6:39 AM`, which restricts `users/{userId}` to
  `request.auth.uid == userId`. The test-mode default below it
  (`Jan 7, 2026 5:40 AM`, `allow read, write: if request.time < timestamp.date(2026, 2, 6)`)
  was replaced within the hour, a month before its expiry. No user's progress
  document has been readable by another client. See **Privacy and data** below
  for the one remaining difference from the repo file.

## Privacy and data

Added 4 Sep 2026 alongside `docs/PRIVACY_POLICY.md` and
`docs/PRIVACY_APP_STORE_NOTES.md`.

**Apple sign-in requests `email` only.** The `fullName` scope was requested but
the returned name was never read or stored, so it was removed from
`auth_service.dart`. Do not re-add it without also adding a Name row to the App
Privacy questionnaire and the privacy manifest.

**`ios/Runner/PrivacyInfo.xcprivacy` declares three data types** — Email Address,
User ID, Other User Content (the feedback message) — all linked, none tracking,
plus `UserDefaults` reason `CA92.1`. These three must stay identical to the App
Privacy questionnaire answers in `docs/PRIVACY_APP_STORE_NOTES.md` section 3;
reviewers compare them.

**`firestore.rules` is deployed as of 14 Sep 2026.** The repo is now the source
of truth: `firebase deploy --only firestore:rules` compiled and released the
file to `cloud.firestore`. The rules it replaced already enforced the same
isolation, so this changed nothing a user can observe — what it added is the
explicit

```
match /{document=**} { allow read, write: if false; }
```

which is documentation rather than enforcement (Firestore denies by default),
but it means a newly added collection has to be granted access deliberately
rather than by forgetting to. Section 11 of the published policy was already
true before this deploy and remains true after it.

**Deploying needs `ljmansour02@gmail.com`, not the CLI's default account.** The
Firebase project belongs to `ljmansour02@gmail.com`. If the CLI is
authenticated as `thesituationmonitoring@gmail.com` — whose
`firebase projects:list` shows only `monitr-39bcd` — the deploy dies with

```
403 … Caller does not have required permission to use project ar-progress-tracker-1b3d8
```

which reads like a missing IAM role but is really the wrong identity. Both
accounts are registered with the CLI, so name the right one:

```bash
firebase deploy --only firestore:rules \
  --project ar-progress-tracker-1b3d8 --account ljmansour02@gmail.com
```

`firebase login:add` cannot be run through an agent or with Claude Code's `!`
prefix — it needs a browser handshake and fails with *"Cannot run login:add in
non-interactive mode"*. Run it in a real terminal.

Live rules at
<https://console.firebase.google.com/project/ar-progress-tracker-1b3d8/firestore/rules>.

## Environment notes

Agents working through the desktop app's Linux sandbox could not delete files in
this folder, so every `git` write left a stale `.git/*.lock` that broke the next
command. If you see *"Another git process seems to be running"*:

```bash
find .git -name "*.lock" -delete
```

This does not happen when git runs natively in Terminal.
