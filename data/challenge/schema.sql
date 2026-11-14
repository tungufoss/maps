PRAGMA foreign_keys = ON;

CREATE TABLE sources (
  year INTEGER PRIMARY KEY,
  source_url TEXT NOT NULL,
  public_url TEXT NOT NULL,
  commit_sha TEXT NOT NULL,
  retrieved_at TEXT NOT NULL,
  sha256 TEXT NOT NULL,
  local_file TEXT NOT NULL,
  licence TEXT NOT NULL DEFAULT 'MIT; see sources/LICENSE.txt'
);
CREATE TABLE categories (
  category_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  classification TEXT NOT NULL DEFAULT 'Editorial; not official challenge categories'
);
CREATE TABLE themes (
  theme_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  category_id INTEGER NOT NULL REFERENCES categories(category_id)
);
CREATE TABLE aliases (
  original_title TEXT PRIMARY KEY,
  theme_id INTEGER NOT NULL REFERENCES themes(theme_id),
  rationale TEXT NOT NULL
);
CREATE TABLE prompts (
  year INTEGER NOT NULL REFERENCES sources(year),
  day INTEGER NOT NULL CHECK (day BETWEEN 1 AND 30),
  prompt_date TEXT NOT NULL,
  original_title TEXT NOT NULL REFERENCES aliases(original_title),
  description_markdown TEXT,
  source_line INTEGER NOT NULL CHECK (source_line > 0),
  PRIMARY KEY (year, day)
);
CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);

CREATE VIEW prompt_details AS
SELECT p.*, t.name AS theme, c.name AS category, a.rationale AS grouping_rationale,
       s.public_url, s.source_url || '#L' || p.source_line AS source_line_url,
       CASE WHEN p.year < CAST(substr((SELECT value FROM metadata WHERE key='as_of'),1,4) AS INTEGER)
            THEN 'past' ELSE 'ongoing' END AS edition_status,
       CASE WHEN p.prompt_date > (SELECT value FROM metadata WHERE key='as_of')
            THEN 'scheduled' ELSE 'date reached' END AS schedule_status
FROM prompts p JOIN aliases a USING(original_title)
JOIN themes t USING(theme_id) JOIN categories c USING(category_id)
JOIN sources s USING(year);

CREATE VIEW exact_repeats AS
SELECT original_title, count(*) AS occurrences, count(DISTINCT year) AS year_count,
       min(year) AS first_year, max(year) AS last_year,
       group_concat(year, ', ') AS years
FROM (SELECT * FROM prompts ORDER BY year, day)
GROUP BY original_title HAVING count(DISTINCT year) > 1;

CREATE VIEW theme_frequency AS
SELECT theme, category, count(*) AS occurrences, count(DISTINCT year) AS year_count,
       min(year) AS first_year, max(year) AS last_year,
       group_concat(year, ', ') AS years
FROM (SELECT * FROM prompt_details ORDER BY year, day)
GROUP BY theme, category;

CREATE VIEW repeated_themes AS SELECT * FROM theme_frequency WHERE year_count > 1;

CREATE VIEW category_frequency AS
SELECT category, count(*) AS occurrences, count(DISTINCT year) AS year_count,
       count(DISTINCT theme) AS theme_count
FROM prompt_details GROUP BY category;

CREATE VIEW category_by_year AS
SELECT year, category, count(*) AS occurrences
FROM prompt_details GROUP BY year, category;

CREATE VIEW past_edition_theme_frequency AS
SELECT theme, category, count(*) AS occurrences, count(DISTINCT year) AS year_count
FROM prompt_details WHERE edition_status='past' GROUP BY theme, category;
