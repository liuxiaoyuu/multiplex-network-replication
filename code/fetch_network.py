"""Fetch raw network inputs at the audited commit; verify every cached or new file."""
from pathlib import Path
import json,hashlib,urllib.request,argparse
p=Path(__file__).resolve().parents[1];dest=p/'private_inputs';dest.mkdir(exist_ok=True)
a=argparse.ArgumentParser();a.add_argument('--verify',action='store_true');args=a.parse_args()
m=json.loads((p/'docs/network_sources.json').read_text())
for f in m['files']:
 target=dest/f['filename']
 if not target.exists() and not args.verify:
  with urllib.request.urlopen(f['url'],timeout=60) as r:b=r.read()
  if len(b)!=f['bytes'] or hashlib.sha256(b).hexdigest()!=f['sha256']:raise RuntimeError('Downloaded input mismatch: '+f['filename'])
  target.write_bytes(b)
 if not target.exists():raise RuntimeError('Missing input: '+f['filename'])
 b=target.read_bytes()
 if len(b)!=f['bytes'] or hashlib.sha256(b).hexdigest()!=f['sha256']:raise RuntimeError('Input mismatch: '+f['filename'])
print('All',len(m['files']),'pinned network inputs verified.')
