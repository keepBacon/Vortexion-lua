#!/usr/bin/env python3
"""Unpack untrusted reference archives without executing their contents."""
import hashlib
import json
from pathlib import Path
import stat
import sys
import zipfile

root = Path(sys.argv[1]).resolve()
records = []
total = 0
count = 0

def unpack(archive, destination, origin, depth=0):
    global total, count
    destination.mkdir(parents=True, exist_ok=True)
    nested = []
    with zipfile.ZipFile(archive) as bundle:
        for entry in bundle.infolist():
            relative = Path(entry.filename)
            if relative.is_absolute() or '..' in relative.parts or '.git' in relative.parts:
                raise ValueError('Unexpected archive path: ' + entry.filename)
            if entry.is_dir():
                continue
            if stat.S_ISLNK(entry.external_attr >> 16):
                raise ValueError('Archive symlink: ' + entry.filename)
            target = (destination / relative).resolve()
            if not target.is_relative_to(root):
                raise ValueError('Archive path escapes reference root')
            count += 1
            total += entry.file_size
            if count > 5000 or entry.file_size > 8 * 1024 * 1024 or total > 64 * 1024 * 1024:
                raise ValueError('Reference extraction budget exceeded')
            data = bundle.read(entry)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            records.append({'path': str(target.relative_to(root)), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(), 'origin': origin})
            if target.suffix.lower() == '.zip' and depth < 2:
                nested.append(target)
    for archive in nested:
        unpack(archive, archive.with_suffix(''), origin + '::' + archive.name, depth + 1)

for category, archive in zip(sys.argv[2::2], sys.argv[3::2]):
    unpack(Path(archive), root / category, archive)
(root / 'manifest.json').write_text(json.dumps(records, indent=2, ensure_ascii=False) + chr(10))
print(json.dumps({'root': str(root), 'files': count, 'bytes': total, 'categories': sys.argv[2::2]}))
