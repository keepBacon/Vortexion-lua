#!/usr/bin/env python3
"""Attachment-derived ID and active-build migration gates."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
baseline = json.loads((ROOT / 'tests/wind_option_ids_baseline.json').read_text())
pattern = r':Add(?:Toggle|Slider|Dropdown|Input)[ ]*[(][ ]*"([^"]+)"'
count = 0
for name, expected in baseline.items():
    current = (ROOT / name).read_text()
    actual = set(re.findall(pattern, current))
    missing = set(expected) - actual
    assert not missing, f'{name}: missing option IDs {sorted(missing)}'
    count += len(expected)
manifest = json.loads((ROOT / 'dist/build-manifest.json').read_text())
assert manifest['unified_entry'] == 'dist/Vortexion_Wind.lua'
assert manifest['vendor_path'] == 'vendor/WindUI/Source.lua'
assert manifest['vendor_sha256'] == 'e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05'
assert 'src/StarlightAdapter.luau' not in manifest['sources']
for name, expected in manifest['sources'].items():
    assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == expected, name
for name, expected in manifest['bundles'].items():
    data = (ROOT / 'dist' / name).read_bytes()
    assert hashlib.sha256(data).hexdigest() == expected['sha256'], name
    assert len(data) == expected['bytes'], name
    text = data.decode('utf8')
    assert 'local Starlight =' not in text and 'StarlightBridgeFactory' not in text, name
assert len(manifest['bundles']) == 6
print(f'PASS attachment option IDs {count}; six Wind bundles, all source/output hashes, unmodified Wind vendor')
