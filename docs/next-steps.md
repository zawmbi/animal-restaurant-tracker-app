# Next steps

Written 2026-08-29, after the three-agent pass on branch
`claude/animal-restaurant-agents-features-9n8hrx`.

---

## 0. Nothing here has ever been compiled

**There is no Flutter or Dart toolchain in the container this work was done in.**
`which flutter` and `which dart` both fail. No line of this branch has been through
`flutter analyze`, `dart format`, `flutter test` or `flutter run`. Not once.

What that means concretely: 33 Dart files were changed by hand
(+2,920 / −444 lines of Dart), including two entirely new features
(`completion/` — 953 new lines — and `shared/widgets/check_all_button.dart`),
verified only by re-reading and grepping. Type errors, null-safety errors,
missing `const`, wrong named arguments, lint failures — none of that class of
problem could have been caught. **Expect real findings on the first analyze run.**
Plan for a debugging session, not a smoke test.

One correction to how this was described to me: the headline "~30,000 lines across
~50 files" overstates the hand-written risk. The real shape is 73 files,
47,458 insertions — but 42,801 of those are regenerated JSON in `assets/data/`
and 1,069 are new Python scrapers. The Dart surface is ~2,900 added lines. Still
unverified, but a smaller blast radius than the raw number suggests.

---

## 1. Verify before you trust

```bash
cd /home/user/animal-restaurant-tracker-app
flutter pub get
flutter analyze          # ← the real gate. Do not skip to `run`.
flutter test             # there is no test/ directory yet; this will no-op
python3 scripts/validate_data.py   # currently passes, see §3
flutter run
```

`flutter analyze` first, alone, before anything else. `analysis_options.yaml`
includes `flutter_lints`, so expect noise as well as real errors — read the
errors, then decide about the infos.

### What to click through, in order of how likely it is to be broken

1. **Home → "% Complete"** (new nav tile, `home_page.dart:319`). This is the
   single largest piece of never-run code. It builds a catalogue of ~6,850 ids
   across 13 categories at first open. If any repository throws, `_guard()`
   catches it and shows that row as unavailable rather than failing the page —
   so **check that no row says "unavailable"**. A silently-degraded row is the
   likely failure mode, not a crash.
2. **Expand the Mementos row on that page and use a per-source "Check all".**
   `CheckAllButton` is new, and the Signature Store subgroup alone is 261 ids
   in one `setManyUnlocked` write. Then force-quit and relaunch to confirm the
   writes actually persisted — the whole point of the `_defaultTypes` fix.
3. **Mementos page → tabs and filter chips.** The list is now 1184 entries, up
   from 8. Two things are wrong here, see §2.4 and §2.5.
4. **Open a memento detail page for something with a structured requirement** —
   e.g. any Signature Store memento, or anything whose `requirement` text says
   "Serve … N times". `mementos_detail_page.dart` gained ~400 lines of new
   requirement-rendering that reads `assets/data/mementos.json` directly. Try
   one with a `serve` block, one with `sell`, one with only `other` residue,
   and one poster memento (no `requirements` block at all — must fall back to
   free text).
5. **Every page whose repository was rewritten**: Customers, Booth Owners,
   Posters, Letters, Movies, Staff, Pets, Dishes, Facilities, Courtyard,
   Battle Pass. All 11 switched from caching-the-value to caching-the-future.
   Open each once, hit a checkbox, back out, re-enter. Courtyard especially —
   its three list queries are now memoised.
6. **Global search** (`SearchIndex` was rewritten). Type a query fast; results
   should be identical to before, ordered customers → letters → dishes →
   facilities → mementos.
7. **Aromatic Acorn → stages 3, 4, 6, 7.** These are the four pages that hit
   the broken image in §2.1.

---

## 2. Known open bugs

All of these I verified against the working tree, not the reports.

### 2.1 `memento.png` does not exist and `RewardIcon` has no `errorBuilder`

`lib/features/shared/widgets/reward_icon.dart:18` declares
`assets/images/memento.png`; `ls assets/images/` shows only
`bell, certificate_one, cod, diamond, film, like, plate, star`. Line 43–48
builds `Image.asset(asset, …)` with no `errorBuilder`, so the missing asset
throws inside the image pipeline: red error box in debug, logged exception and
an empty box in release.

**Scope is much smaller than I was told.** `RewardIcon` is referenced from
exactly one place — `aromatic_acorn_stage_detail_page.dart:146` — not from the
mementos feature at all. The trigger is `_assetFor`'s catch-all branch (line 27:
text containing `memento`/`spatula`/`dish`/`barrette`/`recipes`), which fires on
four reward strings in `aromatic_acorn_data.dart`: `'Golden Spatula'` (stage 3),
`'Kitty Dish'` (stage 4), `'Glorious Barrette'` (stage 6),
`'Mew-chelin Recipes'` (stage 7). So: four broken icons on four stage detail
pages of one minor feature. Not a crash, and not "under the app's largest
category" — that framing was wrong.

**Fix** (one line, do it anyway — it is free):

```dart
// reward_icon.dart:43
return Image.asset(asset, width: size, height: size, fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => Icon(Icons.card_giftcard, size: size));
```

Then either ship a `memento.png` or point `mementoPng` at `star.png`.

**The related claims about `promote.png` / `gachapon.png` / `diamonds.png` are
false alarms.** I checked all 27 `Image.asset` call sites:

* `movies_page.dart:64` and `movies_detail_page.dart:70` — the
  `assets/images/$currencyKey.png` fallback **does** have
  `errorBuilder: (_, __, ___) => const SizedBox.shrink()`.
* `dish_detail_page.dart:541` `_currencyIcon` falls back to `cod.png`, which
  exists. No unresolved path is reachable.
* `battle_pass_detail_page.dart:453/462` (`gachapon.png`, `promote.png`) both
  have `errorBuilder`s falling back to `Icons.casino` / `Icons.campaign`.
* `facility_detail_page.dart:572`, `facilities_page.dart:665`,
  `staff_detail_page.dart:750` all have `errorBuilder`s.

`reward_icon.dart` is the only unguarded one in the app.

### 2.2 Deleting `bells.png` broke 8 facility price rows — the perf report is wrong here

`docs/performance-report.md` claims `bells.png` "is not referenced anywhere".
It was. `lib/features/facilities/model/facility.dart:13-17`:

```dart
String get assetPath => 'assets/images/${key}.png';   // key == describeEnum(this)
```

`MoneyCurrency.bells.key` is `'bells'`, so this resolved to
`assets/images/bells.png` — which existed, byte-identical to `bell.png` — and is
consumed at `facilities_page.dart:666`. There are 8 facility prices denominated
in `bells` across the shards. Those now fall through the `errorBuilder` to a
generic `Icons.attach_money`.

Cosmetic and tiny, but it means the "unreferenced, safe to delete" verification
in that report missed a whole class of call site (dynamically constructed
paths). Worth knowing before you trust its other deletion claims.

**Fix**: make `MoneyCurrencyIcon.assetPath` in `facility.dart` a real switch
mapping `bells→bell`, `plates→plate`, `diamonds→diamond` (the plural forms for
plates and diamonds were *already* broken before this branch — 84 and 409
prices respectively have been showing `attach_money` all along).

While you are in there: `lib/features/economy/model/currency.dart:19` returns
the literal string `'imagescod.png'` (missing slash), and lines 21–29 return
`'images/…'` with no `assets/` prefix. That whole extension is dead — nothing
imports it, `facility.dart` declares its own duplicate `MoneyCurrency` enum —
so delete the file rather than fix it.

### 2.3 `mementos_page.dart` has one global "Check all" over 1184 items

`lib/features/mementos/ui/mementos_page.dart:128-137` renders a bare
`TextButton` as row 0 of the list that calls
`store.setManyUnlocked('memento_collected', ids, !allChecked)` where `ids` is
every currently-filtered memento — up to 1184 on the ALL tab, with no
confirmation. `CheckAllButton` (`shared/widgets/check_all_button.dart`) already
does exactly this plus a confirmation dialog above `confirmThreshold: 10`, and
is already wired into 9 other pages. Drop it in, and add per-source groups the
way `progress_page.dart:_subgroupRow` does — `MementoEntry.source` is populated
on 1183 of 1184 entries, so grouping is free.

### 2.4 The "Dress-Up" tab is now permanently empty — regression from this branch

Not in either report. `mementos_page.dart:101` decides dress-up membership by
`tags.contains('dress_up') || tags.contains('wearable')`. In the regenerated
`mementos.json`, **zero of 1184 entries carry either tag** (I counted). The old
8-entry file had them on `golden_ponytail`; the regenerated entry for that same
memento now has `tags: ["redemption_code", "mysterious_bird_nest"]`.

The wearables data is still there — 553 entries carry an `equips` array of staff
ids — but `MementoEntry` does not expose `equips`, so the page cannot see it.
Fix either by re-tagging in the scraper or by adding `equips` to `MementoEntry`
and switching the tab predicate to `equips.isNotEmpty`.

Same root cause: the `'hidden'` filter chip (`mementos_page.dart:26`) filters by
*tag*, and no entry has a `hidden` tag — 286 entries have a top-level
`"hidden": true` field instead. The chip is dead; the "Hidden only" dropdown
next to it works. Remove the chip.

### 2.5 `MementoEntry` has no `requirements` field, so the detail page reads JSON directly

`lib/features/mementos/data/mementos_index.dart:7-35` — `MementoEntry` exposes
`key, id, name, earnedStars, requirement, description, customerId,
customerName, tags, hidden, source, event`. It does not expose `requirements`,
`equips`, `posterId`, `shareReward` or `equipsNote`, all of which now exist in
the data (1073 / 553 / 111 / 55 / 76 entries respectively).

`mementos_detail_page.dart:28-47` works around this with its own
`_readMementoRequirements()` that re-reads `assets/data/mementos.json` through
`JsonLoader` and builds a second `id → requirements` map. It is cached and
correct, but it is a parallel loading path that will drift. Add the fields to
`MementoEntry` and delete the workaround.

**Related and worse**: `MementosIndex.all()` has no cache at all. It re-reads
both assets, rebuilds a 613-entry customer map and re-allocates 1184
`MementoEntry` objects on **every call** — and `mementos_page.dart:56` calls it
from inside `FutureBuilder` inside `AnimatedBuilder(animation: store)`, i.e.
once per checkbox tap. This was survivable at 8 mementos. At 1184 it is the
worst hot path in the app. The perf report flagged it (item 7 under "Not done")
but could not fix it — file ownership. Fix it: cache the built list, filter over
the cache.

### 2.6 Concert (232) and pet (303) facilities are tracked by nothing

`completion_service.dart:346-356` — `_facilityScenes` lists six areas
(restaurant, kitchen, garden, buffet, takeout, terrace) and deliberately
excludes courtyard, which `_courtyard()` counts separately from its own bucket.
But `FacilityArea.courtyard_concert` and `FacilityArea.courtyard_pets` are
counted by neither, and grepping `lib/` shows the only references to them are
the enum declaration, `parseFacilityArea`, and the shard paths in
`facilities_repository.dart:39-44`. **No page displays them.** So
`concert_facilities.json` (232 items) and `pets_facilities.json` (303 items) —
535 collectibles, 7% of everything in the game — are shipped in the bundle, load
into memory via `FacilitiesRepository.all()`, and are invisible and untrackable.

That is honest as far as the percentage goes (you cannot check them off, so
counting them would peg the ceiling below 100%), but it is a real product gap.
See §5.

### 2.7 `main.dart` does not pass `extraTypes`; the invariant is unenforced

`main.dart:32` calls `UnlockedStore.instance.init()` with no arguments. The
progress-loss fix works by having hard-coded the 13 real bucket names into
`UnlockedStore._defaultTypes` (`unlocked_store.dart:34-58`) instead. Meanwhile
`ProgressTypes.registerOnStartup` (`progress_types.dart:36-50`) lists the same
13 names again, and is consumed only by `completion_service.dart:166`.

So the same list exists twice, in two files, with a comment in each telling you
to keep them in sync, and **nothing checks**. If a new page introduces a bucket
and only one list is updated, progress in that bucket silently vanishes on
restart — exactly the bug that was just fixed. See §4.2.

**Cheapest structural fix**: delete the extra names from `_defaultTypes`, and
make `main.dart` do
`UnlockedStore.instance.init(extraTypes: ProgressTypes.registerOnStartup)`.
One list, one owner. `init()` already accepts it (`unlocked_store.dart:79`).

### 2.8 Bucket rename in `home_page` orphans old search-page checkmarks

`home_page.dart` diff: search-result checkboxes wrote to `'customer'` and
`'facility_purchased'`; they now write to `'customers'` and `'facility'`,
matching what the actual pages use. Correct fix. But any box you ticked *from
the search results list* before this branch is stranded in the old buckets —
still loaded (both legacy names are still in `_defaultTypes`) and never read.
If you used that path, you will see those items unchecked. A one-off migration
in `UnlockedStore.init` that unions `customer` into `customers` and
`facility_purchased` into `facility` would recover them. Judge whether it is
worth it.

### 2.9 Carried forward from the reports (I confirmed these are still open)

From `docs/wiki-data-report.md`:

* **6 dangling references remain**, and `validate_data.py` prints them today:
  `customer.req.facilities` → `star_rating_board`, `halloween_decorations`;
  `staff.wearable` → `sunflower_memento`, `witch_hat`, `crab_memento`,
  `sleepy_little_bear`. The first two are genuinely missing data; the staff four
  are deliberately-kept legacy aliases.
* **Facility gaps**: Takeout is 32 rows short of the wiki hub page and Courtyard
  20 short. Facilities were not touched in this pass and need their own scrape.
* **3 mementos documented as existing but with no data anywhere** (Adventurer
  Stoat, Dani, Aten), and `environmental_badge` has no `source`.
* **`updates.json` is still 2 entries.** Never scraped.
* **Booth mechanics for the 9 new booth owners are partial** — `incomeEvery5Min`
  and `appearanceRatesByFish` are empty arrays because the wiki says TBA.

Two items in that report's §7 are **already fixed** and should be struck:
§7.1 (the `rating` vs `requiredStars` parser bug) was fixed in commit `8433b32`
— `customer.dart:149-150` now reads `json['requiredStars'] ?? json['rating']`,
which picks up all 234 customers with a rating, not just the 54 that got the
data-side mirror. §7.3 (`CustomerRequirements` has no `flowers` field) was also
fixed — `customer.dart:114,155`, and 82 customers carry `requirements.flowers`.

From `docs/performance-report.md`, explicitly not done:

* `letters_page.dart:85-106` still builds all 257 chips eagerly inside a
  `Wrap` in a `SingleChildScrollView` under an `AnimatedBuilder` — every
  checkbox tap rebuilds all of them. Needs a layout decision.
* `dishes_page.dart:197-199` still has `GridView.builder` with
  `shrinkWrap: true` + `NeverScrollableScrollPhysics` inside a
  `SingleChildScrollView` — `shrinkWrap` defeats laziness, so ~500 tiles lay out
  eagerly. Same pattern in `facilities_page.dart` and `facility_detail_page.dart`.
* `unlocked_store.dart` calls `notifyListeners()` from 8 places with no
  granularity, so one tap rebuilds every `AnimatedBuilder` subtree in the app.
  This is described in that report as the biggest remaining win, and it is.
* No `cacheWidth`/`cacheHeight` on any `Image.asset` (needs
  `devicePixelRatioOf(context)` per call site).
* `global_search_page.dart` still has no debounce and no request-id guard.

---

## 3. How far to trust the data

All of `assets/data/**` was **machine-extracted from a fan wiki** by Python
scrapers in `scripts/`. It is not authoritative and it has not been played
against the game.

**What `scripts/validate_data.py` proves** (it passes today): every JSON file
parses; memento `customerId`/`posterId` and every id inside
`requirements.customers/recipeIds/facilities/staff/serve/sell` resolves to
something real; poster performer and requirement ids resolve; customer memento
ids, recipe names, ordered-dish names and facility/flower ids resolve; staff
wearable memento ids resolve; the embedded `customers.json[].mementos` array is
a strict subset of `mementos.json` with matching `customerId`s, no memento on
two customers, and no duplicate ids in the registry.

**What it does not prove**: that any *value* is correct. Not one star count, not
one price, not one requirement threshold, not one description. It is a
referential-integrity check. `deers_cracker` being +10★ or +15★ is a coin flip it
cannot see; `teddy_biscuit`'s takeout price being 10× wrong was invisible to it.

**One thing to fix before you rely on it**: `validate_data.py` prints its
dangling-reference report and then **exits 0 regardless**. There is no
`sys.exit(1)`. Wired into CI as-is, it can never fail a build. Add a non-zero
exit when `prob` is non-empty (with the 6 known dangles allow-listed, or fix
them first).

**The 126 `derivedLinks` are the most likely things to be wrong.** 119 memento
`requirements` blocks carry `"inferred": true`. The wiki says *"Serve
[[White Bunny]] 350 times"*; turning that into
`requirements.customers: ["white_bunny"]` is the scraper's interpretation, not
the wiki's statement. Those are all flagged, all greppable
(`grep -l '"inferred": true'`), and all auditable against a running game. Same
for the 25 inferred customer↔dish links across 18 customers, which are recorded
under `customers.json[].derivedLinks`. Spot-check maybe 20 of them against
mementos you have actually earned; if they hold, trust the rest.

**Budget for a third pass.** The wiki agent found fabricated data **twice** in
files that already looked fine: three invented `mementos_extra.json` entries
(including a redemption code `SPRING202X` that does not exist), an invented
`kibble` memento with a wrong description, wrong star count and wrong
requirement, an invented `film` currency on five event movies, 18 requirement
strings containing raw `{{PAGENAME}}` wikitext, and a literal `blahr` typo. That
is two independent discoveries of confabulation, both found only by
cross-checking one source against another. The base rate is not zero, and there
is no reason to think it went to zero on this pass.

---

## 4. Recommended next work, ranked

### 1. Run `flutter analyze` and fix what it says — half a day to two days

Everything below is speculative until this is done. Do not start feature work
first.

### 2. A regression test for the progress-loss bug class — half a day, highest value per hour

The `_defaultTypes` bug silently destroyed real saved progress across restarts,
for eight buckets, and nothing in the app would ever have surfaced it. The
repo has no `test/` directory at all. One test file fixes the whole class:

```dart
// test/progress_types_test.dart
test('every ProgressTypes bucket is loaded at startup', () {
  // reflectively or by exposing a @visibleForTesting getter on UnlockedStore
  expect(UnlockedStore.debugDefaultTypes,
      containsAll(ProgressTypes.registerOnStartup));
});
test('every bucket a page writes is in ProgressTypes', () { /* … */ });
```

Pair it with the §2.7 structural fix so there is one list instead of two. Then
add a `SharedPreferences` round-trip test: write ids into every bucket,
re-init, assert they come back. That is the actual failure that happened.

### 3. Fix the mementos page — one to two days

`MementosIndex` caching (§2.5), `CheckAllButton` with per-source groups (§2.3),
the empty Dress-Up tab (§2.4), and the dead `hidden` chip. These are all one
feature and one file each, and the mementos page is now the app's biggest set by
a factor of four. Doing them together is much cheaper than separately.

### 4. CI: `flutter analyze` + `validate_data.py` — two hours

A single GitHub Actions workflow. `analyze` is the thing that would have caught
this entire situation. `validate_data.py` needs the `sys.exit(1)` from §3 to be
worth anything. Add `flutter test` once §2 exists. This is cheap and it is the
reason you will not be reading a document like this one again.

### 5. Wire up `fish.json` and `flowers.json` — one day

Nothing in `lib/` reads either file. Both are clean: `fish.json`'s 17 ids are an
exact bidirectional match with every `requiredFishIds` value across all 140
booth owners (0 dangling, 0 unused — I checked), and the 9 flower ids resolve
the `requirements.flowers` on 82 customers that currently point at nothing.

The concrete win: `booth_owners_page.dart:31-52` has a **hard-coded list of 17
fish tuples** driving its filter dropdown. Replace it with `fish.json` and the
list stops drifting. Then a small Fishing Pond page (17 entries, three
rarities), and flower chips on seasonal customer pages.

### 6. Facility follow-up scrape — one to two days

Takeout −32 and Courtyard −20 vs. the wiki, plus deciding what to do about the
535 untracked concert/pet items (§2.6). One scraper run and one UI decision.

### 7. Data-refresh workflow — half a day, do it while the scrapers are fresh

`scripts/README.md` documents the 10-step run order and the scripts cache to
`scripts/.cache/`. Turn that into one `scripts/refresh.sh` that runs all ten in
order and ends with `validate_data.py`. The game updates; in six months nobody
will remember that `reconcile_mementos.py` has to run after
`scrape_page_mementos.py` but before `scrape_posters.py`. Right now that
knowledge is in a README paragraph. A script that fails loudly on the wrong
order is worth more.

### 8. The `unlocked_store` rebuild scope — one to two days, only if it actually feels slow

A per-entry `Listenable` so a checkbox tap rebuilds one row rather than the
whole page. The perf report calls this the biggest remaining win and it is
probably right, but measure first — the asset and JSON work already removed
~25 MB of decoded images and a lot of duplicate parsing, so the app may simply
be fine now. Do not spend two days on this before you have seen it jank.

---

## 5. Questions only you can answer

1. **Should concert and pet facilities count toward completion?** 535 items with
   no UI (§2.6). Three options: build tracking for them (biggest, most honest);
   leave them excluded and add a line on the progress page saying so (cheapest);
   or drop the shards from the bundle entirely (they cost ~228 KB and load into
   memory via `FacilitiesRepository.all()` for nothing).

2. **Is equal weighting the right completion model?** Every collectible counts
   once, so the denominator is roughly: facilities 2193 + courtyard 1336 = 3529
   of ~6,850 — **facilities are 51% of your percentage**. Mementos are another
   17%. A new player who has unlocked every customer, every recipe and every
   letter would still read under 20% complete. That is arithmetically honest and
   may be motivationally useless. If this page is aimed at beginners, consider
   either per-category weighting or making the headline number the average of
   the 13 category percentages rather than the pooled total. This is a product
   call, not a code call, and it should be made before anyone gets attached to
   the number.

3. **Should `customers.json[].mementos` eventually be dropped?** It is a
   denormalised mirror of 123 of the 1184 entries in `mementos.json`, kept
   byte-identical by `reconcile_mementos.py` and asserted identical by
   `validate_data.py`. It works today, and `completion_service` correctly counts
   only `mementos.json`. But it is a second copy that has to be reconciled on
   every scrape, and the customer detail page could read the registry by
   `customerId` instead. Dropping it removes a drift risk and ~110 KB from
   `customers.json`; keeping it avoids touching working UI. Your call, and not
   urgent — but decide it before the next data refresh rather than during.
