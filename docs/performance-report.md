# Performance report

Scope: startup time, scroll smoothness, memory, and data loading. **No visual
changes.** Every item below is behaviour- and appearance-preserving; anything
that would have moved a pixel is listed under "Not done" instead.

There is no Dart/Flutter toolchain in this container, so nothing here was
compiled or run. Every changed file was re-read in full after editing, all
imports were checked to resolve, delimiters were verified balanced with a
Dart-aware (string/comment-stripping) checker, and every cross-module symbol
was grepped before use.

---

## 1. Asset payload: −1.02 MB shipped, −25 MB decoded

### Images (−950,820 B, −86%)

Every `Image.asset` in the entire app renders at **16–26 logical pixels**
(verified: the largest is `width: 26` in `bank_page.dart`; `RewardIcon`
defaults to `size: 18`). There is no `AssetImage`, `DecorationImage` or
`ImageIcon` anywhere, so no image is ever shown large. The source PNGs were
wildly oversampled — `bell.png` was 2000×2000 for an 18 px icon.

All five were resampled to a 256 px longest edge (≈10× the largest logical
size, ≈2.5× the device pixels needed at DPR 4) with Lanczos on **premultiplied
alpha**, preserving aspect ratio, colour and mode. No cropping, no recolouring,
no quantisation. Ancillary metadata chunks were dropped as a side effect.

| file | before | after | saved |
|---|---|---|---|
| `plate.png` 1080×1080 → 256×256 | 638,089 | 41,865 | −596,224 |
| `bell.png` 2000×2000 → 256×256 | 117,508 | 20,935 | −96,573 |
| `cod.png` 465×537 → 222×256 | 111,620 | 27,950 | −83,670 |
| `like.png` 920×964 → 244×256 | 26,368 | 9,092 | −17,276 |
| `diamond.png` 512×512 → 256×256 | 15,376 | 10,626 | −4,750 |
| `bells.png` — **deleted** | 117,508 | 0 | −117,508 |
| `cod_og.png` — **deleted** | 52,801 | 0 | −52,801 |
| **total** | **1,102,490** | **151,670** | **−950,820** |

`bells.png` was a **byte-identical duplicate** of `bell.png` (same MD5,
`f6ebac24…`) and neither it nor `cod_og.png` is referenced anywhere —
`movies_page`/`movies_detail_page` map the JSON currency key `'bells'` to
`assets/images/bell.png`. Both are unreachable dead weight.

**Verification of visual equivalence.** Original and resized were each
downscaled to the real on-screen size (26 logical px at DPR 2, 3 and 4) through
the same premultiplied-alpha path, then compared per channel with the colour
error weighted by opacity (error in transparent pixels is invisible):

| file | mean Δ/255 | max Δ/255 | px > 2/255 | px > 8/255 |
|---|---|---|---|---|
| plate | 0.12 | 14.1 | 1.4% | 0.15% |
| bell | 0.12 | 13.3 | 3.4% | 0.12% |
| cod | 0.09 | 8.1 | 1.3% | 0.01% |
| like | 0.06 | 8.5 | 2.6% | 0.01% |
| diamond | 0.06 | 9.0 | 1.4% | 0.05% |

Mean error is ~0.04% of full scale; the handful of pixels above 8/255 are
single antialiased edge samples. All eight remaining PNGs were then re-verified
byte-for-byte as valid PNGs (signature, every chunk CRC recomputed, no trailing
bytes, full pixel decode).

**Decoded memory** — this is the larger win, because `Image.asset` decodes at
full source resolution regardless of display size:

| | before | after |
|---|---|---|
| plate | 4.67 MB | 262 KB |
| bell | **16.0 MB** | 262 KB |
| cod | 999 KB | 227 KB |
| like | 3.55 MB | 250 KB |
| diamond | 1.05 MB | 262 KB |
| **total** | **~25.0 MB** | **~1.2 MB** |

### Fonts (−89,200 B)

`pubspec.yaml` declared four families but only **`Quano`** is named by any code
(4 occurrences, all in `lib/theme/app_theme.dart` — the only `fontFamily:` in
`lib/`). `MondayFeelings`, `HighwayGothicD` and `PerfectLemonade` have **zero
references across `lib/`, `assets/`, `android/`, `ios/`, `web/`, `macos/`,
`windows/` and `linux/`**. A font family no code names cannot render, so
removing the declarations is invisible. The `.ttf`/`.otf` files were left on
disk in `assets/fonts/`.

Note: `assets/fonts/` is *not* in the `assets:` list, so the other 11
Highwaygothic variants (~143 KB) were never bundled — they are repo clutter,
not download weight.

---

## 2. JSON loading: off the main isolate, and decoded once

`lib/features/shared/json_loader.dart` was a `Map<String, dynamic>` cache with
the classic **"cached the result but not the in-flight future"** race: it
checked `containsKey`, then `await`ed the load. Two callers arriving before the
first finished both loaded *and* both decoded. It also ran `json.decode` on the
main isolate, so opening a big page dropped frames.

Now:

* the cache holds the **`Future`**, so concurrent callers share one load and
  one decode;
* payloads ≥ 32 KB are decoded via `compute()` on a **background isolate**
  (below that the isolate hand-off costs more than the decode). The callback is
  a top-level `_decodeJson`, not a closure or an instance tear-off, so it is
  sendable;
* failures are never cached — the entry is removed so the next caller retries;
* a new `evict(path)` lets a repository drop the raw maps once it has built and
  cached its models.

This matters most at startup: `SearchIndex.preload()` is kicked off from
`HomePage.initState` and transitively pulls **~1.6 MB of facility shards** plus
customers, letters and dishes. All of that parsing now happens off the UI
thread.

**Duplicate decode removed.** `courtyard_facilities.json` (512 KB, 1336
entries) was being read *twice* — once by `CourtyardRepository` into
`CourtyardFacility` models and once by `FacilitiesRepository` for
`FacilityArea.courtyard`, each with its own `rootBundle` + `jsonDecode`. Both
now go through `JsonLoader`, so the 512 KB parse happens once and the two
repositories share it. `signature_store_facilities.json` was likewise decoded
twice (once by `FacilitiesPage`, once by `FacilitiesRepository`) and is now
shared.

**Raw-JSON eviction.** Repositories that are the sole `JsonLoader` consumer of
their asset call `evict` after building models, so the app no longer holds two
representations of the same data for the whole session: `customers.json`
(315 KB) + `booth_owners.json` (74 KB) + `letters.json` (170 KB) +
`staff.json` (125 KB) + `posters.json` (75 KB) + `facilities.json` (94 KB) +
`pets.json` (131 KB) + `dishes.json` (102 KB) + `movies.json` + the battle-pass
files ≈ **1.1 MB of JSON text**, whose decoded `Map`/`List` object graph is
typically 3–5× that on the Dart heap. Sole-consumership was verified by exact
full-path grep for each asset. `mementos.json` and `mementos_extra.json` are
deliberately **not** evicted — `MementosIndex` re-reads them on every call, and
`mementos_detail_page.dart` loads `mementos.json` directly.

---

## 3. Repository caching: single-flight everywhere

Every repository had the same shape — cache the *value*, not the *future* — so
`SearchIndex.preload()` racing the page the user opened caused a duplicated
load **and** a duplicated model-construction pass. All of these now cache the
future, clear it on error so a retry is still possible, and expose the same
public API:

`customers` · `posters` · `letters` · `movies` · `staff` · `pets` · `dishes` ·
`facilities` (both the `model/data/` and `data/` ones) · `courtyard` ·
`battle_pass`.

Concretely, opening Customers while the home page's preload is still running
went from *two* 315 KB decodes plus *two* passes building 564 `Customer`
objects, to one of each.

`CustomersRepository.withTag()` / `.seasonal()` are memoised too. They are
called straight from `_CustomersGrid.build()`, which re-runs on every checkbox
tap, so each tap used to re-filter all 564 customers and hand `FutureBuilder` a
brand-new `Future` that forced a re-subscribe. Verified safe: both consumers
(`customers_page._applySort`, `booth_owners_page._applySort`) copy with
`[...list]` before sorting, and `_applyFilters` never mutates.

A side benefit of stable futures: `FutureBuilder`s that call `all()` from
`build()` (letters, movies, dishes, customers, booth owners) stop tearing down
and re-subscribing their stream on every rebuild. In `dishes_page.dart` that
also removes a latent one-frame full-screen spinner flash, because it gates on
`snap.connectionState != ConnectionState.done` while handing `FutureBuilder` a
fresh future each build. The steady-state rendering is unchanged; only a glitch
frame disappears.

Error semantics were preserved deliberately:
`FacilitiesRepository._tryLoad` still rethrows `FormatException` (malformed
shard) while swallowing "asset not bundled", matching the original split
between `_tryLoadString` and `jsonDecode`; and `BattlePassRepository.byId` was
kept `async` so an unknown id still surfaces as a failed `Future` rather than
throwing synchronously inside a caller's `build()`.

---

## 4. Courtyard page: 3 full scans per tap → 0

`CourtyardPage.build()` calls `availableGroups()`, `allSeriesSorted()` and
`byGroupAndSeries()`, and `build()` re-runs on **every checkbox tap**
(`setState`). Each tap therefore cost, over **1336 facilities**: one set-build
pass, one set-build + sort pass, and one filter + sort pass — roughly 4,000
element visits plus two sorts, per tap.

`_facilities` never changes after the single load, so all three are now
memoised in `CourtyardRepository` (the filtered view keyed per
`(group, series)`). Results are byte-identical — same predicate, same
comparator, same order. Each memo is guarded on `_loaded`, so a call that
somehow arrives before the JSON is in can never freeze an empty result into the
cache.

`allFacilities` is memoised the same way; it previously allocated a fresh
`List.unmodifiable` copy on every access (`completion_service` calls it).

---

## 5. Global search: the hottest path in the app

`GlobalSearchPage` calls `SearchIndex.search()` straight from the text field's
`onChanged` with **no debounce at all** (`home_page` debounces 200 ms; this one
does not). Every keystroke ran, on the main isolate:

* `.toLowerCase()` on 564 customer names **and every one of their tags**;
* `.toLowerCase()` on 257 letter names + series;
* for each of 249 dishes: name, every section, plus `_inferCategoryLabel()`
  which itself built a `Set` of lower-cased sections;
* `.toLowerCase()` on ~2,500 facility names;
* and — by far the worst — `MementosIndex.all(search: q)`, which has **no cache
  of its own**: it re-read both memento assets, rebuilt a customer-id map over
  all 564 customers, and re-allocated every `MementoEntry` from scratch.

That is well over 10,000 short-lived `String` allocations per character typed,
plus a full re-materialisation of the mementos list.

The index is now built **once** during `preload()`: every searchable field is
lower-cased ahead of time into per-entity haystacks, `_inferCategoryLabel` is
evaluated once per dish (its result is also the subtitle), and the mementos
list is fetched once with no filter and filtered locally using the *identical*
predicate `MementosIndex` applies. A keystroke is now a pure `contains` scan
over pre-computed strings that allocates nothing but the hit list.

Result construction, iteration order (customers → letters → dishes →
facilities → mementos), the `SearchHit` fields, and the final
`(type.index, title)` sort are all unchanged, so the rendered result list is
identical. `preload()` is also single-flight now, and the tolerance for
optional sections failing (dishes/facilities/mementos) is preserved.

---

## Files changed

```
lib/features/shared/json_loader.dart                     rewritten
lib/features/search/data/search_index.dart               rewritten
lib/features/courtyard/data/courtyard_repository.dart    memoised + shared decode
lib/features/facilities/data/facilities_repository.dart  single-flight + shared decode
lib/features/facilities/model/data/facilities_repository.dart
lib/features/customers/data/customers_repository.dart
lib/features/customers/data/posters_repository.dart
lib/features/letters/data/letters_repository.dart
lib/features/movies/data/movies_repository.dart
lib/features/staff/data/staff_repository.dart
lib/features/pets/data/pets_repository.dart
lib/features/dishes/data/dishes_repository.dart
lib/features/battle_pass/data/battle_pass_repository.dart
lib/main.dart                                            parallel startup
pubspec.yaml                                             3 unused font families
assets/images/{plate,bell,cod,like,diamond}.png          resized
assets/images/{bells,cod_og}.png                         deleted (unreferenced)
```

`lib/main.dart`: `TimerService.init()`, `UnlockedStore.init()` and
`appSettings.load()` were awaited one after another *behind* `Firebase
.initializeApp`, so cold start paid four round trips end to end. None of them
touches Firebase during init — `TimerService` only sets up local notifications
and timezones, the other two only read `SharedPreferences`, and
`UnlockedStore`'s Firestore sync is gated on `_user != null`, which `AuthBinder`
only sets after `runApp`. They are now started immediately and run concurrently
with Firebase init. All four are still awaited before `runApp`, so the first
frame sees exactly the same state.

`lib/app.dart` is an empty file that nothing imports;
`lib/features/customers/shared/data/json_loader.dart` contains only
`// TODO Implement this library.` and is likewise unreferenced. Both were left
alone (deleting them is cleanup, not performance).

---

## Not done — and why

### Would have changed the design

1. **`letters_page.dart` builds all 257 letter chips eagerly.** A
   `SingleChildScrollView` wrapping a `Wrap` whose children come from
   `list.map(...).toList()`, all inside `AnimatedBuilder(animation: store)` — so
   one checkbox tap rebuilds every chip. There is no lazy `Wrap` in Flutter;
   converting to a grid or sliver would change how the variable-width chips
   flow. **Needs a design decision.**

2. **`dishes_page.dart` builds ~500 grid tiles eagerly.** Five `_section()`
   `ExpansionTile`s each hold a `GridView.builder` with `shrinkWrap: true` and
   `NeverScrollableScrollPhysics` inside a `SingleChildScrollView`.
   `shrinkWrap` defeats laziness: the grid lays out *all* its children to
   measure itself. "All Recipes" alone is 249 tiles, and every dish appears
   again in its category section. The fix is a `CustomScrollView` with
   `SliverList`/`SliverGrid`, which restructures the tree and the expansion
   animation. Same pattern in `facilities_page.dart` and
   `facility_detail_page.dart`.

3. **`certificate_one.png` and `film.png` left untouched.** Resizing
   `certificate_one.png` (472×588 RGB) to 205×256 would cut its decoded
   footprint from 1.1 MB to 210 KB but *grows* the file by 2,834 B — its
   photographic content compresses worse per pixel at the smaller size.
   Palette-quantising it gets 23,072 → 13,204 B but shifts colours (max ΔRGB
   17), i.e. a recolour, which is out of bounds. `film.png` is a 206×300
   *palette* PNG at 16.7 KB; any resize forces it to RGBA and inflates it to
   42 KB. Both need a judgement call, so they were left as-is.

4. **No `cacheWidth`/`cacheHeight` added to `Image.asset`.** Doing it correctly
   requires `MediaQuery.devicePixelRatioOf(context)` at each call site;
   hard-coding the logical size (e.g. `cacheWidth: 18`) would render visibly
   blurry on 2×/3× screens — a real visual regression. With the source assets
   now right-sized the remaining win is ~1.2 MB. The safe recipe, if wanted:
   `cacheWidth: (18 * MediaQuery.devicePixelRatioOf(context)).round()`.

### Outside my file ownership

5. **`unlocked_store.dart` — rebuild scope (the biggest remaining win).**
   `UnlockedStore extends ChangeNotifier` and calls `notifyListeners()` on any
   change, so a single checkbox tap rebuilds *every*
   `AnimatedBuilder(animation: UnlockedStore.instance)` subtree in the app — on
   Courtyard that is the entire list. The clean fix is a per-entry listenable on
   the store, e.g. `Listenable listenableFor(String bucket, String id)` backed
   by a `Map<String, ValueNotifier<bool>>`, so each row listens only to itself.
   Rows could then wrap just their `Checkbox` and keep pixel-identical output.
   I could not do this without editing `unlocked_store.dart`.

6. **`global_search_page.dart` (`search/ui/`) has no debounce.** It calls
   `SearchIndex.search()` directly from `onChanged`. My changes make each search
   far cheaper, but a 200 ms debounce (as `home_page` already does) is the right
   fix. It also does not sequence its futures, so a slow response can overwrite
   a newer one — guard with a request id.

7. **`mementos_index.dart` has no cache whatsoever.** `MementosIndex.all()`
   re-reads both assets, rebuilds a 564-entry customer map and re-allocates
   every `MementoEntry` on *every* call. I worked around it inside the search
   index by calling it once, but `mementos_page.dart` and
   `mementos_detail_page.dart` still pay the full cost on each call. Caching the
   built list and filtering over the cache would be a large win for those pages.

8. **`home_page.dart` preloads ~2 MB at app start.**
   `SearchIndex.instance.preload()` in `initState` now transitively loads all
   facility shards, customers, letters, dishes and mementos. Off-isolate
   decoding means it no longer janks, but it is still a lot of work at launch
   for a feature the user may never open — consider triggering it on first focus
   of the search field.

9. **`lib/features/bank/data/terrace_customers.dart`** still uses `rootBundle` +
   `jsonDecode` directly and has the same in-flight-future gap, but the asset is
   2.6 KB with one call site, so the win is negligible.

10. `completion/**`, `shared/widgets/**`, `staff/ui/**`, `pets/ui/**`,
    `battle_pass/ui/**`, `redemption_codes/ui/**`, `aromatic_acorn/**`,
    `mementos/**`, `customer_detail_page.dart` and `assets/data/**` were not
    touched. Worth flagging: `shared/widgets/reward_icon.dart` references
    `assets/images/memento.png`, and `movies`/`dishes` fall back to
    `assets/images/$currencyKey.png` for keys like `promote`, `gachapon` and
    `diamonds` — **none of those files exist**. `RewardIcon` has no
    `errorBuilder`, so a memento reward throws at paint time. That is a
    correctness bug, not a performance one, but it lives in a file I do not own.
