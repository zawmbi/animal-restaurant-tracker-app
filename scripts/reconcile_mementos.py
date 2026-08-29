import json, re
R='/home/user/animal-restaurant-tracker-app/assets/data/'
import scrape_mementos as B
cust=json.load(open(R+'customers.json'))
mem=json.load(open(R+'mementos.json'))
by={e['id']:e for e in mem}
fix_pn=0; conflicts=[]; rec=0
for c in cust:
    for m in c.get('mementos') or []:
        r=by.get(m['id'])
        if not r: continue
        for k in ('requirement','description'):
            if 'PAGENAME' in (m.get(k) or ''):
                m[k]=m[k].replace('PAGENAME', c['name']); fix_pn+=1
        if m.get('earnedStars') is not None and r.get('earnedStars')!=m['earnedStars']:
            conflicts.append((m['id'],'earnedStars','customer page',m['earnedStars'],'master list',r['earnedStars']))
            r['earnedStars']=m['earnedStars']
        if r.get('description') and r['description']!=m.get('description'):
            m['description']=r['description']
        pr=(m.get('requirement') or '').strip(); mr=(r.get('requirement') or '').strip()
        if pr!=mr:
            chosen = pr if (c['name'] in pr and c['name'] not in mr) else mr
            m['requirement']=chosen; r['requirement']=chosen; rec+=1
# re-derive structured requirements from the final requirement text
changed=0
for e in mem:
    if e.get('posterId'):
        if 'requirements' in e: del e['requirements']
        continue
    st,_,_ = B.parse_requirements(e['requirement'], e['name'])
    cid=e.get('customerId')
    if cid and 'customers' in st:
        st['customers']=[x for x in st['customers'] if x!=cid]
        if not st['customers']: st.pop('customers')
    if st!=e.get('requirements'):
        if st: e['requirements']=st
        elif 'requirements' in e: del e['requirements']
        changed+=1
json.dump(cust, open(R+'customers.json','w'), ensure_ascii=False, indent=2)
json.dump(mem, open(R+'mementos.json','w'), ensure_ascii=False, indent=2)
print('PAGENAME fixed:',fix_pn,'requirements reconciled:',rec,'structured re-derived:',changed)
for x in conflicts: print(' CONFLICT',x)
