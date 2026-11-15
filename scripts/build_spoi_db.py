"""Rebuild the committed spói SQLite database from the unmodified Dryad files.

The .csv files are R's quoted, whitespace-delimited tables, including row names.
No third-party Python dependencies are required.
"""
import argparse
from datetime import datetime, timedelta
import hashlib
import json
from pathlib import Path
import shlex
import sqlite3

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {"raw_positions.csv": "f535a4f97f6fefbf53c3c1c08041f798",
            "temp_cond_wets.csv": "ab587f907c2f3bf0112f86c3fb89a513"}
POSITION_FIELDS = ["birdId", "first", "second", "longitude", "latitude", "elev_angle", "sex"]
ENV_FIELDS = ["birdId", "date", "t_min", "t_max", "wets", "cond"]


def read_source(path, expected):
    with Path(path).open(encoding="utf-8-sig") as stream:
        header = shlex.split(next(stream))
        if header != expected:
            raise ValueError(f"Unexpected header in {path}: {header!r}")
        for line in stream:
            if not line.strip():
                continue
            values = shlex.split(line)
            if len(values) != len(header) + 1:
                raise ValueError(f"Malformed source row in {path}: {values[:2]}")
            yield {"source_row": int(values[0]), **dict(zip(header, values[1:]))}


def number(value):
    return None if value in ("NA", "NaN", "", None) else float(value.replace(",", "."))


def normalise_position(row):
    first = datetime.strptime(row["first"], "%Y-%m-%d %H:%M:%S")
    second = datetime.strptime(row["second"], "%Y-%m-%d %H:%M:%S")
    middle = first + (second - first) / 2
    lat, lon = number(row["latitude"]), number(row["longitude"])
    flags = []
    if second < first:
        flags.append("reversed_interval")
    if lat is None or lon is None:
        flags.append("missing_coordinate")
    elif not (-90 <= lat <= 90 and -180 <= lon <= 180):
        flags.append("invalid_coordinate")
    elif not (0 <= lat <= 75 and -50 <= lon <= 20):
        flags.append("outside_display_region")
    # Conservative calendar approximation of the paper's 40-day equinox exclusions.
    # Keep the raw rows and all flags so this choice can be inspected and revised.
    if any(abs((middle - datetime(middle.year, month, day)).total_seconds()) < 20 * 86400
           for month, day in ((3, 20), (9, 22))):
        flags.append("equinox_window")
    year = middle.year if middle.month >= 7 else middle.year - 1
    return dict(timestamp=middle.isoformat(timespec="seconds"), latitude=lat, longitude=lon,
                month=middle.month, cycle=f"{year}–{year + 1}", quality_flags=";".join(flags))


def build(raw_dir, output):
    raw_dir, output = Path(raw_dir), Path(output)
    manifest = {
        "dataset_doi": "10.5061/dryad.3kf35s5", "paper_doi": "10.1111/jav.01938",
        "dataset_url": "https://datadryad.org/dataset/doi:10.5061/dryad.3kf35s5",
        "licence": "CC0-1.0", "retrieved": "2026-11-14", "version": "2019-11-19",
        "retrieval": "User-provided original Dryad ZIP; publisher MD5s verified",
        "authors": ["Camilo Carneiro", "Tómas G. Gunnarsson", "José A. Alves"],
        "sensor": "light-level geolocator; not GPS", "crs": "Geographic longitude/latitude interpreted as WGS84 (EPSG:4326); datum not specified by the CSV",
        "time_basis": "Source timezone unspecified. Twilight strings retained; interval midpoint used for display/order, not an exact flight fix.",
        "display_policy": "Exclude missing/invalid coordinates, reversed intervals, points outside 0–75N/50W–20E, and ±20 days around calendar March 20 and September 22. Keep every source row. Do not connect gaps exceeding 36 hours or masked rows.",
        "files": []}
    for filename, expected in EXPECTED.items():
        payload = (raw_dir / filename).read_bytes()
        actual = hashlib.md5(payload).hexdigest()
        if actual != expected:
            raise ValueError(f"Publisher MD5 mismatch for {filename}: {actual}")
        manifest["files"].append(dict(name=filename, bytes=len(payload), md5=actual,
                                      sha256=hashlib.sha256(payload).hexdigest()))
    positions = list(read_source(raw_dir / "raw_positions.csv", POSITION_FIELDS))
    environment = list(read_source(raw_dir / "temp_cond_wets.csv", ENV_FIELDS))
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".building.sqlite")
    if temporary.exists():
        temporary.unlink()
    con = sqlite3.connect(temporary)
    con.executescript("""
        PRAGMA foreign_keys=ON;
        CREATE TABLE provenance (key TEXT PRIMARY KEY, value_json TEXT NOT NULL);
        CREATE TABLE birds (bird_id TEXT PRIMARY KEY, sex TEXT NOT NULL);
        CREATE TABLE raw_positions (source_row INTEGER PRIMARY KEY, birdId TEXT NOT NULL,
          first TEXT NOT NULL, second TEXT NOT NULL, longitude TEXT, latitude TEXT, elev_angle TEXT, sex TEXT);
        CREATE TABLE raw_environment (source_row INTEGER PRIMARY KEY, birdId TEXT NOT NULL,
          date TEXT NOT NULL, t_min TEXT, t_max TEXT, wets TEXT, cond TEXT);
        CREATE TABLE observations (source_row INTEGER PRIMARY KEY REFERENCES raw_positions(source_row),
          bird_id TEXT NOT NULL REFERENCES birds(bird_id), timestamp TEXT NOT NULL,
          longitude REAL, latitude REAL, month INTEGER NOT NULL CHECK(month BETWEEN 1 AND 12),
          cycle TEXT NOT NULL, quality_flags TEXT NOT NULL, display_ok INTEGER NOT NULL CHECK(display_ok IN (0,1)));
        CREATE INDEX observations_bird_time ON observations(bird_id,timestamp);
        CREATE INDEX observations_cycle ON observations(cycle);
        CREATE TABLE environment (source_row INTEGER PRIMARY KEY REFERENCES raw_environment(source_row),
          bird_id TEXT NOT NULL REFERENCES birds(bird_id), timestamp TEXT NOT NULL,
          minimum_temperature REAL, maximum_temperature REAL, wet_contacts REAL, conductivity REAL);
        CREATE INDEX environment_bird_time ON environment(bird_id,timestamp);
        CREATE VIEW display_observations AS SELECT * FROM observations WHERE display_ok=1;
    """)
    for bird in sorted({row["birdId"] for row in positions}):
        sexes = {r["sex"] for r in positions if r["birdId"] == bird}
        if len(sexes) != 1:
            raise ValueError(f"Conflicting sex labels for {bird}: {sexes}")
        con.execute("INSERT INTO birds VALUES (?,?)", (bird, sexes.pop()))
    for row in positions:
        con.execute("INSERT INTO raw_positions VALUES (?,?,?,?,?,?,?,?)",
                    [row[k] for k in ["source_row"] + POSITION_FIELDS])
        normal = normalise_position(row)
        con.execute("INSERT INTO observations VALUES (?,?,?,?,?,?,?,?,?)",
                    (row["source_row"], row["birdId"], normal["timestamp"], normal["longitude"],
                     normal["latitude"], normal["month"], normal["cycle"], normal["quality_flags"],
                     int(not normal["quality_flags"])))
    for row in environment:
        con.execute("INSERT INTO raw_environment VALUES (?,?,?,?,?,?,?)",
                    [row[k] for k in ["source_row"] + ENV_FIELDS])
        timestamp = datetime.strptime(row["date"], "%d-%m-%Y %H:%M").isoformat(timespec="seconds")
        con.execute("INSERT INTO environment VALUES (?,?,?,?,?,?,?)",
                    (row["source_row"], row["birdId"], timestamp, *[number(row[k]) for k in ENV_FIELDS[2:]]))
    manifest["counts"] = dict(birds=con.execute("SELECT count(*) FROM birds").fetchone()[0],
        positions=len(positions), environment=len(environment),
        displayed_positions=con.execute("SELECT count(*) FROM display_observations").fetchone()[0])
    manifest["coverage"] = dict(zip(("first_midpoint", "last_midpoint"),
        con.execute("SELECT min(timestamp),max(timestamp) FROM observations").fetchone()))
    for key, value in manifest.items():
        con.execute("INSERT INTO provenance VALUES (?,?)", (key, json.dumps(value, ensure_ascii=False)))
    con.execute("PRAGMA user_version=1")
    con.commit()
    assert con.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    assert not con.execute("PRAGMA foreign_key_check").fetchall()
    con.execute("VACUUM")
    con.close()
    temporary.replace(output)
    output.with_name("source.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw-dir", type=Path, default=ROOT / "data/raw/spoi")
    parser.add_argument("--output", type=Path, default=ROOT / "data/spoi/spoi.sqlite")
    args = parser.parse_args()
    result = build(args.raw_dir, args.output)
    print(json.dumps(result["counts"]))
