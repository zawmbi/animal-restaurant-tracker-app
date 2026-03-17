#!/usr/bin/env python3
"""
Animal Restaurant Facilities Wiki Scraper
==========================================
Fetches all facility pages from the Animal Restaurant Fandom wiki
and outputs facilities.json matching the app's existing schema.

Priority fields: income production (cod/plates per minute or interval),
tip cap increases, gacha draws — everything the bank tracker needs.

Usage:
  pip install requests mwparserfromhell
  python facilities_scraper.py                      # Full scrape → facilities.json
  python facilities_scraper.py --probe "Stone Bowl" # Debug one page
  python facilities_scraper.py --probe-area restaurant  # Debug category list
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

BASE_URL    = "https://animalrestaurant.fandom.com/api.php"
OUTPUT_FILE = "facilities.json"
REQUEST_DELAY = 0.4   # seconds between API calls

HEADERS = {
    "User-Agent": "AnimalRestaurantTrackerApp/1.0 (personal Flutter game tracker)"
}

# ──────────────────────────────────────────────
# AREA / CATEGORY MAP
# Maps wiki category/page names → our "area" field value
# After probing, add or rename entries to match what the wiki actually uses.
# ──────────────────────────────────────────────

AREA_SOURCES = [
    # (wiki_category_or_page, area_id)
    # Sub-pages of the Facilities hub page
    ("Facilities/Restaurant",    "restaurant"),
    ("Facilities/Buffet",        "buffet"),
    ("Facilities/Kitchen",       "kitchen"),
    ("Facilities/Courtyard",     "courtyard"),
    ("Facilities/Terrace",       "terrace"),
    ("Facilities/Fishing Pond",  "fishing_pond"),
    # Alternative category names the wiki might use
    ("Restaurant Facilities",    "restaurant"),
    ("Buffet Facilities",        "buffet"),
    ("Kitchen Facilities",       "kitchen"),
    ("Courtyard Facilities",     "courtyard"),
    ("Terrace Facilities",       "terrace"),
    ("Fishing Pond Facilities",  "fishing_pond"),
]

# Fallback: scrape the top-level Facilities category
FACILITY_CATEGORY = "Facilities"

# ──────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────

def to_id(name: str) -> str:
    s = name.lower().strip()
    s = re.sub(r"[''`]", "", s)
    s = re.sub(r"[^a-z0-9\s\-]", "", s)
    s = re.sub(r"[\s\-]+", "_", s)
    return s.strip("_")


def api_get(params: dict) -> dict:
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


def get_page_links(page_title: str) -> list[str]:
    """
    For hub pages like 'Facilities/Restaurant', fetch the links from the page
    to get individual facility page titles.
    """
    data = api_get({
        "action": "query",
        "titles": page_title,
        "prop": "links",
        "pllimit": "500",
    })
    pages = data.get("query", {}).get("pages", {})
    links = []
    for page in pages.values():
        for lnk in page.get("links", []):
            links.append(lnk["title"])
    return links


def get_wikitext(title: str) -> str | None:
    data = api_get({"action": "parse", "page": title, "prop": "wikitext"})
    return data.get("parse", {}).get("wikitext", {}).get("*")


def parse_int(value: str) -> int | None:
    nums = re.findall(r"[\d,]+", str(value))
    if nums:
        return int(nums[0].replace(",", ""))
    return None


def parse_float(value: str) -> float | None:
    nums = re.findall(r"[\d,]+\.?\d*", str(value))
    if nums:
        return float(nums[0].replace(",", ""))
    return None


def strip_wikitext(value: str) -> str:
    return mwparserfromhell.parse(str(value)).strip_code().strip()


# ──────────────────────────────────────────────
# TEMPLATE FIELD EXTRACTION
# ──────────────────────────────────────────────

def extract_template_fields(wikitext: str) -> dict:
    """Parse the first infobox template and return flat {field: value} dict."""
    parsed = mwparserfromhell.parse(wikitext)
    templates = parsed.filter_templates()
    if not templates:
        return {}

    infobox = None
    for t in templates:
        name = t.name.strip().lower()
        if any(kw in name for kw in ("facility", "infobox", "item", "furniture", "decor")):
            infobox = t
            break
    if infobox is None:
        infobox = templates[0]

    fields = {}
    for param in infobox.params:
        key = str(param.name).strip()
        val = strip_wikitext(str(param.value))
        fields[key] = val
    return fields


# ──────────────────────────────────────────────
# FIELD MAP
# Left = wiki infobox param name (check --probe output)
# Right = internal key used in build_facility()
# Add entries here after running --probe on a few pages.
# ──────────────────────────────────────────────

FIELD_MAP = {
    # Name / description
    "name":              "name",
    "title":             "name",
    "description":       "description",
    "desc":              "description",
    "flavor":            "description",
    "quote":             "description",
    "lore":              "description",

    # Area / location
    "area":              "area",
    "location":          "area",
    "room":              "area",
    "zone":              "area",

    # Group / slot type (e.g. "Tip Desk", "Table 1", "Conveyor Belts")
    "group":             "group",
    "slot":              "group",
    "type":              "group",
    "category":          "group",
    "furniture_type":    "group",
    "slot_type":         "group",

    # Star requirement to unlock
    "stars":             "requiredStars",
    "required_stars":    "requiredStars",
    "star_requirement":  "requiredStars",
    "unlock_stars":      "requiredStars",
    "min_stars":         "requiredStars",

    # Purchase price fields
    "price":             "price_raw",
    "cost":              "price_raw",
    "cod":               "price_cod",
    "cod_price":         "price_cod",
    "diamonds":          "price_diamonds",
    "diamond_price":     "price_diamonds",
    "plates":            "price_plates",
    "plate_price":       "price_plates",
    "currency":          "price_currency",
    "price_currency":    "price_currency",

    # Income / production effects — PRIORITY fields
    # Per-minute income
    "income":            "income_per_minute",
    "income_per_minute": "income_per_minute",
    "cod_per_minute":    "income_per_minute",
    "cod_income":        "income_per_minute",
    "income_minute":     "income_per_minute",
    "plates_per_minute": "plates_per_minute",
    "plate_income":      "plates_per_minute",

    # Per-interval income (conveyor belts = /hr, drinks = /day)
    "income_per_hour":   "income_per_interval_cod",
    "cod_per_hour":      "income_per_interval_cod",
    "hourly_income":     "income_per_interval_cod",
    "income_interval":   "income_per_interval_cod",
    "interval_income":   "income_per_interval_cod",
    "plates_per_day":    "income_per_interval_plates",
    "daily_plates":      "income_per_interval_plates",
    "plate_interval":    "income_per_interval_plates",

    # Interval duration
    "interval":          "interval_minutes",
    "interval_minutes":  "interval_minutes",
    "cooldown":          "interval_minutes",
    "production_time":   "interval_minutes",

    # Tip cap
    "tip_cap":           "tip_cap_increase",
    "tip_capacity":      "tip_cap_increase",
    "tip_increase":      "tip_cap_increase",
    "tip_cap_increase":  "tip_cap_increase",
    "max_tip":           "tip_cap_increase",

    # Rating bonus (stars added)
    "rating":            "rating_bonus",
    "rating_bonus":      "rating_bonus",
    "star_bonus":        "rating_bonus",
    "stars_added":       "rating_bonus",
    "bonus_stars":       "rating_bonus",

    # Gacha machine specific
    "gacha_draws":       "gacha_draws",
    "draws":             "gacha_draws",
    "capsules":          "gacha_draws",
    "gacha_level":       "gacha_level",
    "level":             "gacha_level",
    "gacha_tier":        "gacha_level",

    # Series / theme
    "series":            "series",
    "theme":             "series",
    "collection":        "series",
    "set":               "series",

    # Special requirements / event locks
    "special":           "special_requirements",
    "special_req":       "special_requirements",
    "event":             "special_requirements",
    "event_req":         "special_requirements",
    "requirement":       "special_requirements",
    "requirements":      "special_requirements",
    "unlock":            "special_requirements",
    "unlock_req":        "special_requirements",
    "notes":             "special_requirements",
    "limited":           "special_requirements",
    "availability":      "special_requirements",
}


def map_fields(raw: dict) -> dict:
    out = {}
    for k, v in raw.items():
        mapped = FIELD_MAP.get(k.lower().strip().replace(" ", "_"))
        if mapped:
            out[mapped] = v
        else:
            out[k] = v
    return out


# ──────────────────────────────────────────────
# PRICE PARSER
# ──────────────────────────────────────────────

def parse_price(f: dict, wikitext: str) -> list[dict]:
    """
    Build the price array: [{"currency": "cod", "amount": 1000}, ...]

    Handles:
    - Separate price_cod / price_diamonds / price_plates fields
    - A combined price_raw field
    - Scanning the raw wikitext for price patterns as a fallback
    """
    prices = []

    # Direct fields
    for field, currency in [
        ("price_cod",      "cod"),
        ("price_diamonds", "diamonds"),
        ("price_plates",   "plates"),
    ]:
        if f.get(field):
            amt = parse_int(f[field])
            if amt is not None:
                prices.append({"currency": currency, "amount": amt})

    if prices:
        return prices

    # Combined price_raw field — look for patterns like "1,000 Cod" or "50 Diamonds"
    raw = f.get("price_raw", "")
    if raw:
        for pattern, currency in [
            (r"([\d,]+)\s*(?:cod|fish|金?鳕鱼?)", "cod"),
            (r"([\d,]+)\s*(?:diamond|gem|钻石)", "diamonds"),
            (r"([\d,]+)\s*(?:plate|dish|盘子)", "plates"),
        ]:
            m = re.search(pattern, raw, re.IGNORECASE)
            if m:
                prices.append({"currency": currency, "amount": int(m.group(1).replace(",", ""))})

    if prices:
        return prices

    # Wikitext fallback — scan for price templates or plain numbers near currency words
    for pattern, currency in [
        (r"\|\s*(?:cod|price_cod)\s*=\s*([\d,]+)", "cod"),
        (r"\|\s*(?:diamond|gems?)\s*=\s*([\d,]+)", "diamonds"),
        (r"\|\s*(?:plates?)\s*=\s*([\d,]+)", "plates"),
        (r"([\d,]+)\s*(?:\[\[)?(?:Cod|cod)(?:\]\])?", "cod"),
        (r"([\d,]+)\s*(?:\[\[)?(?:Diamond|Diamonds|diamond)(?:\]\])?", "diamonds"),
    ]:
        m = re.search(pattern, wikitext)
        if m:
            prices.append({"currency": currency, "amount": int(m.group(1).replace(",", ""))})

    return prices


# ──────────────────────────────────────────────
# EFFECT BUILDER
# ──────────────────────────────────────────────

def build_effects(f: dict, wikitext: str) -> list[dict]:
    """
    Build the effects array matching the schema.

    Effect types (in priority order for income tracking):
      incomePerMinute   - {type, currency, amount}
      incomePerInterval - {type, currency, amount, intervalMinutes}
      tipCapIncrease    - {type, capIncrease}
      ratingBonus       - {type, amount}
      gachaDraws        - {type, amount}
      gachaLevel        - {type, level}
    """
    effects = []

    # ── Rating bonus (always present) ────────────────────────────────────
    rating = parse_int(f.get("rating_bonus", ""))
    if rating:
        effects.append({"type": "ratingBonus", "amount": rating})

    # ── Income: per-minute cod ────────────────────────────────────────────
    ipm_cod = parse_int(f.get("income_per_minute", ""))
    if ipm_cod:
        effects.append({
            "type": "incomePerMinute",
            "currency": "cod",
            "amount": ipm_cod,
        })

    # ── Income: per-minute plates ─────────────────────────────────────────
    ipm_plates = parse_int(f.get("plates_per_minute", ""))
    if ipm_plates:
        effects.append({
            "type": "incomePerMinute",
            "currency": "plates",
            "amount": ipm_plates,
        })

    # ── Income: per-interval cod ──────────────────────────────────────────
    # (conveyor belts = every 60 min, drinks = every 1440 min)
    ipi_cod = parse_int(f.get("income_per_interval_cod", ""))
    if ipi_cod:
        interval = parse_int(f.get("interval_minutes", "")) or infer_interval(f, wikitext)
        effects.append({
            "type": "incomePerInterval",
            "currency": "cod",
            "amount": ipi_cod,
            "intervalMinutes": interval,
        })

    # ── Income: per-interval plates ───────────────────────────────────────
    ipi_plates = parse_int(f.get("income_per_interval_plates", ""))
    if ipi_plates:
        interval = parse_int(f.get("interval_minutes", "")) or infer_interval(f, wikitext)
        effects.append({
            "type": "incomePerInterval",
            "currency": "plates",
            "amount": ipi_plates,
            "intervalMinutes": interval,
        })

    # ── Tip cap increase ─────────────────────────────────────────────────
    tip_cap = parse_int(f.get("tip_cap_increase", ""))
    if tip_cap:
        effects.append({"type": "tipCapIncrease", "capIncrease": tip_cap})

    # ── Gacha draws ───────────────────────────────────────────────────────
    gacha_draws = parse_int(f.get("gacha_draws", ""))
    if gacha_draws:
        effects.append({"type": "gachaDraws", "amount": gacha_draws})

    # ── Gacha level ───────────────────────────────────────────────────────
    gacha_level = parse_int(f.get("gacha_level", ""))
    if gacha_level:
        effects.append({"type": "gachaLevel", "level": gacha_level})

    # ── Wikitext fallback: scan for income patterns if effects still empty ─
    if len(effects) <= 1:  # only ratingBonus found so far
        effects.extend(scan_wikitext_for_income(wikitext))

    return effects


def infer_interval(f: dict, wikitext: str) -> int:
    """
    Guess the income interval if not explicitly stated.
    - "per hour" / "hourly" → 60
    - "per day" / "daily" / "24 hours" → 1440
    - Conveyor belt groups → 60
    - Drink groups → 1440
    """
    group = f.get("group", "").lower()
    desc = f.get("description", "").lower()

    if any(kw in group for kw in ("conveyor", "belt", "carousel")):
        return 60
    if any(kw in group for kw in ("drink", "beverage", "tea", "bar")):
        return 1440
    if any(kw in desc for kw in ("per hour", "hourly", "/hr", "every hour")):
        return 60
    if any(kw in desc for kw in ("per day", "daily", "/day", "every 24")):
        return 1440

    # Scan wikitext
    wt_lower = wikitext.lower()
    if "per hour" in wt_lower or "hourly" in wt_lower or "/hour" in wt_lower:
        return 60
    if "per day" in wt_lower or "daily" in wt_lower or "1440" in wt_lower:
        return 1440

    return 60  # safe default


INCOME_PATTERNS = [
    # (pattern, currency, effect_type)
    (r"([\d,]+)\s*(?:cod|鳕鱼)\s*(?:per|/)\s*min(?:ute)?", "cod", "incomePerMinute"),
    (r"([\d,]+)\s*(?:plate|盘子)\s*(?:per|/)\s*min(?:ute)?", "plates", "incomePerMinute"),
    (r"([\d,]+)\s*(?:cod|鳕鱼)\s*(?:per|/)\s*hour", "cod", "incomePerInterval"),
    (r"([\d,]+)\s*(?:cod|鳕鱼)\s*(?:per|/)\s*day", "cod", "incomePerInterval"),
    (r"([\d,]+)\s*(?:plate|盘子)\s*(?:per|/)\s*day", "plates", "incomePerInterval"),
]

def scan_wikitext_for_income(wikitext: str) -> list[dict]:
    """Fallback: scan raw wikitext for income numbers when template parse misses them."""
    found = []
    wt = wikitext.lower()
    for pattern, currency, effect_type in INCOME_PATTERNS:
        m = re.search(pattern, wt, re.IGNORECASE)
        if m:
            amount = int(m.group(1).replace(",", ""))
            if effect_type == "incomePerMinute":
                found.append({"type": "incomePerMinute", "currency": currency, "amount": amount})
            elif effect_type == "incomePerInterval":
                interval = 1440 if "day" in pattern else 60
                found.append({"type": "incomePerInterval", "currency": currency,
                               "amount": amount, "intervalMinutes": interval})
    return found


# ──────────────────────────────────────────────
# SPECIAL REQUIREMENTS PARSER
# ──────────────────────────────────────────────

# Date window patterns: "Jun 1st–Jun 30th", "Dec 6th–Jan 18th", etc.
DATE_WINDOW_RE = re.compile(
    r"(?:limited[- ]?time|unlock(?:able)?)[^:]*?:?\s*"
    r"((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s*\d+(?:st|nd|rd|th)?"
    r"\s*[–\-—to]+\s*"
    r"(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s*\d+(?:st|nd|rd|th)?)",
    re.IGNORECASE
)

# Aromatic Acorn judging gates
ACORN_RE = re.compile(
    r"(?:complete|pass|finish|require[sd]?)[^.]*?aromatic\s*acorn[^.]*?(\d[-\s]?star)",
    re.IGNORECASE
)

# Event source patterns
EVENT_SOURCE_RE = re.compile(
    r"(?:obtain(?:ed)?|won|available|sold)\s+(?:from|during|in)\s+(?:the\s+)?([A-Z][^.!?]+?(?:event|event\s+\d{4}))",
    re.IGNORECASE
)

def extract_special_requirements(f: dict, wikitext: str, description: str) -> list[str] | None:
    """
    Extract special requirements from:
    1. The mapped 'special_requirements' field
    2. The description text (date windows, event mentions)
    3. Raw wikitext
    """
    reqs = []

    # From template field
    raw_req = f.get("special_requirements", "")
    if raw_req:
        # Split on common delimiters
        parts = re.split(r"[;\n•]|<br\s*/?>", raw_req)
        for p in parts:
            p = p.strip()
            if p and len(p) > 3:
                reqs.append(p)

    # From description — extract date window
    m = DATE_WINDOW_RE.search(description)
    if m and not any("unlock" in r.lower() for r in reqs):
        date_range = m.group(1).strip()
        reqs.append(f"Unlock from {date_range}")

    # From description — Aromatic Acorn
    m = ACORN_RE.search(description)
    if m and not any("acorn" in r.lower() for r in reqs):
        stars = m.group(1).strip()
        reqs.append(f"Complete Aromatic Acorn {stars} Judging")

    # From wikitext — event source
    m = EVENT_SOURCE_RE.search(wikitext)
    if m and not any("event" in r.lower() for r in reqs):
        event = m.group(1).strip()
        reqs.append(f"Obtained from {event}")

    return reqs if reqs else None


# ──────────────────────────────────────────────
# MAIN FACILITY BUILDER
# ──────────────────────────────────────────────

def build_facility(
    title: str,
    wikitext: str,
    area_hint: str | None = None,
    group_hint: str | None = None,
) -> dict:
    """
    Build a facility dict matching the schema:
    {
      id, name, area, group, description,
      requiredStars,           # omitted if absent
      price,                   # [] if unknown/free
      effects,
      series,
      specialRequirements      # omitted if none
    }
    """
    raw = extract_template_fields(wikitext)
    f   = map_fields(raw)

    name = f.get("name", title).strip() or title
    facility_id = to_id(name)

    description = f.get("description", "").strip()

    # ── Area ─────────────────────────────────────────────────────────────
    area = (
        f.get("area")
        or area_hint
        or infer_area_from_wikitext(wikitext)
        or "unknown"
    )
    area = area.lower().replace(" ", "_")

    # ── Group (slot type) ────────────────────────────────────────────────
    group = (
        f.get("group")
        or group_hint
        or infer_group_from_wikitext(wikitext, area)
        or ""
    )

    # ── Required stars ───────────────────────────────────────────────────
    req_stars = parse_int(f.get("requiredStars", ""))

    # ── Price ────────────────────────────────────────────────────────────
    price = parse_price(f, wikitext)

    # ── Effects ──────────────────────────────────────────────────────────
    effects = build_effects(f, wikitext)

    # ── Series ───────────────────────────────────────────────────────────
    series = f.get("series", "").strip()
    if not series:
        series = infer_series_from_wikitext(wikitext)

    # ── Special requirements ─────────────────────────────────────────────
    special = extract_special_requirements(f, wikitext, description)

    # ── Assemble ─────────────────────────────────────────────────────────
    facility: dict = {
        "id":          facility_id,
        "name":        name,
        "area":        area,
        "group":       group,
        "description": description,
    }

    if req_stars is not None:
        facility["requiredStars"] = req_stars

    facility["price"]   = price
    facility["effects"] = effects
    facility["series"]  = series

    if special:
        facility["specialRequirements"] = special

    return facility


# ──────────────────────────────────────────────
# AREA / GROUP / SERIES INFERENCE
# ──────────────────────────────────────────────

AREA_KEYWORDS = {
    "restaurant": ["restaurant", "dining", "waiter", "jiji", "dori", "lobby"],
    "buffet":     ["buffet", "gumi", "kitchen", "conveyor", "gachapon", "sliding door",
                   "wall hanging", "ice cream", "drink", "beverage"],
    "kitchen":    ["kitchen", "stove", "oven", "cooking", "chef"],
    "courtyard":  ["courtyard", "outdoor", "garden", "terrace"],
    "terrace":    ["terrace", "gathering"],
    "fishing_pond": ["fishing", "pond", "fish", "bait"],
}

def infer_area_from_wikitext(wikitext: str) -> str | None:
    wt = wikitext.lower()
    for area, keywords in AREA_KEYWORDS.items():
        if any(kw in wt for kw in keywords):
            return area
    return None


GROUP_KEYWORDS = {
    "Tip Desk":       ["tip desk", "tip counter", "cashier", "register", "tip cap"],
    "Conveyor Belts": ["conveyor", "carousel", "belt"],
    "Gachapon":       ["gachapon", "capsule machine", "gacha"],
    "Self-serve Drinks": ["drink", "beverage", "tea", "dispenser", "fountain", "kettle", "bar"],
    "Wall Hangings":  ["wall lamp", "chandelier", "lantern", "hanging", "wall hanging"],
    "Ice Cream":      ["ice cream", "shaved ice", "dessert cart", "dessert shop"],
    "Sliding Doors":  ["sliding door", "door", "entrance"],
}

def infer_group_from_wikitext(wikitext: str, area: str) -> str | None:
    wt = wikitext.lower()
    for group, keywords in GROUP_KEYWORDS.items():
        if any(kw in wt for kw in keywords):
            return group
    return None


SERIES_RE = re.compile(
    r"(?:series|collection|set|theme)[^\n]*?[:\|]\s*\[?\[?([A-Z][^\]\|\n]{3,40})\]?\]?",
    re.IGNORECASE
)

def infer_series_from_wikitext(wikitext: str) -> str:
    m = SERIES_RE.search(wikitext)
    return m.group(1).strip() if m else ""


# ──────────────────────────────────────────────
# FULL SCRAPE
# ──────────────────────────────────────────────

def full_scrape():
    print("📋  Building facility page list…\n")

    # page_title → area_hint
    page_area: dict[str, str] = {}

    # Strategy 1: try sub-pages of the Facilities hub
    for page_name, area_id in AREA_SOURCES:
        links = get_page_links(page_name)
        if links:
            print(f"  {page_name}: {len(links)} links")
            for title in links:
                # Only include pages that look like facility names (not categories, talk, etc.)
                if ":" not in title and title != page_name:
                    page_area.setdefault(title, area_id)
        time.sleep(REQUEST_DELAY)

    # Strategy 2: top-level Facilities category as fallback
    if not page_area:
        print(f"  Falling back to Category:{FACILITY_CATEGORY}…")
        members = get_category_members(FACILITY_CATEGORY)
        for title in members:
            page_area.setdefault(title, "unknown")
        print(f"  Found {len(members)} pages in category")
        time.sleep(REQUEST_DELAY)

    total = len(page_area)
    print(f"\n🔍  Fetching {total} facility pages…\n")

    facilities = []
    errors = []

    for i, (title, area_hint) in enumerate(sorted(page_area.items()), 1):
        print(f"  [{i:>4}/{total}] {title}", end="", flush=True)
        try:
            wikitext = get_wikitext(title)
            if not wikitext:
                print(" — ⚠  No wikitext")
                errors.append(title)
                continue

            facility = build_facility(title, wikitext, area_hint=area_hint)

            # Skip pages that produced clearly bad results
            # (e.g., navigation pages, categories)
            if not facility.get("effects") and not facility.get("price"):
                print(" — ⚠  Skipped (no effects/price found)")
                continue

            facilities.append(facility)
            effect_summary = ", ".join(e["type"] for e in facility["effects"])
            print(f" ✓  [{facility['area']}/{facility['group']}] {effect_summary}")

        except Exception as e:
            print(f" ✗  ERROR: {e}")
            errors.append(title)

        time.sleep(REQUEST_DELAY)

    # Sort: by area then group
    area_order = {"restaurant": 0, "buffet": 1, "kitchen": 2,
                  "courtyard": 3, "terrace": 4, "fishing_pond": 5, "unknown": 9}
    facilities.sort(key=lambda f: (area_order.get(f["area"], 9), f.get("group", ""), f["name"]))

    with open(OUTPUT_FILE, "w", encoding="utf-8") as fh:
        json.dump(facilities, fh, indent=2, ensure_ascii=False)

    print(f"\n✅  Done! {len(facilities)} facilities → {OUTPUT_FILE}")
    if errors:
        print(f"⚠   {len(errors)} pages had errors: {errors}")

    # Print income summary for quick verification
    print("\n📊  Income effect summary:")
    for area in ["restaurant", "buffet", "kitchen", "courtyard", "terrace", "fishing_pond"]:
        area_facilities = [f for f in facilities if f["area"] == area]
        ipm = sum(
            e["amount"] for f in area_facilities
            for e in f["effects"]
            if e["type"] == "incomePerMinute"
        )
        ipi = sum(
            e["amount"] for f in area_facilities
            for e in f["effects"]
            if e["type"] == "incomePerInterval"
        )
        if area_facilities:
            print(f"  {area:15s}: {len(area_facilities):>3} items | "
                  f"Σ income/min={ipm:>8,} cod | Σ income/interval={ipi:>8,}")


# ──────────────────────────────────────────────
# DIAGNOSTIC PROBE
# ──────────────────────────────────────────────

def probe(title: str):
    print(f"🔬  Probing facility: {title}\n{'='*60}")
    wikitext = get_wikitext(title)
    if not wikitext:
        print("No wikitext returned. Check the page title.")
        return

    print("\n── RAW WIKITEXT (first 120 lines) ──────────────────────────")
    lines = wikitext.splitlines()
    for line in lines[:120]:
        print(line)
    if len(lines) > 120:
        print(f"  … ({len(lines) - 120} more lines)")

    print("\n── EXTRACTED TEMPLATE FIELDS ───────────────────────────────")
    raw = extract_template_fields(wikitext)
    for k, v in raw.items():
        print(f"  {k!r:35s} = {v!r}")

    print("\n── AFTER FIELD_MAP ─────────────────────────────────────────")
    mapped = map_fields(raw)
    for k, v in mapped.items():
        print(f"  {k!r:35s} = {v!r}")

    print("\n── PARSED PRICE ────────────────────────────────────────────")
    price = parse_price(mapped, wikitext)
    print(f"  {price}")

    print("\n── PARSED EFFECTS ──────────────────────────────────────────")
    effects = build_effects(mapped, wikitext)
    for e in effects:
        print(f"  {e}")

    print("\n── FINAL FACILITY OBJECT ───────────────────────────────────")
    facility = build_facility(title, wikitext)
    print(json.dumps(facility, indent=2, ensure_ascii=False))


def probe_area(area_name: str):
    """List what pages the scraper would find for a given area source."""
    print(f"🔬  Probing area sources for: {area_name}\n{'='*60}")
    for page_name, area_id in AREA_SOURCES:
        if area_name.lower() in area_id.lower() or area_name.lower() in page_name.lower():
            print(f"\n  Trying page: {page_name}")
            links = get_page_links(page_name)
            print(f"  Found {len(links)} links:")
            for lnk in links[:30]:
                print(f"    {lnk}")
            if len(links) > 30:
                print(f"    … and {len(links) - 30} more")
            time.sleep(REQUEST_DELAY)


# ──────────────────────────────────────────────
# ENTRY POINT
# ──────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Animal Restaurant facilities scraper")
    parser.add_argument(
        "--probe", nargs="?", const="Stone Bowl", metavar="FACILITY_NAME",
        help="Debug: dump wikitext + parsed fields for one facility"
    )
    parser.add_argument(
        "--probe-area", metavar="AREA",
        help="Debug: list all pages found for a given area (e.g. restaurant, buffet)"
    )
    args = parser.parse_args()

    if args.probe is not None:
        probe(args.probe)
    elif args.probe_area:
        probe_area(args.probe_area)
    else:
        full_scrape()
