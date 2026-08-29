import json,subprocess,urllib.parse,os,time,sys
from workdir import W
CACHE=W('catcache'); os.makedirs(CACHE,exist_ok=True)
def members(cat, ns=None):
    fn=os.path.join(CACHE, cat.replace('/','_').replace(' ','_')+('' if ns is None else '_ns%s'%ns)+'.json')
    if os.path.exists(fn): return json.load(open(fn))
    out=[]; cont=None
    while True:
        url="https://animalrestaurant.fandom.com/api.php?action=query&list=categorymembers&cmtitle=Category:%s&cmlimit=500&format=json"%urllib.parse.quote(cat)
        if ns is not None: url+="&cmnamespace=%d"%ns
        if cont: url+="&cmcontinue="+urllib.parse.quote(cont)
        d=json.loads(subprocess.run(["curl","-s",url],capture_output=True,text=True).stdout)
        out+= [m['title'] for m in d.get('query',{}).get('categorymembers',[])]
        cont=d.get('continue',{}).get('cmcontinue')
        time.sleep(0.3)
        if not cont: break
    json.dump(out,open(fn,'w'))
    return out
if __name__=='__main__':
    for c in sys.argv[1:]:
        m=members(c); print(c, len(m))
