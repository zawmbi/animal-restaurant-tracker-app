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
10. `validate_data.py`    – parses every JSON file and reports dangling cross-references

`validate_data.py` is safe to run on its own and is the thing to wire into CI.
