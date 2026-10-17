#!/usr/bin/env python3
"""Package verified local artifacts without publishing or executing game code."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT.parent / "Vortexion_WindUI_enriched_verified.zip"
ASSET_PACK = PurePosixPath("assets/forsaken")
ASSET_MANIFEST = ASSET_PACK / "asset-manifest.json"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def asset_target(root, relative):
    """Resolve a manifest asset path inside the pack; absolute or escaping paths are rejected."""
    if not isinstance(relative, str) or not relative.strip():
        raise ValueError("Asset manifest entry path missing: " + repr(relative))
    if relative.startswith(("/", "\\")) or ":" in relative.split("/")[0] or PurePosixPath(relative).is_absolute():
        raise ValueError("Asset path must be relative: " + relative)
    parts = PurePosixPath(relative).parts
    if not parts or any(part in ("", ".", "..") for part in parts):
        raise ValueError("Asset path escapes pack root: " + relative)
    base = (root / ASSET_PACK).resolve()
    target = base.joinpath(*parts)
    resolved = target.resolve()
    if resolved != base and base not in resolved.parents:
        raise ValueError("Asset path escapes pack root: " + relative)
    return target, base, resolved


def verify_asset_manifest(root):
    """Per-item bytes/SHA, traversal, symlink, missing-file gates for the asset pack."""
    manifest_path = root / ASSET_MANIFEST
    if manifest_path.is_symlink():
        raise ValueError("Asset manifest must be a regular workspace file: " + ASSET_MANIFEST.as_posix())
    if not manifest_path.exists():
        return {}
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise ValueError("Asset manifest unreadable: " + str(error))
    verified = {}
    for item in manifest.get("files", []):
        relative = item.get("executorWorkspacePath") or item.get("name")
        target, base, resolved = asset_target(root, relative)
        # Walk the original (unresolved) path components: a symlinked assets/ or
        # assets/forsaken/ root, or any intermediate pack directory, is rejected here.
        original = root
        for part in ASSET_PACK.parts + PurePosixPath(relative).parts[:-1]:
            original = original / part
            if original.is_symlink():
                raise ValueError("Asset input must be a regular workspace file: " + relative)
        if target.is_symlink():
            raise ValueError("Asset input must be a regular workspace file: " + relative)
        if resolved != base and base not in resolved.parents:
            raise ValueError("Asset path escapes pack root: " + relative)
        if not target.is_file():
            raise ValueError("Asset missing from pack: " + relative)
        if not isinstance(item.get("bytes"), int) or not isinstance(item.get("sha256"), str):
            raise ValueError("Asset manifest entry incomplete: " + relative)
        data = target.read_bytes()
        if len(data) != item["bytes"] or digest(data) != item["sha256"]:
            raise ValueError("Verified asset changed: " + relative)
        verified[(ASSET_PACK / relative).as_posix()] = item
    return verified


def package(output=OUTPUT):
    evidence = json.loads((ROOT / "tests/release-test-results.json").read_text())
    if evidence["status"] != "offline_verified_runtime_unverified" or evidence["passedStages"] != evidence["expectedStages"] or evidence.get("testsStable") is not True:
        raise ValueError("Release gates have not completed successfully")
    expected = {**evidence["source_sha256"], **evidence["test_sha256"]}
    expected["dist/build-manifest.json"] = evidence["build_manifest_sha256"]
    expected.update({"dist/" + name: value["sha256"] for name, value in evidence["bundles"].items()})
    for name, value in expected.items():
        if digest((ROOT / name).read_bytes()) != value:
            raise ValueError("Verified input changed: " + name)
    sidecar = output.with_suffix(output.suffix + ".sha256")
    if output.exists() or sidecar.exists():
        raise FileExistsError("Existing archive/checksum preserved: " + str(output))
    asset_items = verify_asset_manifest(ROOT)
    for guard in (Path("assets"), ASSET_PACK):
        candidate = ROOT / guard
        if candidate.is_symlink():
            raise ValueError("Archive input must be a regular workspace file: " + guard.as_posix())
    files = [ROOT / name for name in ("README.md", "build.py", "loader.lua", "package.json", "后续任务.md")]
    for directory in ("src", "dist", "docs", "tests", "tools", "vendor", "assets"):
        for file in sorted((ROOT / directory).rglob("*")):
            relative = file.relative_to(ROOT)
            if any(part in ("__pycache__", "node_modules") for part in relative.parts) or file.suffix == ".pyc":
                continue
            if file.is_symlink():
                raise ValueError("Archive input must be a regular workspace file: " + str(relative))
            if file.is_file():
                files.append(file)
    hashes = {}
    contents = {}
    for file in sorted(files):
        relative = file.relative_to(ROOT).as_posix()
        contents[relative] = file.read_bytes()
        hashes[relative] = {"sha256": digest(contents[relative]), "bytes": len(contents[relative])}
    for name, value in expected.items():
        if name not in contents or digest(contents[name]) != value:
            raise ValueError("Input changed during archive snapshot: " + name)
    for relative, item in asset_items.items():
        if relative not in contents:
            raise ValueError("Asset missing from archive snapshot: " + relative)
        if len(contents[relative]) != item["bytes"] or digest(contents[relative]) != item["sha256"]:
            raise ValueError("Asset changed during archive snapshot: " + relative)
    metadata = {"status": evidence["status"], "release_stages_passed": evidence["passedStages"], "roblox_android_tested": False, "publication": "not_published_to_github", "files": hashes}
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for relative, data in contents.items():
            archive.writestr("wind-project/" + relative, data)
        archive.writestr("wind-project/release-package-manifest.json", json.dumps(metadata, indent=2, sort_keys=True) + "\n")
    with zipfile.ZipFile(output) as archive:
        bad = archive.testzip()
        if bad is not None:
            raise ValueError("Archive CRC failure: " + bad)
        for relative, value in hashes.items():
            if digest(archive.read("wind-project/" + relative)) != value["sha256"]:
                raise ValueError("Archive digest mismatch: " + relative)
    checksum = digest(output.read_bytes())
    with sidecar.open("x", encoding="utf-8") as stream:
        stream.write(checksum + "  " + output.name + "\n")
    print("PASS archive CRC and " + str(len(hashes)) + " member hashes")
    print(str(output))
    print("SHA256 " + checksum)
    print("BYTES " + str(output.stat().st_size))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    package(parser.parse_args().output.resolve())
