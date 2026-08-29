from workdir import W
import re, json
from wiki_common import to_id, plain
from wiki_fetch import fetch
txt=fetch('Open Air Cinema')
sec=txt[txt.index('==Movies=='):]
# split on === headers
parts=re.split(r"\n===\s*([^=]+?)\s*===\n", sec)
movies=[]
CUR={'plates':'plates','film':'film','diamond':'diamonds','diamonds':'diamonds','cod':'cod','bell':'bells','bells':'bells'}
for i in range(1,len(parts),2):
    title=plain(parts[i]).strip()
    body=parts[i+1]
    rm=re.search(r"Reward:\s*\{\{(\w+)\|([\d,]+)\}\}", body)
    if not rm:
        rm2=re.search(r"Reward:\s*\{\{(\w+)\|?\}\}", body)
        cur = CUR.get(rm2.group(1).lower(),rm2.group(1).lower()) if rm2 else None
        amt = 0
    else:
        cur=CUR.get(rm.group(1).lower(), rm.group(1).lower()); amt=int(rm.group(2).replace(',',''))
    acts=len(re.findall(r"'''Act\s+[IVX]+'''", body))
    movies.append({"id":to_id(title),"name":title,"actCount":acts,
                   "reward":{"currency":cur or "cod","amount":amt}})
print(len(movies))
json.dump(movies,open(W('movies_new.json'),'w'),ensure_ascii=False,indent=1)
