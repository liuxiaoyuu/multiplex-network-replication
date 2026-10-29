"""Optional provenance audit of the 2019 experiment, not a model input."""
from pathlib import Path
import hashlib,json,urllib.request,zipfile,io,subprocess,os
p=Path(__file__).resolve().parents[1];os.chdir(p)
m=json.loads((p/'docs/gossip_source.json').read_text());z=p/'private_inputs/GossipFinalData.zip';z.parent.mkdir(exist_ok=True)
if not z.exists():
    with urllib.request.urlopen(m['url'],timeout=120) as r:b=r.read()
    if hashlib.sha256(b).hexdigest()!=m['sha256']:raise RuntimeError('Historical archive hash mismatch')
    z.write_bytes(b)
assert z.stat().st_size==m['bytes'] and hashlib.sha256(z.read_bytes()).hexdigest()==m['sha256']
with zipfile.ZipFile(z) as outer:
    with zipfile.ZipFile(io.BytesIO(outer.read('Supplementary/Final_Data.zip'))) as inner:
        for name in ['Final_Data/data/karnataka_cell_rct.dta','Final_Data/README','Final_Data/do/analysis_cell_RCT.do']:
            target=p/'private_inputs/gossip_sources'/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(inner.read(name))
subprocess.run(['Rscript','code/audit_original_archive.R'],check=True)
