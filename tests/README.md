# Test organization

`python3 -m unittest discover -s tests -p 'test_*.py'` runs maintained Python contracts.

Historical regression snapshots were moved to `archive/` because they assert a
superseded single-bundle manifest (e.g. output_sha256, output_bytes) or old
Starlight/Fluent interface paths. They are **not passing current release gates**;
not deleted, and not counted as validation. Rework their assertions separately
before making them release gates again.

The `test_wind_router.py` suite includes modular core/module artifacts and
loader failure simulation using a Lua 5.4 VM shim; this is **not Roblox Android**.
Actual production code is Luau, and its native compiler/device behavior has not
been validated here. Additional JS/Luau harnesses may require `luau-web` npm
dependencies that are not installed in an offline Termux or CI environment.
