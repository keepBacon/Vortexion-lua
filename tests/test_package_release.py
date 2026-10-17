import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("package_release", PROJECT / "tools/package_release.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class PackageContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="package-fixture-", dir=PROJECT / "tests")
        self.root = Path(self.temp.name)
        self.old_root = module.ROOT
        module.ROOT = self.root
        for folder in ("src", "dist", "docs", "tests", "tools", "vendor", "assets"):
            (self.root / folder).mkdir()
        for name in ("README.md", "build.py", "loader.lua", "package.json", "src/mock.luau", "tests/mock.luau", "dist/fixture.lua", "dist/build-manifest.json", "后续任务.md"):
            (self.root / name).write_text("fixture", encoding="utf-8")
        sha = lambda name: hashlib.sha256((self.root / name).read_bytes()).hexdigest()
        self.evidence = {"status": "offline_verified_runtime_unverified", "passedStages": 1, "expectedStages": 1, "testsStable": True, "source_sha256": {"src/mock.luau": sha("src/mock.luau")}, "test_sha256": {"tests/mock.luau": sha("tests/mock.luau")}, "build_manifest_sha256": sha("dist/build-manifest.json"), "bundles": {"fixture.lua": {"sha256": sha("dist/fixture.lua")}}}
        self.output = self.root / "release.zip"
        self.write_assets()
        self.save_evidence()

    def write_assets(self):
        pack = self.root / "assets/forsaken/TerioThings"
        pack.mkdir(parents=True, exist_ok=True)
        entries = []
        for name, data in (("coagulate.mp3", b"coagulate-fixture"), ("lance_swing.mp3", b"lance-fixture"), ("sil_whip.mp3", b"whip-fixture")):
            (pack / name).write_bytes(data)
            entries.append({"name": name, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(), "executorWorkspacePath": "TerioThings/" + name})
        self.write_manifest({"pack": "forsaken-audio", "files": entries})

    def manifest_path(self):
        return self.root / "assets/forsaken/asset-manifest.json"

    def write_manifest(self, manifest):
        self.manifest_path().write_text(json.dumps(manifest), encoding="utf-8")

    def load_manifest(self):
        return json.loads(self.manifest_path().read_text(encoding="utf-8"))

    def archive_members(self):
        with zipfile.ZipFile(self.output) as archive:
            return set(archive.namelist())

    def tearDown(self):
        module.ROOT = self.old_root
        self.temp.cleanup()

    def save_evidence(self):
        (self.root / "tests/release-test-results.json").write_text(json.dumps(self.evidence), encoding="utf-8")

    def package(self):
        with contextlib.redirect_stdout(io.StringIO()):
            module.package(self.output)

    def test_archive_and_sidecar_match(self):
        self.package()
        sidecar = self.output.with_suffix(".zip.sha256")
        self.assertEqual(sidecar.read_text().split()[0], hashlib.sha256(self.output.read_bytes()).hexdigest())
        with zipfile.ZipFile(self.output) as archive:
            self.assertIsNone(archive.testzip())
            manifest = json.loads(archive.read("wind-project/release-package-manifest.json"))
            for name, item in manifest["files"].items():
                content = archive.read("wind-project/" + name)
                self.assertEqual(hashlib.sha256(content).hexdigest(), item["sha256"])
                self.assertEqual(len(content), item["bytes"])

    def test_existing_archive_is_preserved(self):
        self.output.write_bytes(b"original")
        with self.assertRaises(FileExistsError): self.package()
        self.assertEqual(self.output.read_bytes(), b"original")

    def test_existing_sidecar_is_preserved_before_archive_creation(self):
        sidecar = self.output.with_suffix(".zip.sha256")
        sidecar.write_text("original")
        with self.assertRaises(FileExistsError): self.package()
        self.assertFalse(self.output.exists())
        self.assertEqual(sidecar.read_text(), "original")

    def test_changed_input_is_rejected(self):
        (self.root / "src/mock.luau").write_text("changed")
        with self.assertRaisesRegex(ValueError, "Verified input changed"): self.package()
        self.assertFalse(self.output.exists())

    def test_unstable_tests_are_rejected(self):
        self.evidence["testsStable"] = False; self.save_evidence()
        with self.assertRaisesRegex(ValueError, "not completed successfully"): self.package()
        self.assertFalse(self.output.exists())

    def test_snapshot_race_is_rejected(self):
        target = self.root / "src/mock.luau"
        original_read = Path.read_bytes
        count = 0
        def read(path):
            nonlocal count
            if path == target:
                count += 1
                if count == 2: return b"changed after verification"
            return original_read(path)
        with patch.object(Path, "read_bytes", read):
            with self.assertRaisesRegex(ValueError, "Input changed during archive snapshot"): self.package()
        self.assertFalse(self.output.exists())

    def test_symlinks_are_rejected(self):
        (self.root / "src/link.luau").symlink_to(self.root / "src/mock.luau")
        with self.assertRaisesRegex(ValueError, "regular workspace file"): self.package()
        self.assertFalse(self.output.exists())


    def test_assets_and_followup_are_archived(self):
        self.package()
        members = self.archive_members()
        self.assertIn("wind-project/后续任务.md", members)
        for name in ("coagulate.mp3", "lance_swing.mp3", "sil_whip.mp3"):
            member = "wind-project/assets/forsaken/TerioThings/" + name
            self.assertIn(member, members)
            with zipfile.ZipFile(self.output) as archive:
                manifest = json.loads(archive.read("wind-project/release-package-manifest.json"))
                item = manifest["files"]["assets/forsaken/TerioThings/" + name]
                content = archive.read(member)
                self.assertEqual(item["bytes"], len(content))
                self.assertEqual(item["sha256"], hashlib.sha256(content).hexdigest())

    def test_asset_sha_drift_is_rejected(self):
        manifest = self.load_manifest()
        manifest["files"][0]["sha256"] = "0" * 64
        self.write_manifest(manifest)
        with self.assertRaisesRegex(ValueError, "Verified asset changed"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_bytes_drift_is_rejected(self):
        (self.root / "assets/forsaken/TerioThings/sil_whip.mp3").write_bytes(b"tampered")
        with self.assertRaisesRegex(ValueError, "Verified asset changed"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_missing_file_is_rejected(self):
        (self.root / "assets/forsaken/TerioThings/sil_whip.mp3").unlink()
        with self.assertRaisesRegex(ValueError, "Asset missing from pack"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_path_traversal_is_rejected(self):
        mock = self.root / "src/mock.luau"
        manifest = self.load_manifest()
        manifest["files"][0].update({"name": "mock.luau", "executorWorkspacePath": "../src/mock.luau", "bytes": len(mock.read_bytes()), "sha256": hashlib.sha256(mock.read_bytes()).hexdigest()})
        self.write_manifest(manifest)
        with self.assertRaisesRegex(ValueError, "escapes pack root"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_absolute_path_is_rejected(self):
        manifest = self.load_manifest()
        manifest["files"][0]["executorWorkspacePath"] = str(self.root / "assets/forsaken/TerioThings/coagulate.mp3")
        self.write_manifest(manifest)
        with self.assertRaisesRegex(ValueError, "must be relative"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_symlink_is_rejected(self):
        target = self.root / "assets/forsaken/TerioThings/sil_whip.mp3"
        target.unlink()
        target.symlink_to(self.root / "assets/forsaken/TerioThings/coagulate.mp3")
        with self.assertRaisesRegex(ValueError, "regular workspace file"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_manifest_entry_incomplete_is_rejected(self):
        manifest = self.load_manifest()
        del manifest["files"][1]["sha256"]
        self.write_manifest(manifest)
        with self.assertRaisesRegex(ValueError, "entry incomplete"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_snapshot_drift_is_rejected(self):
        target = self.root / "assets/forsaken/TerioThings/sil_whip.mp3"
        original_read = Path.read_bytes
        count = 0
        def read(path):
            nonlocal count
            if path == target:
                count += 1
                if count == 2: return b"changed after verification"
            return original_read(path)
        with patch.object(Path, "read_bytes", read):
            with self.assertRaisesRegex(ValueError, "Asset changed during archive snapshot"): self.package()
        self.assertFalse(self.output.exists())

    def test_missing_asset_manifest_is_allowed(self):
        self.manifest_path().unlink()
        self.package()
        members = self.archive_members()
        self.assertNotIn("wind-project/assets/forsaken/asset-manifest.json", members)
        self.assertIn("wind-project/assets/forsaken/TerioThings/coagulate.mp3", members)

    def test_asset_pack_root_symlink_is_rejected(self):
        real = self.root / "pack-real"
        shutil.copytree(self.root / "assets/forsaken", real)
        shutil.rmtree(self.root / "assets/forsaken")
        (self.root / "assets/forsaken").symlink_to(real, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "regular workspace file"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_parent_dir_symlink_is_rejected(self):
        real = self.root / "assets-real"
        shutil.copytree(self.root / "assets", real)
        shutil.rmtree(self.root / "assets")
        (self.root / "assets").symlink_to(real, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "regular workspace file"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_manifest_symlink_is_rejected(self):
        real = self.root / "assets/forsaken/real-manifest.json"
        shutil.copy2(self.manifest_path(), real)
        self.manifest_path().unlink()
        self.manifest_path().symlink_to(real)
        with self.assertRaisesRegex(ValueError, "regular workspace file"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_intermediate_dir_symlink_is_rejected(self):
        real = self.root / "assets/forsaken/things-real"
        shutil.copytree(self.root / "assets/forsaken/TerioThings", real)
        shutil.rmtree(self.root / "assets/forsaken/TerioThings")
        (self.root / "assets/forsaken/TerioThings").symlink_to(real, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "regular workspace file"): self.package()
        self.assertFalse(self.output.exists())

    def test_asset_pack_root_symlink_without_manifest_is_rejected(self):
        self.manifest_path().unlink()
        real = self.root / "pack-real"
        shutil.copytree(self.root / "assets/forsaken", real)
        shutil.rmtree(self.root / "assets/forsaken")
        (self.root / "assets/forsaken").symlink_to(real, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "regular workspace file"): self.package()
        self.assertFalse(self.output.exists())
if __name__ == "__main__":
    unittest.main(verbosity=2)
