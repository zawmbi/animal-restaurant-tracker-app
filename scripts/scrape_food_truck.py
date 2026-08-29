import re, json
from wiki_common import to_id, plain
from wiki_fetch import fetch
R='/home/user/animal-restaurant-tracker-app/assets/data/'
t=fetch('Template:Food Truck')
rows=re.split(r"\n\|-\n", t)
out=[]
for row in rows[1:]:
    cells=[c for c in row.split("\n|") if c.strip()]
    cells=[c for c in cells if not c.startswith('}')]
    if not cells or 'File:' not in cells[0] or len(cells)<7: continue
    nm=re.search(r"'''(.+?)'''", cells[0])
    if not nm: continue
    name=plain(nm.group(1))
    desc=plain(cells[1]); desc='' if desc.upper()=='TBA' else desc
    rm=re.search(r'(\d[\d,]*)', plain(cells[2])); rating=int(rm.group(1).replace(',','')) if rm else None
    ings=[]
    for line in plain(cells[3]).split('\n'):
        line=line.strip()
        if not line: continue
        m=re.match(r'(.+?)\s*\((\d+|TBA)\)$', line)
        if m:
            amt=m.group(2)
            ings.append({"item":m.group(1).strip(),
                         "amount":None if amt=='TBA' else int(amt),
                         **({"tba":True} if amt=='TBA' else {})})
        else:
            ings.append({"item":line,"amount":None,"tba":True})
    pm=re.search(r'(\d+)', plain(cells[4])); perfect=int(pm.group(1)) if pm else None
    tm=re.search(r'(\d+)\s*s', plain(cells[5])); prep=int(tm.group(1)) if tm else None
    flavor=plain(cells[6]).replace('⬤','').strip()
    out.append({"id":to_id(name),"name":name,"sections":["Food Truck Recipes"],
        "description":desc,"refinedRating":rating,"perfectDishes":perfect,
        "prepTimeSeconds":prep,"flavor":flavor,"refinementRatingReward":rating,
        "ingredients":ings})
print('parsed',len(out))
old=json.load(open(R+'food_truck_recipes.json'))
oi={x['id']:x for x in old}
print('old',len(old))
print('lost ids:',[i for i in oi if i not in {x['id'] for x in out}])
print('new ids:',[x['id'] for x in out if x['id'] not in oi])
json.dump(out, open(R+'food_truck_recipes.json','w'), ensure_ascii=False, indent=2)
