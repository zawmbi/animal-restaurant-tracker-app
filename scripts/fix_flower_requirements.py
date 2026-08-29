#!/usr/bin/env python3
"""Move flower ids out of customers' requirements.facilities.

Flowers are grown in the Vegetable Garden, not bought as facilities, and no
flower id exists in any facilities shard. Leaving them in
requirements.facilities made the customer page render them as facility chips
that navigate to a FacilityDetailPage which cannot resolve -- the "false
facility" bug.

Also normalises three aliases that requirements.flowers used but flowers.json
never defined.
"""
import json

ALIASES = {'rose': 'red_rose', 'wrose': 'white_rose', 'mleaf': 'maple_leaf'}

flowers = {f['id'] for f in json.load(open('assets/data/flowers.json'))}
cust = json.load(open('assets/data/customers.json'))

moved = aliased = 0
touched = set()
for c in cust:
    r = c.get('requirements')
    if not r:
        continue

    fl = [ALIASES.get(x, x) for x in (r.get('flowers') or [])]
    aliased += sum(1 for x in (r.get('flowers') or []) if x in ALIASES)

    fac = r.get('facilities') or []
    keep = [x for x in fac if x not in flowers]
    leaked = [x for x in fac if x in flowers]
    if leaked:
        moved += len(leaked)
        touched.add(c['id'])
        fl.extend(leaked)

    fl = sorted(set(fl))
    unknown = [x for x in fl if x not in flowers]
    assert not unknown, f"{c['id']}: unknown flower {unknown}"

    if fl:
        r['flowers'] = fl
    elif 'flowers' in r:
        del r['flowers']

    if keep:
        r['facilities'] = keep
    elif 'facilities' in r:
        del r['facilities']

json.dump(cust, open('assets/data/customers.json', 'w'), indent=2, ensure_ascii=False)
print(f'flower ids moved out of requirements.facilities: {moved}')
print(f'aliases normalised (rose/wrose/mleaf): {aliased}')
print(f'customers touched: {len(touched)}')
