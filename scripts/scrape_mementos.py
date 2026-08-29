from workdir import W
import json, re, collections
from wiki_common import to_id, plain

R='/home/user/animal-restaurant-tracker-app/assets/data/'
master=json.load(open(W('master_raw.json')))
cust=json.load(open(R+'customers.json'))
dishes=json.load(open(R+'dishes.json'))
posters=json.load(open(R+'posters.json'))
fac_index=json.load(open(W('facility_index.json')))

POSTER_NAMES={p['name'] for p in posters}
POSTER_ID={p['name']:p['id'] for p in posters}

cust_by_name={}
for c in cust:
    cust_by_name.setdefault(c['name'], c['id'])
    cust_by_name.setdefault(to_id(c['name']), c['id'])
cust_ids={c['id'] for c in cust}

dish_by_name={}
for d in dishes:
    dish_by_name.setdefault(d['name'], d)
dish_names_sorted=sorted(dish_by_name, key=len, reverse=True)

fac_by_name=dict(fac_index)

STAFF_NAME_TO_ID={'eggy':'eggy','jiji':'jiji','apricat':'apricat','dori':'dori','timmy':'timmy',
 'gumi':'chef_gumi','chef gumi':'chef_gumi','lucky':'lucky','prince':'prince','hedwig':'hedwig',
 'yolky':'yolky','ding':'ding','tate':'tate','kate':'kate','meow':'support_chef_meow',
 'support chef meow':'support_chef_meow','seedy':'seedy','paddy':'paddy'}

EVENT_RE = re.compile(r"((?:\d{4}\s+)?[A-Z][\w'’\-]*(?:\s+[A-Z][\w'’\-]*)*\s+Event(?:\s+\d{4})?)")

def source_of(name, req):
    low = req.lower()
    tags=[]
    def add(t):
        if t not in tags: tags.append(t)
    if name in POSTER_NAMES: add('poster')
    if low.startswith('serve '): add('customer_gift')
    if 'gachapon' in low: add('gachapon')
    if 'wishing well' in low: add('wishing_well')
    if 'signature store' in low: add('signature_store')
    if 'redemption code' in low: add('redemption_code')
    if 'mysterious bird nest' in low: add('mysterious_bird_nest')
    if 'wondrous coatroom' in low: add('wondrous_coatroom')
    if 'bottle spinning' in low or 'meal side cabinet' in low or 'spin bottle' in low: add('meal_side_cabinet')
    if 'diamond store' in low: add('diamond_store')
    if 'aromatic acorn' in low: add('aromatic_acorn_judging')
    if 'battle pass' in low: add('battle_pass')
    if 'blind box' in low: add('blind_box')
    if 'call back' in low or 'callback' in low: add('poster')
    if 'event' in low or 'card-playing mouse' in low: add('event')
    if '[shop]' in low or 'shop]' in low: add('shop')
    if 'creamy kingdom' in low or 'fantastical party' in low or 'slumberous nights' in low \
       or 'deep-sea ballad' in low or 'midsummer birdsong' in low: add('battle_pass')
    return tags

def event_of(req):
    m=EVENT_RE.search(req)
    return m.group(1).strip() if m else None

def parse_requirements(raw, name):
    """Return structured requirements dict + inferred flags."""
    txt = raw
    links=[ (t.split('#')[0].strip(), (l or t).split('#')[-1].strip())
            for t,l in re.findall(r'\[\[([^\]\|]+)(?:\|([^\]]+))?\]\]', txt) ]
    flat = plain(txt)

    out={}
    derived=[]
    stated=0; inferred=0

    customers=[]; recipes=[]; recipeIds=[]; facilities=[]; staff=[]; other=[]

    def add_customer(nm, is_stated):
        cid = cust_by_name.get(nm) or (to_id(nm) if to_id(nm) in cust_ids else None)
        if cid and cid not in customers:
            customers.append(cid)
            if not is_stated: derived.append('customer:'+cid)
            return True
        return False

    def add_dish(nm, is_stated):
        d = dish_by_name.get(nm)
        if d and d['name'] not in recipes:
            recipes.append(d['name']); recipeIds.append(d['id'])
            if not is_stated: derived.append('recipe:'+d['id'])
            return True
        return False

    def add_fac(nm, is_stated):
        fid = fac_by_name.get(nm)
        if fid and fid not in facilities:
            facilities.append(fid)
            if not is_stated: derived.append('facility:'+fid)
            return True
        return False

    for target, label in links:
        for nm in (label, target):
            if add_customer(nm, True): stated+=1; break
            if add_dish(nm, True): stated+=1; break
            if add_fac(nm, True): stated+=1; break
            if nm in POSTER_NAMES:
                pid=POSTER_ID[nm]
                out.setdefault('posters',[]).append(pid); stated+=1; break
        else:
            sid = STAFF_NAME_TO_ID.get(target.lower())
            if sid and sid not in staff:
                staff.append(sid); stated+=1

    # rating
    rm = re.search(r"Rating must reach\s*\{\{R\|\s*([\d,]+)", txt) or \
         re.search(r"Rating must reach\s*([\d,]+)", flat)
    if rm:
        out['rating']=int(rm.group(1).replace(',',''))
        out['requiredStars']=out['rating']

    # serve counts -- "Serve X 350 times." (X may be a link or plain text)
    serve=[]
    for m in re.finditer(r"Serve\s+(.+?)\s+([\d,]+)\s+times", flat):
        who=m.group(1).strip().strip('.')
        cnt=int(m.group(2).replace(',',''))
        cid=cust_by_name.get(who) or (to_id(who) if to_id(who) in cust_ids else None)
        was_linked = any(who in (t,l) for t,l in links)
        if cid:
            if cid not in customers:
                customers.append(cid)
                if not was_linked: derived.append('customer:'+cid); inferred+=1
            serve.append({"customerId":cid,"count":cnt})
        else:
            other.append(m.group(0).strip())
    if serve: out['serve']=serve
    for m in re.finditer(r"Serve\s+(.+?)\s+to get", flat):
        who=m.group(1).strip()
        cid=cust_by_name.get(who)
        if cid and cid not in customers: customers.append(cid)

    # sell counts -- "Sell X 2000 times." or "Sell 2000 X."
    sell=[]
    for m in re.finditer(r"Sell\s+(.+?)\s+([\d,]+)\s+times", flat):
        nm=m.group(1).strip(); cnt=int(m.group(2).replace(',',''))
        d=dish_by_name.get(nm)
        was_linked = any(nm in (t,l) for t,l in links)
        if d:
            sell.append({"recipeId":d['id'],"name":d['name'],"count":cnt})
            if d['name'] not in recipes:
                recipes.append(d['name']); recipeIds.append(d['id'])
                if not was_linked: derived.append('recipe:'+d['id']); inferred+=1
        else:
            other.append(m.group(0).strip())
    for m in re.finditer(r"Sell\s+([\d,]+)\s+([A-Z][\w'’\- ]+?)\.", flat):
        cnt=int(m.group(1).replace(',','')); nm=m.group(2).strip()
        d=dish_by_name.get(nm)
        if d and not any(s['recipeId']==d['id'] for s in sell):
            sell.append({"recipeId":d['id'],"name":d['name'],"count":cnt})
            if d['name'] not in recipes:
                recipes.append(d['name']); recipeIds.append(d['id'])
                derived.append('recipe:'+d['id']); inferred+=1
    if sell: out['sell']=sell

    # unlinked dish/customer names mentioned in plain text (inference)
    if not links:
        for nm in dish_names_sorted:
            if len(nm)>4 and re.search(r'\b'+re.escape(nm)+r'\b', flat):
                if add_dish(nm, False): inferred+=1
                break

    if customers: out['customers']=customers
    if recipes:
        out['recipes']=recipes; out['recipeIds']=recipeIds
    if facilities: out['facilities']=facilities
    if staff: out['staff']=staff
    # leftover free text: only lines from which nothing structured was extracted
    consumed=set()
    for ln in flat.split('\n'):
        l=ln.strip()
        if not l: continue
        if re.match(r'^Serve\s', l) or re.match(r'^Sell\s', l) or l.startswith('Rating must reach'):
            consumed.add(l); continue
        for nm in customers:
            pass
        hit=False
        for tgt,lbl in links:
            for nm in (lbl,tgt):
                if nm and nm in l and (
                    cust_by_name.get(nm) in customers or
                    (dish_by_name.get(nm) and dish_by_name[nm]['name'] in recipes) or
                    fac_by_name.get(nm) in facilities):
                    hit=True; break
            if hit: break
        if hit: consumed.add(l)
    rest=[l.strip() for l in flat.split('\n') if l.strip() and l.strip() not in consumed]
    if rest: out['other']=rest
    # every entity relationship here is derived from the requirement prose --
    # the wiki states the entity (as a link) but never labels the relationship type.
    for c in customers: derived.append('customer:'+c)
    for s_ in out.get('serve',[]): derived.append('customer:'+s_['customerId'])
    for rid in recipeIds: derived.append('recipe:'+rid)
    for f in facilities: derived.append('facility:'+f)
    for st_ in staff: derived.append('staff:'+st_)
    if derived:
        out['inferred']=True
        out['derivedLinks']=sorted(set(derived))
    return out, stated, len(set(derived))

if __name__ == '__main__':
    # ---------------- build ----------------
    owner={}
    for c in cust:
        for m in c.get('mementos') or []:
            owner.setdefault(m['name'], c['id'])
    page_owner=set()
    for t,ms in json.load(open(W('page_mementos.json'))).items():
        for m in ms: page_owner.add(m['name'])

    out=[]; seen=collections.Counter()
    staff_wear=collections.defaultdict(list)
    tot_stated=0; tot_inferred=0
    for o in master:
        name=o['name']; mid=to_id(name)
        seen[mid]+=1
        if seen[mid]>1: mid='%s_%d'%(mid,seen[mid])
        bm=re.search(r"([+-]?\d[\d,]*)", plain(o['bonus']))
        stars=int(bm.group(1).replace(',','')) if bm else 0
        desc=plain(o['desc']); desc='' if desc.upper()=='TBA' else desc
        req=plain(o['req_raw']); req='' if req.upper()=='TBA' else req
        eq_raw=o['equips_raw'].strip()
        share=None; equips=[]; eqnote=None
        sm=re.search(r"Share reward:\s*([\d,]+)", plain(eq_raw))
        if sm: share=int(sm.group(1).replace(',',''))
        elif eq_raw and eq_raw!='-':
            nms=[(l or t).strip() for t,l in re.findall(r'\[\[([^\]\|]+)(?:\|([^\]]+))?\]\]', eq_raw)]
            residue=re.sub(r'\[\[[^\]]*\]\]','',eq_raw)
            residue=re.sub(r'[\s,]|and','',residue,flags=re.I).strip()
            if nms and not residue:
                for n in nms:
                    sid=STAFF_NAME_TO_ID.get(n.lower())
                    if sid:
                        equips.append(sid)
                        staff_wear[sid].append({'mementoId':mid,'earnedStars':stars,'requirements':req})
                    else: equips.append(to_id(n))
            else: eqnote=plain(eq_raw)
        tags=source_of(name, req)
        e={'id':mid,'name':name}
        cid=owner.get(name)
        if cid:
            e['customerId']=cid
            if name not in page_owner: e['customerIdInferred']=True
        e['earnedStars']=stars; e['description']=desc; e['requirement']=req
        structured, st, inf = parse_requirements(o['req_raw'], name)
        if cid and 'customers' in structured:
            structured['customers']=[x for x in structured['customers'] if x!=cid]
            if not structured['customers']: structured.pop('customers')
        if name in POSTER_NAMES:
            e['posterId']=POSTER_ID[name]
            structured={}   # posters.json is canonical for poster unlock requirements
        tot_stated+=st; tot_inferred+=inf
        if structured: e['requirements']=structured
        if tags: e['tags']=tags; e['source']=tags[0]
        ev=event_of(req)
        if ev and 'event' in tags: e['event']=ev
        if equips: e['equips']=equips
        if share is not None: e['shareReward']=share
        if '✔' in o['hidden_raw']: e['hidden']=True
        if eqnote: e['equipsNote']=eqnote
        out.append(e)

    json.dump(out, open(R+'mementos.json','w'), ensure_ascii=False, indent=2)
    json.dump({k:v for k,v in staff_wear.items()}, open(W('staff_wear.json'),'w'), ensure_ascii=False, indent=1)
    print('mementos:',len(out))
    print('source dist:', collections.Counter(e.get('source') for e in out))
    print('with structured requirements:', sum(1 for e in out if 'requirements' in e))
    print('stated entity links:',tot_stated,' inferred entity links:',tot_inferred)
    print('with customerId:', sum(1 for e in out if 'customerId' in e))
