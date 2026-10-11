#!/usr/bin/env python3
"""Legacy regression entrypoint, superseded by v8 unified router test."""
from pathlib import Path
import runpy
print('Legacy touch tests superseded by tests/test_touch_v8.py')
runpy.run_path(str(Path(__file__).with_name('test_touch_v8.py')), run_name='__main__')
