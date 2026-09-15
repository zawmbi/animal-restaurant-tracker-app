# Wiki data scrapers

Regenerate `assets/data/*.json` from https://animalrestaurant.fandom.com via the MediaWiki API.

Requires only python3 + `curl`. Pages are cached under `scripts/.cache/` (gitignored) so
re-runs are cheap and polite to the wiki.

Run order (each writes straight into `assets/data/`):

1. `scrape_customers.py`  – customer entries from `Category:Customers`/`Performer`/`Booth Owner`/…
2. `scrape_page_mementos.py` – per-customer `{{Memento}}` blocks (feeds `customers.json[].mementos`)
3. `scrape_mementos.py`   – the full memento registry from `Template:Mementos` → `mementos.json`
4. `reconcile_mementos.py` – makes `customers.json[].mementos` and `mementos.json` agree, then
   re-derives the structured `requirements` blocks
5. `scrape_posters.py`    – `Template:Poster` → `posters.json`
6. `scrape_dishes.py`     – missing recipe pages → `dishes.json`
7. `scrape_food_truck.py` – `Template:Food Truck` → `food_truck_recipes.json`
8. `scrape_movies.py`     – `Open Air Cinema` → `movies.json`
9. `infer_dish_links.py`  – dish-page `for=`/`orders=` → customer recipe/order links
10. `scrape_updates.py`   – the `Updates` changelog → `updates.json`
11. `validate_data.py`    – parses every JSON file and reports dangling cross-references

`validate_data.py` is safe to run on its own and is the thing to wire into CI.


## `scrape_updates.py`

Independent of the other nine — it reads one page and writes one file, so it
can be run on its own whenever the game ships a version.

The `Updates` page is a `<tabber>` with a tab per major version, and the
formatting drifts across six years of edits. Three variations cost a run each
before the output was complete, so they are worth knowing about:

* **Heading spelling.** v9 and newer write `==v11.26.0g==`; v8 and older write
  `==v8.19.0.g==`, with a dot before the suffix. Matching only the first form
  silently drops four whole tabs — and does not look like a failure, because
  those releases' bullets get absorbed into whichever release was parsed last.
* **Month spelling.** `September 7th 2026` in v11, `Apr. 30th 2021` in v8.
  Dates are matched on the three-letter prefix.
* **Trailing period.** `'''Sep. 29th, 2020.'''` — inside the bold markers.

Eleven v5-v7 releases have no date line at all; each is a bare "Game
optimizations and bugs fixed." They are skipped rather than given an invented
date, and the script prints which ones, so the count can be checked against
the page rather than assumed.
