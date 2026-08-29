from workdir import W
import re, json, os, glob, urllib.parse
from wiki_common import to_id, plain, find_templates
from wiki_bulk import get, path

def page_mementos(text):
    out=[]
    for params in find_templates(text, 'Memento'):
        idxs=set()
        for k in params:
            m=re.match(r'^Name(\d*)$', k)
            if m: idxs.add(m.group(1))
        for suf in sorted(idxs, key=lambda s: int(s) if s else 0):
            name = plain(params.get('Name'+suf,''))
            if not name or name.upper()=='TBA': continue
            rating = params.get('Rating'+suf,'')
            rm = re.search(r'(\d[\d,]*)', plain(rating))
            stars = int(rm.group(1).replace(',','')) if rm else 0
            desc = plain(params.get('Description'+suf,''))
            if desc.upper()=='TBA': desc=''
            req = plain(params.get('Requirement'+suf,''))
            if req.upper()=='TBA': req=''
            out.append({"id":to_id(name),"name":name,"earnedStars":stars,
                        "description":desc,"requirement":req})
    return out

if __name__=='__main__':
    tot=0; pages=0
    res={}
    for f in glob.glob(W('pages') + '/*.txt'):
        title=urllib.parse.unquote(os.path.basename(f)[:-4].replace('_','%'))
        t=open(f,encoding='utf-8').read()
        ms=page_mementos(t)
        if ms:
            res[title]=ms; tot+=len(ms); pages+=1
    print("pages with mementos:",pages,"total mementos:",tot)
    json.dump(res, open(W('page_mementos.json'),'w'), ensure_ascii=False, indent=1)
