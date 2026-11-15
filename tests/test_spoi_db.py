import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("spoi", Path(__file__).parents[1] / "scripts/build_spoi_db.py")
spoi = importlib.util.module_from_spec(spec)
spec.loader.exec_module(spoi)


class SpoiTests(unittest.TestCase):
    def row(self, **changes):
        row = dict(birdId="TEST", first="2014-08-17 03:48:10", second="2014-08-17 22:37:10", longitude="-17.149", latitude="65.745", elev_angle="-5.8", sex="M")
        return row | changes

    def test_valid_observation_is_accepted(self):
        obs = spoi.normalise_position(self.row())
        self.assertEqual(obs["quality_flags"], "")
        self.assertEqual(obs["cycle"], "2014–2015")
        self.assertEqual(obs["timestamp"], "2014-08-17T13:12:40")

    def test_missing_latitude_is_retained_but_flagged(self):
        obs = spoi.normalise_position(self.row(latitude="NA"))
        self.assertIsNone(obs["latitude"])
        self.assertIn("missing_coordinate", obs["quality_flags"])

    def test_reversed_twilight_interval_is_not_silently_repaired(self):
        obs = spoi.normalise_position(self.row(second="2014-08-16 03:48:10"))
        self.assertIn("reversed_interval", obs["quality_flags"])

    def test_equinox_and_outside_region_are_flagged(self):
        obs = spoi.normalise_position(self.row(first="2014-09-22 06:00:00", second="2014-09-22 18:00:00", latitude="-80"))
        self.assertIn("equinox_window", obs["quality_flags"])
        self.assertIn("outside_display_region", obs["quality_flags"])

    def test_html_cannot_pass_as_source_table(self):
        import tempfile
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "bad.csv"
            path.write_text("<!doctype html><title>Validating</title>")
            with self.assertRaises(ValueError):
                list(spoi.read_source(path, ["birdId", "first"]))

    def test_source_decimal_comma_is_read_as_decimal(self):
        self.assertEqual(spoi.number("21,6"), 21.6)


if __name__ == "__main__":
    unittest.main()
