#!/usr/bin/env python3
"""
Prepare simulator screenshots for App Store Connect.

The problem this exists for: every screenshot out of the iOS Simulator —
`xcrun simctl io ... screenshot` and Cmd+S alike — is RGBA, and App Store
Connect will not accept a screenshot with an alpha channel. It does not say so.
You drag the file into Media Manager and it simply disappears: no error, no
red badge, no row. The same rule bites app icons, where at least the upload
fails loudly.

Screenshots are fully opaque in practice, so dropping the alpha channel is
lossless. This checks that before doing it, and refuses rather than silently
flattening something that really was transparent.

Usage:
    # strip alpha, write into ./store-ready/
    python3 scripts/prep_store_screenshots.py shots/*.png

    # also resize for a different App Store Connect slot
    python3 scripts/prep_store_screenshots.py --size 1284x2778 shots/*.png

    # a whole folder, output somewhere specific
    python3 scripts/prep_store_screenshots.py --out ~/Desktop/6.9 shots/

App Store Connect slots, for reference:
    6.9" iPhone    1290x2796  or  1320x2868
    6.5" iPhone    1242x2688  or  1284x2778
    13"  iPad      2064x2752  or  2048x2732

Originals are never modified.
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python3 -m pip install Pillow")


def parse_size(text: str) -> tuple[int, int]:
    try:
        w, h = text.lower().split("x")
        return int(w), int(h)
    except ValueError:
        raise argparse.ArgumentTypeError(
            f"--size wants WIDTHxHEIGHT, e.g. 1284x2778 (got {text!r})"
        )


def collect(paths: list[str]) -> list[Path]:
    out: list[Path] = []
    for raw in paths:
        p = Path(raw).expanduser()
        if p.is_dir():
            out.extend(sorted(q for q in p.iterdir()
                              if q.suffix.lower() == ".png"))
        elif p.suffix.lower() == ".png":
            out.append(p)
        else:
            print(f"  skipped (not a .png): {p}")
    return out


def fully_opaque(img: Image.Image) -> bool:
    """True when every pixel's alpha is 255, i.e. dropping it changes nothing."""
    if "A" not in img.getbands():
        return True
    alpha = img.getchannel("A")
    lo, hi = alpha.getextrema()
    return lo == 255 and hi == 255


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Strip the alpha channel (and optionally resize) so App "
                    "Store Connect will accept the screenshots.")
    ap.add_argument("paths", nargs="+", help="PNG files, or folders of them")
    ap.add_argument("--out", default="store-ready",
                    help="output directory (default: ./store-ready)")
    ap.add_argument("--size", type=parse_size, default=None,
                    help="resize to WIDTHxHEIGHT, e.g. 1284x2778")
    ap.add_argument("--force-flatten", action="store_true",
                    help="composite partly-transparent images onto white "
                         "instead of refusing them")
    args = ap.parse_args()

    files = collect(args.paths)
    if not files:
        print("No .png files found.")
        return 1

    out_dir = Path(args.out).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)

    written = 0
    refused = 0

    for src in files:
        with Image.open(src) as img:
            had_alpha = "A" in img.getbands()

            if had_alpha and not fully_opaque(img):
                if not args.force_flatten:
                    print(f"  REFUSED {src.name}: has real transparency. "
                          f"Re-run with --force-flatten to composite onto white.")
                    refused += 1
                    continue
                white = Image.new("RGB", img.size, (255, 255, 255))
                white.paste(img, mask=img.getchannel("A"))
                rgb = white
            else:
                rgb = img.convert("RGB")

            before = rgb.size
            if args.size and rgb.size != args.size:
                # LANCZOS: these are screenshots full of small text, and a
                # cheaper filter turns antialiased glyphs to mush.
                rgb = rgb.resize(args.size, Image.LANCZOS)

            dst = out_dir / src.name
            rgb.save(dst, format="PNG", optimize=True)

            note = []
            if had_alpha:
                note.append("alpha stripped")
            if args.size and before != args.size:
                note.append(f"{before[0]}x{before[1]} -> "
                            f"{args.size[0]}x{args.size[1]}")
            if not note:
                note.append("already clean")
            print(f"  {src.name}: {', '.join(note)}")
            written += 1

    print(f"\n{written} written to {out_dir}"
          + (f", {refused} refused" if refused else ""))
    return 1 if refused else 0


if __name__ == "__main__":
    raise SystemExit(main())
