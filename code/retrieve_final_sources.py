from pathlib import Path
import urllib.request,urllib.parse,xml.etree.ElementTree as E,json,hashlib
p=Path(__file__).resolve().parents[1];d=p/'private_inputs';base='https://pmc-oa-opendata.s3.amazonaws.com/'
def get(u):
 with urllib.request.urlopen(u,timeout=60) as r:return r.read()
x=get(base+'?list-type=2&prefix=PMC13367815.&delimiter=/');(d/'pmc_version_listing.xml').write_bytes(x)
ns={'s':'http://s3.amazonaws.com/doc/2006-03-01/'};prefixes=[e.text for e in E.fromstring(x).findall('s:CommonPrefixes/s:Prefix',ns)]
records=[]
for pre in prefixes:
 meta=json.loads(get(base+pre+pre.strip('/')+'.json'))
 (d/(pre.strip('/')+'.json')).write_text(json.dumps(meta,indent=2));print('META',json.dumps(meta),flush=True)
 for url in [meta.get('pdf_url')]+meta.get('media_urls',[]):
  if not url or not url.split('?')[0].endswith('.pdf'):continue
  if url.startswith('s3://'):url=url.replace('s3://pmc-oa-opendata/',base)
  b=get(url);q=urllib.parse.parse_qs(urllib.parse.urlparse(url).query)
  if q.get('md5'):assert hashlib.md5(b).hexdigest()==q['md5'][0]
  name=Path(urllib.parse.urlparse(url).path).name;(d/name).write_bytes(b)
  records.append({'file':name,'url':url,'bytes':len(b),'md5':hashlib.md5(b).hexdigest(),'sha256':hashlib.sha256(b).hexdigest()})
(p/'docs/final_article_sources.json').write_text(json.dumps({'date':'2026-10-28','source':'NIH NLM PMC Article Datasets on AWS','versions':prefixes,'files':records},indent=2))
print('Saved verified PDFs',[(r['file'],r['bytes']) for r in records])
