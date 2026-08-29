from workdir import W
import os
import json, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wiki_fetch import fetch

REPO='/home/user/animal-restaurant-tracker-app'

def to_id(name):
    s = name.lower().strip()
    s = re.sub(r"[‘’'`]", "", s)
    s = re.sub(r"[^a-z0-9\s\-&]", "", s)
    s = s.replace("&", " and ")
    s = re.sub(r"[\s\-]+", "_", s)
    return s.strip("_")

perf = json.load(open(W('perf.json')))
PERFORMERS = {m['title'] for m in perf['query']['categorymembers']}
PERFORMERS.discard('Performers')

txt = fetch('Template:Poster')
rows = txt.split('\n|-\n')
posters=[]
for row in rows:
    cells = [c.strip() for c in row.strip().split('\n|')]
    cells = [c for c in cells if c and c.strip() not in ('|-','-') and not c.startswith('!') and not c.startswith('{|') and not c.startswith('}')]
    cells = [c[1:].strip() if c.startswith('|') else c for c in cells]
    # a data row: first cell contains File: + bolded name
    if not cells or 'File:' not in cells[0]:
        continue
    if len(cells) < 4:
        print("SKIP short row:", cells[:1]); continue
    namecell, desc, req, earn = cells[0], cells[1], cells[2], cells[3]
    m = re.search(r"'''(.+?)'''", namecell)
    if not m:
        print("SKIP noname:", namecell[:80]); continue
    name = m.group(1).strip()
    desc = desc.strip()
    if desc.upper() == 'TBA':
        desc = ''
    em = re.search(r"([+-]?\d+)\s*%", earn)
    pct = int(em.group(1)) if em else 0

    lines = re.split(r'<br\s*/?>|\n', req)
    customers=[]; facilities=[]; notes=[]; performers=[]
    for line in lines:
        line = line.strip()
        if not line: continue
        links = re.findall(r'\[\[([^\]\|]+)(?:\|([^\]]+))?\]\]', line)
        plain = re.sub(r'\[\[([^\]\|]+)\|([^\]]+)\]\]', r'\2', line)
        plain = re.sub(r'\[\[([^\]]+)\]\]', r'\1', plain).strip()
        is_note = 'call back' in line.lower() or 'callback' in line.lower()
        for target, label in links:
            target = target.strip()
            disp = (label or target).strip()
            if target in PERFORMERS:
                pid = to_id(target)
                if pid not in performers: performers.append(pid)
                if pid not in customers: customers.append(pid)
            else:
                fid = to_id(disp if label else target)
                if fid not in facilities: facilities.append(fid)
        if is_note:
            notes.append(plain)
        elif not links:
            notes.append(plain)
    posters.append({
        "id": to_id(name),
        "name": name,
        "description": desc,
        "earningIncreasePercent": pct,
        "requiredPerformerIds": performers,
        "requirements": {"customers": customers, "facilities": facilities, "notes": notes},
    })

print("parsed", len(posters))
ids=[p['id'] for p in posters]
dupes=[i for i in set(ids) if ids.count(i)>1]
print("dupes", dupes)
json.dump(posters, open(W('posters_new.json'),'w'), indent=2, ensure_ascii=False)
