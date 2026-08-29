import json, glob, os, collections, sys
R = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'data') + os.sep

def _facility_index():
    idx = {}
    for f in glob.glob(R + 'facilities_jsons/*.json') + [R + 'facilities.json']:
        d = json.load(open(f))
        def walk(o):
            if isinstance(o, dict):
                if isinstance(o.get('id'), str) and isinstance(o.get('name'), str):
                    idx[o['name']] = o['id']
                for v in o.values(): walk(v)
            elif isinstance(o, list):
                for v in o: walk(v)
        walk(d)
    return idx
ok=True
files=sorted(glob.glob(R+'*.json')+glob.glob(R+'*/*.json'))
for f in files:
    try: json.load(open(f))
    except Exception as e: print('INVALID JSON', f, e); ok=False
print('parsed %d json files'%len(files))

cust=json.load(open(R+'customers.json'))
mem=json.load(open(R+'mementos.json'))
dishes=json.load(open(R+'dishes.json'))
posters=json.load(open(R+'posters.json'))
staff=json.load(open(R+'staff.json'))
cids={c['id'] for c in cust}; mids={m['id'] for m in mem}
dids={d['id'] for d in dishes}; pids={p['id'] for p in posters}; sids={s['id'] for s in staff}
fac=_facility_index(); fids=set(fac.values())
flowers={x['id'] for x in json.load(open(R+'flowers.json'))}

prob=collections.Counter(); samples=collections.defaultdict(list)
def chk(cond, key, val):
    if not cond:
        prob[key]+=1
        if len(samples[key])<6: samples[key].append(val)

for m in mem:
    if 'customerId' in m: chk(m['customerId'] in cids,'memento.customerId',m['customerId'])
    if 'posterId' in m: chk(m['posterId'] in pids,'memento.posterId',m['posterId'])
    for e in m.get('equips',[]):
        pass
    r=m.get('requirements') or {}
    for c in r.get('customers',[]): chk(c in cids,'memento.req.customers',c)
    for d in r.get('recipeIds',[]): chk(d in dids,'memento.req.recipeIds',d)
    for f in r.get('facilities',[]): chk(f in fids,'memento.req.facilities',f)
    for s in r.get('staff',[]): chk(s in sids,'memento.req.staff',s)
    for s in r.get('serve',[]): chk(s['customerId'] in cids,'memento.req.serve',s['customerId'])
    for s in r.get('sell',[]): chk(s['recipeId'] in dids,'memento.req.sell',s['recipeId'])
for p in posters:
    for c in p['requiredPerformerIds']: chk(c in cids,'poster.performer',c)
    for c in p['requirements']['customers']: chk(c in cids,'poster.req.customers',c)
    for f in p['requirements']['facilities']: chk(f in fids,'poster.req.facilities',f)
dnames={d['name'] for d in dishes}
for c in cust:
    for m in c.get('mementos') or []: chk(m['id'] in mids,'customer.memento',m['id'])
    r=c.get('requirements') or {}
    for x in r.get('recipes',[]): chk(x in dnames,'customer.req.recipes',x)
    for x in c.get('dishesOrderedIds',[]): chk(x in dnames,'customer.dishesOrdered',x)
    # Flowers are NOT facilities: accepting them here let 84 flower ids sit in
    # requirements.facilities and render as facility chips linking to a
    # FacilityDetailPage that cannot resolve them.
    for x in r.get('facilities',[]): chk(x in fids,'customer.req.facilities',x)
    for x in r.get('flowers',[]): chk(x in flowers,'customer.req.flowers',x)
    for x in r.get('customers',[]): chk(x in cids,'customer.req.customers',x)
for s in staff:
    for w in s['wearableMementos']: chk(w['mementoId'] in mids,'staff.wearable',w['mementoId'])
print('--- dangling reference report ---')
for k,v in prob.items(): print(' ',k,v,samples[k])
if not prob: print('  none')

# --- memento registry invariants -------------------------------------
emb=[(c['id'],m['id']) for c in cust for m in (c.get('mementos') or [])]
own=collections.defaultdict(set)
for c_,m_ in emb: own[m_].add(c_)
reg={m['id']:m for m in mem}
print('--- memento registry invariants ---')
print('  embedded mementos:', len(emb))
print('  embedded ids subset of mementos.json:', all(m_ in reg for _,m_ in emb))
print('  customerId matches on all embedded:', all(reg[m_].get('customerId')==c_ for c_,m_ in emb))
print('  no memento id on more than one customer:', all(len(v)==1 for v in own.values()))
print('  duplicate ids in mementos.json:', [k for k,v in collections.Counter(m['id'] for m in mem).items() if v>1])

# --- CI gate ---------------------------------------------------------
# Known-dangling references that are accepted for now. Anything outside
# this allow-list fails the run so a bad scrape cannot land silently.
# Shrink this dict as the underlying data gets fixed; never grow it to
# make a run pass.
KNOWN_DANGLING = {
    # Facilities the wiki references but has no page for yet.
    'customer.req.facilities': {'star_rating_board', 'halloween_decorations'},
    # Legacy staff wearable aliases kept so old saves still resolve.
    'staff.wearable': {
        'sunflower_memento', 'witch_hat', 'crab_memento', 'sleepy_little_bear',
    },
}

_failures = []
for _k, _v in samples.items():
    _unexpected = set(_v) - KNOWN_DANGLING.get(_k, set())
    if _unexpected:
        _failures.append((_k, sorted(_unexpected)))

_invariants = [
    ('embedded ids subset of registry', all(m_ in reg for _, m_ in emb)),
    ('customerId matches on all embedded',
     all(reg[m_].get('customerId') == c_ for c_, m_ in emb)),
    ('no memento id on more than one customer',
     all(len(v) == 1 for v in own.values())),
    ('no duplicate ids in mementos.json',
     not [k for k, v in collections.Counter(m['id'] for m in mem).items()
          if v > 1]),
]
_broken = [name for name, ok in _invariants if not ok]

print('--- ci gate ---')
if _failures or _broken:
    for _k, _v in _failures:
        print(f'  FAIL unexpected dangling {_k}: {_v}')
    for _name in _broken:
        print(f'  FAIL invariant broken: {_name}')
    sys.exit(1)
print('  ok')
