#!/usr/bin/env python3
"""Create and verify a reproducible source-and-dist deliverable."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT.parent / 'Vortexion-WindUI.zip'
manifest = json.loads((ROOT / 'dist/build-manifest.json').read_text())
report = json.loads((ROOT / 'dist/wind-test-results.json').read_text())
assert report['unified_sha256'] == manifest['bundles']['Vortexion_Wind.lua']['sha256']
for name, digest in manifest['sources'].items():
    assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest, name
for name, info in manifest['bundles'].items():
    assert hashlib.sha256((ROOT / 'dist' / name).read_bytes()).hexdigest() == info['sha256'], name
excluded = {'node_modules', '__pycache__', '.git', '.test-tools'}
files = [p for p in sorted(ROOT.rglob('*')) if p.is_file() and not any(part in excluded for part in p.relative_to(ROOT).parts) and p.suffix not in {'.pyc', '.pyo'}]
entries = {}
with zipfile.ZipFile(OUTPUT, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
    for source in files:
        name = 'Vortexion-WindUI/' + source.relative_to(ROOT).as_posix()
        data = source.read_bytes()
        entry = zipfile.ZipInfo(name, date_time=(2000, 1, 1, 0, 0, 0))
        entry.compress_type = zipfile.ZIP_DEFLATED
        entry.external_attr = 0o100644 << 16
        bundle.writestr(entry, data, compresslevel=9)
        entries[name] = hashlib.sha256(data).hexdigest()
with zipfile.ZipFile(OUTPUT) as bundle:
    assert bundle.testzip() is None
    assert set(bundle.namelist()) == set(entries)
    for name, digest in entries.items():
        assert hashlib.sha256(bundle.read(name)).hexdigest() == digest, name
print(json.dumps({'path': str(OUTPUT), 'files': len(entries), 'bytes': OUTPUT.stat().st_size, 'sha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(), 'verified': True}, indent=2))
