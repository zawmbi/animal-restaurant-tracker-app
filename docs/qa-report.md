# QA report

> **Status, 11 Sep 2026.** Most of what this report found has since been fixed —
> the six colliding facility ids (#4), the orphaned concert/pet shards (#2), the
> battle pass pre-claim (#5), the redemption gift kinds (#7) and the name
> resolution on the customer and staff pages (#12/#13/#14). `flutter test` now
> passes 194/194. See **Game data bugs fixed** in `IOS_RELEASE_HANDOFF.md` for
> what changed and what was deliberately left alone. This file is kept as the
> record of what was found, not as a to-do list; check the code before acting on
> any item here.

Round 6. Written from two seats at once: a player who knows what the numbers
are supposed to mean, and a tester whose job is to find what is broken.

**What I could and could not do.** There is no Flutter or Dart toolchain in
this container (`which flutter`, `which dart` both fail), so nothing under
`test/` has been executed. Everything in the "Verified" column below was
checked by running Python over `assets/data/**` and by static analysis of
`lib/**`, and the exact command that proves it is named. Everything marked
"Not run" is a test I wrote for you to run; each was written against the API as
it is actually declared (I grepped every constructor and method signature
before using it), but I cannot claim it compiles.

Three new checkers exist and **all three currently fail**:

```
python3 scripts/qa_refs.py              # 10 failures — cross-dataset links by entity kind
python3 scripts/qa_progress_buckets.py  #  6 failures — buckets + reachability
python3 scripts/qa_formatting.py        #  9 failures — formatting consistency, duplicate code
```

They exit non-zero, so they can join CI next to `scripts/validate_data.py`.

One `lib/` change was made, and it is additive only: `UnlockedStore` gained
`@visibleForTesting` `startupBuckets` and `debugResetForTest()`. Nothing else
in `lib/` was touched. **No visual design was changed.**

---

## First: a correction to `scripts/validate_data.py`

The existing validator's CI gate is unsound and will pass a file with hundreds
of broken references.

`scripts/validate_data.py` collects at most **six** examples per problem key:

```python
def chk(cond, key, val):
    if not cond:
        prob[key]+=1
        if len(samples[key])<6: samples[key].append(val)
```

and then gates on `samples`, not on the real set:

```python
for _k, _v in samples.items():
    _unexpected = set(_v) - KNOWN_DANGLING.get(_k, set())
```

So if a slot gains 500 dangling ids and the first six happen to be in
`KNOWN_DANGLING`, the run prints "ok" and exits 0. This is why the checker
below finds ten classes of dangling reference that `validate_data.py` reports
as clean. `scripts/qa_refs.py` gates on the full set and covers every id slot,
not the eight the old script knew about.

---

## Defects, ranked by what they cost a player

Severity: **S1** loses or corrupts tracked progress, or makes 100% unreachable.
**S2** shows wrong information or breaks a link the player is relying on.
**S3** cosmetic inconsistency. **S4** latent / maintenance.

---

### 1. S1 — 808 of the 1,336 courtyard facilities have no tab, so 100% is unreachable

**Verified.** `python3 scripts/qa_progress_buckets.py`, section "courtyard group
reachability".

`CourtyardRepository.availableGroups()`
(`lib/features/courtyard/data/courtyard_repository.dart:97`) builds the
Courtyard page's tabs as `orderedGroups.where(existing.contains)`. A group in
the data that is *not* in `orderedGroups` (line 68) gets no tab, and there is no
other screen that renders courtyard facilities. But
`CompletionService._courtyard()` counts **all** of `repo.allFacilities`, i.e.
all 1,336.

| Group in `courtyard_facilities.json` | Facilities | Tab? |
|---|---:|---|
| `Decor (Floor)` | 477 | no |
| `Decor (Wall)` | 149 | no |
| `Long Fences` | 116 | no |
| `Short Fences` | 58 | no |
| `Gathering Long Table` | 8 | no |
| **total unreachable** | **808** | |

`orderedGroups` names `'Floor Decor'`, `'Wall Decor'`, `'Long Fence'`,
`'Short Fence'` — near-misses for `'Decor (Floor)'`, `'Decor (Wall)'`,
`'Long Fences'`, `'Short Fences'`. Each of those four *does* match exactly two
facilities in the data, which is why the tabs look populated and the bug
survived: the "Short Fence" tab shows 2 items and the 58 real short fences are
nowhere.

**Reproduce:** open Courtyard. Count the tabs' contents; you get 528 of 1,336.
Open the progress page; the Courtyard denominator says 1,336. Check every box
you can reach and Courtyard tops out at 39.5%.

**Fix (do not guess — pick one deliberately):** either rename the groups in the
data, or map the aliases in `orderedGroups`. I did not make this change because
it is a data edit or a design-affecting tab-list edit, both outside my remit.

---

### 2. S1 — 535 facilities are loaded, searchable, and counted by nothing

**Verified.** Same script, section "facility reachability".

`FacilitiesRepository._assetsForArea` loads `concert_facilities.json` (232) and
`pets_facilities.json` (303) under `FacilityArea.courtyard_concert` and
`courtyard_pets`. Nothing renders them:

* `FacilitiesPage._scenes` (`facilities_page.dart:19`) lists six scene areas and
  excludes both.
* `CourtyardRepository` reads only `courtyard_facilities.json`.
* `CompletionService._facilityScenes` (`completion_service.dart:353`) matches
  the page, and `_courtyard()` reads only `CourtyardRepository`.

But `FacilitiesRepository.all()` merges every area, and `SearchIndex` indexes
`all()`. So a player *can* find "Bell of Blessing" in search and tick it — into
the `facility` bucket, where nothing counts it and no page will ever show it
again.

---

### 3. S1 — 568 of 725 "Required Recipes" chips dead-end at "Recipe not found"

**Verified.** `python3 scripts/qa_formatting.py`, section "field names match
their contents".

`customers[].requirements.recipes` holds display **names**
(`"Adzuki Bean Dumpling"`), not ids (`adzuki_bean_dumpling`). Dish ids and
names are never equal — 0 of 268 match.

`customer_detail_page.dart:208` pushes
`DishDetailPage(dishId: id.toString())` with the name, and `DishDetailPage`
resolves it through `DishesRepository.byId`, which lowercases but does **not**
slugify:

```dart
Future<Dish?> byId(String id) async {
  final trimmedId = id.trim().toLowerCase();
  return _byId?[trimmedId];      // keys are slugs: 'adzuki_bean_dumpling'
}
```

Only single-word recipes survive the round trip: **157 of 725 resolve, 568 do
not.** `"Americano"` works; `"Adzuki Bean Dumpling"` shows "Recipe not found."

The same page (line 198) computes the chip's owned-fill as
`store.isUnlocked('dish', <the name>)` while the recipes page writes `Dish.id`,
so **the fill can never light up for any of the 725** — set lookup is
case-sensitive, so even the 157 that navigate correctly never show as owned.

`DishesRepository.resolve()` already accepts either form and is the right call
site here. (It has its own small bug: `_byId![key]` uses the un-lowercased key
against a lowercased map, so the id branch only works by falling through to the
name branch.)

Note the direction that *does* work: `DishDetailPage._buildCustomerSections`
matches on both id and name, so dish → customer is fine. It is only
customer → dish that is broken.

---

### 4. S1 — six facility ids collide, two of them inside the same bucket

**Verified.** Same script, section "facility reachability".

| id | appears as | and as |
|---|---|---|
| `star_gazing` | restaurant / "Star Gazing" (Wall Decor) | terrace / "Star Gazing" (Telescope) |
| `christmas_long_table` | garden / "Christmas Long Table" | terrace / "Christmas Long Table" |
| `christmas_tree` | restaurant / "Christmas Tree" | courtyard / "Christmas Tree" |
| `gift_teddy_bear` | terrace / "Gift Teddy Bear" | courtyard / "Gift Teddy Bear" |
| `planetary_orbit` | terrace / "Planetary Orbit" (Table 1) | courtyard / "Planetary Orbit" (Decor) |
| `jingle_bell_door` | buffet / **"Jingle Bell"** (Sliding Doors) | courtyard / **"Jingle Bell Door"** (Door) |

The first two are in the same `facility` bucket, so **checking the restaurant
Star Gazing also ticks the terrace telescope**, and the denominator is 2 short
(2,193 rows, 2,191 unique).

The last four straddle `facility` and `courtyard_facility_purchased`: the same
id is counted twice toward the overall total and has to be checked off on two
separate screens.

`jingle_bell_door` is worse than a duplicate — those are two genuinely
different items sharing a slug. `FacilitiesRepository.byId('jingle_bell_door')`
returns whichever shard loaded first (buffet's "Jingle Bell"), so any cross-link
to it opens the wrong facility.

---

### 5. S1 — a free player who ticks a battle pass tier silently pre-claims the Super track

**Verified by reading.** `battle_pass_detail_page.dart:85-96`.

```dart
void _setTierClaimedForPhase({...}) {
  store.setUnlocked('battle_pass_claimed', normalKey, value);
  store.setUnlocked('battle_pass_claimed', superKey, value);   // always
}
```

Both keys are written regardless of whether the player owns premium.
`CompletionService._battlePass()` only puts the Super keys in the denominator
when `battle_pass_premium` is set for that pass, so today the percentage looks
right. The moment the player buys premium and ticks the premium box, **573
Super rewards jump straight to "claimed"** without them touching a thing.

Pinned in `test/completion/completion_counting_test.dart` →
"buying premium after claiming the normal track cannot exceed 100%".

---

### 6. S1 — `'battle_pass'` is a bucket that exists in no startup list

**Verified.** `python3 scripts/qa_progress_buckets.py`, section "bucket strings
used anywhere in lib/".

`lib/home/ui/home_page.dart:229`:

```dart
case HitType.battlePass:
  bucket = 'battle_pass';
```

`'battle_pass'` is not in `UnlockedStore._defaultTypes` and not in
`ProgressTypes`, so anything written there is invisible to every other screen
and is gone on the next launch — the exact failure that has already shipped
twice on this branch (`'customer'` vs `'customers'`, `'facility_purchased'` vs
`'facility'`).

It is **currently dead**: `SearchIndex.search()` never emits a
`HitType.battlePass` hit, so the branch is unreachable today. It becomes a live
progress-loss bug the day battle passes are added to the search index.

`GlobalSearchPage` already handles this case correctly — it sets `bucketFor =
null` and hides the checkbox, because a battle pass hit has no single bucket.
`home_page.dart` should do the same.

**I did not fix this.** The fix needs the `Checkbox` restructured to the
nullable-bucket shape (`bucket == null ? null : Checkbox(...)`), because
`bucket` currently type-promotes to non-null off the exhaustive switch. That is
a ~10-line widget change I cannot compile, so it goes here rather than into a
blind edit.

---

### 7. S2 — 38 of 91 redemption codes give a reward the app cannot link or track

**Verified.** `python3 scripts/qa_refs.py`, section `redemption_codes.json`.

`redemption_codes.json` carries `giftKind` (`memento` 43, `facility` 38,
`unresolved` 2, absent 8) and `giftRefId`. `RedemptionCode.fromJson`
(`redemption_codes_page.dart:62-86`) **reads neither**; it only takes
`giftMementoId`. The page then does:

```dart
memento: c.giftMementoId != null ? mementosById[c.giftMementoId!] : null,
```

For the 38 facility gifts, `giftMementoId` holds a **facility** id
(`ARLOVE2026` → `telephone_bear`), so the lookup misses, the reward renders as
plain grey text with no link, and the checkbox is disabled. The "gifts *n*/*m*"
counter in the header silently excludes them.

Player impact: you redeem `ARLOVE2026`, receive Telephone Bear, and the app
gives you no way to record it — while your Facilities page keeps showing it
unowned.

Two more (`SWEETLOVEAR` → `gift_teddy_bear_2`, `MOONFESTIVAL` →
`osmanthus_hanging_ornament`) are marked `unresolved` and resolve to nothing at
all.

---

### 8. S2 — 84 battle pass rewards point at entities that do not exist

**Verified.** `python3 scripts/qa_refs.py`, section `battle_passes/*.json`.

| Reward type | Total | Unresolved (distinct ids) |
|---|---:|---:|
| `facility` | 382 | **70** |
| `memento` | 50 | **14** |
| `item` (`flower`) | — | 1 (`rose`; `flowers.json` has `red_rose`/`white_rose`) |
| `movie` | 10 | type not handled at all |

`_rewardLabel` (`battle_pass_detail_page.dart:487-500`) falls back to printing
the **raw id** when a lookup misses, so a player sees
`cresting_waves_long_2` and `devout_winged_crown` in reward boxes.

`movie` is worse: `BattlePassReward._parseType` has no `movie` case and a
`default:` that returns `BattlePassRewardType.text`
(`battle_pass.dart:84-86`), whose label is `r.text ?? 'Info'`. Ten reward boxes
across Deep Sea Ballad and Slumberous Nights literally read **"Info"**.

Two more label paths never resolve at all, by construction:

* `item` → `'${qty}x $t'` where `t` is `r.id`, so `2x red_puffer`, `1x rose`;
* `chest` → `r.id`, so `deep_sea_ballad_normal_reward_chest`.

---

### 9. S2 — 60 of 61 performers show a blank Concert card

**Verified.** `python3 -c` over `customers.json`; also asserted in
`test/models/model_parsing_test.dart` → "a performer block keeps its earnings".

All 61 performer blocks in `customers.json` exist, but only
`cutie_white_bunny` has data. For the other 60:

* `performer.baseEarnings.amountPerMinute` is `null` (60/61)
* `performer.showDurationMinutes` is `null` (60/61)
* `performer.posterIds` is empty (60/61)
* `performer.fansCustomerIds` is empty (60/61)
* `performer.canInviteThis` / `canBeInvitedBy` are empty (60/61)

`CustomerDetailPage._performerSection` gates each row on non-null, so opening
DJ Wolf shows a band chip and nothing else — no earnings, no show length, no
posters, no invite chances.

Every one of those numbers is already in `performer_income.json`, which has all
61 complete and is keyed by the same customer id. Nothing joins the two on the
customer page. (The Bank page does use `performer_income.json`.)

This one is listed as known-open in the brief; it is still open, and I have
quantified it exactly.

---

### 10. S2 — the Mementos page's Dress-Up tab and `hidden` chip are both permanently empty

**Verified.** Counts over `mementos.json`:

* `dress_up` tag: **0** entries. `wearable` tag: **0**. The Dress-Up tab
  (`mementos_page.dart:101`) filters on exactly those two, so it always says
  "No mementos match your filters." Meanwhile **553** mementos carry an
  `equips` array naming which staff can wear them, and **589** equip references
  in total, all of which resolve to a real staff id.
* `hidden` tag: **0** entries; top-level `hidden: true`: **286**. The `hidden`
  entry in `commonTags` (`mementos_page.dart:26`) feeds `includeTags`, which is
  a **tag** filter, so selecting that chip returns nothing. The separate
  tri-state `_hidden` filter works correctly, which is what makes the dead chip
  easy to miss.

Both are in the brief's known-open list; both confirmed still live, with the
numbers.

---

### 11. S2 — two different Facility detail screens, depending on where you tapped from

**Verified.** `python3 scripts/qa_formatting.py`, section "duplicate top-level
declarations", plus a diff of the two.

`lib/features/facilities/ui/facility_detail_page.dart` is a stale near-copy of
`lib/features/facilities/ui/facilities_page.dart`. Both declare
`FacilitiesPage`, `FacilityDetailPage`, `_FacilitiesPageState`, `_ScenesBar`,
`_ThemeRail`, `_FacilityGroupSection` and `_FacilityDetailBody`.

Which one you get depends on the route:

| Entry point | Opens |
|---|---|
| Facilities page → tap a facility | the copy in `facilities_page.dart` |
| Customer / Letter / Staff / Battle Pass chip, Global Search | the copy in `facility_detail_page.dart` |

They render differently. The stale copy has no Effects card, a different
star-requirement row, and a currency icon path built as
`'assets/images/${c.key}.png'` (line 383) — which yields `plates.png`,
`diamonds.png`, `bells.png` and `buttons.png`, none of which exist. It is
guarded by an `errorBuilder`, so you get a generic `$` icon rather than the
plate artwork you get on the other screen.

The `FacilitiesPage` inside `facility_detail_page.dart` is dead (no importer
constructs it) and, being stale, lacks the Signature Store sub-tab entirely.

Two more duplicate declarations, both dead:

* `FacilitiesRepository` in `lib/features/facilities/model/data/facilities_repository.dart`, reading the legacy 193-row `assets/data/facilities.json`. No importer.
* `RedemptionCode` in `lib/features/redemption_codes/ui/redemption_code.dart` — an entirely different shape (`isMemento`, `startDate`, `gift`) from the live one in `redemption_codes_page.dart`. No importer.

---

### 12. S2/S3 — raw snake_case ids printed to the player, in six places on one page

**Verified.** `python3 scripts/qa_formatting.py`, section "raw id leakage".

All on `lib/features/customers/ui/customer_detail_page.dart`:

| Line | What it prints | Should print |
|---|---|---|
| 449 | `${row.fishId}: 52.91 / …` | the fish name |
| 513 | Fans chip `label: id` | the customer's name |
| 532 | `'${e.performerId} (54.00%)'` | the performer's name |
| 551 | same, other direction | the performer's name |
| 570 | Poster chip `label: pid` | the poster's name |
| 616 | `_simpleLinks` → `label: id.toString()` | name of the facility / flower / letter / customer |

Line 449 is the sharpest: the **Required Fish** row eight lines above it was
already fixed to use `FishNames.instance.nameFor`, so the same page prints
"Hermit Crab" in one section and `hermit_crab` in the next.

Line 616 is the shared helper, so it hits four sections at once — Required
Facilities (122 refs), Required Flowers (105), Required Letters (13),
Prerequisite Customers (54). Every one of those names exists in the data.

`flowers.json` is loaded by **no Dart file at all** (verified by
`qa_progress_buckets.py`), which is why the flower chips have no name to show.
This is exactly the `hermit_crab` / fish fix, one dataset later.

---

### 13. S2/S3 — 66 staff wearable chips print the wrong name

**Verified.** `python3 scripts/qa_formatting.py`, section "labels derived from
ids".

`staff_detail_page.dart:350` renders `_titleizeId(wm.mementoId)` — a local
titleizer (line 774) that is a fourth variant of `prettyId` — instead of the
memento's actual name, which the page already has to hand (it calls
`MementosIndex.byId` in the tap handler at line 117).

66 of the 556 wearables therefore read wrong:

| id | printed | actual name |
|---|---|---|
| `bakers_hat` | Bakers Hat | Baker's Hat |
| `band_aid` | Band Aid | Band-Aid |
| `blueberries_and_cream_hat` | Blueberries And Cream Hat | Blueberries and Cream Hat |
| `anti_romance_style` | Anti Romance Style | Anti-romance Style |
| `bamboo_copter` | Bamboo Copter | Bamboo-copter |

The general rule, asserted in `test/models/display_names_test.dart`:
`prettyId` is fine for a slug with no canonical name (a memento *source*); it is
not a substitute for a lookup. **1,358 of 4,058 facility names** cannot be
recovered from their id either, so the same shortcut is wrong wherever it is
applied to a facility.

---

### 14. S3 — currency still printed as a lowercase data key on facility prices

**Verified.** `python3 scripts/qa_formatting.py`, section "currency
capitalisation".

```dart
Text('${_formatNumber(p.amount)} ${p.currency.key}')
```

* `lib/features/facilities/ui/facilities_page.dart:684`
* `lib/features/facilities/ui/facility_detail_page.dart:582`

`.key` is the enum name, i.e. the lowercase data key. Every facility price pill
in the app reads "14,000 cod", "40 plates". This is the same class as the
`plates 40.0` the owner already caught; the helper (`prettyCurrency`,
`MoneyCurrencyLabel.label`) exists and is used elsewhere — the customer page's
booth income line one screen away reads "Plates".

The same page also has an inconsistency with itself: `customer_detail_page.dart:414`
prints `'${b.customerDrop!.currency}: …'` raw while line 430 right below uses
`prettyCurrency(r.currency)`.

---

### 15. S3 — seven thousands-separator implementations, three percentage precisions

**Verified.** `python3 scripts/qa_formatting.py`, section "number formatting".

Seven byte-identical hand-rolled `_fmt` / `_formatNumber` functions:

```
lib/features/bank/ui/bank_page.dart
lib/features/battle_pass/ui/battle_pass_detail_page.dart
lib/features/completion/ui/completion_page.dart
lib/features/dishes/ui/dish_detail_page.dart
lib/features/dishes/ui/dish_leaderboard_page.dart
lib/features/facilities/ui/facilities_page.dart
lib/features/facilities/ui/facility_detail_page.dart
```

They already differ. `bank_page`'s handles negatives and non-finite doubles;
`completion_page`'s handles negatives; the other **five** do neither — they
call `v.toString()` with no `abs()`, so the minus sign is treated as a digit
and the comma lands right after it. `_fmt(-100)` returns `-,100`
(`'-100'.length == 4`, and 4 % 3 == 1 triggers a comma at index 0). Latent
today because nothing negative reaches them, live the moment a "still to buy"
or delta figure does.

Percentages disagree across screens: 0 decimals in the facility pages, 1 in the
completion and progress pages and the stove calculator, 2 in the customer
detail page. So a player sees `+50%`, `12.5%` and `54.00%` for the same kind of
quantity in one session.

Five separate currency → icon mappings exist as well:
`MoneyCurrencyIcon.assetPath`, `battle_pass_detail_page._currencyAsset`,
`dish_detail_page._currencyIcon`, `pets_page._currencyIcon`, `RewardIcon`. The
pets one keys on `'bell'` singular while the data writes `bells`.

**Not fixed** — collapsing these into one helper touches seven files and the
brief says surgical only. But it is the single cheapest consistency win here.

---

### 16. S3 — dangling references the old validator did not look for

**Verified.** `python3 scripts/qa_refs.py`.

| Slot | Refs | Unresolved |
|---|---:|---|
| `customer.requirements.letters → letter` | 13 | `halloween_invitation`, `white_shiba_intro_letter` |
| `customer.requiredFoodId → recipe name` | 196 | `Mocha Cake Roll` |
| `pets.photoTasks[].furniture → facility` | 38 | `tiny_stationary_holder` |
| `pets.pets[].likes → any kind` | 34 | 10 of no known kind: `egg_beater`, `gumi`, `king_jiji`, `prince_murong`, `pfp_paddy`, `dori_the_emotional`, `murong_gumi`, `delivery_boy_tate_avatar`, `delivery_girl_kate_avatar`, `support_chef_meow_avatar` |

`pets[].likes` mixes 15 real staff ids with 10 that resolve against no dataset —
they look like staff *skins* or avatars that have no file. The pets page shows
them, so whatever it shows for those ten is unverifiable.

Also a data spelling split: `letters[].combinations` slots contain both
`"Seed"` and `"Seeds"` for what is one pot item.

---

### 17. S4 — orphan assets and latent crash paths

**Verified.**

* `assets/data/flowers.json` — referenced by **no** Dart file, while 105
  flower requirement chips print raw slugs (see #12).
* `assets/data/food_truck_recipes.json` — referenced by no Dart file. Ten of
  its 11 recipes are also in `dishes.json`; `four_happiness_lucky_bags` exists
  only here and is therefore in no page and no denominator.
* `letters[].imageAsset` is parsed into `Letter.imageAsset` and rendered
  nowhere. 184 letters name a file under `assets/images/letters/`, a directory
  that does not exist and is not declared in `pubspec.yaml`.
* Four referenced images do not exist: `buttons.png`, `gachapon.png`,
  `memento.png`, `promote.png`. All four call sites currently have an
  `errorBuilder`, so they degrade to an icon rather than throwing.
* Six `Image.asset` call sites build their path at run time with **no**
  `errorBuilder` (`dish_detail_page.dart:503,515,533`,
  `letter_detail_page.dart:436`, `pets_page.dart:35,266`). Every path they can
  currently produce happens to exist, so this is latent, not live — but a
  missing `memento.png` already took a page down once by exactly this route.
* `ProgressTypes.registerOnStartup`'s doc comment says it lists "buckets that
  are **not** in `UnlockedStore._defaultTypes`". All 13 **are** in
  `_defaultTypes`. The comment inverts the actual invariant, which is the one
  thing a maintainer would rely on when adding a bucket.

---

## Findings from the brief I could not confirm as still-broken

Reported honestly, because catching a stale claim is worth as much as finding a
new bug:

* **"flower ids in `requirements.facilities`"** — fixed and staying fixed. 105
  flower refs are in `requirements.flowers`, 122 facility refs in
  `requirements.facilities`, and no flower id appears in the facilities slot.
  Now pinned by a test.
* **"per-hour rates read as per-minute"** — I could not find a remaining site.
  Every `income.json` row carries its unit in the channel name, every one of
  the 32 channels is both declared and used, no row is missing a quantity, and
  no `codPerSeconds` row is missing its period. All twelve ceilings quoted in
  `docs/economy-report.md` reproduce exactly from the data (11,116 cod/min,
  3,596,000 cap, 728,780 cod/h, 7,582,320 cod/h active, 18,690/purchase,
  78,649–3,970,000 cod and 5,044–100,050 film per gather, 13,384,000 flat,
  +356%, 171,700/view, 36 bottles, 62 orders, 3,760 capacity, 5,942 plates/day,
  292 gacha draws, 56 invites).
* **`MementosIndex.all()` has no cache** — still true, and still called inside
  `AnimatedBuilder` on the mementos page, so 1,184 `MementoEntry` objects plus a
  613-customer map are rebuilt on every checkbox tap. `SearchIndex` works around
  it by caching its own copy. Confirmed, unchanged, still worth fixing.
* **`assets/images/memento.png` missing** — still missing, still guarded.

---

## Test suite

`test/` did not exist; it does now. **None of it has been run** — no toolchain
here. Written to be correct on first read: every constructor and method
signature was checked against its declaration before use.

| File | Tests | Needs asset bundle? |
|---|---|---|
| `test/progress/unlocked_store_test.dart` | round trip across a simulated relaunch for every bucket, bulk writes, clearing, notification counts, guest namespace, upload snapshot | no |
| `test/progress/progress_types_test.dart` | `registerOnStartup` ⊆ startup buckets, every `ProgressTypes` constant is a startup bucket, battle-pass and acorn key shapes match their page's, memento source labels | no |
| `test/completion/completion_counting_test.dart` | 0% at zero and exactly 100% at full, subset categories excluded, unavailable categories excluded, gated Super track, memento single-count invariants, facility id collisions, courtyard/concert reachability | no |
| `test/models/model_parsing_test.dart` | every row of every shipped dataset through its `fromJson`, plus missing-field and explicit-null rows, plus the hard-cast type guards | no |
| `test/models/display_names_test.dart` | `prettyId` / `prettyCurrency`, and where prettifying an id is a lie | no |
| `test/economy/earnings_calculator_test.dart` | every worked example in `docs/economy-report.md`, and that unpublished odds return `null` rather than a number | no |
| `test/economy/income_repository_test.dart` | `summarize` over the real `income.json`: per-facility examples and all twelve ceilings | **yes** |
| `test/links/cross_link_test.dart` | every recipe / facility / letter / prerequisite-customer chip resolves; redemption gifts resolve; page-vs-checkbox bucket agreement | **yes** |
| `test/widgets/check_all_button_test.dart` | label state, bulk apply, the destructive-uncheck confirmation and its Cancel path, singular/plural, multi-bucket groups, one-notification-per-batch | no |

**Which of these should fail on the first run**, if the analysis above is right:

* `completion_counting_test` — courtyard tabs, concert/pets orphans, facility
  id collisions, premium pre-claim.
* `model_parsing_test` — performer blanks, Dress-Up tag count, hidden
  tag-vs-field mismatch, battle pass `movie` reward type.
* `display_names_test` — staff wearable names.
* `cross_link_test` — recipe chips, letter chips, redemption gifts.

Everything else should pass. If one of the "should pass" ones fails, that is a
finding I missed — please send me the output.

### Notes on running

* Anything touching `UnlockedStore` needs `SharedPreferences.setMockInitialValues({})`; every such test does it in `setUp`.
* **Firebase never initialises.** Every Firestore path in `UnlockedStore` is behind `_user != null`, and `_user` stays null without `attachUser`, so all tests run in guest mode — which is also the mode a player is in before signing in.
* Guest ↔ uid namespace switching cannot be unit tested: it needs a real `firebase_auth` `User`, which the package does not let you construct. It is a manual scenario below instead of a faked test.
* Model tests read assets with `dart:io`, not `rootBundle`, so they need `flutter test` to run from the package root but nothing else.

---

## Test scenario matrix

What a player actually does. **A** = automated in `test/`, **P** = automated in
`scripts/qa_*.py`, **M** = manual, must be done on a device.

| # | Scenario | Steps | Expected | Cover |
|---|---|---|---|---|
| 1 | First launch, no data | Fresh install, open Progress | 0.0% overall; every category 0/N with the right N; no error rows | A |
| 2 | First launch, offline | Airplane mode, cold start | App opens, guest namespace, no Firebase error surfaced | M |
| 3 | Track a first customer | Customers → White Bunny → tick | Tick persists; Progress customers goes 1/613; booth-owner row unchanged unless she is one | A (store) + M (UI) |
| 4 | Same customer from three screens | Tick on Customers, open Booth Owners, Band page, Global Search | All four show ticked (all must use `customers`) | A |
| 5 | Check all on a large group | Mementos → Check all (1,184) | One write, one rebuild, no confirmation, count = 1,184 | A |
| 6 | Uncheck all on a large group | Same group → Uncheck all | Confirmation names the exact count and the group; Cancel changes nothing | A |
| 7 | Force-quit and relaunch | Tick one id in each bucket, kill the app, reopen | Every tick is still there | A (simulated) + **M (real, must be done)** |
| 8 | Sign in as a new user | Guest progress, then sign in | Guest progress uploads; namespace becomes the uid | **M** |
| 9 | Sign out | Signed-in progress, then sign out | UI resets to guest progress, uid data untouched | **M** |
| 10 | Sign back in | Sign out, tick things as guest, sign back in | Cloud copy wins only if newer; guest ticks stay in the guest namespace | **M** |
| 11 | Search a customer | Type "bunny" | Hits ranked, checkbox writes `customers` | A (bucket) + M (UI) |
| 12 | Search a facility | Type "oven" | Opens the right facility; **note** concert/pet-yard facilities are findable but shown nowhere (#2) | P |
| 13 | Customer detail cross-links | Open a customer with all requirement kinds | Every chip resolves and shows a **name**, not a slug | A (resolution) + P (names) |
| 14 | Dish detail cross-links | Open a dish | "Required for" and "Can order" list real customers | A |
| 15 | Memento detail | Open a memento with `equips` | Names the staff who can wear it | M |
| 16 | Staff detail | Open Eggy → wearables | Chips show real memento names, tap opens the memento | A (names) |
| 17 | Letter detail | Open a letter with combinations | Slots read as flower/item names; unlock chips resolve | A (letters) |
| 18 | Poster detail | Open a poster | Performers resolve to customer names | P |
| 19 | Battle pass | Open a pass, no premium, tick a tier | Only the Normal reward is claimed (**fails today**, #5) | A |
| 20 | Battle pass rewards | Scroll a phase | Every reward box names something real (**fails today**, #8) | P |
| 21 | Redemption codes | Open the page, filter Active only | Every gift is linkable and tickable (**fails today**, #7) | A |
| 22 | Courtyard | Open Courtyard, count every tab | All 1,336 facilities reachable (**fails today**, #1) | A |
| 23 | Facilities → Signature Store | Takeout → Signature Store | 41 items, distinct from the 281 takeout ones | M |
| 24 | Bank with nothing owned | Fresh account, open Bank | "Not published" where it is not published; no invented numbers; no NaN | A (calculator) + M |
| 25 | Bank with everything owned | Tick every facility, open Bank | The twelve ceilings from the economy report | A |
| 26 | Booth owner odds | Open a booth with no published odds | Min and max shown, no single expected value | A |
| 27 | Reach 100% | Tick every id in every category | Exactly 100.0%, not 99.9% or 100.1% | A |
| 28 | Wipe all progress | Settings → wipe | Every bucket empties and stays empty after a relaunch | A |
| 29 | Rotate / resize | Rotate on every list page | No overflow; `Check all` stays reachable | **M** |
| 30 | Dark mode | Toggle theme on every page | Every page legible; no hard-coded light-only colour | **M** |

Scenarios 2, 7–10, 15, 23, 29 and 30 cannot be automated from here and are the
ones I would run by hand first — 7 through 10 especially, since persistence and
namespace switching are where this app has lost real progress before.

---

## Suggested order of work

1. **#1 courtyard groups** — 808 collectibles, and the reason 100% is
   unreachable. One decision: rename in data, or alias in `orderedGroups`.
2. **#3 recipe chips** — 568 dead links on the most-visited detail page.
   `DishesRepository.resolve()` already does the right thing.
3. **#2 concert/pet facilities** — decide whether they are collectibles. If yes
   they need a page and a category; if no they should not be in
   `FacilitiesRepository.all()` and therefore not in search.
4. **#5 battle pass pre-claim** — a two-line guard on `_hasPremium`.
5. **#7 redemption gift kinds** — parse `giftKind` / `giftRefId` and branch to
   the facility page. The data is already correct; only the model drops it.
6. **#4 id collisions** — `star_gazing` and `christmas_long_table` are the
   urgent two; they corrupt tracking today.
7. **#12/#13/#14 name resolution** — one pass over `customer_detail_page.dart`
   and `staff_detail_page.dart`, plus loading `flowers.json`.
8. **#15 one formatting helper** — cheapest consistency win in the report.
9. **#11 delete the stale duplicates** — `facility_detail_page.dart`'s
   `FacilitiesPage`, `model/data/facilities_repository.dart`,
   `redemption_code.dart`. All three are dead; the first makes the app render
   two different facility screens.
10. Wire the three `qa_*.py` checkers into CI and fix the sampling bug in
    `validate_data.py` (or retire it in favour of `qa_refs.py`, which is a
    superset).
