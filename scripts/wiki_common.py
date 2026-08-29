import re, json
def to_id(name):
    s = name.lower().strip()
    s = re.sub(r"[‘’'`’,]", "", s)
    s = re.sub(r"[^a-z0-9\s\-&]", " ", s)
    s = s.replace("&", " and ")
    s = re.sub(r"[\s\-]+", "_", s)
    return s.strip("_")

def plain(t):
    """wikitext -> plain text"""
    s = t
    s = re.sub(r"\[\[File:[^\]]*\]\]", "", s)
    s = re.sub(r"<br\s*/?>", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    # templates like {{R|+5}} {{Cod|5,000}} {{Film|300}}
    def tmpl(m):
        parts = m.group(1).split("|")
        nm = parts[0].strip()
        rest = [p.strip() for p in parts[1:] if "=" not in p]
        if not rest:
            return nm
        return rest[-1]
    for _ in range(4):
        s2 = re.sub(r"\{\{([^{}]*)\}\}", tmpl, s)
        if s2 == s: break
        s = s2
    s = re.sub(r"\[\[([^\]\|]+)\|([^\]]+)\]\]", r"\2", s)
    s = re.sub(r"\[\[([^\]]+)\]\]", r"\1", s)
    s = s.replace("'''", "").replace("''", "")
    s = re.sub(r"[ \t]+", " ", s)
    s = "\n".join(l.strip() for l in s.split("\n"))
    return s.strip()

def find_templates(text, name):
    """Yield (params_dict) for each {{name|...}} template (top-level, nested-aware)."""
    out=[]
    i=0
    n=len(text)
    target=name.lower()
    while True:
        j=text.find("{{", i)
        if j<0: break
        # find matching close
        depth=0; k=j
        while k < n-1:
            if text[k:k+2]=="{{": depth+=1; k+=2; continue
            if text[k:k+2]=="}}":
                depth-=1; k+=2
                if depth==0: break
                continue
            k+=1
        body=text[j+2:k-2]
        head=body.split("|",1)[0].strip().lower()
        if head==target:
            out.append(_params(body))
            i=k
        else:
            i=j+2
    return out

def _params(body):
    parts=[]; depth=0; cur=""
    i=0
    while i < len(body):
        c=body[i]
        two=body[i:i+2]
        if two in ("{{","[["):
            depth+=1; cur+=two; i+=2; continue
        if two in ("}}","]]"):
            depth-=1; cur+=two; i+=2; continue
        if c=="|" and depth==0:
            parts.append(cur); cur=""; i+=1; continue
        cur+=c; i+=1
    parts.append(cur)
    d={}
    for p in parts[1:]:
        if "=" in p:
            k,v=p.split("=",1)
            d[k.strip()]=v.strip()
    return d
