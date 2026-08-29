import sys, json, urllib.parse, subprocess, os, time
from workdir import W
CACHE = W("wcache")
os.makedirs(CACHE, exist_ok=True)
def fetch(title):
    key = urllib.parse.quote(title, safe="") .replace('%','_')[:180]
    p = os.path.join(CACHE, key + ".txt")
    if os.path.exists(p):
        return open(p, encoding='utf-8').read()
    url = "https://animalrestaurant.fandom.com/api.php?action=parse&page=%s&prop=wikitext&format=json&redirects=1" % urllib.parse.quote(title, safe="")
    out = subprocess.run(["curl","-s",url],capture_output=True,text=True).stdout
    try:
        d = json.loads(out)
        txt = d["parse"]["wikitext"]["*"]
    except Exception as e:
        txt = "__ERROR__ " + out[:300]
    open(p,"w",encoding='utf-8').write(txt)
    time.sleep(0.35)
    return txt
if __name__ == "__main__":
    for t in sys.argv[1:]:
        print("="*20, t)
        print(fetch(t))
