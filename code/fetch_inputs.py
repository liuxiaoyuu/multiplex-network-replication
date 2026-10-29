"""Fetch verified, pinned inputs for the local feasibility audit (no paid services)."""
import argparse,hashlib,json,urllib.request
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--verify',action='store_true');args=p.parse_args()
m=json.loads((root/'docs/source_manifest.json').read_text())
for f in m['files']:
 if not f.get('source_path'):continue
 target=root/'private_inputs'/f['filename'];target.parent.mkdir(exist_ok=True)
 if not target.exists() and not args.verify:
  req=urllib.request.Request(f['url'],headers={'User-Agent':'replication-feasibility-audit'})
  with urllib.request.urlopen(req,timeout=60) as r:data=r.read()
  if hashlib.sha256(data).hexdigest()!=f['sha256'] or len(data)!=f['bytes']:raise RuntimeError('Downloaded input mismatch: '+f['filename'])
  target.write_bytes(data)
 if not target.exists():raise RuntimeError('Missing '+str(target))
 if len(target.read_bytes())!=f['bytes'] or hashlib.sha256(target.read_bytes()).hexdigest()!=f['sha256']:raise RuntimeError('Input mismatch: '+f['filename'])
print('All pinned author inputs verified.')
