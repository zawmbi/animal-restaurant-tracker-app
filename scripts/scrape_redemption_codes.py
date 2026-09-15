#!/usr/bin/env python3
"""Regenerate assets/data/redemption_codes.json from Template:RedemptionCode.

The file had 91 codes whose newest validFrom was 2026-02-17, so on 15 Sep 2026
exactly one code was active — AR999, the permanent one, whose gift resolves to
nothing and whose checkbox is therefore disabled. The page built for redeeming
codes showed a single row you could not tick.

Gifts are resolved to a memento or facility id by name, the same two registries
the app checks at runtime. A gift that resolves in neither is written with
giftKind "unresolved" and left untappable rather than guessed at.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from wiki_common import to_id  # noqa: E402
from wiki_fetch import fetch  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "data")
OUT = os.path.join(ROOT, "redemption_codes.json")

DATES = re.compile(r"Valid from\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*until\s*([0-9]{4}-[0-9]{2}-[0-9]{2})")
PERMANENT = re.compile(r"permanent|no expiry|forever", re.I)
GIFT_LINK = re.compile(r"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]")


def registries():
    """name -> {ids}, for the two registries the app resolves gifts against.

    Sets, not single ids: two different facilities really can share a display
    name. SWEETLOVEAR's "Gift Teddy Bear" is both a free courtyard item and a
    9.5M terrace one, and picking whichever shard loaded first would silently
    invent an answer. A name with more than one id stays unresolved.
    """
    mementos = {}
    for m in json.load(open(os.path.join(ROOT, "mementos.json"), encoding="utf-8")):
        if m.get("name"):
            mementos.setdefault(m["name"].strip().lower(), set()).add(m["id"])

    facilities = {}
    shards = os.path.join(ROOT, "facilities_jsons")
    for fn in sorted(os.listdir(shards)):
        if not fn.endswith(".json"):
            continue
        for f in json.load(open(os.path.join(shards, fn), encoding="utf-8")):
            if f.get("name"):
                facilities.setdefault(f["name"].strip().lower(), set()).add(f["id"])
    return mementos, facilities


def cells(row):
    """The |-separated cells of one wiki table row."""
    out = []
    for line in row.split("\n"):
        line = line.strip()
        if line.startswith("|") and not line.startswith("|-"):
            out.append(line[1:].strip())
    return out


def gift_of(cell):
    """(display name, wiki link target) from a gift cell."""
    name, target = "", ""
    for m in GIFT_LINK.finditer(cell):
        link, label = m.group(1), m.group(2)
        if link.startswith("File:"):
            continue
        target = link.strip()
        name = (label or link).strip()
    return name, target


def main():
    wikitext = fetch("Template:RedemptionCode")
    if wikitext.startswith("__ERROR__"):
        sys.exit("could not fetch the template: " + wikitext[:200])

    mementos, facilities = registries()
    rows, unresolved = [], []

    for raw in wikitext.split("|-")[1:]:
        c = cells(raw)
        if len(c) < 5:
            continue
        code = c[0].strip()
        if not re.fullmatch(r"[A-Za-z0-9_]{3,30}", code):
            continue

        validity, reason, gift_cell = c[2], c[3], c[4]
        dates = DATES.search(validity)
        if dates:
            valid_from, valid_until = dates.group(1), dates.group(2)
        elif PERMANENT.search(validity):
            valid_from, valid_until = "2019-01-01", "2099-12-31"
        else:
            valid_from, valid_until = None, None

        label, target = gift_of(gift_cell)
        key = label.strip().lower()
        if not label:
            # Currency-only codes. The old data used a null giftKind for
            # these, and the page relies on it to disable the checkbox, so
            # they are not the same thing as a gift it could not find.
            kind, ref = None, None
        elif len(mementos.get(key, ())) == 1:
            kind, ref = "memento", next(iter(mementos[key]))
        elif len(facilities.get(key, ())) == 1:
            kind, ref = "facility", next(iter(facilities[key]))
        else:
            kind, ref = "unresolved", to_id(label)
            why = "ambiguous" if (mementos.get(key) or facilities.get(key)) else "absent"
            unresolved.append((code, label, target, why))

        row = {
            "code": code,
            "validFrom": valid_from,
            "validUntil": valid_until,
            "reason": re.sub(r"\s+", " ", reason).strip(),
            # Legacy field name the data has always used; the app reads
            # giftRefId first and branches on giftKind.
            "giftMementoId": ref,
            "giftLabel": label,
            "giftKind": kind,
            "giftRefId": ref,
        }
        rows.append(row)

    if not rows:
        sys.exit("parsed 0 codes — the template layout probably changed")

    rows.sort(key=lambda r: (r["validFrom"] or "", r["code"]), reverse=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(rows, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    from datetime import date
    today = date.today().isoformat()
    live = [r["code"] for r in rows
            if (r["validFrom"] or "9999") <= today <= (r["validUntil"] or "0000")]
    print("wrote %d codes" % len(rows))
    print("active today (%s): %d — %s" % (today, len(live), ", ".join(live)))
    if unresolved:
        print("gifts resolving to neither registry: %d" % len(unresolved))
        for code, label, target, why in unresolved:
            print("   %-16s %-30s %-9s (wiki link: %s)" % (code, label, why, target))


if __name__ == "__main__":
    main()
