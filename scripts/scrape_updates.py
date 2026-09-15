#!/usr/bin/env python3
"""Regenerate assets/data/updates.json from the wiki's `Updates` page.

The page is one long changelog, split into <tabber> tabs per major version.
Each release is an `==v11.26.0g==` heading, followed by a bold date line and a
bullet list. Sub-bullets (`**`) are indented notes on the bullet above; they
are kept, flattened with a leading en dash, because several of them carry the
dates an event actually runs.

`updates.json` had two entries, the newest six months old, and nothing in
`scripts/` produced it — so it had been written by hand once and left.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from wiki_common import plain  # noqa: E402
from wiki_fetch import fetch  # noqa: E402

OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "assets", "data", "updates.json"
)

# Keyed by the first three letters, because the page is not consistent:
# v11 writes 'September 7th 2026' and v8 writes 'Apr. 30th 2021'.
MONTHS = {
    m[:3].lower(): i + 1
    for i, m in enumerate(
        "January February March April May June July August September "
        "October November December".split()
    )
}

# v11 writes "v11.26.0g"; v8 and older write "v8.19.0.g", with a dot before
# the suffix. Missing that cost four whole tabber tabs on the first run.
HEADING = re.compile(r"^==\s*v?([0-9]+\.[0-9]+\.[0-9]+\.?[a-z]?)\s*==\s*$")
# "September 7th 2026", "August 17th, 2026", "March 5 2026"
DATE = re.compile(
    r"'''\s*([A-Z][a-z]+)\.?\s+([0-9]{1,2})(?:st|nd|rd|th)?,?\s+([0-9]{4})\.?\s*'''"
)


def iso_date(line):
    m = DATE.search(line)
    if not m:
        return None
    month, day, year = m.group(1)[:3].lower(), int(m.group(2)), int(m.group(3))
    if month not in MONTHS:
        return None
    return "%04d-%02d-%02d" % (year, MONTHS[month], day)


def clean(bullet):
    """Wikitext bullet -> the sentence a player reads."""
    text = plain(bullet)
    text = re.sub(r"\s+", " ", text).strip()
    return text.strip(" *:")


def parse(wikitext):
    releases = []
    current = None

    for raw in wikitext.split("\n"):
        line = raw.rstrip()

        head = HEADING.match(line.strip())
        if head:
            current = {"version": "v" + head.group(1), "date": None, "changes": []}
            releases.append(current)
            continue

        if current is None:
            continue

        if current["date"] is None:
            got = iso_date(line)
            if got:
                current["date"] = got
                continue

        # Galleries, images and templates are not changelog text.
        if line.startswith(("<gallery", "[[File:", "{{", "|", "</gallery")):
            continue

        if line.startswith("**"):
            text = clean(line[2:])
            if text:
                current["changes"].append("– " + text)
        elif line.startswith("*"):
            text = clean(line[1:])
            if text:
                current["changes"].append(text)

    kept = [r for r in releases if r["date"] and r["changes"]]
    # Eleven v5-v7 maintenance releases carry no date line on the wiki at all
    # — each is a bare "Game optimizations and bugs fixed." They are dropped
    # rather than given a made-up date, and counted so the drop is visible
    # instead of silent.
    undated = [r["version"] for r in releases if not r["date"]]
    return kept, undated


def main():
    wikitext = fetch("Updates")
    if wikitext.startswith("__ERROR__"):
        sys.exit("could not fetch Updates: " + wikitext[:200])

    releases, undated = parse(wikitext)
    if not releases:
        sys.exit("parsed 0 releases — the page layout probably changed")

    # Newest first, by date then by version, so the page reads as a changelog.
    def sort_key(r):
        parts = re.findall(r"\d+", r["version"])
        return (r["date"], [int(p) for p in parts])

    releases.sort(key=sort_key, reverse=True)

    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(releases, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    total_changes = sum(len(r["changes"]) for r in releases)
    print("wrote %d releases, %d change lines" % (len(releases), total_changes))
    print("newest: %s (%s)" % (releases[0]["version"], releases[0]["date"]))
    print("oldest: %s (%s)" % (releases[-1]["version"], releases[-1]["date"]))
    if undated:
        print(
            "skipped %d releases with no date on the wiki: %s"
            % (len(undated), ", ".join(undated))
        )


if __name__ == "__main__":
    main()
