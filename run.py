"""Run the local reproduction and exploratory extension."""
from pathlib import Path
import argparse,subprocess,hashlib,json,os
root=Path(__file__).resolve().parent
os.chdir(root)
p=argparse.ArgumentParser();p.add_argument('--skip-networks',action='store_true');args=p.parse_args()
for filename in ['plan_lock.json','publication_plan_lock.json']:
 lock=json.loads((Path('docs')/filename).read_text())
 if hashlib.sha256(Path(lock['file']).read_bytes()).hexdigest()!=lock['sha256']:raise SystemExit('Methods document changed: '+filename)
Path('results').mkdir(exist_ok=True)
for name in ['source_manifest.json','network_sources.json']:
 for f in json.loads((root/'docs'/name).read_text())['files']:
  if not f.get('source_path'):continue
  path=root/'private_inputs'/f['filename']
  if hashlib.sha256(path.read_bytes()).hexdigest()!=f['sha256']:raise SystemExit('Input mismatch '+f['filename'])
if not args.skip_networks:subprocess.run(['Rscript','code/rebuild_networks.R'],check=True)
subprocess.run(['Rscript','code/minimum.R'],check=True)
subprocess.run(['Rscript','code/extension.R'],check=True)
subprocess.run(['Rscript','code/publication_analysis.R'],check=True)
if Path('code/plots.R').exists():subprocess.run(['Rscript','code/plots.R'],check=True)
subprocess.run(['Rscript','code/publication_plots.R'],check=True)
subprocess.run(['Rscript','code/plot_multiplex_village.R'],check=True)
print('Methods documents, input hashes, reproduction and extension checks passed.')
