"""Shared cache / intermediate-file directory for the wiki scrapers."""
import os
BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.cache')
os.makedirs(BASE, exist_ok=True)

def W(name):
    """Resolve an intermediate/cache file name inside scripts/.cache/."""
    p = os.path.join(BASE, name)
    d = os.path.dirname(p)
    if d:
        os.makedirs(d, exist_ok=True)
    return p
