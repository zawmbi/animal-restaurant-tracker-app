#!/usr/bin/env python3
"""Progress-bucket and reachability checks, by static analysis of lib/.

Two failure modes this guards against, both of which have already cost real
tracked progress on this branch:

1. A page writes to a bucket string nothing else reads, or to a bucket that is
   not loaded on startup. `UnlockedStore._defaultTypes` and
   `ProgressTypes.registerOnStartup` are two hand-maintained copies of the same
   list; nothing in the app makes them agree.

2. A collectible is counted in the completion denominator but has no screen
   that can check it off, so 100% is unreachable. Or the reverse: a collectible
   is shipped in the data and shown nowhere and counted nowhere.

Exit code 1 on any failure.
"""

import collections
import re

from qa_common import (
    Report, load, facilities_by_area, FACILITY_SCENE_AREAS, dart_sources,
    sample, LIB,
)

STORE_FILE = 'lib/features/shared/data/unlocked_store.dart'
TYPES_FILE = 'lib/features/completion/data/progress_types.dart'

# Calls whose FIRST string argument is an UnlockedStore bucket.
BUCKET_CALL = re.compile(
    r"\b(?:isUnlocked|setUnlocked|setManyUnlocked|registerType|clearType|"
    r"toggle|ids|count)\(\s*'([a-z0-9_]+)'"
)
# `static const String _bucketX = 'foo';` and `static const _bucket = 'foo';`
BUCKET_CONST = re.compile(r"_bucket\w*\s*=\s*'([a-z0-9_]+)'")
# `bucket = 'foo';` inside the switch statements on the search pages.
BUCKET_ASSIGN = re.compile(r"\bbucket\w*\s*=\s*'([a-z0-9_]+)'\s*;")
# Buckets declared privately inside a progress helper class.
PRIVATE_BUCKET = re.compile(r"static const String _\w*[Bb]ucket\s*=\s*'([a-z0-9_]+)'")
TYPE_CONST = re.compile(r"static const String _type\s*=\s*'([a-z0-9_]+)'")


def _strip_comments(text):
    """Drop // line comments, so prose about a bucket is not read as a bucket."""
    return '\n'.join(re.sub(r'//.*$', '', line) for line in text.split('\n'))


def _dart_string_list(text, marker, pattern=r"'([a-z0-9_]+)'"):
    """The string literals between `marker` and the closing `];`, code only."""
    start = text.index(marker)
    end = text.index('];', start)
    return re.findall(pattern, _strip_comments(text[start:end]))


def _progress_types_values(text):
    return dict(re.findall(r"static const String (\w+)\s*=\s*'([a-z0-9_]+)';", text))


def main():
    rep = Report('qa_progress_buckets')
    sources = dict(dart_sources())

    store_src = sources[STORE_FILE]
    types_src = sources[TYPES_FILE]

    default_types = _dart_string_list(store_src, '_defaultTypes = <String>[')
    assert default_types, 'could not read UnlockedStore._defaultTypes'
    pt_values = _progress_types_values(types_src)
    register_names = _dart_string_list(
        types_src, 'registerOnStartup = <String>[', r'\b(\w+),')
    register_on_startup = [pt_values[n] for n in register_names if n in pt_values]

    rep.section('bucket list invariants')
    rep.check(len(default_types) == len(set(default_types)),
              'UnlockedStore._defaultTypes has no duplicates',
              sample([b for b, n in collections.Counter(default_types).items()
                      if n > 1]))
    rep.check(len(register_names) == len(register_on_startup),
              'every ProgressTypes.registerOnStartup entry resolves to a constant',
              f'unresolved: {sample(set(register_names) - set(pt_values))}')
    missing = [b for b in register_on_startup if b not in default_types]
    rep.check(not missing,
              'ProgressTypes.registerOnStartup is a subset of '
              'UnlockedStore._defaultTypes',
              f'not loaded on startup: {sample(missing)}')
    # Every ProgressTypes constant, not just the registered ones, has to be a
    # startup bucket: CompletionService counts them all.
    counted = {v for k, v in pt_values.items()}
    missing_counted = sorted(counted - set(default_types))
    rep.check(not missing_counted,
              'every ProgressTypes constant is a startup bucket',
              f'missing: {sample(missing_counted)}')

    rep.section('bucket strings used anywhere in lib/')
    found = collections.defaultdict(set)
    for path, text in sources.items():
        if path == STORE_FILE:
            continue
        code = _strip_comments(text)
        for pattern in (BUCKET_CALL, BUCKET_CONST, BUCKET_ASSIGN,
                        PRIVATE_BUCKET, TYPE_CONST):
            for bucket in pattern.findall(code):
                found[bucket].add(path)
        # Pages that go through the ProgressTypes constants instead of a
        # literal count as users of the bucket the constant names.
        if path != TYPES_FILE:
            for name in re.findall(r'ProgressTypes\.(\w+)', code):
                if name in pt_values:
                    found[pt_values[name]].add(path)

    unknown = {b: v for b, v in found.items() if b not in default_types}
    for bucket, files in sorted(unknown.items()):
        print(f'        {bucket!r} used in {sorted(files)}')
    rep.check(not unknown,
              f'every bucket literal in lib/ is a startup bucket '
              f'({len(found)} distinct)',
              f'unknown: {sample(unknown)}')

    # A bucket in _defaultTypes that nothing reads or writes is dead weight;
    # a warning rather than a failure, because legacy spellings are kept
    # deliberately so old saves still load.
    unused = [b for b in default_types if b not in found]
    rep.warn(not unused,
             'no startup bucket is unused by lib/',
             f'never read or written: {sample(unused)}')

    rep.section('facility reachability')
    by_area = facilities_by_area()
    scene_ids = collections.Counter()
    for area in FACILITY_SCENE_AREAS:
        for row in by_area[area]:
            scene_ids[row['id']] += 1
    # Two rows in the SAME bucket sharing an id means checking one checks both,
    # and the denominator is short by the difference.
    collisions = {i: n for i, n in scene_ids.items() if n > 1}
    rep.check(not collisions,
              "no id collisions inside the 'facility' bucket "
              f'({sum(scene_ids.values())} rows)',
              f'{len(collisions)} colliding ids: {sample(collisions)}')

    courtyard_ids = {row['id'] for row in by_area['courtyard']}
    cross = sorted(set(scene_ids) & courtyard_ids)
    rep.check(not cross,
              "no facility id is in both the 'facility' and "
              "'courtyard_facility_purchased' buckets",
              f'{len(cross)} double-counted, must be checked twice: {sample(cross)}')

    # Concert and pet-yard shards are loaded by FacilitiesRepository (so global
    # search finds them) but shown by no page and counted by no category.
    orphan_areas = {}
    for area in ('courtyard_concert', 'courtyard_pets'):
        orphan_areas[area] = len(by_area[area])
    total_orphan = sum(orphan_areas.values())
    rep.check(total_orphan == 0,
              'every facility shard is reachable from some page',
              f'{total_orphan} facilities in areas no page renders: {orphan_areas}')

    rep.section('courtyard group reachability')
    # CourtyardPage only renders a tab per group listed in
    # CourtyardRepository.orderedGroups; anything else is in the denominator
    # but has no checkbox anywhere.
    courtyard_src = sources['lib/features/courtyard/data/courtyard_repository.dart']
    ordered = _dart_string_list(courtyard_src, 'orderedGroups = [', r"'([^']+)'")
    groups = collections.Counter(row['group'] for row in by_area['courtyard'])
    tabless = {g: n for g, n in groups.items() if g not in ordered}
    for g, n in sorted(tabless.items(), key=lambda kv: -kv[1]):
        print(f'        {g!r}: {n} facilities, no tab')
    rep.check(not tabless,
              f'every courtyard group has a tab '
              f'({sum(groups.values())} facilities in {len(groups)} groups)',
              f'{sum(tabless.values())} facilities unreachable')
    empty_tabs = [g for g in ordered if g not in groups]
    rep.warn(not empty_tabs, 'no courtyard tab is empty', sample(empty_tabs))

    rep.section('completion totals')
    # These are the denominators the progress page adds up. If one of them
    # moves, the percentage a player has been staring at moves with it.
    expected = {
        'customers': 613,
        'mementos': 1184,
        'recipes': 268,
        'letters': 257,
        'facilities': 2191,
        'courtyard': 1336,
        'pets': 49,
        'staff': 16,
        'movie acts': 198,
        'posters': 155,
        'battle pass (normal track)': 573,
    }
    pets = load('pets.json')
    actual = {
        'customers': len(load('customers.json')),
        'mementos': len(load('mementos.json')),
        'recipes': len(load('dishes.json')),
        'letters': len(load('letters.json')),
        'facilities': len(set(scene_ids)),
        'courtyard': len(courtyard_ids),
        'pets': 2 * len(pets['pets']) + len(pets['petRooms'])
                + len(pets['photoTasks']),
        'staff': len(load('staff.json')),
        'movie acts': sum(m['actCount'] for m in load('movies.json')),
        'posters': len(load('posters.json')),
        'battle pass (normal track)': sum(
            len(p['tiers'])
            for pid in ('deep_sea_ballad', 'fantastical_party',
                        'midsummer_birdsong', 'slumberous_nights')
            for p in load(f'battle_passes/{pid}.json')['phases']),
    }
    for key, want in expected.items():
        rep.warn(actual[key] == want, f'{key} total is {want}',
                 f'now {actual[key]}')

    rep.section('data assets nothing loads')
    all_text = '\n'.join(sources.values())
    import os
    import glob as _glob
    shipped = [os.path.relpath(p, os.path.dirname(LIB))
               for p in _glob.glob(os.path.join(
                   os.path.dirname(LIB), 'assets', 'data', '*.json'))]
    orphans = [a for a in shipped if a not in all_text]
    rep.check(not orphans,
              'every assets/data/*.json is referenced from lib/',
              f'unreferenced: {sample(orphans)}')

    rep.finish()


if __name__ == '__main__':
    main()
