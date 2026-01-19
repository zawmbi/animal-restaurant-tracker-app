import json
import re
import time
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup, Tag

BASE = "https://animalrestaurant.fandom.com"
START_URL = "https://animalrestaurant.fandom.com/wiki/Regular_Customers"
OUT_FILE = "regular_customers.json"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (AnimalRestaurantTracker; +https://example.com)"
}

# ---------- small utils ----------

def slugify(text: str) -> str:
    if text is None:
        return ""
    s = text.strip().lower()
    s = re.sub(r"[’'`]", "", s)
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s

def clean(text: str | None) -> str | None:
    if not text:
        return None
    t = re.sub(r"\s+", " ", text).strip()
    return t if t else None

def split_list(s: str | None) -> list[str]:
    """
    Splits common list strings:
    - "A, B, C"
    - "A · B · C"
    - "A • B • C"
    """
    if not s:
        return []
    s = s.replace("·", ",").replace("•", ",")
    parts = [p.strip() for p in s.split(",")]
    return [slugify(p) for p in parts if p.strip()]

def parse_int(s: str | None) -> int | None:
    if not s:
        return None
    m = re.search(r"(\d[\d,]*)", s)
    if not m:
        return None
    return int(m.group(1).replace(",", ""))

def find_heading(soup: BeautifulSoup, heading_text: str):
    # Finds a section heading like "Requirements" or "Memento"
    pat = re.compile(rf"^{re.escape(heading_text)}\s*$", re.I)
    for tag in soup.find_all(["h2", "h3"]):
        span = tag.find(["span"], class_="mw-headline")
        if span and span.get_text(strip=True) and pat.match(span.get_text(strip=True)):
            return tag
    return None

def next_tables_after(tag: Tag, limit: int = 80):
    """
    Yield tables after a given tag, skipping obvious navboxes.
    """
    cur = tag
    steps = 0
    while cur is not None and steps < limit:
        cur = cur.find_next()
        steps += 1
        if cur is None:
            return
        if getattr(cur, "name", None) != "table":
            continue
        cls = " ".join(cur.get("class", []))
        if "navbox" in cls:
            continue
        yield cur

# ---------- infobox parsing (robust) ----------

def infobox_kv(soup: BeautifulSoup) -> dict[str, str]:
    """
    Reads Fandom portable infobox rows into a label->value dict.
    This catches lots of pages reliably.
    """
    out: dict[str, str] = {}
    infobox = soup.select_one("aside.portable-infobox")
    if not infobox:
        return out

    # Typical rows: .pi-data with .pi-data-label and .pi-data-value
    for row in infobox.select(".pi-data"):
        label_el = row.select_one(".pi-data-label")
        value_el = row.select_one(".pi-data-value")
        label = clean(label_el.get_text(" ")) if label_el else None
        value = clean(value_el.get_text(" ")) if value_el else None
        if label and value:
            out[label.lower()] = value

    # Some pages also store values in data-source fields
    for row in infobox.select(".pi-item[data-source]"):
        ds = row.get("data-source")
        val = row.select_one(".pi-data-value") or row.select_one(".pi-item-spacing")
        v = clean(val.get_text(" ")) if val else None
        if ds and v:
            out[ds.lower()] = v

    return out

def get_value(soup: BeautifulSoup, label_regex: str) -> str | None:
    """
    Robust value getter:
    1) portable infobox label/value pairs
    2) "Requirements" section table label/value rows (teal left cells)
    3) fallback: any table label/value rows
    """
    pat = re.compile(label_regex, re.I)

    # 1) portable infobox
    kv = infobox_kv(soup)
    for k, v in kv.items():
        if pat.search(k):
            return v

    # 2) "Requirements" section table
    req_h = find_heading(soup, "Requirements")
    if req_h:
        for tbl in next_tables_after(req_h):
            got = _table_label_value(tbl, pat)
            if got:
                return got

    # 3) fallback: any table
    for tbl in soup.find_all("table"):
        got = _table_label_value(tbl, pat)
        if got:
            return got

    return None

def _table_label_value(tbl: Tag, pat: re.Pattern) -> str | None:
    for tr in tbl.find_all("tr"):
        cells = tr.find_all(["th", "td"])
        if len(cells) < 2:
            continue
        left = clean(cells[0].get_text(" "))
        if left and pat.search(left):
            return clean(cells[1].get_text(" "))
    return None

def get_right_card_description(soup: BeautifulSoup) -> str | None:
    """
    Tries hard to find the right-card short description.
    """
    # portable infobox often has description
    infobox = soup.select_one("aside.portable-infobox")
    if infobox:
        # Best: explicit description source
        for sel in [
            "[data-source='description'] .pi-data-value",
            ".pi-data[data-source='description'] .pi-data-value",
        ]:
            el = infobox.select_one(sel)
            if el:
                txt = clean(el.get_text(" "))
                if txt and len(txt) <= 400:
                    return txt

        # Sometimes just a "Description" label row exists
        for row in infobox.select(".pi-data"):
            label_el = row.select_one(".pi-data-label")
            if not label_el:
                continue
            if "description" in label_el.get_text(" ").strip().lower():
                val_el = row.select_one(".pi-data-value")
                txt = clean(val_el.get_text(" ")) if val_el else None
                if txt and len(txt) <= 400:
                    return txt

    # Fallback: first paragraph in main content
    content = soup.select_one("div.mw-parser-output")
    if content:
        for p in content.find_all("p", recursive=False):
            txt = clean(p.get_text(" "))
            if txt and len(txt) > 10 and "This article is about" not in txt:
                return txt[:400]
    return None

# ---------- discovery (ONLY regular customers) ----------

def discover_regular_customer_urls() -> list[str]:
    """
    The Regular_Customers page contains the 4 lists:
    Nearby / Village / Town / City.
    We ONLY collect links inside those lists.
    This avoids navboxes/footers and avoids booth owners / performers / posters etc.
    """
    html = requests.get(START_URL, headers=HEADERS, timeout=30).text
    soup = BeautifulSoup(html, "html.parser")

    content = soup.select_one("div.mw-parser-output")
    if not content:
        return []

    wanted_sections = {"nearby", "village", "town", "city"}
    urls: set[str] = set()

    # Find headings that match those section names
    for h in content.find_all(["h2", "h3", "h4"]):
        span = h.find("span", class_="mw-headline")
        if not span:
            continue
        title = clean(span.get_text(" "))
        if not title:
            continue
        key = title.strip().lower()
        if key not in wanted_sections:
            continue

        # Grab the next sibling list(s) that contain the names
        sib = h
        for _ in range(30):
            sib = sib.find_next_sibling()
            if sib is None:
                break

            # stop when we hit another heading
            if getattr(sib, "name", None) in ("h2", "h3", "h4"):
                break

            # The names are usually in <ul> (sometimes multiple)
            if getattr(sib, "name", None) == "ul":
                for a in sib.select("a[href^='/wiki/']"):
                    href = a.get("href", "")
                    if ":" in href:
                        continue
                    full = urljoin(BASE, href.split("#")[0])
                    # skip list pages
                    if full.endswith("/wiki/Regular_Customers"):
                        continue
                    if full.endswith("/wiki/Customers"):
                        continue

                    link_text = clean(a.get_text(" "))
                    if not link_text or link_text.lower() in wanted_sections:
                        continue

                    # keep it
                    urls.add(full)

            # Sometimes Fandom uses <p> with links; accept those only if they look like a name list
            if getattr(sib, "name", None) == "p":
                # only if it contains lots of dots (·) or many links
                link_count = len(sib.select("a[href^='/wiki/']"))
                if link_count >= 5:
                    for a in sib.select("a[href^='/wiki/']"):
                        href = a.get("href", "")
                        if ":" in href:
                            continue
                        full = urljoin(BASE, href.split("#")[0])
                        if full.endswith("/wiki/Regular_Customers") or full.endswith("/wiki/Customers"):
                            continue
                        link_text = clean(a.get_text(" "))
                        if not link_text or link_text.lower() in wanted_sections:
                            continue
                        urls.add(full)

    return sorted(urls)

# ---------- mementos parsing (STRICT table selection) ----------

def _find_memento_table(soup: BeautifulSoup) -> Tag | None:
    mem_h = find_heading(soup, "Memento") or find_heading(soup, "Mementos")
    if not mem_h:
        return None

    for tbl in next_tables_after(mem_h, limit=120):
        txt = clean(tbl.get_text(" ")) or ""
        # A real memento table almost always contains "Serve" or "Sell" and "+<number>"
        if re.search(r"\bServe\b|\bSell\b", txt, re.I) and re.search(r"\+\d", txt):
            return tbl

    return None

def parse_mementos(soup: BeautifulSoup) -> list[dict]:
    tbl = _find_memento_table(soup)
    if not tbl:
        return []

    mementos: list[dict] = []

    for tr in tbl.find_all("tr"):
        # Skip header rows
        if tr.find("th"):
            continue

        row_text = clean(tr.get_text(" "))
        if not row_text:
            continue

        # must include Serve/Sell to be a memento row
        if not re.search(r"\bServe\b|\bSell\b", row_text, re.I):
            continue

        # Extract star bonus like "+45" or "+160"
        stars = None
        m = re.search(r"\+(\d[\d,]*)", row_text)
        if m:
            stars = int(m.group(1).replace(",", ""))

        # Name: usually strong/b
        name = None
        for cand in tr.find_all(["b", "strong"]):
            t = clean(cand.get_text(" "))
            if t and len(t) <= 80:
                name = t
                break

        # Fallback: try first td text chunk before "Serve"
        if not name:
            before_serve = re.split(r"\bServe\b", row_text, maxsplit=1, flags=re.I)[0]
            before_serve = clean(before_serve)
            if before_serve and len(before_serve) <= 80:
                name = before_serve

        if not name:
            continue

        # Requirement line: try to capture "Serve ... times." and optional "Sell ..."
        req = None
        mm = re.search(r"(Serve .*?times\.?(?:.*?Sell .*?\.)?)", row_text, re.I)
        if mm:
            req = clean(mm.group(1))
        else:
            mm2 = re.search(r"(Serve .*?times\.?)", row_text, re.I)
            if mm2:
                req = clean(mm2.group(1))

        # Description: remove name/stars/req from row_text crudely
        desc = row_text
        if req:
            desc = desc.replace(req, " ")
        # remove "+NNN"
        desc = re.sub(r"\+\d[\d,]*", " ", desc)
        # remove name if it appears
        if name:
            desc = desc.replace(name, " ")
        desc = clean(desc)
        if desc and len(desc) > 240:
            desc = desc[:240]

        mementos.append({
            "id": slugify(name),
            "name": name,
            "stars": stars,
            "description": desc,
            "requirement": req,
            "tags": ["customer_gift"],
            "source": "customer_gift",
            "shareReward": None
        })

    return mementos

# ---------- main customer scrape ----------

def scrape_customer(url: str) -> dict:
    html = requests.get(url, headers=HEADERS, timeout=30).text
    soup = BeautifulSoup(html, "html.parser")

    h1 = soup.select_one("h1")
    name = clean(h1.get_text(" ")) if h1 else None
    if not name:
        t = soup.select_one("title")
        name = clean(t.get_text(" ")) if t else "Unknown"

    cid = slugify(name)

    lives_in = get_value(soup, r"^lives in$|^lives\s+in")
    appearance_weight = parse_int(get_value(soup, r"^appearance weight$|^appearance\s+weight"))

    required_food = get_value(soup, r"^required food$|^required\s+food")
    dishes_ordered = get_value(soup, r"^dishes ordered$|^dishes\s+ordered")

    required_facilities = get_value(soup, r"^required facilities$|^required\s+facilities")
    required_flowers = get_value(soup, r"^required flowers$|^required\s+flowers")
    required_letters = get_value(soup, r"^required letters$|^required\s+letters")

    customer_desc = get_right_card_description(soup)

    dishes = split_list(dishes_ordered)
    facilities = split_list(required_facilities)
    flowers = split_list(required_flowers)
    letters = split_list(required_letters)

    # requiredFoodId: first item only (some pages list multiple foods)
    required_food_id = None
    if required_food:
        first = required_food.replace("·", ",").replace("•", ",").split(",")[0].strip()
        required_food_id = slugify(first) if first else None

    tags = ["customer", "restaurant", "regular"]
    if lives_in:
        tags.append(slugify(lives_in))

    mementos = parse_mementos(soup)

    return {
        "id": cid,
        "name": name,
        "tags": tags,
        "livesIn": lives_in,
        "appearanceWeight": appearance_weight,
        "requiredFoodId": required_food_id,
        "dishesOrderedIds": dishes,
        "customerDescription": customer_desc or "",
        "requirements": {
            "rating": None,
            "recipes": [],
            "facilities": facilities,
            "letters": letters,
            "customers": [],
            "flowers": flowers
        },
        "mementos": mementos,
        "boothOwner": None,
        "performer": None,
        "_sourceUrl": url
    }

# ---------- runner ----------

def main():
    urls = discover_regular_customer_urls()
    print(f"Discovered {len(urls)} regular customer pages total")

    # test first 5
    urls = urls[:5]
    print(f"Testing first {len(urls)} pages")

    out = []
    for i, url in enumerate(urls, 1):
        print(f"[{i}/{len(urls)}] {url}")
        try:
            out.append(scrape_customer(url))
        except Exception as e:
            print("ERROR:", url, repr(e))
        time.sleep(0.35)

    with open(OUT_FILE, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2, ensure_ascii=False)

    print("Saved:", OUT_FILE)

if __name__ == "__main__":
    main()
