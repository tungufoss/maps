-- Exact original titles that recur, with no semantic merging.
SELECT * FROM exact_repeats ORDER BY year_count DESC, original_title;

-- Editorially grouped themes, including known wording variants.
SELECT * FROM repeated_themes ORDER BY year_count DESC, theme;

-- Category totals, each prompt assigned to one primary category.
SELECT * FROM category_frequency ORDER BY occurrences DESC, category;

-- Compare category mix across years.
SELECT * FROM category_by_year ORDER BY year, category;

-- Inspect original wording, alias rationale, and exact source line.
SELECT year, day, original_title, theme, category, grouping_rationale, source_line_url
FROM prompt_details WHERE theme = 'OpenStreetMap' ORDER BY year, day;

-- Completed editions only: 2019–2025 at the snapshot date.
SELECT * FROM past_edition_theme_frequency ORDER BY year_count DESC, theme;

-- Prompts scheduled after the snapshot date, not completed maps.
SELECT year, day, original_title FROM prompt_details
WHERE schedule_status='scheduled' ORDER BY prompt_date;
