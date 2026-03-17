#!/usr/bin/env python3
"""
Animal Restaurant Wiki Scraper
================================
Fetches all customer pages from the Animal Restaurant Fandom wiki
and outputs a customers.json matching the app's existing schema.

Usage:
  pip install requests mwparserfromhell
  python scraper.py               # Full scrape → customers.json
  python scraper.py --probe       # Dump raw wikitext for one page (debug)
  python scraper.py --probe "Deer"  # Probe a specific customer
"""

import re
import sys
import json
import time
import argparse
import requests
import mwparserfromhell

# ──────────────────────────────────────────────
# CONFIG
# ──────────────────────────────────────────────

BASE_URL = "https://animalrestaurant.fandom.com/api.php"
OUTPUT_FILE = "customers.json"
REQUEST_DELAY = 0.4   # seconds between API calls — be polite

HEADERS = {
    "User-Agent": "AnimalRestaurantTrackerApp/1.0 (personal Flutter game tracker)"
}

# All customer subcategories to scrape. Each maps to the tag added to that customer.
CATEGORY_TAG_MAP = {
    "Regular Customers":       "regular",
    "Seasonal Customers":      "regular",     # seasonal are also regular, just flower-gated
    "Special Customers":       "special",
    "Event Customers":         "event",
    "Booth Owner Customers":   "booth_owner",
    "Doll Figure Customers":   "gachapon",
    "Performers":              "performer",
    "Terrace Customers":       "regular",
}

# ──────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────

def to_id(name: str) -> str:
    """Convert display name → snake_case id (mirrors your existing ids)."""
    s = name.lower().strip()
    s = re.sub(r"[''`]", "", s)           # smart quotes
    s = re.sub(r"[^a-z0-9\s\-]", "", s)  # drop punctuation
    s = re.sub(r"[\s\-]+", "_", s)       # spaces/hyphens → underscore
    return s.strip("_")


def api_get(params: dict) -> dict:
    """Thin wrapper around requests.get with retry logic."""
    params["format"] = "json"
    for attempt in range(4):
        try:
            r = requests.get(BASE_URL, params=params, headers=HEADERS, timeout=20)
            r.raise_for_status()
            return r.json()
        except Exception as e:
            wait = 2 ** attempt
            print(f"  ⚠  Attempt {attempt+1} failed ({e}). Retrying in {wait}s…")
            time.sleep(wait)
    raise RuntimeError(f"All retries failed for params: {params}")


def get_category_members(category: str) -> list[str]:
    """Return all page titles in a wiki category (handles pagination)."""
    titles = []
    params = {
        "action": "query",
        "list": "categorymembers",
        "cmtitle": f"Category:{category}",
        "cmlimit": "500",
        "cmtype": "page",
    }
    while True:
        data = api_get(params)
        for m in data.get("query", {}).get("categorymembers", []):
            titles.append(m["title"])
        if "continue" not in data:
            break
        params["cmcontinue"] = data["continue"]["cmcontinue"]
    return titles


def get_wikitext(title: str) -> str | None:
    """Fetch the raw wikitext for a page."""
    data = api_get({"action": "parse", "page": title, "prop": "wikitext"})
    return data.get("parse", {}).get("wikitext", {}).get("*")


# ──────────────────────────────────────────────
# WIKITEXT FIELD EXTRACTORS
# ──────────────────────────────────────────────

def extract_template_fields(wikitext: str) -> dict:
    """
    Parse the first infobox/character template on the page and return
    a flat dict of {field_name: raw_value}.

    NOTE: After running --probe on a few pages, update FIELD_MAP below
    to match the actual parameter names the wiki uses.
    """
    parsed = mwparserfromhell.parse(wikitext)
    templates = parsed.filter_templates()

    if not templates:
        return {}

    # Take the first template that looks like a character/customer infobox
    # (not a navbox, icon template, etc.)
    infobox = None
    for t in templates:
        name = t.name.strip().lower()
        if any(kw in name for kw in ("customer", "infobox", "character", "npc")):
            infobox = t
            break

    if infobox is None:
        infobox = templates[0]  # fallback: first template

    fields = {}
    for param in infobox.params:
        key = str(param.name).strip()
        val = mwparserfromhell.parse(str(param.value)).strip_code().strip()
        fields[key] = val

    return fields


# ── Field name mapping ──────────────────────────────────────────────────────
# Left  = what the wiki infobox parameter is actually called (check --probe)
# Right = what we want in our schema
# Add/rename entries here after running --probe on a few pages.
FIELD_MAP = {
    # Description / lore
    "description":     "description",
    "desc":            "description",
    "lore":            "description",
    "quote":           "description",

    # Location
    "location":        "livesIn",
    "lives":           "livesIn",
    "lives_in":        "livesIn",
    "area":            "livesIn",
    "origin":          "livesIn",

    # Appearance weight / rarity
    "weight":          "appearanceWeight",
    "appearance":      "appearanceWeight",
    "rarity":          "appearanceWeight",
    "rate":            "appearanceWeight",

    # Required food to first attract
    "required_food":   "requiredFoodId",
    "attract_food":    "requiredFoodId",
    "food_required":   "requiredFoodId",
    "signature_food":  "requiredFoodId",

    # Dishes ordered (multiple)
    "dishes":          "dishesOrdered",
    "food":            "dishesOrdered",
    "orders":          "dishesOrdered",
    "order":           "dishesOrdered",

    # Requirements
    "rating":          "req_rating",
    "stars":           "req_rating",
    "star_rating":     "req_rating",
    "min_rating":      "req_rating",
    "facility":        "req_facilities",
    "facilities":      "req_facilities",
    "facility_req":    "req_facilities",
    "letter":          "req_letters",
    "letters":         "req_letters",
    "letter_req":      "req_letters",
    "recipe":          "req_recipes",
    "recipes":         "req_recipes",
    "food_req":        "req_recipes",
    "flower":          "req_flowers",
    "flowers":         "req_flowers",
    "flower_req":      "req_flowers",
    "customer_req":    "req_customers",
    "customer":        "req_customers",
    "prerequisite":    "req_customers",

    # Season (for seasonal customers)
    "season":          "season",

    # Performer fields
    "band":            "band",
    "group":           "band",
    "duration":        "showDurationMinutes",
    "show_duration":   "showDurationMinutes",
    "callback":        "callbackRequirementHours",
    "callback_hours":  "callbackRequirementHours",
    "earnings":        "baseEarnings",
    "base_earnings":   "baseEarnings",
    "fans":            "fans",
}


def map_fields(raw: dict) -> dict:
    """Apply FIELD_MAP to a raw template dict."""
    out = {}
    for k, v in raw.items():
        mapped = FIELD_MAP.get(k.lower().replace(" ", "_"))
        if mapped:
            out[mapped] = v
        else:
            out[k] = v   # keep unmapped fields too, for inspection
    return out


def parse_list_links(value: str) -> list[str]:
    """
    Extract wiki link targets from a value like:
      [[White Rose]], [[Sunflower|Sun]]
    Returns snake_case ids: ["white_rose", "sunflower"]
    """
    targets = re.findall(r"\[\[([^\]|#]+)(?:\|[^\]]*)?\]\]", value)
    # Also handle comma/newline-separated plain text (no brackets)
    if not targets:
        targets = [x.strip() for x in re.split(r"[,\n•*]", value) if x.strip()]
    return [to_id(t) for t in targets if t.strip()]


def parse_int_value(value: str) -> int | None:
    """Extract the first integer from a string (handles commas, stars icons, etc.)."""
    nums = re.findall(r"[\d,]+", value)
    if nums:
        return int(nums[0].replace(",", ""))
    return None


def extract_mementos(wikitext: str) -> list[dict]:
    """
    Extract memento objects from the page.

    Fandom wikis typically store mementos in one of:
      - A wikitable with columns (name | stars | description | requirement)
      - Repeated {{Memento}} templates
      - A plain section with headers

    This parser handles the most common patterns. If your wiki uses
    a different format, inspect the --probe output and adjust accordingly.
    """
    mementos = []
    parsed = mwparserfromhell.parse(wikitext)

    # ── Pattern 1: {{Memento|...}} templates ─────────────────────────────
    for t in parsed.filter_templates():
        if "memento" in t.name.strip().lower():
            m = {}
            for p in t.params:
                k = str(p.name).strip().lower()
                v = mwparserfromhell.parse(str(p.value)).strip_code().strip()
                if k in ("name", "title"):
                    m["name"] = v
                    m["id"] = to_id(v)
                elif k in ("stars", "star", "earned_stars", "earnedstars"):
                    try:
                        m["earnedStars"] = int(re.search(r"\d+", v).group())
                    except Exception:
                        m["earnedStars"] = 0
                elif k in ("description", "desc", "flavor", "flavour"):
                    m["description"] = v
                elif k in ("requirement", "req", "unlock", "condition"):
                    m["requirement"] = v
                elif k in ("source", "type"):
                    m["source"] = v
                elif k in ("reward", "share_reward", "sharereward"):
                    try:
                        m["shareReward"] = int(re.search(r"\d+", v).group())
                    except Exception:
                        pass
            if m.get("name"):
                mementos.append(m)

    if mementos:
        return mementos

    # ── Pattern 2: wikitable rows ─────────────────────────────────────────
    # Look for a section headed "Mementos" and parse the table under it
    in_memento_section = False
    rows = []
    for line in wikitext.splitlines():
        stripped = line.strip()
        if re.search(r"==\s*[Mm]emento", stripped):
            in_memento_section = True
            continue
        if in_memento_section and stripped.startswith("==") and "memento" not in stripped.lower():
            break
        if in_memento_section and stripped.startswith("|-"):
            rows.append([])
        elif in_memento_section and stripped.startswith("|") and rows:
            cell = mwparserfromhell.parse(stripped.lstrip("|")).strip_code().strip()
            rows[-1].append(cell)

    # Rows usually: [name, stars, description, requirement, ...]
    for row in rows:
        if len(row) >= 3:
            m = {
                "id": to_id(row[0]),
                "name": row[0],
                "earnedStars": parse_int_value(row[1]) or 0,
                "description": row[2] if len(row) > 2 else "",
                "requirement": row[3] if len(row) > 3 else "",
            }
            mementos.append(m)

    return mementos


# ──────────────────────────────────────────────
# CUSTOMER BUILDER
# ──────────────────────────────────────────────

def build_customer(title: str, wikitext: str, extra_tags: list[str]) -> dict:
    """
    Construct a customer dict from a page's wikitext, matching the schema:

    {
      id, name, tags, livesIn, appearanceWeight, requiredFoodId,
      dishesOrderedIds, customerDescription, requirements, mementos,
      [performer], [season]
    }
    """
    raw = extract_template_fields(wikitext)
    f = map_fields(raw)

    name = f.get("name", title).strip() or title
    customer_id = to_id(name)

    # ── Tags ──────────────────────────────────────────────────────────────
    tags = ["customer"] + extra_tags

    # Detect seasonal customers by presence of seasonal flower requirement
    if f.get("req_flowers") or f.get("season"):
        if "regular" not in tags:
            tags.append("regular")

    # Detect performer
    is_performer = "performer" in tags or bool(f.get("band"))

    # ── Requirements ─────────────────────────────────────────────────────
    requirements = {
        "recipes":    parse_list_links(f.get("req_recipes", "")),
        "facilities": parse_list_links(f.get("req_facilities", "")),
        "letters":    parse_list_links(f.get("req_letters", "")),
        "customers":  parse_list_links(f.get("req_customers", "")),
        "flowers":    parse_list_links(f.get("req_flowers", "")),
        "rating":     parse_int_value(f.get("req_rating", "")) if f.get("req_rating") else None,
    }

    # Drop empty flower list to keep schema clean (match existing pattern)
    if not requirements["flowers"]:
        del requirements["flowers"]

    # ── Dishes ───────────────────────────────────────────────────────────
    dishes_raw = f.get("dishesOrdered", "")
    dishes = parse_list_links(dishes_raw) if dishes_raw else []

    # ── Required food (first attract food) ───────────────────────────────
    req_food_raw = f.get("requiredFoodId", "")
    req_food = to_id(req_food_raw) if req_food_raw else None

    # ── Customer object ───────────────────────────────────────────────────
    customer: dict = {
        "id": customer_id,
        "name": name,
        "tags": tags,
        "livesIn": f.get("livesIn") or None,
        "appearanceWeight": parse_int_value(f.get("appearanceWeight", "")) if f.get("appearanceWeight") else None,
        "requiredFoodId": req_food,
        "dishesOrderedIds": dishes,
        "customerDescription": f.get("description", ""),
        "requirements": requirements,
        "mementos": extract_mementos(wikitext),
    }

    # ── Season field (seasonal customers) ────────────────────────────────
    season = f.get("season", "").lower()
    if season:
        customer["season"] = season

    # ── Performer block ───────────────────────────────────────────────────
    if is_performer:
        customer["performer"] = {
            "band": f.get("band", ""),
            "showDurationMinutes": parse_int_value(f.get("showDurationMinutes", "")) if f.get("showDurationMinutes") else None,
            "callbackRequirementHours": parse_int_value(f.get("callbackRequirementHours", "")) if f.get("callbackRequirementHours") else None,
            "baseEarnings": {
                "currency": "film",
                "amountPerMinute": None,
            },
            "fansCustomerIds": parse_list_links(f.get("fans", "")),
            "canInviteThis": [],
            "canBeInvitedBy": [],
            "posterIds": [],
        }

    return customer


# ──────────────────────────────────────────────
# MAIN SCRAPE
# ──────────────────────────────────────────────

def full_scrape():
    """Scrape all categories and write customers.json."""
    print("📋  Building page list from wiki categories…\n")

    # Map: title → set of extra tags
    page_tags: dict[str, set] = {}

    for category, tag in CATEGORY_TAG_MAP.items():
        members = get_category_members(category)
        print(f"  {category}: {len(members)} pages")
        for title in members:
            page_tags.setdefault(title, set()).add(tag)
        time.sleep(REQUEST_DELAY)

    total = len(page_tags)
    print(f"\n🔍  Fetching {total} customer pages…\n")

    customers = []
    errors = []

    for i, (title, tags) in enumerate(sorted(page_tags.items()), 1):
        print(f"  [{i:>4}/{total}] {title}", end="", flush=True)
        try:
            wikitext = get_wikitext(title)
            if not wikitext:
                print(" — ⚠  No wikitext")
                errors.append(title)
                continue

            customer = build_customer(title, wikitext, sorted(tags))
            customers.append(customer)
            print(f" ✓  ({len(customer['mementos'])} mementos)")
        except Exception as e:
            print(f" ✗  ERROR: {e}")
            errors.append(title)

        time.sleep(REQUEST_DELAY)

    # Sort to match existing file order (regular first, then booth, etc.)
    tag_order = {"regular": 0, "seasonal": 1, "special": 2, "booth_owner": 3,
                 "gachapon": 4, "performer": 5, "event": 6}
    customers.sort(key=lambda c: min(tag_order.get(t, 99) for t in c["tags"]))

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(customers, f, indent=2, ensure_ascii=False)

    print(f"\n✅  Done! {len(customers)} customers → {OUTPUT_FILE}")
    if errors:
        print(f"⚠   {len(errors)} pages had errors: {errors}")


# ──────────────────────────────────────────────
# DIAGNOSTIC PROBE
# ──────────────────────────────────────────────

def probe(title: str = "White Bunny"):
    """
    Fetch one page and print:
      1. Raw wikitext (first 150 lines)
      2. Extracted template fields
      3. What build_customer() would produce

    Use this to verify FIELD_MAP is correct before running the full scrape.
    """
    print(f"🔬  Probing: {title}\n{'='*60}")
    wikitext = get_wikitext(title)
    if not wikitext:
        print("No wikitext returned. Check the page title.")
        return

    # 1. Raw wikitext
    print("\n── RAW WIKITEXT (first 120 lines) ──────────────────────────")
    lines = wikitext.splitlines()
    for line in lines[:120]:
        print(line)
    if len(lines) > 120:
        print(f"  … ({len(lines) - 120} more lines)")

    # 2. Extracted template fields
    print("\n── EXTRACTED TEMPLATE FIELDS ───────────────────────────────")
    raw = extract_template_fields(wikitext)
    for k, v in raw.items():
        print(f"  {k!r:30s} = {v!r}")

    # 3. Mapped fields
    print("\n── AFTER FIELD_MAP ─────────────────────────────────────────")
    mapped = map_fields(raw)
    for k, v in mapped.items():
        print(f"  {k!r:30s} = {v!r}")

    # 4. Mementos
    print("\n── DETECTED MEMENTOS ───────────────────────────────────────")
    mementos = extract_mementos(wikitext)
    for m in mementos:
        print(f"  {m}")

    # 5. Final customer object
    print("\n── FINAL CUSTOMER OBJECT ───────────────────────────────────")
    customer = build_customer(title, wikitext, ["regular"])
    print(json.dumps(customer, indent=2, ensure_ascii=False))


# ──────────────────────────────────────────────
# ENTRY POINT
# ──────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Animal Restaurant wiki scraper")
    parser.add_argument(
        "--probe", nargs="?", const="White Bunny", metavar="CUSTOMER_NAME",
        help="Debug mode: dump wikitext + parsed fields for one customer"
    )
    args = parser.parse_args()

    if args.probe is not None:
        probe(args.probe)
    else:
        full_scrape()
