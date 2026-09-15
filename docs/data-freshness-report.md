# Data freshness: what is stale, and why it went stale

Written 15 Sep 2026, after `updates.json` turned out to be six months old.

The changelog is now scraped (`scrape_updates.py`, 169 releases to v11.26.0g),
which makes it usable as a checklist: every release names the content it
added, so the game's own release notes can be tested against `assets/data/`.
Doing that turns up two problems — content we are missing, and the reason we
did not know.

---

## 1. Content added since roughly May 2026 that we do not have

Checked by parsing "Added …" lines out of every v11 release and looking each
name up in our data. False positives from the parse (descriptive phrases, a
date fragment) are excluded; these are confirmed absent.

**Customers — 6**

| Customer | Added in | Date |
|---|---|---|
| The Thinker | v11.21.0g | 2026-06-16 |
| Dean of Students | v11.21.0g | 2026-06-16 |
| Top-Notch Makeup Artist | v11.22.0g | 2026-07-02 |
| Post-Apocalyptic Enthusiast | v11.22.0g | 2026-07-02 |
| Master Ventriloquist | v11.22.0g | 2026-07-02 |
| Opossum Mom | v11.25.0g | 2026-08-17 |

**Letters — 9**: Old Journal Page 3 and Yorkie Pup's Letter 5 (v11.20.0g),
Snow Leopard Pup's Letter and Eggy's Diary 26 (v11.21.0g), Rabbit Ding's
Fishing Record 2 (v11.23.0g), Yolky's Ramblings 6, Damascus Goat Growth Diary
3 and Corgi's Diary 1 (v11.24.0g), Weaver Girl's Letter 2 (v11.25.0g). We
have `Weaver Girl's Letter` but not the second one, and `Yorkie Pup's Letter`
through 4 but not 5.

**Movies — 1**: Puffy Power Girls: BBFs (v11.25.0g).

**Facilities and mementos** cannot be checked this way — the changelog names
them by series ("Added Forest Tea Party series facilities to all locations")
rather than individually — but six releases since May added facility series,
so assume the same gap exists there.

The pattern says our data was last genuinely refreshed around **v11.19,
May 2026**, four months before the scrapers were last touched.

---

## 2. Why nobody noticed: most of the data has no way to be regenerated

`scripts/README.md` lists a ten-step run order and says each step "writes
straight into `assets/data/`". Neither half is quite true.

**Twelve of the nineteen data files have no script that writes them at all:**

```
booth_owners.json      income.json           performer_income.json
facilities.json        letters.json          pets.json
fish.json              mementos_extra.json   redemption_codes.json
movies.json            staff.json            terrace_customers.json
```

…plus the 11 shards in `facilities_jsons/`. These were produced once, by hand
or by something that no longer exists, and there is no way to refresh them.
`letters.json` is in that list, which is exactly why it is missing nine
letters and why that went unnoticed.

**Of the scrapers that do exist, most do not write where the README says.**
`scrape_customers.py`, `scrape_movies.py` and `scrape_posters.py` write
`new_customers.json`, `movies_new.json` and `posters_new.json` into
`scripts/.cache/` — which is gitignored. Only `scrape_dishes.py` writes into
`assets/data/`. So the documented pipeline ends in a directory that is thrown
away, and a human had to merge the results by hand. Nothing records whether
that merge happened, or when.

That is the actual root cause. The data is not stale because someone forgot to
run a script; it is stale because running the scripts does not update the app,
and nothing says so.

---

## 3. What to do, in order

1. **Fix the README** so it describes what the scripts do. Done alongside this
   report.
2. **Make the scrapers write where they claim to**, or add an explicit merge
   step that does. Until then every refresh needs someone to know the trick.
3. **Write the missing scrapers**, starting with `letters.json` — it is the
   file with a confirmed gap, and letters are simple, flat records.
4. **Re-run everything and diff.** Expect more than the 16 entries above:
   facilities and mementos could not be checked by name.
5. **Wire `validate_data.py` and a freshness check into CI.** The freshness
   check can be the one written for this report: parse the newest release in
   `updates.json`, look up every name it says was added, fail if any is
   missing. It would have caught all of this in June.
