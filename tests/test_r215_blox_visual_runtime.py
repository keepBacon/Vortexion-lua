"""Superseded runtime simulation: new native Billboard ESP is exercised in R2.19."""
import unittest
from test_r219_billboard_weapon import R219Tests
class R215VisualTest(unittest.TestCase):
    def test_model_esp_creation_and_teardown(self):
        R219Tests().test_billboard_runtime_no_humanoid_occlusion_and_teardown()
