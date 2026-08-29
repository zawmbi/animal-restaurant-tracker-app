from workdir import W
import json, re, sys
from wiki_common import to_id, plain, find_templates
from wiki_bulk import get
from extract_mementos import page_mementos

R='/home/user/animal-restaurant-tracker-app/assets/data/'

SKIP = {'Anniversary Event','Booth Owner Appearance Rate','Christmas Event',
        'Doll Fragment Event','Halloween Event','Lunar New Year Event'}

CAT_TAG = {
    'Regulars':'regular', 'Seasonal':'regular', 'Flower Customer':'regular',
    'Event Customers':'event', 'Special Customers':'special',
    'Booth Owner':'booth_owner', 'Doll Figure Customers':'gachapon',
    'Performer':'performer', 'Terrace Customers':'terrace',
    'Halloween Customers':'halloween', 'Halloween':'halloween',
}

def links(v):
    """display names from wiki links, preserving order"""
    out=[]
    for tgt,lbl in re.findall(r'\[\[([^\]\|]+)(?:\|([^\]]+))?\]\]', v or ''):
        n = (lbl or tgt).strip()
        n = n.split('#')[-1].strip()
        if n and n not in out: out.append(n)
    return out

CATS_API={}

def build(title):
    txt = get(title) or ''
    if not txt.strip(): return None
    base = re.sub(r"\s*\(.*\)$","",title)
    cid = to_id(base)
    # description
    desc=''
    for tname in ('Customer','S2','Staff','Booth','Performer'):
        for p in find_templates(txt, tname):
            if p.get('description'):
                desc = plain(p['description']); break
        if desc: break
    if not desc:
        m=re.search(r"\|\s*description\s*=\s*(.+)", txt)
        if m: desc = plain(m.group(1))
    req = {}
    rs = find_templates(txt, 'Requirements')
    r = rs[0] if rs else {}

    lives = plain(r.get('Lives','')) or None
    if lives: lives = lives.strip() or None
    weight_raw = plain(r.get('Weight',''))
    wm = re.search(r'(\d[\d,]*)', weight_raw)
    weight = int(wm.group(1).replace(',','')) if wm else None

    foods = links(r.get('Food',''))
    dishes = links(r.get('Dishes',''))
    facs = [to_id(x) for x in links(r.get('Facilities',''))]
    flowers=[]
    for p in find_templates(r.get('Flowers',''), 'Flower'):
        pass
    fl = r.get('Flowers','')
    for m in re.findall(r'\{\{Flower\|([^}|]+)', fl):
        flowers.append(to_id(m))
    for x in links(fl):
        if to_id(x) not in flowers: flowers.append(to_id(x))
    letters = [to_id(x) for x in links(r.get('Letters',''))]
    picky = plain(r.get('Picky',''))
    pm = re.search(r'(\d[\d,]*)', picky)
    rating = int(pm.group(1).replace(',','')) if pm else None
    prereq = r.get('Prerequisite','')
    prereq_customers = []

    requirements = {}
    if rating is not None:
        requirements['rating'] = rating
        requirements['requiredStars'] = rating
    if foods: requirements['recipes'] = foods
    if facs: requirements['facilities'] = facs
    if letters: requirements['letters'] = letters
    if flowers: requirements['flowers'] = flowers

    # tags from categories on page
    cats = re.findall(r'\[\[Category:([^\]]+)\]\]', txt)
    cats = list(cats) + list(CATS_API.get(title, []))
    tags=['customer']
    for c in cats:
        t = CAT_TAG.get(c.strip())
        if t and t not in tags: tags.append(t)
    if 'regular' not in tags and 'Regulars' in cats: tags.append('regular')

    notes=[]
    if prereq:
        notes.append(plain(prereq))
    ability = plain(r.get('Ability','')).strip()
    full_desc = desc
    extra=[]
    if picky.strip():
        extra.append("Picky: Rating must reach %s." % picky.strip())
    if ability:
        extra.append("Ability — %s" % ability)
    for n in notes:
        if n: extra.append(n)
    if extra:
        full_desc = (desc + ' ' + ' '.join(extra)).strip()

    ent = {
        "id": cid,
        "name": base,
        "tags": tags,
        "customerDescription": full_desc,
        "requirements": requirements,
        "mementos": page_mementos(txt),
        "livesIn": lives,
        "appearanceWeight": weight,
        "requiredFoodId": foods[0] if foods else None,
        "dishesOrderedIds": dishes,
    }
    season = None
    for c in cats:
        cl=c.strip().lower()
        if cl in ('spring','summer','autumn','winter','halloween','christmas','lunar new year'):
            season = cl
    if season: ent['season']=season
    return ent

if __name__=='__main__':
    from wiki_categories import members
    for c in ["Customers","Performer","Booth Owner","Doll Figure Customers","Terrace Customers","Event Customers","Special Customers","Regulars","Flower Customer","Halloween Customers","Seasonal"]:
        for t in members(c):
            CATS_API.setdefault(t,set()).add(c)
    missing=[t for t in json.load(open(W('missing_customers.json'))) if t not in SKIP]
    out=[]
    for t in missing:
        e=build(t)
        if e is None:
            print("NO PAGE:", t); continue
        out.append(e)
    print("built", len(out))
    json.dump(out, open(W('new_customers.json'),'w'), ensure_ascii=False, indent=1)
