# Wiki data completeness report

Source of truth: <https://animalrestaurant.fandom.com> (MediaWiki API, fetched 2026-08-29).
Scope of this pass: `assets/data/**`, `scripts/**`, this file. No `lib/` changes were made.

Everything below is reproducible — see `scripts/README.md`. `scripts/validate_data.py` parses
every JSON file, reports dangling cross-references, and asserts the memento-registry invariants.

---

## 1. Per-dataset before / after

| File | Before | After | Notes |
|---|---:|---:|---|
| `customers.json` | 564 | **613** | +49 customers; 244 empty fields backfilled |
| `customers.json` → embedded mementos | 8 | **123** | the app had mementos for 4 customers total |
| `mementos.json` | 8 | **1184** | full registry from `Template:Mementos` |
| `mementos_extra.json` | 3 | **0** | all three entries were fabricated (see §3) |
| `posters.json` | 2 | **155** | full `Template:Poster` table |
| `dishes.json` | 249 | **268** | +15 recipes, +4 Halloween candies |
| `movies.json` | 38 | **43** | +5, and 5 event-exclusive rewards de-fabricated |
| `staff.json` | 16 | 16 | complete; wearable mementos **462 → 592** |
| `pets.json` → pets | 15 | **17** | +Peachy, +Spooky |
| `pets.json` → pet rooms | 5 | **6** | +Room 6 (Film 150,000, needs 16 pets) |
| `food_truck_recipes.json` | 9 | **11** | +Frosted Gingerbread House, +Four Happiness Lucky Bags |
| `booth_owners.json` | 131 | **140** | booth mechanics for the 9 newly added booth owners |
| `redemption_codes.json` | 91 | 91 | gift references classified (see §5) |
| `letters.json` | 257 | 257 | **already complete** (wiki has 232 letter pages) |
| `terrace_customers.json` | 5 | 5 | **already complete** (wiki `Category:Terrace Customers` = 5) |
| `updates.json` | 2 | 2 | not touched — see §7 |
| `fish.json` | — | **17** | new file |
| `flowers.json` | — | **9** | new file |

### Facility scenes (app item count vs. wiki hub-page rows)

The wiki files facilities as one page per *type*, so a category count is not comparable.
These numbers count individual facility items in the app vs. table rows on `Facilities/<Scene>`
(the row heuristic is approximate — treat small deltas as "verify", not "confirmed missing").

| Scene | App | Wiki hub rows | Δ |
|---|---:|---:|---:|
| Restaurant | 469 | 479 | −10 |
| Kitchen | 463 | 463 | 0 |
| Garden | 209 | 209 | 0 |
| Buffet | 196 | 183 | +13 |
| Takeout | 281 | 313 | **−32** |
| Terrace | 390 | 390 | 0 |
| Courtyard | 1336 | 1356 | **−20** |
| Concert | 232 | 203 | +29 |
| Pets | 303 | 304 | −1 |
| Vegetable Garden | 144 | 144 | 0 |
| Signature Store | 41 | n/a | hub page has no table |

Facilities were **not** modified in this pass. Takeout (−32) and Courtyard (−20) are the two
real gaps worth a follow-up scrape.

---

## 2. Customers

`Category:Customers` ∪ `Performer` ∪ `Booth Owner` ∪ `Doll Figure Customers` ∪
`Terrace Customers` ∪ `Event/Special Customers` ∪ `Regulars` ∪ `Flower Customer`
= 619 pages, of which 6 are hub/event pages. 50 were absent from the app; 49 were added
(the 50th, `Fisherman Old Gene`, is the same character as the app's existing
`fisherman_old_gin` — see §6).

Added: 4 performers (`coach_roo`, `trainee_foxy`, `trainee_mingo`, `trainee_stripey`),
9 booth owners, 12 gachapon doll figures, 12 regulars, 5 terrace customers (now also present
in `customers.json` tagged `terrace`, in addition to `terrace_customers.json`), 3 event/special,
plus `prince_michael`, `sheltie`, `peacock_sage`, `taowu` and others.

Existing customers were **only filled, never overwritten**: 244 previously-empty fields
(`livesIn`, `appearanceWeight`, `requiredFoodId`, `dishesOrderedIds`, `requirements.*`,
`customerDescription`) were populated from the wiki. No existing non-empty value was replaced
and no id was renamed.

---

## 3. Fabricated / corrupt data removed

| Where | What | Verdict |
|---|---|---|
| `mementos_extra.json` | `code_spring_bundle` — "Use Redemption Code **SPRING202X**" | Invented. No such code or memento anywhere on the wiki. **Removed.** |
| `mementos_extra.json` | `poster_courtyard_intro` — "Courtyard Poster – Intro" | Invented. Not a poster, not a memento. **Removed.** |
| `mementos_extra.json` | `wwell_lucky_coin` — "Lucky Coin" from the Wishing Well | Invented. No memento named "Lucky Coin" exists in the 1184-entry master list. **Removed.** |
| `mementos.json` | `calculator` requirement contained the literal typo `blahr` | **Fixed** (file regenerated from the wiki). |
| `customers.json` (18 mementos) | requirement text contained the literal string `PAGENAME` — leaked `{{PAGENAME}}` wikitext, e.g. *"Serve PAGENAME 30 times."* | **Fixed**: substituted the real customer name in all 17 remaining cases. Same class of corruption as `blahr`; found by cross-checking against the registry. |
| `mementos.json` / `customers.json` | `kibble` was recorded as *"Crunchy dog food."* / 10★ / "Serve White Shiba 500 times" | Not on the wiki in any form. Both the White Shiba page and the master list say *"Only one word to describe it—delicious!"* / 85★ / 195 times. **Corrected.** |
| `movies.json` (4 entries) | `healing_night`, `the_stolen_sun`, `seaside_songstress`, `the_strange_bird_in_the_cave` carried `{"currency":"film","amount":0}` | These are event-exclusive movies with **no** reward. The `film` currency was invented. **Reward set to `null`**, with a `note` recording the source event. |
| `dishes.json` | `teddy_biscuit` takeout tier prices were 1 000 / 10 000 / 30 000 (10× low) | Wiki: 10 000 / 100 000 / 300 000. Isolated error — the other 47 takeout dishes were spot-checked and correct. **Corrected.** |
| `customers.json` | dish references `Pork on Rice` and `Mocha Cake Roll` | Wiki redirects: → `Eggscellent Bowl`, → `Matcha Cake Roll` (a typo). **Corrected** (display names only, no ids touched). |

Two genuine wiki-internal conflicts were **not** silently resolved; the per-customer page value
was kept (it matches what the app already showed) and both readings are recorded here:

* `deers_cracker` — Deer's page says **+10★**, `Template:Mementos` says +15★.
* `tiny_socks` — Hedgehog's page says **+45★**, `Template:Mementos` says +40★.

---

## 4. Mementos — one canonical registry

`mementos.json` is the **single source of truth for the memento set** (1184 entries).
`customers.json[].mementos` is a denormalised convenience mirror of the 123 customer-gift
mementos; it is **not** an independent set. A completion-percentage denominator must count
`mementos.json` and must not add the embedded arrays on top.

Machine-checked by `scripts/validate_data.py` (all currently true):

```
embedded mementos: 123
embedded ids subset of mementos.json: True
customerId matches on all embedded: True
no memento id on more than one customer: True
duplicate ids in mementos.json: []
```

Values were reconciled so the two files never disagree — after reconciliation the drift between
them is **0 fields**. Reconciliation rule: `earnedStars` from the per-customer page (which is what
the app already displayed), `description` from the master list (better copy, fixes ~15 typos such
as *convinient*, *personell*, *Dyansty*), `requirement` from whichever source actually names the
customer — this is what keeps `tool` / `engineers_helmet` on **Otter** rather than the master
list's stale "Serve Beaver".

Ids are byte-identical across both files. All 8 pre-existing memento ids
(`purse`, `calculator`, `rabbit_hat`, `carrot_cellphone`, `sturdy_flower`, `deers_cracker`,
`kibble`, `golden_ponytail`) survive unchanged, so saved progress keys still resolve.
The only disambiguation was a genuine name collision: two distinct mementos are both called
"Ice Skates" → `ice_skates` and `ice_skates_2` (neither existed in the app before).

### Sources

`source` was resolved for **1183 / 1184** entries (was: 978 unresolved out of 1184 in the first
draft of this file).

| source | n | | source | n |
|---|---:|---|---|---:|
| `signature_store` | 261 | | `redemption_code` | 45 |
| `gachapon` | 240 | | `wondrous_coatroom` | 32 |
| `wishing_well` | 133 | | `meal_side_cabinet` | 11 |
| `customer_gift` | 119 | | `battle_pass` | 10 |
| `mysterious_bird_nest` | 118 | | `aromatic_acorn_judging` | 9 |
| `poster` | 111 | | `shop` | 2 |
| `event` | 91 | | `diamond_store` | 1 |

The single unresolved entry is `environmental_badge` ("Sweep up 100 pieces of trash.") — the wiki
does not attribute it to any system, so `source` is left **absent** rather than guessed.
225 entries also carry an `event` name; 286 are flagged `hidden`; 55 carry a `shareReward`;
553 carry `equips` (staff ids).

### Structured requirements (new, additive)

Every memento keeps its original free-text `requirement` untouched. A sibling `requirements`
object was added (1073 entries have one), keyed to match the `customers.json` convention:

```jsonc
"requirement": "Serve White Bunny 1500 times.\nSell Taiyaki 2000 times.",
"requirements": {
  "serve":     [{ "customerId": "white_bunny", "count": 1500 }],
  "sell":      [{ "recipeId": "taiyaki", "name": "Taiyaki", "count": 2000 }],
  "recipes":   ["Taiyaki"],          // display names — same convention as customers.json
  "recipeIds": ["taiyaki"],          // resolved ids, so nothing dangles
  "facilities":["..."],              // facility ids
  "customers": ["..."],              // customer ids (excludes the owning customer, see below)
  "staff":     ["..."],              // staff ids
  "rating": 1000, "requiredStars": 1000,
  "other":     ["…lines nothing structured could be extracted from…"],
  "inferred": true,
  "derivedLinks": ["customer:white_bunny", "recipe:taiyaki"]
}
```

Counts: 109 `serve` blocks, 7 `sell` blocks, 5 `rating` blocks, 119 blocks flagged `inferred`
with 126 `derivedLinks`. `other` holds only residue — lines that produced no structured output.

### Stated vs. inferred

* **653 entity references were *stated*** — the wiki names the entity as an explicit `[[link]]`
  inside the requirement text, and it was resolved to an existing app id.
* **All 126 relationship edges recorded in `derivedLinks` are *inferred***: the wiki states
  *"Serve [[White Bunny]] 350 times"* but never says "this memento requires White Bunny".
  Turning that sentence into `requirements.customers` / `requirements.serve` is our derivation,
  so those blocks carry `"inferred": true`.
* **123 memento → customer ownership edges are *stated*** — every one comes from a `{{Memento}}`
  block on the customer's own page. None had to be inferred from the master list's requirement
  text (`customerIdInferred` count: 0).
* **25 customer ↔ dish links were *inferred*** from the reverse direction (§ below), spread over
  18 customers.
* A scan for entity names mentioned in memento requirements *without* a wiki link found **zero**
  genuine cases — `Template:Mementos` is consistently linked.

### Inferring links the wiki does not state

Dish pages carry `for = [[Customer]]` (this dish is required to attract them) and
`orders = [[Customer]], …`. All 253 recipe pages were cross-referenced against
`customers.json`; where a customer page omitted a dish that the dish page claims, the link was
added to the customer:

* 2 additions to `requirements.recipes` (`gretel` ← Buttery Apple, `sunny` ← Matcha Cake Roll)
* 23 additions to `dishesOrderedIds` across 17 customers

1 688 links were already consistent in both directions — the two datasets agree well.
Every inferred addition is recorded on the customer so a human can audit it:

```jsonc
"derivedLinks": { "requirements.recipes": ["Buttery Apple"],
                  "dishesOrderedIds":     ["Buttery Apple"] }
```

19 `for`/`orders` targets could not be resolved to an app customer id and were skipped rather
than guessed.

### No double-linking — canonical direction per relationship

| Relationship | Canonical direction | Deliberately *not* emitted |
|---|---|---|
| memento ↔ owning customer | `mementos.json[].customerId` (+ the mirror in `customers.json[].mementos`, guaranteed identical) | the owner is **removed** from `requirements.customers`; the count lives in `requirements.serve` instead, so a detail page can't render "requires White Bunny" twice |
| memento ↔ poster | `mementos.json[].posterId` → `posters.json` | poster mementos carry **no** `requirements` block at all; `posters.json` owns the unlock requirements (111 entries) |
| customer ↔ dish | `customers.json` (`requirements.recipes`, `dishesOrderedIds`) | `dishes.json` gets no reverse customer list |
| staff ↔ memento | both `staff.json[].wearableMementos` and `mementos.json[].equips` exist and were generated from the same wiki column, so they agree by construction; prefer `staff.json` on a staff page and `equips` on a memento page — never sum them |
| booth owner ↔ fish | `booth_owners.json[].requiredFishIds` → `fish.json` | `fish.json` gets no reverse booth-owner list |

---

## 5. Other findings

**Redemption code gifts.** 41 of 91 `giftMementoId` values did not resolve against the memento
registry. 38 of them are in fact **facility (decoration) ids**, not mementos — the field is
mislabelled. `giftMementoId` was left untouched (id stability) and two additive fields were
added: `giftKind` (`"memento"` 43 / `"facility"` 38 / `"unresolved"` 2) and `giftRefId`.
The 2 unresolved are `gift_teddy_bear_2` and `osmanthus_hanging_ornament`.

**Staff.** All 16 staff match `Category:Staff` exactly. Wearable memento lists were 20–35%
short across the board and were topped up from the master list's *Equips* column
(462 → 592; e.g. Paddy 4 → 13, Dori 34 → 46, Support Chef Meow 24 → 36). Four legacy
`mementoId`s in the app do not exist on the wiki under those slugs —
`sunflower_memento`, `witch_hat`, `crab_memento` (aliases of `sunflower`, `witchs_hat`, `crab`)
and `sleepy_little_bear` (no match at all). They were **kept, not renamed**, to preserve saved
progress; the canonical duplicate was suppressed for the three aliases so no staff page shows
the same item twice.

**New files.** Two systems the app referenced but had no data for:

* `fish.json` (17) — the Fishing Pond catch table, split `common` / `specialty` / `rare`.
  Its ids are an exact 1:1 match with every `requiredFishIds` value in `booth_owners.json`
  (0 dangling in either direction), so booth-owner attraction can finally be rendered.
* `flowers.json` (9) — Garden flowers with per-level `baseView` / `avgStarPerView`.
  These 9 ids were already being referenced from `customers.json[].requirements.facilities`
  by 86 seasonal customers and resolved to nothing.

`pubspec.yaml` was **not** modified — its `assets:` section uses directory globs
(`- assets/data/`), so new files are picked up automatically.

---

## 6. Could not resolve

* **3 mementos are documented as existing but have no data anywhere on the wiki**:
  Adventurer Stoat, Dani and Aten each declare `|Memento = 1` on their page but no
  `{{Memento}}` block, and nothing in the 1184-entry master list maps to them. Left absent.
* **`fisherman_old_gin` vs. "Fisherman Old Gene"** — same character (identical description,
  "He fishes up anything but fish."); the wiki has since renamed it. The **id was not changed**;
  the entry was enriched from the Gene page instead. Its display name still reads
  "Fisherman Old Gin" — renaming the `name` (not the id) would be safe if desired.
* **`greedy_hedgehog_doll_figure`** — no wiki page under that or any near name; left as-is.
* **`star_rating_board`, `halloween_decorations`** — referenced from
  `customers.json[].requirements.facilities` but present in neither the facility data nor
  `flowers.json`. 2 references total.
* **`environmental_badge`** — no system attribution on the wiki, `source` left absent.
* **Facilities gaps** — Takeout (−32) and Courtyard (−20) vs. the wiki hub pages. Out of scope
  for this pass; needs a facility scrape.
* **`updates.json` (2 entries)** — the wiki's `Updates` page is a very long changelog going back
  to v1. Not parsed; it is a nice-to-have and the shape is trivial, but it is a large,
  low-signal scrape. Left untouched.
* **Booth mechanics for the 9 new booth owners** are partial: `requiredFishIds`, `timeRange`
  and (where stated) `stayDurationMinutes` are filled, but the wiki lists `TBA` for their income
  probabilities and customer drops, so `incomeEvery5Min` and `appearanceRatesByFish` are empty
  arrays rather than invented numbers.

---

## 7. Dart-side follow-ups required (`lib/` was not touched)

1. **`CustomerRequirements.fromJson` reads `requiredStars`, but the JSON key is `rating`.**
   `lib/features/customers/model/customer.dart` does `requiredStars: _nullableInt(json['requiredStars'])`
   while every entry in `customers.json` stores it as `rating` — so **every customer star
   requirement is currently silently dropped**. As a data-side stopgap, `requiredStars` is now
   mirrored alongside `rating` on all 54 customers that have a value, so the field starts working
   without a code change. The parser should still be fixed to accept both.
2. **`CustomerMemento` only parses `id` and `name`.** The embedded memento objects now carry
   `earnedStars`, `description`, `requirement` and sometimes `shareReward` / `tags` / `source`,
   and the completion-percentage feature needs at least `earnedStars`. Extend the model, or read
   from `mementos.json` instead (preferred — see §4).
3. **`CustomerRequirements` has no `flowers` field.** `customers.json` uses
   `requirements.flowers` on some entries, and 86 seasonal customers additionally carry their
   flower under `requirements.facilities` (a legacy mis-file). Those flower ids now resolve
   against the new `flowers.json`. Adding a `flowers` field would let the UI label them
   properly; I did not move them between keys because that would make them vanish from the
   current UI.
4. **New optional keys the models will ignore until wired up** (all backwards-compatible):
   `mementos.json[].requirements` / `.posterId` / `.customerId` / `.event` / `.equipsNote`,
   `customers.json[].derivedLinks`, `movies.json[].note`,
   `redemption_codes.json[].giftKind` / `.giftRefId`.
5. **`movies.json` reward can now be `null`** for the 5 event-exclusive films. The existing UI
   already null-checks (`m.reward != null && m.reward!.amount > 0`), so this is safe — but any
   new movie UI must keep that check.
6. **No repository reads `fish.json` or `flowers.json` yet.** Both are well-formed and fully
   cross-referenced; they need a repository + UI.
7. **`mementos_extra.json` is now `[]`.** `MementosIndex` handles an empty list fine. If nothing
   else will ever be added there, the second load could be dropped.


---

## Why the customer count is 613 and the wiki says 500 (checked 15 Sep 2026)

Three numbers get quoted for the same thing, and none of them is a miscount.
They answer different questions.

| Number | What it counts |
|---|---|
| **500** | Members of the wiki's `Category:Customers`, exactly. Includes about six index pages — "Seasonal Customers", "Regular Customers", "Event Customers", "Terrace Customers", "Puff Customer", "Rose Customer" — which are hub pages, not customers. |
| **613** | `customers.json`, which is the union of **eleven** categories: Customers, Performer, Booth Owner, Doll Figure Customers, Terrace Customers, Event Customers, Special Customers, Regulars, Flower Customer, Halloween Customers, Seasonal. |
| **572** | What the wiki's `Customers` page says in its opening line: *"There are currently 572 customers in the game."* It is a hand-typed sentence, and it does not match the page's own lists — see below. |

### What the wiki's own page actually contains

The `Customers` page transcludes nine section templates — Regular, Special,
Seasonal, Doll Figure, Terrace, Booth Owning, Performers, Event and Battle
Pass. So the wiki's headline number uses the **same broad definition we do**,
booth owners and performers included; it is not the narrow
`Category:Customers`.

Counting the links in those nine templates gives 591 distinct targets, of
which 28 are not customers at all — event hub pages, `Fishing Pond`,
`Concert`, `Gachapon`, the `Terrace` scene, a `Category:` link, and nine
letters that appear as unlock requirements (`Eggy's Diary 2`, `Otter's Letter
1`, `Little Fox's Letter`, the New Zealand Journal pages). One more,
`Gumi`, redirects to **Chef Gumi**, who is a staff member and is correctly in
`staff.json`, not `customers.json`.

That leaves **563 real customer pages on a page whose first line claims 572**.
The sentence is maintained by hand and has drifted from the lists beneath it,
so it is not a number to reconcile against.

**We are missing none of them.** After normalising for the "(Customer)"
disambiguation suffix (`Puff (Customer)`, `Rose (Customer)`) and the diacritic
in `Felicity Nüwa`, every real customer on that page is in `customers.json`.
Our 613 is a strict superset: the extra ~50 are dominated by **31
Halloween/event customers** that live in `Category:Halloween Customers` and are
not listed on the `Customers` page at all.

The 113-row gap between 500 and 613 is mostly **76 performers**: they live in
`Category:Performer`, which `Category:Customers` does not contain. The rest is
20 regulars, 17 gachapon dolls and 9 booth owners the wiki files only under
their own categories.

**613 is not inflated by junk.** 613 rows, 613 unique ids, 613 unique names, no
duplicates, and no index pages leaked in — `scrape_customers.py` already skips
those. One name collides with a recipe (`candied_hawthorn`), and that is
correct: the booth and the dish really do share a name.

**Booth owners are named after their booths.** `Category:Booth Owner` names
each page after the stall rather than its animal owner, so the customer list
carries entries like "American Hot Dog", "Bowl Pudding" and "Wholegrain
Pancake" among names like "Old Joe". They look like recipes in a list and are
not; nothing is duplicated. Worth knowing before someone "fixes" it.

**Decision taken:** the All tab stays as all 613. This is a completion
tracker, and narrowing All to the wiki's definition would leave 76 performers
untickable from the one screen that claims to list everything. The narrower
sets already have their own tabs.

**Fixed at the same time:** eight customers — `deer`, `gloomy`, `white_shiba`,
`bouncy_the_pika`, `dobermann`, `hoppy_the_pika`, `mad_hatter`, `sunny` —
carried only tags like `restaurant` or `terrace`, which no tab reads, and no
season, so they appeared on All and nowhere else. The Regular tab now also
collects anything no other tab claims, which is resilient in a way re-tagging
the data would not be: a customer whose wiki categories change still lands
somewhere rather than vanishing. `test/customers/customer_tabs_test.dart`
asserts no customer is ever All-only again.
