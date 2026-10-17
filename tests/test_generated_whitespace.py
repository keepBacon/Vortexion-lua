"""Prevent generated Lua whitespace from blocking R2's git diff --check gate."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class GeneratedWhitespaceTest(unittest.TestCase):
    def test_all_build_bundles_have_no_trailing_whitespace(self):
        bundles = sorted((ROOT / "dist").glob("Vortexion_*.lua"))
        self.assertEqual(len(bundles), 12, "Expected six standalone + six modular bundles")
        for bundle in bundles:
            with self.subTest(bundle=bundle.name):
                bad = [
                    number
                    for number, line in enumerate(bundle.read_bytes().splitlines(), 1)
                    if line.rstrip(b" \t") != line
                ]
                self.assertEqual(bad, [], f"Trailing whitespace in {bundle}: {bad[:10]}")
                mixed = []
                for number, line in enumerate(bundle.read_bytes().splitlines(), 1):
                    indent = line[:len(line) - len(line.lstrip(b" \t"))]
                    if b" \t" in indent:
                        mixed.append(number)
                self.assertEqual(mixed, [], f"Space before tab in {bundle}: {mixed[:10]}")


if __name__ == "__main__":
    unittest.main()
