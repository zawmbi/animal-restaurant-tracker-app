# App Store Connect listing — paste-ready copy + screenshot plan

Fills in the gap left open at `IOS_RELEASE_HANDOFF.md` §6 ("Still to do: the App
Store Connect listing"). Everything below is written to be pasted into a field as
it stands. Character counts are measured, not estimated.

The whole listing is written around one constraint: **this app is built on
someone else's game.** Animal Restaurant belongs to DH Games. Every choice here
trades a little discoverability for a lot less exposure to (a) an Apple metadata
rejection under guideline 4.1 Copycats / 5.2.1 IP, and (b) a takedown request
from the rights-holder, which Apple honours on receipt and which is much harder
to undo than a rejection.

---

## 1. The one decision that has to be made first: the name

The app's trademark exposure is concentrated almost entirely in the **name**,
because the name is the part Apple's metadata reviewer reads first and the part a
rights-holder's search turns up. The description and screenshots are a much
smaller surface.

| Option | App Store name | Risk | Cost to you |
|---|---|---|---|
| **A (recommended)** | `Chef's Ledger` (13 chars) | Lowest. No third-party mark in any displayed field. | You lose the game's name from the title. Search traffic comes from the keyword field instead, which still indexes. |
| **B** | `Tracker for Animal Restaurant` (29) | Medium. "for X" is the classic nominative-use pattern and lots of companion apps ship with it, but Apple can and does ask for written authorisation from the mark holder, and a takedown request still lands. | None. |
| **C (current)** | `Animal Restaurant Tracker` (25) | Highest. Leads with the mark, reads like a first-party app. This is the shape Apple's 4.1 reviewers flag. | None. |

**If you take A, rename in both places.** The App Store name and the
`CFBundleDisplayName` in `ios/Runner/Info.plist` are separate: the store name can
be changed any time without a rebuild, but the home-screen name is baked into the
binary. Leaving them mismatched means the reviewer installs "Chef's Ledger" and
sees `Animal Restaurant Tracker` on the springboard — which is both a metadata
inconsistency and puts the mark right back in front of them. So renaming means a
**build 9**. Budget for that before you decide.

Everything below is written for option A. If you pick B or C, the description and
screenshots do not change — only the first line of the description gets more
load-bearing.

---

## 2. Paste-ready fields

### Name (30 max)
```
Chef's Ledger
```

### Subtitle (30 max) — 29 chars
```
Unofficial collection tracker
```
"Unofficial" in the subtitle is doing real work. It is the first thing a reviewer
reads after the name, and it is the single cheapest signal that the app is not
passing itself off as first-party.

### Keywords (100 max) — 90 chars
```
animal restaurant,cod,memento,checklist,completionist,idle,cafe,cat,progress,guide,collect
```
Comma-separated, no spaces after commas (a space costs you a character and buys
nothing). Do not repeat words already in the name or subtitle — those are indexed
already and repeating them wastes the field. The keyword field is **not displayed
publicly**, which is why the game's name lives here rather than in the title: it
still earns you the search result, without putting the mark on your store page.

### Promotional text (170 max) — editable without submitting a new build
```
Now tracking every memento, letter, poster and courtyard upgrade, with a percentage-complete view across the lot. Missing something? There's a feedback form in the app.
```

### Description (4000 max) — 1,956 chars
```
Chef's Ledger is an unofficial, fan-made checklist for players of the mobile game Animal Restaurant. It is not a game, and it is not made by or connected to the game's developer. Think of it as the notebook you were already keeping, except it adds itself up.

WHAT IT DOES

Tick off what you've collected. Customers, mementos, letters, posters, recipes, movies, pets, staff and every facility branch, each with its own list and its own running count.

See how far along you actually are. A percentage-complete view across every collection, so you can tell what's finished from what you've barely started.

Find out what finishing costs. Add up the upgrades you have left in a section and see the total before you commit to it.

Plan your income. Work out what your current setup earns per hour and weigh it against whatever you're saving up for.

Set reminders. Local notifications for the long buffet and tip-jar waits, or for anything else you'd rather not keep checking on.

Search everything at once. One box, every list in the app.

Look things up offline. All the reference data ships inside the app, so it works with no connection.

Sync, or don't. Sign in to carry your progress between devices, or tap "Continue without an account" and keep everything on your phone. No ads, no in-app purchases, no accounts required.

HOW IT WORKS

You enter your own progress. The app does not connect to Animal Restaurant, read your save data, automate anything, or change how the game plays. Nothing you tick here touches your game, and nothing in your game shows up here until you put it there.

WHO MADE IT

One person, who plays the game. Animal Restaurant and all related names, characters and content are trademarks and copyright of their respective owner. This app is independent and is not affiliated with, authorised by, sponsored by or endorsed by them.

Something wrong or out of date? There's a feedback form in the app, and it comes straight to me.
```

Deliberate omissions, each of which is a known rejection or takedown trigger — do
not add them back later without re-reading this list:

- No "official", "ultimate", "complete guide", "the only app you need".
- No "cheat", "hack", "mod", "bot", "auto", "unlimited", "free gems/diamonds".
  These read as game manipulation to Apple *and* are what a developer's legal
  team searches for.
- No comparison to other tracker apps, no mention of Android or Google Play, no
  pricing claims, no "beta" or "coming soon" features.
- No use of the game's logo, wordmark, font or colour scheme anywhere in the
  listing art.

### What's New (for version 1.0.0)
```
First release.
```

### Copyright field
```
2026 Linda Mansour
```
Your name, not the game's. This field is asserting who owns *this app*.

### Category
Primary **Reference**, secondary **Utilities**.

Do not file it under Games. It isn't one, and the Games category is where
copycat review is strictest — a checklist app sitting next to the game it tracks
invites exactly the comparison you want to avoid.

### Age rating
4+ on every question. The app has no ads, no purchases, no user-generated
content, and no unrestricted web access — the only outbound links are the privacy
policy and the support page, both opened in Safari.

### Support URL — **required, and you don't have one yet**
`zawmbi.com` has a privacy page but no support page. App Store Connect will not
let you submit without a Support URL, and it must resolve to a real page with a
way to contact you. Cheapest fix: a page at
`https://zawmbi.com/support/chefs-ledger/` with one paragraph and the
`privacy@zawmbi.com` address (or a dedicated `support@`). A mailto: link alone is
not accepted.

### Privacy Policy URL
`https://zawmbi.com/privacy/animal-restaurant-tracker/` — already live and
verified. If you rename the app, leave a 301 rather than moving it; see
`PRIVACY_APP_STORE_NOTES.md` §2 for the two places in App Store Connect it goes.

---

## 3. App Review notes (the "Notes" field under App Review Information)

This field is free text that only the reviewer sees. Filling it in properly is
the single highest-value thing you can do against a 2.1 rejection, because the
app has a sign-in screen and a reviewer who cannot get past one rejects on sight.

```
This app is an unofficial, independently made checklist and reference tool for players of the mobile game Animal Restaurant. It is not affiliated with the game or its developer, it does not connect to the game in any way, and it contains no game code, artwork or assets. All progress in the app is entered by hand by the user. All artwork in the app was drawn for it.

SIGNING IN: an account is not required. On the sign-in screen, tap "Continue without an account" to go straight into the full app with anonymous sign-in. Every feature is available without an account; signing in only syncs progress between devices. If you would prefer a credentialed account instead, please let me know and I will provide one.

The app works fully offline. All reference data is bundled in the build; the only network calls are Firebase authentication (optional), Firestore progress sync (only when signed in), and the in-app feedback form.
```

---

## 4. Screenshots

### Sizes you actually have to produce

- **iPhone 6.9"** — 1290 x 2796. Required. Apple scales this down for smaller
  iPhones, so this is the only iPhone set you need to shoot.
- **iPad 13"** — 2064 x 2752, from the iPad Pro 13-inch (M4) simulator.
  Required because the build ships `UIDeviceFamily = [1, 2]`.

  **Checked on 15 Sep 2026, and the app is fine there.** This was flagged as an
  open decision — shoot the iPad set, or drop iPad with
  `TARGETED_DEVICE_FAMILY = "1"` — because per `IOS_RELEASE_HANDOFF.md` §6
  nobody had ever run it at that width. It was booted and looked at: the app
  launches, the intro plays, the home grid renders and nothing is clipped,
  overlapped or broken. **Keeping iPad support is the cheaper path.**

  The one weakness is density, not correctness: `home_page.dart:288` hardcodes
  `crossAxisCount: 3`, so on a 13" iPad the nav tiles are enormous — a large
  icon, a small label, and a lot of empty tile around both — and only twelve of
  the twenty fit on screen. The collection grids fare better, because they size
  by available width (`(maxWidth / 180)`) and reach four columns there. A
  reviewer will not reject over this; it just looks unconsidered. If you want it
  tighter, the home grid should compute its column count the way the collection
  grids already do.

Six to eight screenshots is plenty; the store shows the first three without
scrolling, so front-load them.

### Before you upload: strip the alpha channel

**Every screenshot the iOS Simulator produces is RGBA, and App Store Connect
will not accept a screenshot with an alpha channel.** It does not tell you.
You drag the file into Media Manager and it vanishes — no error, no red badge,
no row appears. `xcrun simctl io ... screenshot` and Cmd+S both do this.

Check any file with:

```bash
sips -g hasAlpha -g pixelWidth -g pixelHeight shot.png
```

`hasAlpha: yes` means Media Manager will swallow it. Fix the whole batch with:

```bash
python3 scripts/prep_store_screenshots.py ~/Desktop/shots/
```

That writes alpha-free copies into `./store-ready/` and never touches the
originals. Add `--size 1284x2778` to retarget another slot. Screenshots are
fully opaque, so dropping alpha is lossless; the script verifies that and
refuses anything with real transparency rather than flattening it silently.

The same rule is what `IOS_RELEASE_HANDOFF.md` records for the app icon, where
at least the upload fails loudly.

### Which slot, and the sizes that go in it

| Slot | Accepted pixel sizes | Simulator that gives it |
|---|---|---|
| 6.9" iPhone | 1290x2796 or **1320x2868** | iPhone 16 Pro Max |
| 6.5" iPhone | 1242x2688 or 1284x2778 | iPhone 11 Pro Max / 13 Pro Max |
| 13" iPad | 2064x2752 or 2048x2732 | iPad Pro 13" |

Dropping a 1320x2868 file into the **6.5"** slot fails with a dimensions error
naming the 6.5" sizes, which reads as "my screenshots are wrong" when the file
is fine and only the slot is wrong. Apple scales 6.9" shots down to cover
smaller iPhones, so filling 6.9" and leaving 6.5" empty is normally enough.

### The shot list

Shoot these against a **filled-in account**, not a fresh install. Apple rejects
screenshots of empty states under 2.3.3, and an empty checklist app looks
broken. Tick a believable amount — partway through, not 100%.

| # | Page | What to have on screen | Caption |
|---|---|---|---|
| 1 | `home_page.dart` — the nav grid | Scrolled to the top, whole grid of tiles visible | **Every list in one place** |
| 2 | `progress_page.dart` (% Complete) | Several collections at different percentages | **See how far along you really are** |
| 3 | `completion_page.dart` (Cost to Complete) | A section with a non-trivial remaining total | **Know what finishing will cost** |
| 4 | `mementos_page.dart` | The two-column grid, some ticked, some not | **1,184 mementos, all tickable** |
| 5 | `timers_page.dart` | One or two timers running with real end times | **Reminders for the long waits** |
| 6 | `global_search_page.dart` | A query with results from more than one list | **One search across everything** |
| 7 | `bank_page.dart` | An income calculation filled in | **Plan what your setup earns** |

### What must not be in frame

- **No game screenshots, ever.** Not in a collage, not behind a caption, not as
  a "before/after", not blurred in the background. This is the single most
  common way a companion app gets pulled.
- **No game sprites, character art, logo, wordmark or UI.** Your bundled icons
  (`assets/images/` — cod, plate, bell, diamond, film, star) were drawn for this
  app and are fine in frame. `certificate_one.png` is the one that most reads as
  traced from the game; keep it out of the hero shots.
- **Prefer list pages over detail pages.** Detail pages — mementos especially —
  display item descriptions lifted verbatim from the game
  (`"Looks very light, as if there is nothing inside."` and 1,183 others). Those
  strings are the game developer's copy. Reproducing them in the app is a
  defensible companion-app use; blowing one up to 1290px wide as marketing
  material for your own product is a different thing, and it's the frame a
  rights-holder would screenshot back at you. List views show your structure —
  counts, checkboxes, progress — which is your work.
- **Keep the Redemption Codes page out of the screenshots.** 101 live promo
  codes is the most provocative single screen in the app, and putting it on your
  store page advertises it to exactly the person least happy to see it. Leave the
  feature in; just don't lead with it.
- **No device frames with fake content, no award badges, no fabricated review
  quotes, no "#1" claims.** Plain captions over plain app UI.

### Caption rules

Set captions in your own font on a plain background from your own palette. Do
not imitate the game's art style, hand-lettered look or colour scheme — style
imitation plus a matching subject is what "copycat" means under 4.1, and it is
judged on overall impression, not on any single copied element.

Put the word **Unofficial** somewhere in the first screenshot's caption, or as a
small footer line across the set. It costs you nothing and it is the clearest
possible statement of non-affiliation at the moment of first impression.

---

## 5. Adjacent rejection risks, since they'll bite in the same review

Not listing copy, but they surface in the same submission:

1. **The Buy Me a Coffee link** (`support_page.dart:14`) opens an external
   payment page. Guideline 3.1.1 has historically been read as forbidding
   in-app links to outside purchase mechanisms, and tip-jar link-outs have been
   rejected on it. The US-storefront external-link rules have moved recently and
   may now permit it. Check the current text of 3.1.1 before you submit rather
   than trusting either this note or an older memory of the rule — and either
   way, don't feature that screen in a screenshot.

2. **No in-app credit for the wiki.** The bundled data was scraped from the
   Animal Restaurant Fandom wiki (`scraper.py`, `lib/scraping/`). Fandom content
   is CC BY-SA, which asks for attribution. Plain facts — numbers, requirements,
   unlock costs — aren't copyrightable and you owe nothing for them, but a
   credit line is cheap insurance and good manners. One line in Settings:
   *"Reference data compiled from the Animal Restaurant Fandom wiki, CC BY-SA."*

3. **A non-affiliation line inside the app**, not just in the listing. Right now
   `grep` finds no "unofficial" or "not affiliated" text anywhere in `lib/`. It
   belongs on the first screen a user sees and in Settings. A reviewer weighing
   4.1 looks at the app, not only the store page.
