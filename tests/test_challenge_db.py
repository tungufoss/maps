"""Check source completeness and the intended distinction between exact and grouped repeats."""
import importlib.util
from pathlib import Path
import sqlite3
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('builder', ROOT / 'scripts/build_challenge_db.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class HistoricalDatabaseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workspace = tempfile.TemporaryDirectory()
        cls.path = Path(cls.workspace.name) / 'challenge.sqlite'
        builder.build(cls.path)
        cls.db = sqlite3.connect(cls.path)

    @classmethod
    def tearDownClass(cls):
        cls.db.close()
        cls.workspace.cleanup()

    def test_every_edition_has_thirty_days(self):
        counts = self.db.execute('SELECT year,count(*),min(day),max(day) FROM prompts GROUP BY year').fetchall()
        self.assertEqual(counts, [(year, 30, 1, 30) for year in range(2019, 2027)])
        self.assertEqual(self.db.execute('PRAGMA integrity_check').fetchone(), ('ok',))
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def test_parser_rejects_missing_or_duplicate_day(self):
        source = (builder.DATA / 'sources/themes-2019.md').read_text(encoding='utf-8')
        with self.assertRaises(ValueError):
            builder.parse_prompts(source.replace('| 30 ', '| 29 '), 2019)

    def test_wording_and_literal_null_are_preserved(self):
        self.assertEqual(self.db.execute('SELECT original_title FROM prompts WHERE year=2022 AND day=20').fetchone(),
                         ('"My favourite…"',))
        self.assertEqual(self.db.execute("SELECT count(*) FROM prompts WHERE original_title='NULL'").fetchone(), (4,))
        self.assertEqual(self.db.execute('SELECT count(*) FROM prompts WHERE original_title IS NULL').fetchone(), (0,))

    def test_variants_group_without_merging_related_constraints(self):
        aliases = dict(self.db.execute('SELECT original_title,theme_id FROM aliases'))
        self.assertEqual(aliases['OpenStreetMap'], aliases['Data challenge 1: OpenStreetMap'])
        self.assertEqual(aliases['New tool'], aliases['Map with a new tool'])
        for first, second in [('5 minute map', '10 minute map'), ('Monochrome', 'Black & white'),
                              ('Historical map', 'Vintage'), ('Points', 'Dot'), ('Interactions', 'Interactive map')]:
            self.assertNotEqual(aliases[first], aliases[second])

    def test_repeats_and_ongoing_schedule(self):
        repeats = dict(self.db.execute('SELECT original_title,year_count FROM exact_repeats'))
        for title in ['Points', 'Lines', 'Polygons', 'Hexagons', 'Raster']:
            self.assertEqual(repeats[title], 8)
        self.assertEqual(self.db.execute("SELECT count(*) FROM prompt_details WHERE edition_status='past'").fetchone(), (210,))
        self.assertEqual(self.db.execute("SELECT count(*) FROM prompt_details WHERE schedule_status='scheduled'").fetchone(), (16,))
        self.assertEqual(self.db.execute('SELECT sum(occurrences) FROM category_frequency').fetchone(), (240,))


if __name__ == '__main__':
    unittest.main()
