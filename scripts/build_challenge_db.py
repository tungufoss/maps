"""Rebuild the historical prompt database offline from pinned official tables."""
from __future__ import annotations

import argparse
from contextlib import closing
import csv
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data' / 'challenge'


def parse_prompts(text: str, year: int) -> list[tuple]:
    rows = []
    for line_number, line in enumerate(text.splitlines(), 1):
        cells = [cell.strip() for cell in line.strip().strip('|').split('|')]
        if not cells or not re.fullmatch(r'\d{1,2}(?:-11-\d{4})?', cells[0]):
            continue
        day = int(cells[0].split('-')[0])
        if '-' in cells[0] and int(cells[0][-4:]) != year:
            raise ValueError(f'Wrong year on source line {line_number}')
        if len(cells) not in (2, 3) or not cells[1]:
            raise ValueError(f'Unexpected table row at line {line_number}')
        rows.append((year, day, f'{year}-11-{day:02d}', cells[1],
                     cells[2] or None if len(cells) == 3 else None, line_number))
    if sorted(row[1] for row in rows) != list(range(1, 31)):
        raise ValueError(f'{year}: expected exactly one prompt per day 1–30')
    return rows


def build(destination: Path) -> None:
    manifest = json.loads((DATA / 'sources.json').read_text(encoding='utf-8-sig'))
    taxonomy = json.loads((DATA / 'taxonomy.json').read_text(encoding='utf-8'))
    if sorted(item['year'] for item in manifest) != list(range(2019, 2027)):
        raise ValueError('Expected the eight source editions 2019–2026')
    prompts = []
    for source in manifest:
        raw = (DATA / source['file']).read_bytes()
        if hashlib.sha256(raw).hexdigest() != source['sha256']:
            raise ValueError(f"Source checksum mismatch: {source['file']}")
        prompts.extend(parse_prompts(raw.decode('utf-8-sig'), source['year']))

    category_for = {}
    for category, titles in taxonomy['categories'].items():
        for title in titles:
            if title in category_for:
                raise ValueError(f'Duplicate classification: {title}')
            category_for[title] = category
    originals = {row[3] for row in prompts}
    if originals != set(category_for):
        raise ValueError(f'Taxonomy mismatch: missing={originals - set(category_for)}, '
                         f'unknown={set(category_for) - originals}')
    aliases = {title: (title, 'Original title retained as a distinct theme.') for title in originals}
    assigned = set()
    for group in taxonomy['alias_groups']:
        for title in group['titles']:
            if title not in originals or title in assigned:
                raise ValueError(f'Invalid or duplicate alias: {title}')
            assigned.add(title)
            aliases[title] = (group['theme'], group['rationale'])
    theme_category = {}
    for title, (theme, _) in aliases.items():
        category = category_for[title]
        if theme in theme_category and theme_category[theme] != category:
            raise ValueError(f'Conflicting categories for {theme}')
        theme_category[theme] = category

    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=destination.parent, suffix='.sqlite', delete=False) as tmp:
        temporary = Path(tmp.name)
    try:
        with closing(sqlite3.connect(temporary)) as db:
            db.executescript((DATA / 'schema.sql').read_text(encoding='utf-8'))
            db.executemany('INSERT INTO sources VALUES (?,?,?,?,?,?,?,?)', [
                (s['year'], s['source_url'], s['public_url'], s['commit_sha'],
                 s['retrieved_at'], s['sha256'], s['file'], 'MIT; see sources/LICENSE.txt') for s in manifest])
            db.executemany('INSERT INTO metadata VALUES (?,?)', [
                ('as_of', '2026-11-14'), ('taxonomy_version', str(taxonomy['version'])),
                ('classification_method', taxonomy['method']),
                ('scope', 'Official announced daily prompts; not participant entries or map popularity.')])
            for cid, category in enumerate(sorted(taxonomy['categories']), 1):
                db.execute('INSERT INTO categories(category_id,name) VALUES (?,?)', (cid, category))
            category_ids = dict(db.execute('SELECT name,category_id FROM categories'))
            for tid, theme in enumerate(sorted(theme_category), 1):
                db.execute('INSERT INTO themes VALUES (?,?,?)', (tid, theme, category_ids[theme_category[theme]]))
            theme_ids = dict(db.execute('SELECT name,theme_id FROM themes'))
            db.executemany('INSERT INTO aliases VALUES (?,?,?)', [
                (title, theme_ids[theme], reason) for title, (theme, reason) in sorted(aliases.items())])
            db.executemany('INSERT INTO prompts VALUES (?,?,?,?,?,?)', sorted(prompts))
            if db.execute('PRAGMA foreign_key_check').fetchall():
                raise ValueError('Foreign key validation failed')
            if db.execute('PRAGMA integrity_check').fetchone()[0] != 'ok':
                raise ValueError('SQLite integrity check failed')
            db.commit()
            for view, order in [('prompt_details', 'year,day'), ('theme_frequency', 'year_count DESC,theme'),
                                ('category_frequency', 'occurrences DESC,category')]:
                result = db.execute(f'SELECT * FROM {view} ORDER BY {order}')
                with (destination.parent / f'{view}.csv').open('w', encoding='utf-8', newline='') as stream:
                    writer = csv.writer(stream)
                    writer.writerow([col[0] for col in result.description])
                    writer.writerows(result)
            print(f'{len(prompts)} prompts; {len(originals)} exact titles; '
                  f'{len(theme_ids)} grouped themes; {len(category_ids)} categories')
            print('Most recurrent themes:', db.execute(
                'SELECT theme,year_count FROM repeated_themes ORDER BY year_count DESC,theme LIMIT 12').fetchall())
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=DATA / '30daymapchallenge.sqlite')
    build(parser.parse_args().output.resolve())
