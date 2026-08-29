import json, re
from wiki_common import to_id, plain, find_templates
from wiki_bulk import get
R='/home/user/animal-restaurant-tracker-app/assets/data/'
CUR={'cod':'cod','plates':'plates','bells':'bells','film':'film','diamond':'diamonds','diamonds':'diamonds'}

def money(v):
    out=[]
    for m in re.finditer(r"\{\{(Cod|Plates|Bells|Film|Diamond|Diamonds)\|\s*\+?([\d,]+)", v or '', re.I):
        out.append({"currency":CUR[m.group(1).lower()],"amount":int(m.group(2).replace(',',''))})
    return out

def firstnum(v, tmpl):
    m=re.search(r"\{\{%s\|\s*\+?([\d,]+)"%tmpl, v or '', re.I)
    return int(m.group(1).replace(',','')) if m else 0

def other_links(v):
    out=[]
    for t,l in re.findall(r'\[\[([^\]\|]+)(?:\|([^\]]+))?\]\]', v or ''):
        n=(l or t).split('#')[-1].strip()
        if n and n not in out: out.append(n)
    return out

OVERRIDE_ID={'Candied Hawthorn Recipe':None,'Cola (Takeout Recipe)':None,
             'Yogurt Drink (Buffet Recipe)':'yogurt_drink_buffet'}

def build(title):
    txt=get(title) or ''
    if not txt.strip(): return None
    name=re.sub(r"\s*\(.*\)$","",title)
    name=re.sub(r"\s+Recipe$","",name)
    did=OVERRIDE_ID.get(title, to_id(name))
    if did is None: return None
    f=find_templates(txt,'Food'); b=find_templates(txt,'BuffetFood'); tk=find_templates(txt,'TakeoutFood')
    if f:
        p=f[0]
        ct=re.search(r'(\d+)', plain(p.get('cooking_time','')))
        e={"id":did,"name":name,"sections":["Freshly Made"],
           "description":plain(p.get('description','')),
           "timeSeconds":int(ct.group(1)) if ct else 0,
           "earningsMax":firstnum(p.get('earning(s)',''),'Cod'),
           "requiredStars":firstnum(p.get('prerequisite(s)',''),'R'),
           "price":money(p.get('price(s)',''))}
        reqs=other_links(p.get('prerequisite(s)',''))
        if reqs: e["requirements"]=reqs
        return e
    if b:
        p=b[0]
        e={"id":did,"name":name,"sections":["Buffet"],
           "description":plain(p.get('description','')),
           "earningsPerHour":firstnum(p.get('earning',''),'Cod'),
           "requiredStars":firstnum(p.get('requirement',''),'R'),
           "price":money(p.get('cost',''))}
        reqs=other_links(p.get('requirement',''))
        if reqs: e["requirements"]=reqs
        return e
    if tk:
        p=tk[0]
        inc=plain(p.get('income5') or p.get('income1') or '')
        m=re.search(r'\+?([\d,]+)\s*~\s*([\d,]+)', inc)
        e={"id":did,"name":name,"sections":["Takeout"],
           "description":plain(p.get('description','')),
           "earningsRange":{"min":int(m.group(1).replace(',','')),"max":int(m.group(2).replace(',',''))} if m else None,
           "requiredStars":firstnum(p.get('req1',''),'R'),
           "requirementsLikes":firstnum(p.get('req1',''),'Likes'),
           "price":[]}
        reqs=other_links(p.get('req1',''))
        if reqs: e["requirements"]=reqs
        tiers=[]
        for lvl,tier in ((2,'C'),(3,'B'),(4,'A'),(5,'S')):
            r=p.get('req%d'%lvl,''); c=p.get('cost%d'%lvl,'')
            if not (r or c): continue
            tiers.append({"tier":tier,"requiredStars":firstnum(r,'R'),
                          "requirementsLikes":firstnum(r,'Likes'),"price":money(c)})
        if tiers: e["tiers"]=tiers
        return e
    return None

if __name__=='__main__':
    titles=['Buttery Apple','Candied Hawthorn Recipe','Cloud Cake','Cola (Takeout Recipe)','Corn Ice Cream','Crabmeat Sushi','Durian Sushi','Grape Ramune','Matcha','Peach Blossom Sliced Fish','Pomelo','Popping Candy','Snowman Lava Toast','Steamed Garlic Shrimp with Vermicelli','Sweet Sticky Rice in Lotus Root with Osmanthus Syrup','Two-colored Macaron','Yogurt Drink (Buffet Recipe)']
    d=json.load(open(R+'dishes.json'))
    have={x['id'] for x in d}
    added=[]
    for t in titles:
        e=build(t)
        if not e: print('skip',t); continue
        if e['id'] in have: print('dup, skipping',e['id']); continue
        d.append(e); have.add(e['id']); added.append(e['id'])
    # fix teddy_biscuit tier prices (app had 10x-low C/B/A)
    for x in d:
        if x['id']=='teddy_biscuit':
            for tr,amt in zip(x['tiers'],[10000,100000,300000,1000000]):
                tr['price']=[{"currency":"cod","amount":amt}]
    json.dump(d, open(R+'dishes.json','w'), ensure_ascii=False, indent=2)
    print('added %d dishes:'%len(added), added, ' total', len(d))
