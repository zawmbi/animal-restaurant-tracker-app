import json, subprocess, urllib.parse, os, time, sys
from workdir import W
CACHE=W('pages'); os.makedirs(CACHE,exist_ok=True)
def path(t): return os.path.join(CACHE, urllib.parse.quote(t,safe='').replace('%','_')[:180]+'.txt')
def have(t): return os.path.exists(path(t))
def get(t):
    p=path(t)
    return open(p,encoding='utf-8').read() if os.path.exists(p) else None
def fetch_many(titles):
    todo=[t for t in titles if not have(t)]
    for i in range(0,len(todo),40):
        chunk=todo[i:i+40]
        url=("https://animalrestaurant.fandom.com/api.php?action=query&prop=revisions&rvprop=content&rvslots=main&format=json&formatversion=2&titles="
             + urllib.parse.quote("|".join(chunk)))
        r=subprocess.run(["curl","-s","--max-time","60",url],capture_output=True,text=True).stdout
        try:
            d=json.loads(r)
        except Exception as e:
            print("ERR json", chunk[:2], r[:200]); continue
        got=set()
        for pg in d.get('query',{}).get('pages',[]):
            title=pg.get('title')
            if pg.get('missing'):
                open(path(title),'w').write(''); got.add(title); continue
            try:
                c=pg['revisions'][0]['slots']['main']['content']
            except Exception:
                c=''
            open(path(title),'w',encoding='utf-8').write(c); got.add(title)
        # normalized titles
        for n in d.get('query',{}).get('normalized',[]):
            if n['to'] in got and not have(n['from']):
                open(path(n['from']),'w',encoding='utf-8').write(get(n['to']) or '')
        sys.stdout.write('.'); sys.stdout.flush()
        time.sleep(0.3)
    print()
