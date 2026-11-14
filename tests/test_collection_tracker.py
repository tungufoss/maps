import importlib.util
import json
from pathlib import Path
import sqlite3
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('tracker',ROOT/'scripts/build_collection_tracker.py')
tracker=importlib.util.module_from_spec(spec);spec.loader.exec_module(tracker)


class CollectionTrackerTests(unittest.TestCase):
    def test_every_source_listing_is_present(self):
        _,source=tracker.load_directory()
        with sqlite3.connect(ROOT/'data/community/collections.sqlite') as db:
            rows=db.execute('SELECT year,creator,url,description FROM collection_tracker').fetchall()
            self.assertCountEqual(rows,[(r['year'],r['creator'],r['link'],r.get('description') or '') for r in source])
            self.assertEqual(db.execute('PRAGMA integrity_check').fetchone(),('ok',))
            self.assertEqual(db.execute('PRAGMA foreign_key_check').fetchall(),[])

    def test_all_years_and_only_exact_url_deduplication(self):
        payload=json.loads((ROOT/'data/community/collections.json').read_text(encoding='utf-8'))
        items=payload['collections']
        self.assertEqual(payload['listing_count'],223)
        self.assertEqual(len(items),222)
        self.assertEqual(len({x['url'] for x in items}),222)
        self.assertEqual(sum(len(x['listings']) for x in items),223)
        self.assertEqual({y for x in items for y in x['years']},set(range(2019,2026)))
        self.assertNotEqual(tracker.collection_id('https://example.com/2024'),tracker.collection_id('https://example.com/2025'))


if __name__=='__main__':unittest.main()
