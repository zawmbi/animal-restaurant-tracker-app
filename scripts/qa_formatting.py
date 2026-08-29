#!/usr/bin/env python3
"""User-visible formatting consistency, duplicate code, and orphan detection.

The requirement is that the same kind of value reads the same way everywhere:
no raw snake_case ids in front of a player, one thousands separator, one
percentage precision, one currency capitalisation, one detail screen per kind
of entity.

Everything here is static: it reads assets/data and lib/ and never runs Flutter.

Exit code 1 on any failure.
"""

import collections
import glob
import os
import re

from qa_common import (
    Report, ROOT, LIB, load, dart_sources, facility_names_by_id, sample,
)


def pretty_id(raw):
    """The Dart prettyId in lib/features/shared/utils/display_names.dart."""
    return ' '.join(
        w[0].upper() + w[1:]
        for w in re.split(r'[_\s]+', raw) if w
    )


def main():
    rep = Report('qa_formatting')
    sources = dict(dart_sources())

    # ------------------------------------------------- duplicate declarations
    rep.section('duplicate top-level declarations')
    decls = collections.defaultdict(list)
    for path, text in sources.items():
        for name in re.findall(r'^class (\w+)', text, re.M):
            decls[name].append(path)
        for name in re.findall(r'^enum (\w+)', text, re.M):
            decls[name].append(path)
    dupes = {n: v for n, v in decls.items()
             if len(set(v)) > 1 and not n.startswith('_')}
    for name, paths in sorted(dupes.items()):
        print(f'        {name}: {sorted(set(paths))}')
    rep.check(not dupes,
              'no public class or enum name is declared in two files',
              f'{len(dupes)} duplicated: {sample(dupes)}')

    # ------------------------------------------------------ number formatting
    rep.section('number formatting')
    # Every hand-rolled thousands separator in the app. One helper, used
    # everywhere, or two screens will disagree about what 1000 looks like.
    thousands = sorted(
        path for path, text in sources.items()
        if re.search(r'%\s*3\s*==\s*1\)\s*buf\.write\(\',\'\)', text)
        or re.search(r"remaining % 3 == 1\) buf\.write\(','\)", text)
        or re.search(r"fromEnd % 3 == 1\) buf\.write\(','\)", text)
    )
    for path in thousands:
        print(f'        thousands separator implemented in {path}')
    rep.check(len(thousands) <= 1,
              'exactly one thousands-separator implementation',
              f'{len(thousands)} copies')

    # A percentage is written with a different number of decimals on different
    # screens. Collect every literal precision used next to a '%'.
    pct_precision = collections.defaultdict(set)
    for path, text in sources.items():
        for m in re.finditer(r'toStringAsFixed\((\d)\)[^\n]{0,30}%', text):
            pct_precision[m.group(1)].add(path)
    for digits, paths in sorted(pct_precision.items()):
        print(f'        percentages with {digits} decimal(s): {sorted(paths)}')
    rep.check(len(pct_precision) <= 1,
              'percentages use one decimal precision app-wide',
              f'{len(pct_precision)} different precisions in use')

    # ------------------------------------------------------- raw id leakage
    rep.section('raw id leakage into user-visible strings')
    # A chip or label whose text is an id variable rather than a resolved name.
    leaks = []
    leak_patterns = [
        # EntityChip(label: id) / label: pid / label: someId
        (r'label:\s*(?:id|pid|[a-z]\w*Id)\b(?!\s*==)', 'chip label is a raw id'),
        (r"label:\s*'\$\{?\w*[Ii]d\}?", 'chip label interpolates a raw id'),
        (r'label:\s*\w+\.toString\(\)', 'chip label is an unresolved id'),
        (r"Text\(\s*'\$\{row\.fishId\}", 'row prints a raw fish id'),
        (r"'\$\{e\.performerId\}", 'prints a raw performer id'),
    ]
    for path, text in sources.items():
        for line_no, line in enumerate(text.split('\n'), 1):
            if line.strip().startswith('//'):
                continue
            for pattern, why in leak_patterns:
                if re.search(pattern, line):
                    leaks.append(f'{path}:{line_no} {why}')
    for leak in leaks:
        print(f'        {leak}')
    rep.check(not leaks,
              'no user-visible label renders a raw id',
              f'{len(leaks)} sites')

    # ----------------------------------------------- currency capitalisation
    rep.section('currency capitalisation')
    # Every interpolation of a `.currency` field that does not go through
    # prettyCurrency prints the lowercase data key ("cod", "plates").
    raw_currency = []
    for path, text in sources.items():
        for line_no, line in enumerate(text.split('\n'), 1):
            if line.strip().startswith('//'):
                continue
            if re.search(r'\$\{?\w+(?:!)?\.currency\}?', line) \
                    and 'prettyCurrency' not in line \
                    and '.currency.label' not in line \
                    and '.currency!.label' not in line:
                raw_currency.append(f'{path}:{line_no} {line.strip()[:90]}')
    for r in raw_currency:
        print(f'        {r}')
    rep.check(not raw_currency,
              'every currency shown to a player goes through prettyCurrency '
              'or MoneyCurrencyLabel',
              f'{len(raw_currency)} sites print the raw lowercase key')

    # ------------------------------------------------------- missing artwork
    rep.section('image assets')
    on_disk = {os.path.basename(p)
               for p in glob.glob(os.path.join(ROOT, 'assets', 'images', '*'))}
    referenced = set()
    for path, text in sources.items():
        for m in re.finditer(r"'assets/images/([A-Za-z0-9_]+\.png)'", text):
            referenced.add(m.group(1))
    missing = sorted(referenced - on_disk)
    for m in missing:
        print(f'        referenced but absent: assets/images/{m}')
    rep.warn(not missing,
             'every referenced image asset exists',
             f'{len(missing)} missing (all call sites must have an errorBuilder)')

    # Any Image.asset without an errorBuilder will throw at paint time if its
    # file is absent, which is how a missing memento.png took out a whole page.
    unguarded_risky = []
    unguarded_safe = []
    for path, text in sources.items():
        for m in re.finditer(r'Image\.asset\(\s*([^,\n]+)', text):
            window = text[m.start():m.start() + 500]
            if 'errorBuilder' in window:
                continue
            line_no = text[:m.start()].count('\n') + 1
            arg = m.group(1).strip()
            literal = re.fullmatch(r"'assets/images/([A-Za-z0-9_]+\.png)'", arg)
            where = f'{path}:{line_no} {arg}'
            if literal and literal.group(1) in on_disk:
                # Safe today, but only because the file happens to exist.
                unguarded_safe.append(where)
            else:
                # A path built at run time, or one pointing at a file that is
                # not there: this throws at paint time and takes the page down.
                unguarded_risky.append(where)
    for u in unguarded_risky:
        print(f'        UNGUARDED, path not statically known to exist: {u}')
    for u in unguarded_safe:
        print(f'        unguarded but file exists: {u}')
    rep.check(not unguarded_risky,
              'no Image.asset builds its path at run time without an '
              'errorBuilder',
              f'{len(unguarded_risky)} can throw at paint time')
    rep.warn(not unguarded_safe,
             'every Image.asset has an errorBuilder',
             f'{len(unguarded_safe)} rely on the file still being there')

    # ------------------------------------------------------ dataset hygiene
    rep.section('dataset id hygiene')
    for name, key in (('customers.json', 'id'), ('mementos.json', 'id'),
                      ('dishes.json', 'id'), ('letters.json', 'id'),
                      ('posters.json', 'id'), ('staff.json', 'id'),
                      ('movies.json', 'id'), ('fish.json', 'id'),
                      ('flowers.json', 'id')):
        rows = load(name)
        counts = collections.Counter(r[key] for r in rows)
        dupe = [i for i, n in counts.items() if n > 1]
        rep.check(not dupe, f'{name} has no duplicate ids', sample(dupe))

    # ------------------------------------- id-derived labels vs real names
    rep.section('labels derived from ids instead of looked up')
    # StaffDetailPage titleizes wearableMementos[].mementoId rather than
    # reading the memento's own name, so anything with punctuation is wrong.
    memento_names = {m['id']: m['name'] for m in load('mementos.json')}
    staff = load('staff.json')
    wearables = {w['mementoId'] for s in staff for w in s['wearableMementos']}
    wrong = sorted(
        m for m in wearables
        if m in memento_names and pretty_id(m) != memento_names[m]
    )
    rep.check(not wrong,
              f'titleizing a memento id reproduces its real name '
              f'({len(wearables)} staff wearables)',
              f"{len(wrong)} would read wrong, e.g. "
              f"{[(m, pretty_id(m), memento_names[m]) for m in wrong[:3]]}")

    # Same question for facilities, which several pages render by id.
    fac_names = facility_names_by_id()
    fac_wrong = [i for i, n in fac_names.items() if pretty_id(i) != n]
    rep.warn(not fac_wrong,
             f'titleizing a facility id reproduces its real name '
             f'({len(fac_names)} facilities)',
             f'{len(fac_wrong)} would read wrong — facility ids must be '
             f'resolved to names, never prettified')

    # ---------------------------------------------- id-vs-name slot naming
    rep.section('field names match their contents')
    dishes = load('dishes.json')
    dish_ids = {d['id'] for d in dishes}
    dish_names = {d['name'] for d in dishes}
    customers = load('customers.json')
    ordered = [x for c in customers for x in (c.get('dishesOrderedIds') or [])]
    rep.check(
        all(x in dish_ids for x in ordered),
        'customers[].dishesOrderedIds holds dish ids, as its name says',
        f'{sum(1 for x in ordered if x in dish_names)} of {len(ordered)} are '
        f'display names, not ids')

    # DishesRepository.byId now falls back id -> display name -> slugified
    # display name, because every one of these refs is a display name. This
    # mirrors that lookup; if the fallbacks are ever removed, this fails again.
    def _slug(raw):
        return re.sub(r'^_+|_+$', '', re.sub(r'[^a-z0-9]+', '_', raw.strip().lower()))

    dish_slugs = {_slug(n) for n in dish_names}
    recipes = [x for c in customers
               for x in (c.get('requirements') or {}).get('recipes', [])]
    unresolvable = [
        r for r in recipes
        if r.lower() not in dish_ids
        and r.lower() not in {n.lower() for n in dish_names}
        and _slug(r) not in dish_slugs
    ]
    rep.check(
        not unresolvable,
        'every customers[].requirements.recipes value resolves through '
        'DishesRepository.byId (id, then display name, then slug)',
        f'{len(unresolvable)} of {len(recipes)} dead-end at "Recipe not '
        f'found": {sample(set(unresolvable), 5)}')

    rep.finish()


if __name__ == '__main__':
    main()
