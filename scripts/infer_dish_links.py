from workdir import W
import json, re, collections
from wiki_common import to_id, plain, find_templates
from wiki_bulk import get
from wiki_categories import members

R='/home/user/animal-restaurant-tracker-app/assets/data/'
cust=json.load(open(R+'customers.json'))
dishes=json.load(open(R+'dishes.json'))
by_cid={c['id']:c for c in cust}
cust_by_name={}
for c in cust:
    cust_by_name.setdefault(c['name'], c['id'])
dish_by_name={d['name']:d for d in dishes}

def linknames(v):
    out=[]
    for t,l in re.findall(r'\[\[([^\]\|]+)(?:\|([^\]]+))?\]\]', v or ''):
        n=(l or t).split('#')[-1].strip()
        if n and n not in out: out.append(n)
    return out

stats=collections.Counter()
added_req=collections.defaultdict(list)   # cid -> [dish display names]
added_ord=collections.defaultdict(list)
for title in [x for x in members('Recipes') if ':' not in x]:
    txt=get(title) or ''
    if not txt.strip(): continue
    name=re.sub(r"\s*\(.*\)$","",title); name=re.sub(r"\s+Recipe$","",name)
    d=dish_by_name.get(name)
    if not d: stats['dish_unresolved']+=1; continue
    ts=find_templates(txt,'Food') or find_templates(txt,'BuffetFood') or find_templates(txt,'TakeoutFood')
    if not ts: continue
    p=ts[0]
    for field, bucket in (('for',added_req), ('orders',added_ord)):
        for cn in linknames(p.get(field,'')):
            cid=cust_by_name.get(cn) or (to_id(cn) if to_id(cn) in by_cid else None)
            if not cid: stats['customer_unresolved']+=1; continue
            c=by_cid[cid]
            if field=='for':
                cur=(c.get('requirements') or {}).get('recipes') or []
                if d['name'] not in cur:
                    bucket[cid].append(d['name']); stats['req_inferred']+=1
                else: stats['req_already']+=1
            else:
                cur=c.get('dishesOrderedIds') or []
                if d['name'] not in cur:
                    bucket[cid].append(d['name']); stats['ord_inferred']+=1
                else: stats['ord_already']+=1
print(stats)
json.dump({'requirements_recipes':added_req,'dishes_ordered':added_ord},
          open(W('inferred_dish_links.json'),'w'), ensure_ascii=False, indent=1)
print('customers gaining required recipes:', len(added_req))
print('customers gaining ordered dishes:', len(added_ord))
