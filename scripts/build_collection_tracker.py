"""Build an offline catalogue of every yearly listing in the official directory."""
from collections import Counter
from contextlib import closing
import csv
import hashlib
import json
from pathlib import Path
import sqlite3
from urllib.parse import urlsplit

import yaml

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data/community'
APP = ROOT / 'tools/collection-review'


def collection_id(url):
    # Group exact URLs only: do not conflate different pages or guessed creator identities.
    return hashlib.sha256(url.encode('utf-8')).hexdigest()[:20]


def load_directory():
    source = json.loads((DATA / 'source.json').read_text(encoding='utf-8'))
    raw = (DATA / 'sources/galleries.yml').read_bytes()
    if hashlib.sha256(raw).hexdigest() != source['sha256']:
        raise ValueError('Official directory checksum mismatch')
    entries = yaml.safe_load(raw)
    if not isinstance(entries, list) or not entries:
        raise ValueError('Expected a nonempty directory list')
    seen = set()
    for entry in entries:
        if set(entry) - {'creator', 'link', 'year', 'description'}:
            raise ValueError('Unrecognised source field')
        if not isinstance(entry.get('year'), int) or not 2019 <= entry['year'] <= 2100:
            raise ValueError('Invalid edition year')
        for key in ['creator', 'link']:
            if not isinstance(entry.get(key), str) or not entry[key].strip():
                raise ValueError(f'Missing {key}')
        url = urlsplit(entry['link'])
        if url.scheme not in ('http', 'https') or not url.hostname:
            raise ValueError('Only HTTP(S) collection links are accepted')
        key = (entry['year'], entry['link'])
        if key in seen:
            raise ValueError(f'Duplicate yearly listing: {key}')
        seen.add(key)
    return source, entries


def build():
    source, entries = load_directory()
    catalogue = {}
    for order, entry in enumerate(entries, 1):
        cid = collection_id(entry['link'])
        item = catalogue.setdefault(cid, {
            'id': cid, 'url': entry['link'], 'host': urlsplit(entry['link']).hostname,
            'listings': []})
        item['listings'].append({'year': entry['year'], 'creator': entry['creator'],
                                 'description': entry.get('description') or '', 'source_order': order})
    items = sorted(catalogue.values(), key=lambda item: (-max(x['year'] for x in item['listings']),
                                                       item['listings'][0]['creator'].casefold(), item['url']))
    for item in items:
        item['listings'].sort(key=lambda x: -x['year'])
        item['creator'] = item['listings'][0]['creator']
        item['years'] = sorted({x['year'] for x in item['listings']}, reverse=True)
        item['description'] = next((x['description'] for x in item['listings'] if x['description']), '')
    payload = {'version': 1, 'source': source, 'listing_count': len(entries), 'collections': items}
    (DATA / 'collections.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    APP.mkdir(parents=True, exist_ok=True)
    (APP / 'catalog.js').write_text('window.COLLECTION_CATALOG = '+json.dumps(payload, ensure_ascii=False).replace('<', '\\u003c')+';\n', encoding='utf-8')
    target = DATA / 'collections.sqlite'
    temporary = DATA / 'collections.build.sqlite'
    temporary.unlink(missing_ok=True)
    try:
        with closing(sqlite3.connect(temporary)) as db:
            db.executescript('''
                PRAGMA foreign_keys=ON;
                CREATE TABLE source (source_url TEXT, directory_url TEXT, commit_sha TEXT,
                    retrieved_at TEXT, sha256 TEXT, licence TEXT);
                CREATE TABLE collections (collection_id TEXT PRIMARY KEY, url TEXT NOT NULL UNIQUE, host TEXT NOT NULL);
                CREATE TABLE listings (year INTEGER NOT NULL, collection_id TEXT NOT NULL REFERENCES collections,
                    creator TEXT NOT NULL, description TEXT, source_order INTEGER NOT NULL UNIQUE,
                    PRIMARY KEY(year,collection_id));
                CREATE VIEW collection_tracker AS SELECT l.year,l.creator,c.url,c.host,l.description,
                    c.collection_id,l.source_order,'not reviewed' AS initial_review_status
                    FROM listings l JOIN collections c USING(collection_id);
                CREATE VIEW yearly_counts AS SELECT year,count(*) AS listings FROM listings GROUP BY year;
            ''')
            db.execute('INSERT INTO source VALUES (?,?,?,?,?,?)', tuple(source[k] for k in
                       ['source_url','directory_url','commit_sha','retrieved_at','sha256','licence']))
            db.executemany('INSERT INTO collections VALUES (?,?,?)', [(x['id'],x['url'],x['host']) for x in items])
            db.executemany('INSERT INTO listings VALUES (?,?,?,?,?)', [
                (listing['year'], item['id'], listing['creator'], listing['description'], listing['source_order'])
                for item in items for listing in item['listings']])
            assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
            assert not db.execute('PRAGMA foreign_key_check').fetchall()
            db.commit()
            result = db.execute('SELECT * FROM collection_tracker ORDER BY year DESC,creator,url')
            with (DATA / 'collection_tracker.csv').open('w', encoding='utf-8', newline='') as stream:
                writer = csv.writer(stream)
                writer.writerow([x[0] for x in result.description])
                writer.writerows(result)
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)
    print(f'{len(entries)} yearly listings; {len(items)} distinct URLs; '
          f'{len(set(x["creator"] for x in entries))} source creator labels')
    print('Yearly listings:', dict(sorted(Counter(x['year'] for x in entries).items())))


if __name__ == '__main__':
    build()
