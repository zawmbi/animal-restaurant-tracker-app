"""Shared loading + reporting helpers for the scripts/qa_*.py checkers.

These run with plain python3 over the shipped JSON in assets/data and the
Dart sources in lib/. Nothing here needs Flutter.
"""

import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'assets', 'data')
LIB = os.path.join(ROOT, 'lib')

# The shards FacilitiesRepository._assetsForArea maps to each FacilityArea.
# Keep in sync with lib/features/facilities/data/facilities_repository.dart.
FACILITY_SHARDS_BY_AREA = {
    'restaurant': ['restaurant_facilities.json'],
    'kitchen': ['kitchen_facilities.json'],
    'garden': ['garden_facilities.json', 'vegetable_garden_facilities.json'],
    'buffet': ['buffet_facilities.json'],
    'takeout': ['takeout_facilities.json', 'signature_store_facilities.json'],
    'terrace': ['terrace_facilities.json'],
    'courtyard': ['courtyard_facilities.json'],
    'courtyard_concert': ['concert_facilities.json'],
    'courtyard_pets': ['pets_facilities.json'],
}

# The areas FacilitiesPage._scenes shows and CompletionService._facilityScenes
# counts, i.e. the 'facility' bucket.
FACILITY_SCENE_AREAS = [
    'restaurant', 'kitchen', 'garden', 'buffet', 'takeout', 'terrace',
]


def load(name):
    with open(os.path.join(DATA, name), encoding='utf-8') as fh:
        return json.load(fh)


def facility_shard(name):
    with open(os.path.join(DATA, 'facilities_jsons', name), encoding='utf-8') as fh:
        return json.load(fh)


def facilities_by_area():
    """{area: [row, ...]} exactly as FacilitiesRepository builds it."""
    out = {}
    for area, shards in FACILITY_SHARDS_BY_AREA.items():
        rows = []
        for shard in shards:
            rows.extend(facility_shard(shard))
        out[area] = rows
    return out


def all_facility_rows():
    rows = []
    for area_rows in facilities_by_area().values():
        rows.extend(area_rows)
    return rows


def facility_ids():
    return {row['id'] for row in all_facility_rows()}


def facility_names_by_id():
    # First writer wins, matching FacilitiesRepository.byId's firstWhere.
    out = {}
    for row in all_facility_rows():
        out.setdefault(row['id'], row['name'])
    return out


def dart_sources():
    """[(relative path, text)] for every .dart file under lib/."""
    out = []
    for path in sorted(glob.glob(os.path.join(LIB, '**', '*.dart'), recursive=True)):
        with open(path, encoding='utf-8') as fh:
            out.append((os.path.relpath(path, ROOT), fh.read()))
    return out


class Report:
    """Collects pass/fail lines and decides the process exit code."""

    def __init__(self, title):
        self.title = title
        self.failures = []
        self.warnings = []

    def check(self, ok, label, detail=''):
        if ok:
            print(f'  ok    {label}')
        else:
            print(f'  FAIL  {label}{(" — " + detail) if detail else ""}')
            self.failures.append(label)

    def warn(self, ok, label, detail=''):
        if ok:
            print(f'  ok    {label}')
        else:
            print(f'  warn  {label}{(" — " + detail) if detail else ""}')
            self.warnings.append(label)

    def section(self, name):
        print()
        print(f'--- {name} ---')

    def finish(self):
        print()
        if self.warnings:
            print(f'{len(self.warnings)} warning(s)')
        if self.failures:
            print(f'{self.title}: {len(self.failures)} FAILURE(S)')
            for f in self.failures:
                print(f'  - {f}')
            sys.exit(1)
        print(f'{self.title}: ok')
        sys.exit(0)


def sample(items, n=8):
    items = sorted(items)
    if len(items) <= n:
        return str(items)
    return f'{items[:n]} … (+{len(items) - n} more)'
