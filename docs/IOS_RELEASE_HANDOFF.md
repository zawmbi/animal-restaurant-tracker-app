# iOS release handoff

**Last verified:** 11 Sep 2026, on
`claude/animal-restaurant-agents-features-9n8hrx` (working tree dirty — privacy
work and the game-data fixes uncommitted).

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

**The IPA on disk is `1.0.0 (2)`,** built 3 Sep 16:43 under the correct bundle
id with `ITSAppUsesNonExemptEncryption=False`. It is not stale in the way this
file used to warn about — but it predates the in-app privacy links (7 Sep) and
every game-data fix (11 Sep), so it is not the build to ship. See Outstanding
item 4.

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

4. **Build 3.** Build 2 exists on disk (`build/ios/ipa/`, 3 Sep, correct bundle
   id, `1.0.0 (2)`) but predates both the privacy links and every game-data fix
   below, so it must not be the build that ships:
   ```bash
   flutter build ipa --release --build-name=1.0.0 --build-number=3
   ```
   Signing will want the new bundle ID. If automatic provisioning fails on the
   Sign in with Apple capability, say so — do not silently drop the entitlement
   to get a green build.

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
- **Firestore security rules were never in this repo.** `firestore.rules` now
  exists and is wired into `firebase.json`, but writing the file changes nothing
  until it is deployed, and nobody has confirmed what the live console rules
  actually say. If the project is still on test-mode rules, every user's progress
  document is readable by any authenticated client, and those rules expire on a
  date after which sync silently breaks. See **Privacy and data** below.

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

**`firestore.rules` is new and undeployed.** It restricts `users/{uid}` to
`request.auth.uid == uid` and denies everything else. Section 11 of the published
policy tells users this is true, so it needs to actually be deployed:

```bash
firebase deploy --only firestore:rules
```

Check the live rules first at
<https://console.firebase.google.com/project/ar-progress-tracker-1b3d8/firestore/rules>
— if they read `allow read, write: if request.time < timestamp.date(...)`, the
project is in test mode and this is urgent rather than routine.

## Environment notes

Agents working through the desktop app's Linux sandbox could not delete files in
this folder, so every `git` write left a stale `.git/*.lock` that broke the next
command. If you see *"Another git process seems to be running"*:

```bash
find .git -name "*.lock" -delete
```

This does not happen when git runs natively in Terminal.
