# Animal Restaurant — economy and banking audit

Scope: every source of income in the game, the formula the app now uses for it,
where that formula came from, and what is still unknown.

Sources, in order of authority:

1. **The game's own FAQ**, mirrored on the wiki at
   [Frequently Asked Questions](https://animalrestaurant.fandom.com/wiki/Frequently_Asked_Questions).
   This is the developers' text and it settles the two mechanics everything
   else depends on (see "The two rules that decide everything" below).
2. **The wiki facility tables**
   (`Facilities/Restaurant`, `/Kitchen`, `/Garden`, `/Buffet`, `/Takeout`,
   `/Terrace`, `/Courtyard`, `/Concert`, `/Pets`, `/Vegetable Garden`), the
   per-performer `{{Performer}}` infoboxes, `Template:Poster`,
   `Template:Customers/Booth Owning` and the `Template:Raise/*` staff tables.
   Read 2026-08-29.
3. **The wiki's community guides** (`Guide:Cod`, `Guide:Plate`, `Guide:Film`,
   `Guide:Bell`, `Guide:Diamond`, `Guide:Star`, `Guide:Getting Started`).
   These are player-written; claims taken from them are labelled below.
4. **Third-party guides and search results.** Nothing from these was used as a
   number. They were checked for contradictions and found to add nothing the
   wiki did not already say.

---

## The two rules that decide everything

### 1. Effects stack across everything you own, not across what you display

> *"Except for Flowerbed, a facility's effect (e.g. tips increase, tips cap,
> star rating, etc.) is calculated based on the combined effect of unlocked
> Facilities of different levels."* — game FAQ, "About Facilities"

> *"…you can change them and customize your restaurant according to your
> preferences **without affecting your earnings**."* — same page

> *"Is the usage cap combined for Facilities such as Wishing Well and
> Gachapon? Yes, they are."* — same page

So summing every unlocked facility is the correct model, and the app's
existing decision to sum is **right**. The one documented exception is the
Flowerbed, which the app does not sum. Courtyard facilities additionally do
not need to be displayed at all
([Guide:Getting Started](https://animalrestaurant.fandom.com/wiki/Guide:Getting_Started)).

### 2. Units are per-area and are *not* interchangeable

This is where the old Bank page went wrong. Read straight off the wiki tables:

| Area | Group | Unit the wiki prints |
|---|---|---|
| Restaurant | Tip Desk | `Tip cap {{Cod\|+N}}` (a capacity, not a rate) |
| Restaurant | Tip Desk, Table 1–6, Plant, Mat, Curtains, Wall Decor | `{{Cod\|+N/min}}` |
| Restaurant | Dessert Bar, Coffee Bar, Bar | `{{Cod\|+N/purchase}}` |
| Kitchen | Window, Trash Can, Cupboard, Goods, Kitchen Rack, Fridge | `{{Cod\|+N/min}}` |
| Kitchen | Oven, Cabinet, Counter | `{{Cod\|+N/30s}}` |
| Kitchen | Stove | `+N% efficiency` |
| Garden | Path, Fence | `{{Cod\|+N/min}}` |
| Garden | Mailbox, Barbecue | `{{Cod\|+N/30s}}` |
| **Buffet** | Conveyor Belts, Ice Cream, Sliding Doors, Wall Hangings | **`{{Cod\|+N/h}}`** |
| Buffet | Self-serve Drinks, Time Clock | `{{Plates\|+N/Day}}` |
| Takeout | Signature Store, Stairs, Takeout Counter, Wall Decor | `{{Cod\|+N/min}}` |
| Takeout | Provision Table | `+N orders` |
| Takeout | Snack/Drink/Fruit Cabinet, Refrigerator | `+N capacity` |
| Terrace | Gathering Table, Table | `Customers pay {{Cod\|+N}}` / `pay N% more` |
| Terrace | Display Stand, Open Air Cinema, Telescope | `{{Cod\|+N}} income from each view` |
| Terrace | Snack Counter, Floor Decorations | `{{Cod\|+N}}/30s` |
| Terrace | Meal Side Cabinet | `{{Bottle\|+N}} daily`, `+N free daily refresh` |
| Courtyard | House Type, Door, Window, Stool, Gathering Long Table | `{{Cod\|+N~M}}` per gather |
| Courtyard | Table, Short/Long Fences, Plants, Speaker, Decor | `{{Film\|+N~M}}` per gather |
| Courtyard | Game Machine | `{{Film\|+N}} for passed game` |
| Concert | Lights | `Free Daily Invites +N`, `Chance of inviting a performer +N%` |
| Concert | Water Fountain | `{{Film\|+N~M}}` |
| Concert | Wall/Floor Decor | `Increases profit of <band> by N%` |
| Pets | Pet Paradise | `{{Cod\|+N~M}}` / `{{Film\|+N~M}}` after playing |
| Vegetable Garden | Vegetable Racks | `Counter capacity +N` |

Every `/Ns` row in the whole wiki is `/30s`; the app still stores the period
explicitly rather than assuming it.

---

## What was wrong, and by how much

### A. Buffet income was overstated ~38×  *(fixed)*

`assets/data/facilities_jsons/buffet_facilities.json` stores 74 of the buffet's
cod rows as `incomePerMinute` when the wiki prints them as `/h`. Those same
files store the *other* 48 buffet cod rows correctly as
`incomePerInterval` with `intervalMinutes: 60`. The old `BankService` then
multiplied the per-minute ones by 60.

* Old model, every buffet facility owned: **27,977,630 cod/h**
* Verified from the wiki: **728,780 cod/h**
* Ratio: **38.4×**

Example: `ice_cream_shop` ("Ice Cream") is `+4,200/h` on the wiki and was being
reported as 252,000 cod/h.

### B. Tip jar fill rate was understated ~700×  *(fixed)*

The old service only counted `area == restaurant` per-minute cod, and the
facilities JSON contains only **three** such rows in the whole game
(`stone_bowl` 5/min, `table1_small_stump` 4/min, `table1_elegant_table` 7/min).
The wiki has **670**, spread across Restaurant, Kitchen, Garden and Takeout —
all of them the same in-game effect, which the game words as
*"Increase tips +x/Every minute"* ([Guide:Cod](https://animalrestaurant.fandom.com/wiki/Guide:Cod)).

* Old model, everything owned: **960 cod/h** (16 cod/min)
* Verified: **666,960 cod/h** (11,116 cod/min)

### C. Tips were wrongly capped at 12 hours  *(fixed)*

The old page did `math.min(minutes, 12 * 60)` on the tip jar. Nothing supports
that. The 12-hour ceiling belongs to the Buffet conveyor
(*"The conveyor belt can work continuously for a maximum of 12 hours"* —
Buffet tutorial). The tip jar is limited by the **jar**, and the FAQ describes
the tip desk as raising *"the limit of your offline profits"*. A jar that
takes 33 hours to fill really does keep filling past hour 12.

### D. The buffet ad multiplier was wrong  *(fixed)*

Old page: `base * 1.5`, bonus capped at `+1,500,000`.
Wiki [Guide:Cod](https://animalrestaurant.fandom.com/wiki/Guide:Cod):

> *"Ad bonus for the buffet is 40% of the buffet earning and capped at
> 1,000,000. So it is recommended to watch buffet ads before or as buffet
> earning reaches 2,500,000 as there is no benefit to waiting longer."*

Those two figures are self-consistent (0.40 × 2,500,000 = 1,000,000), which is
why this is treated as verified rather than as a community claim. The tip jar
ad is a straight ×2, from the same guide, and that part of the old page was
right.

Confidence: **high** for the 40 %/1,000,000 pair (two independent statements on
the same page agree). If anyone can confirm it in-game, that would settle it.

### E. Courtyard income was recorded as per-minute instead of per-gather  *(fixed)*

The courtyard shard has a small set of stub rows that record the **minimum of a
per-gather range** as a per-minute rate. `Log Door` is `{{Cod|+95~4,800}}` per
gather on the wiki and `incomePerMinute: 95` in the app; `Pine Fence (Short)`
is `{{Film|+3~58}}` per gather and `incomePerMinute: 3`. Because the old tip
calculation only looked at `area == restaurant` these never actually reached a
displayed number, but they would have as soon as anyone widened that filter.

13 app rows claim income that the wiki does not corroborate at all — they are
duplicate stubs in groups the wiki does not have (`Short Fence` vs
`Short Fences`, `Table Decor`, `Long Fence`):
`long_fence_pine`, `long_fence_stake`, `short_fence_pine`, `short_fence_stake`,
`stool_wooden`, `stool_mushroom`, `table_log`, `table_picnic_cloth`,
`table_decor_strawberry_cake`, `table_decor_picnic_basket`,
`plant_little_apple_tree_sapling`, `plant_fragrant_white_flowering_tree_sapling`,
`a_favorite_of_both_children_and_adults`.
None of them are in `income.json`, so none of them can inflate a Bank total.

### F. Courtyard purchases were invisible to the Bank page  *(fixed)*

`BankService` read only the `facility` progress bucket. The Courtyard page
writes the **same facility ids** into `courtyard_facility_purchased`
(`lib/features/courtyard/ui/courtyard_page.dart:21`). Every courtyard purchase
was therefore ignored. The service now reads `facility`,
`courtyard_facility_purchased` and the legacy `facility_purchased`, and
de-duplicates ids before summing.

### G. `MoneyCurrency` was declared twice, one copy with broken icons  *(fixed)*

`lib/features/economy/model/currency.dart` declared a second `MoneyCurrency`
whose `assetPath` returned `'imagescod.png'` (missing slash) and
`'images/plate.png'` (missing the `assets/` prefix). Nothing imported it, so
nothing broke, but importing both files would not have compiled.
`currency.dart` is now a re-export of the canonical enum in
`lib/features/facilities/model/facility.dart`, whose mapping is correct.
`facility.dart`'s public surface is untouched.

### H. `MoneyBag.operator /` returned null  *(fixed)*

`operator /(double other) {}` — no return type, empty body — so `bag / 2`
evaluated to `null`. Replaced with `MoneyBag.scaled(double)`.

### I. `EarningsCalculator` ignored 8 of 11 effect types  *(replaced)*

`tipCapIncrease`, `cookingEfficiencyBonus`, `ordersIncrease` and
`storageIncrease` all fell through a no-op `break`, and
`incomePerEventRange` — the one branch written for random income — matches
**zero rows** in the entire dataset. The calculator has been rewritten around
the channel model below and covers all 32 channels.

---

## Where the numbers now come from

`assets/data/income.json` (new, 2,788 facilities, 2,794 wiki rows) is a
transcription of the wiki facility tables keyed by the facility ids already in
`assets/data/facilities_jsons/*.json`. **No existing id, key or file was
renamed or removed.** Each row keeps the unit the wiki printed, in the
`channel` name. `assets/data/performer_income.json` (new, 61 performers) does
the same for the concert.

Both files were checked to have zero dangling ids against
`facilities_jsons/*.json` and `customers.json`, and
`python3 scripts/validate_data.py` exits 0.

47 wiki rows could not be matched to an app facility id. They are facilities
the app's data does not have yet (`Cake Stool` in six tiers, `Spongy Fence`,
`Sweet Cake Fountain`, `Brown Sugar Artisan Table`, `A Sweet Call`,
`Sweetness Overload`, `Soft and Sweet Dreamy Island`, `Scarlet Persimmon Tree`,
five Courtyard decors, and `Small Stump`/`Elegant Table` in Restaurant
Table 2–6). They are listed under "For the orchestrator" below.

---

## Every income source, with its formula

### 1. Tip jar — cod, online and offline

```
rate  = Σ tipPerMinute over unlocked facilities  (+ Apricat's tips/min while sweeping)
cap   = Σ tipCap over unlocked facilities        (Tip Desk only)
held(t minutes) = min(rate × t, cap)
time to fill    = cap / rate
with ad         = held × 2
```

Worked example — a brand-new account with only the free `Stone Bowl`
(cap 10,000, 5 cod/min): after 60 minutes the jar holds
min(5 × 60, 10,000) = **300 cod**; it fills at 10,000 / 5 = 2,000 minutes =
**33.3 hours**, so a 12-hour absence collects 3,600 cod, not a full jar.

Ceiling if every facility in the game were owned: **11,116 cod/min
(666,960/h)** into a **3,596,000 cod** jar, which fills in 5.4 hours.

Range: none — this is deterministic.

**Apricat** adds `tipsPerMinute` (12 at raise 0, 60 at raise 24) but alternates
sweeping (150→270 s) and resting (250→130 s). The wiki does not say whether the
rate applies only while sweeping, so the app shows her figure as a separate
line and calls it a ceiling. *Unverified.*

### 2. Buffet — cod, offline only

```
perHour = Σ buffetCodPerHour over unlocked buffet facilities
banked(h) = perHour × min(h, 12)  +  0.10 × perHour × friends × min(h, 4)
adBonus   = min(0.40 × banked, 1,000,000)
```

Worked example — only the free `Simple Carousel` (3,200 cod/h), away 3 hours:
3,200 × 3 = **9,600 cod**, ad bonus 0.40 × 9,600 = **3,840**, total 13,440.
Away 20 hours: still 3,200 × 12 = **38,400**, because accrual stops at 12 h.

Ad break-even: 1,000,000 / 0.40 = **2,500,000 cod banked**. Past that the ad
stops improving, which is a real decision the page now surfaces.

Ceiling if every buffet facility were owned: **728,780 cod/h**, i.e. the 12-hour
cap of 8,745,360 cod is reached, and the ad is capped, after 3.4 hours.

Friends: *"Each friend working will increase the buffet's revenue by 10% for 4
hours"* (wiki Buffet page, Update 5.1). How many friends can work at once is
**not published**, so the page asks.

### 3. Plates

```
facilities  = Σ buffetPlatesPerDay      (Self-serve Drinks + Time Clock, once per daily reset)
part-time   = (200 + Yolky's platesPer4Hours) per 4 hours, so × 6 per day
```

Worked example — Yolky at raise 24 (140 plates/4 h): part-time gives
(200 + 140) × 6 = **2,040 plates/day**. Every drinks and clock facility owned
adds **5,942/day** on top.

Yolky's table in `staff.json` matches the wiki exactly (all 25 levels).

Not modelled — **no published rates**: plates dropped by buffet customers,
Buffet Get Together parties, Gachapon prizes, daily tasks, events.

### 4. Cod while the game is open

```
perHour = Σ (amount × 3600 / seconds) over unlocked codPerSeconds facilities
        + Eggy's codPer60Seconds × 60
```

Worked example — `Fine Oven` is +95/30 s → 95 × 120 = **11,400 cod/h of play**.
`Ornate Oven` +160/30 s → 19,200/h. Eggy at raise 24 is 1,600 cod/60 s →
**96,000 cod/h**, and *"unlike most staff members Eggy takes no breaks"*
(wiki Eggy page), so his rate is not duty-cycled.

Ceiling from facilities alone: **7,582,320 cod/h of play**. This is the single
biggest number in the game and it is why `Guide:Cod` tells active players to
buy mailboxes and barbecues first.

> **Wiki error found.** The prose on
> [Eggy the Handyman](https://animalrestaurant.fandom.com/wiki/Eggy_the_Handyman)
> says *"at maximum raise he produces 210,000/60s"*. `Template:Raise/Eggy` says
> 1,600 cod/60 s at level 24 and 210,000 cod **cost** at level 24. The prose has
> read the wrong column. `staff.json` matches the table and is correct.

### 5. Dessert Bar / Coffee Bar / Bar — cod per purchase

```
bonus = Σ codPerPurchase over unlocked facilities, applied to each purchase
```

Worked example — `Fruit Platter` is +40/purchase. All three slots fully owned
sum to **+18,690 cod per purchase**. How often a customer purchases is **not
published**, so the page takes a purchase count from the player instead of
inventing a customer arrival rate.

### 6. Courtyard gathers — cod and film, random

```
perGather.min = Σ min over unlocked courtyard payout facilities
perGather.max = Σ max
midpoint      = (min + max) / 2      ← the mean of the endpoints, NOT an expected value
```

Worked example — `Log Door` alone pays **95–4,800 cod** per gather.
`Pine Fence (Short)` tier 1 pays **3–58 film**.
Everything owned: **78,649–3,970,000 cod** and **5,044–100,050 film** per
gather.

Budget: 3 free gathers a day plus up to 6 more from ads (wiki Courtyard page).

**Unknown:** one gather brings 6–10 customers and *"each customer will gift you
Film, Cod and Stars"*. The wiki prints each facility's range without saying
whether it is per gather or per customer. The app shows the per-gather reading
and says so on the card. If it is per customer, real income is up to 10× the
figure shown. The distribution of the roll is also unpublished, which is why
the midpoint is labelled a midpoint and not an expected value.

### 7. Terrace

```
flat    = Σ terracePayFlat        ("Customers pay +N")
percent = Σ terracePayPercent     ("Customers pay N% more")
view    = Σ codPerFlowerView      (Display Stand, Open Air Cinema, Telescope)
bottles = Σ bottlesPerDay         (Meal Side Cabinet)
```

Ceilings: 13,384,000 cod flat, +356 %, 171,700 cod per view, 36 bottles/day.

**Unknown and flagged in the UI:** whether "Customers pay +N" is charged per
customer or per gather, and whether the percentages add or compound. A +356 %
sum would mean customers pay 4.56× — plausible for a maxed terrace, but not
stated anywhere. These lines are labelled "summed" and described as a measure
of investment, not as cod about to arrive.

Verified: 6 gathers/day; cooldowns 3, 10, 15, 40, 80, 120 minutes (4.5 hours of
elapsed time for all six); a rejected gather costs 1–50 minutes. The existing
"enter your own cod per gather" input is kept, because that remains the only
honest way to get a real terrace number.

### 8. Takeout — bells

```
extra orders = Σ takeoutOrders (Provision Tables)   → +62 if all owned
capacity     = Σ takeoutCapacity                    → +3,760 if all owned
documented ceiling: 65 orders/day
```

*"A maximum of 65 orders are possible every day, increased by upgrading Support
Chef Meow and purchasing Provision Table facilities."* — wiki Takeout page.
Support Chef Meow's raise runs `maxDailyOrders` 1 → 5.

**Not modelled — no formula exists.** What one order pays in bells *"depends on
item, quantity and item quality"*. The app counts order slots and says
explicitly that it is not converting them to bells.

### 9. Fishing pond booths

```
per payout (every 5 minutes) = exactly one of the booth's two outcomes
expected value               = Σ chance × amount   ← only computable for 5 of 140 booths
```

The wiki writes every booth as *"{{Plates|+10}} **or** {{Cod|+100}}"* and
publishes **no probabilities** for any of the 134 booths it lists.
`booth_owners.json` carries a `chance` on only 5 of its 140 entries
(`traditional_popcorn` 0.12/0.88, `portrait_drawing_booth` 0.12/0.88,
`old_joe`, `sketch_artist`, `picnicking_rabbit` 0.2/0.8) and those five values
have **no source I could find** — treat them as unverified. The remaining 252
outcome rows have `chance: null`.

So the Bank page shows **min and max only**, and says the split is unpublished.
`EarningsCalculator.expectedValue` returns `null` rather than a number when any
probability is missing or the probabilities do not sum to 1.

Worked example — `Traditional Popcorn` over one hour is 12 payouts: **either**
120 plates **or** 1,200 cod, or any mix between. The page shows both extremes
and says they are the two ends of one distribution, not two incomes.

Verified extra: booth owners drawn by a rare fish have a **50 % chance of 5
diamonds**; rare fish spawn every 12–72 hours (wiki Fishing Pond, v8.5.8g).

Amount check: 129 of 134 booths match the wiki exactly. Five do not — see
"For the orchestrator".

### 10. Concert — performers, bands, posters

```
one show = amountPerMinute × showDurationMinutes
with poster and band decor = show × (1 + (posterPercent + bandPercent) / 100)
```

Worked example — Cutie White Bunny: 10 film/min for 30 min = **300 film**.
With a +50 % poster and the Cutie Girlies' +13 % from concert decor:
300 × 1.63 = **489 film**.

Every band has the same shape: two film members and two cod members. The best
single shows in the game both belong to **Ball Lightning**, whose members play
for 55 minutes: **Bassist Brown Wolf, 16 film/min × 55 = 880 film** and
**DJ Wolf, 1,200 cod/min × 55 = 66,000 cod**. Nebulae is second at 800 film
(Rapper Bean) and 60,000 cod (Leader Scotch Collie) over 50 minutes.

* Poster percentages: all **155** posters in `posters.json` match
  `Template:Poster` **exactly**. Verified.
* Poster caveat from the wiki: *"Earning increase from the poster only applies
  when all members in that poster are performing."* Only one poster can be
  displayed at a time.
* Band decor: 32 Concert wall/floor decors give a named band +8 % to +31 %
  cumulative.
* Ticket Booth caps: **10,000,000 cod / 100,000 film**. Income past those is
  lost.
* Free daily invites: the Light facilities sum to **56**, but
  [Guide:Film](https://animalrestaurant.fandom.com/wiki/Guide:Film) says
  *"Up to 20 can be earned via lights, up to 10 from ads, up to 3 from Treasure
  Hunts."* The app shows the capped figure and explains the discrepancy.
  Confidence in the cap: **medium** — it is a community guide, not the FAQ.

**Not modelled:** fan tips during a gather. The wiki says fans of the
performing act tip film or cod during a Courtyard gather but publishes no
amounts.

### 11. Gachapon and Wishing Well

Draws and wishes combine across unlocked machines (FAQ, quoted above).
Owning all 29 gachapon machines sums to **292 draws/day**, while the Gachapon
page's own summary says *"a maximum of 286 draws + 1 free draw on each side per
day"*. One of the two is stale and I could not determine which, so the page
shows both figures and says so. Wishing Well wishes sum to **+44**.

**Not modelled:** what a draw is worth. The prize pool is weighted and the
weights are not published.

### 12. Stoves — cooking efficiency

The wiki prints `+N% efficiency` per stove. Summing every stove gives **3,018 %**,
which cannot be a straight subtraction from cook time. The mapping from the
combined percentage to actual seconds is **not published anywhere**.

`stove_cook_calculator.dart` previously multiplied a dish's base seconds by
`1 - pct/100`, i.e. it claimed a formula the sources do not support (and would
have returned 0 seconds for any two decent stoves). It now lists the bonus and
states that the conversion is unknown, rather than showing a fabricated cook
time. The Bank page does not convert it either.

### 13. Flowers, letters and stars

`flowers.json` holds per-level `baseView` and `avgStarPerView`. These produce
**star rating**, not currency, so they are out of scope for the Bank page.
Garden Tables add flower **views** (+43 if all owned), which is tracked.

---

## What is still unmodelled, and why

| Source | Why not modelled |
|---|---|
| What a customer pays for a dish | No published price-per-customer formula; depends on rating, dish and customer tier |
| Promotion (Dori, Speaker) | Attracts customers; the cod that follows has no published formula |
| Bells per takeout order | *"depends on item, quantity and item quality"* — no formula |
| Buffet Get Together parties | No published plate amounts |
| Buffet customer plate drops | Chance-based, no published rate |
| Gachapon prize values | Weighted pool, weights unpublished |
| Wishing Well prize values | Unpublished |
| Terrace bottle-spin prizes | Only one figure is published: diamonds at 2.94 % (Guide:Diamond, community) |
| Terrace mini-games | Unpublished |
| Concert fan tips during a gather | Unpublished |
| Letters, achievements, daily tasks | One-off, unpublished |
| Events, battle pass, redemption codes, Tapjoy, IAP packs | Time-limited and unpublished, except the Value/Luxury pack diamond totals in Guide:Diamond |
| Vegetable Garden buttons | Sale prices exist per crop but the throughput does not |
| Pet Paradise payouts | Ranges are transcribed into `income.json`, but whether several apparatus stack is unpublished, so the calculator reports the **best single** one and the count rather than a sum |
| Game Machine film | Same: best single machine, not a sum |

---

## Community claims used, and how much to trust them

| Claim | Source | Used? | Confidence |
|---|---|---|---|
| Buffet ad = 40 % of banked, capped at 1,000,000 cod | Guide:Cod (community) | **Yes** — replaces the app's unsourced 1.5×/1,500,000 | High: two internally consistent statements on the same page |
| Tip jar ad = ×2 | Guide:Cod (community) | Yes | High: matches the in-game "Cod ×2" button described in several third-party guides |
| Concert invites capped at 20/day from lights | Guide:Film (community) | Yes, as a cap over the summed 56 | Medium |
| All `/min` effects feed one tip jar | Guide:Cod wording *"Increase tips +x/Every minute"* | Yes | High: it is the game's own effect text |
| Booth `chance` values (0.12/0.88, 0.2/0.8) already in `booth_owners.json` | Unknown | **No** — shown as ranges instead | Low: no source found |
| "You can buy more tip desks… add multiple ones" (third-party guide) | HubPages/LevelSkip | Consistent with the FAQ's stacking rule, so no separate use | — |

Third-party sites (LevelSkip/HubPages, MrGuider, LevelWinner, Playoholic,
VMOSCloud) were checked. None contained a number the wiki did not, and none
contradicted the wiki. Nothing from them was used as a value.

---

## For the orchestrator — data fixes outside my file ownership

These are in files I do not own. Nothing in the Bank page depends on them being
fixed (it reads `income.json` instead), but the Facilities, Customers and Staff
pages will show wrong numbers until they are.

**`assets/data/facilities_jsons/buffet_facilities.json`**
1. 74 rows use `incomePerMinute` for values the wiki prints as `/h`. They should
   be `incomePerInterval` with `intervalMinutes: 60` (which the file's other 48
   buffet rows already do). Correct values are in `income.json` under
   `buffetCodPerHour`.
2. `a_favorite_of_both_children_and_adults` is a **duplicate** of
   `ice_cream_shop`: the wiki's first Ice Cream row lost its name and its
   description ended up as the title. Same rating (+25), same income (4,200/h).
   Deleting it needs care — it is an existing id and may be in someone's save.
3. The 11 `Time Clock` facilities have **no plates effect at all** in the app
   (`wooden_time_clock` +45/day, `pawprint_time_clock` +55,
   `cat_cial_recognition` +70, `rudder_time_clock` +72,
   `bearhug_time_clock` +75, `crabapple_flower_brocade` +75,
   `march_hare_attendance_machine` +90, `punctual_lemon` +95,
   `ufo_time_clock` +100, `fluffy_clouds_hot_beverage` +130,
   `serene_elegance` +170). That is 942 plates/day missing.

**`assets/data/facilities_jsons/restaurant_facilities.json`**
4. `mousse_tip_desk` has no `tipCapIncrease`; the wiki gives it +50,000.
5. Groups `Table 2`–`Table 6` are each missing `Small Stump` and
   `Elegant Table` (36 items in Table 1, 34 in the rest).
6. 289 `{{Cod|+N/min}}` rows exist on the wiki for this area and almost none are
   in the shard.

**`assets/data/facilities_jsons/courtyard_facilities.json`**
7. The 13 stub rows listed in finding E claim per-minute income that does not
   exist. The real effect is a per-gather range.
8. Groups `Short Fence`, `Long Fence`, `Wall Decor`, `Table Decor`, `Carpet`,
   `Floor Decor`, `Certificate of Honor`, `Pet Houses`, `Pet Paradise` hold two
   stub rows each that duplicate the real `Short Fences` / `Long Fences` /
   `Decor (Wall)` / `Decor (Floor)` groups.

**`assets/data/customers.json`**
9. **60 of the 61 performer blocks are empty** — `showDurationMinutes: null`,
   `callbackRequirementHours: null`, `baseEarnings.amountPerMinute: null`,
   empty `fansCustomerIds`, `canInviteThis`, `canBeInvitedBy`, `posterIds`.
   Only `cutie_white_bunny` is populated. Correct values for all 61 are in
   `assets/data/performer_income.json` and can be copied straight across.
10. The wiki lists **72** performers; the app has 61.

**`assets/data/booth_owners.json`**
11. Five booths disagree with `Template:Customers/Booth Owning`:
    * `candied_hawthorn` — app `{plates 30, cod 250}`, wiki `{plates 30, rating +0.4}`
    * `egg_waffle` — app `rating 0.4`, wiki `rating 0.6`
    * `exquisite_embroidery` — app empty, wiki `{plates 80, cod 700}`
    * `pineneedle_lacquer_fans` — app empty, wiki `{plates 75, rating +0.7}`
    * `dazzling_iron_fireworks` — app empty, wiki `{plates 90, cod 730}`
12. 252 outcome rows have `chance: null` and the 5 that do not have no source.
    Either find a source or drop the field; a half-populated probability table
    invites exactly the fabricated averages this report is trying to avoid.

**`assets/data/staff.json`**
13. `apricat` has only **11** of 25 raise levels. The missing 14 run
    tips/minute 34 → 60 (level 24 = 60 cod/min, sweep 270 s, rest 130 s, cost
    300,000 cod). `eggy` and `yolky` match the wiki exactly.

**`assets/images/`**
14. There is no `buttons.png`, so the Buttons currency renders its fallback.
    Every `Image.asset` I added guards with an `errorBuilder`.

---

## Files changed

| File | Change |
|---|---|
| `assets/data/income.json` | **new** — 2,788 facilities, 32 channels, units intact |
| `assets/data/performer_income.json` | **new** — 61 performers |
| `lib/features/economy/model/currency.dart` | now re-exports the canonical enum; broken duplicate removed |
| `lib/features/economy/model/money_bag.dart` | `operator /` fixed → `scaled()`; adds `AmountRange` and `RangeBag` |
| `lib/features/economy/model/income.dart` | **new** — channel model, tolerant parsing |
| `lib/features/economy/model/economy_constants.dart` | **new** — every constant carries its source |
| `lib/features/economy/data/income_repository.dart` | **new** |
| `lib/features/economy/data/side_income_repository.dart` | **new** — booth and staff payout fields |
| `lib/features/economy/logic/earnings_calculator.dart` | rewritten; all 32 channels, worked examples in comments |
| `lib/features/bank/data/bank_service.dart` | rewritten; reads all three progress buckets |
| `lib/features/bank/ui/bank_page.dart` | 13 cards, same widget vocabulary and theme |
| `lib/features/facilities/model/stove_cook_calculator.dart` | no longer invents a cook time |

`python3 scripts/validate_data.py` exits 0. There is no Dart toolchain in this
container, so nothing here has been compiled; every file was re-read after
editing and delimiter-checked, and every cross-file symbol was grepped for its
definition.
