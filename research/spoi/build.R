# Run from the repository root: Rscript research/spoi/build.R
# Uses committed SQLite; live OpenTopoMap tiles need internet when viewed.
html_only <- "--html-only" %in% commandArgs(trailingOnly = TRUE)
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.UTF-8")
.libPaths(c(file.path(getwd(), ".R-library"), .libPaths()))
required <- c("leaflet", "htmlwidgets", "htmltools", "jsonlite", "sf", "DBI", "RSQLite", "png", "base64enc", "ggplot2", "ragg", "boot", "terra", "systemfonts", "isoband")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages first: ", paste(missing, collapse = ", "))
root <- normalizePath(getwd(), winslash = "/")
if (!html_only) source("research/spoi/poster.R", encoding = "UTF-8")
db_path <- file.path(root, "data/spoi/spoi.sqlite")
if (!file.exists(db_path)) stop("Run python scripts/build_spoi_db.py first.")
con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
stopifnot(DBI::dbGetQuery(con, "PRAGMA integrity_check")[[1]] == "ok")
positions <- DBI::dbGetQuery(con, "SELECT source_row,bird_id,timestamp,longitude,latitude,month,cycle,display_ok,quality_flags FROM observations ORDER BY bird_id,cycle,timestamp")
birds <- DBI::dbGetQuery(con, "SELECT * FROM birds ORDER BY bird_id")
quality <- DBI::dbGetQuery(con, "SELECT bird_id,count(*) AS observations,sum(latitude IS NULL) AS missing_latitudes,sum(display_ok) AS displayed FROM observations GROUP BY bird_id ORDER BY bird_id")
flags <- DBI::dbGetQuery(con, "SELECT quality_flags,count(*) AS n FROM observations GROUP BY quality_flags ORDER BY n DESC")
environment_missing <- DBI::dbGetQuery(con, "SELECT count(*) AS total,sum(minimum_temperature IS NULL) AS minimum_missing,sum(maximum_temperature IS NULL) AS maximum_missing FROM environment")

# Store the cartographic dependency in the same committed SQLite artifact.
sf::sf_use_s2(FALSE)
if (!DBI::dbExistsTable(con, "basemaps") || !"processing" %in% DBI::dbListFields(con, "basemaps")) {
  land_zip <- file.path(root, "data/raw/spoi/ne_110m_land.zip")
  if (!file.exists(land_zip)) stop("Download https://naciscdn.org/naturalearth/110m/physical/ne_110m_land.zip to data/raw/spoi/ne_110m_land.zip")
  land <- sf::st_read(paste0("/vsizip/", land_zip), quiet = TRUE)
  land <- sf::st_make_valid(land)
  geo_path <- tempfile(fileext = ".geojson")
  sf::st_write(land, geo_path, driver = "GeoJSON", quiet = TRUE)
  DBI::dbWriteTable(con, "basemaps", data.frame(name = "natural-earth-110m-land", geojson = paste(readLines(geo_path, warn = FALSE), collapse = "\n"),
    source = "https://naciscdn.org/naturalearth/110m/physical/ne_110m_land.zip", licence = "Public domain", retrieved = "2026-11-14", md5 = unname(tools::md5sum(land_zip)), processing = "GEOS-planar-validity-v1"), overwrite = TRUE)
}
basemap <- DBI::dbReadTable(con, "basemaps")
journey_payload <- if(DBI::dbExistsTable(con,"journey_summary"))list(
  summary=DBI::dbReadTable(con,"journey_summary"),anchors=DBI::dbReadTable(con,"journey_anchors"),
  journeys=DBI::dbReadTable(con,"journey_journeys"),
  density=DBI::dbReadTable(con,"journey_density")$geojson[[1]],
  lanes=DBI::dbReadTable(con,"journey_lanes")$geojson[[1]],
  method=jsonlite::fromJSON(DBI::dbReadTable(con,"journey_methods")$method_json[[1]])) else NULL
cached_land <- tempfile(fileext = ".geojson")
writeLines(enc2utf8(basemap$geojson[[1]]), cached_land, useBytes = TRUE)
land <- sf::st_read(cached_land, quiet = TRUE)
DBI::dbDisconnect(con)
stopifnot(all(sf::st_is_valid(land)))
# Clip in geographic coordinates before projecting; avoid polar/dateline polygons
# entering the North Atlantic poster extent.
sf::sf_use_s2(FALSE)
land <- sf::st_make_valid(land)
land <- suppressWarnings(sf::st_crop(land, c(xmin = -180, ymin = -60, xmax = 180, ymax = 84)))
land_geo <- tempfile(fileext = ".geojson")
sf::st_write(land, land_geo, quiet = TRUE)
out <- file.path(root, "previews/spoi")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
manifest <- jsonlite::fromJSON(file.path(root, "data/spoi/source.json"))
payload <- list(positions = positions, birds = birds, quality = quality, flags = flags,journey=journey_payload,
  environmentMissing = environment_missing, manifest = manifest,
  birdImage = base64enc::dataURI(file = file.path(root, "research/illustrations/spoi-flight-ai.png"), mime = "image/png"))

map <- leaflet::leaflet(width = "100%", height = 700, options = leaflet::leafletOptions(
  zoomControl = FALSE, preferCanvas = TRUE, minZoom = 2, maxZoom = 9, attributionControl = TRUE))
map <- leaflet::addProviderTiles(map, leaflet::providers$OpenTopoMap)
map <- leaflet::fitBounds(map, -38, 0, 10, 70)
render_code <- paste("function(el,x,data){", paste(readLines("research/spoi/poster-data.js", warn = FALSE, encoding = "UTF-8"), collapse = "\n"), paste(readLines("research/spoi/poster.js", warn = FALSE, encoding = "UTF-8"), collapse = "\n"), "}", sep = "\n")
map <- htmlwidgets::onRender(map, render_code, data = payload)
css <- paste(readLines("research/spoi/poster.css", warn = FALSE, encoding = "UTF-8"), collapse = "\n")
font_uri <- base64enc::dataURI(file = "styles/fonts/Jost-wght.ttf", mime = "font/ttf")
css <- paste0("@font-face{font-family:Jost;src:url('",font_uri,"') format('truetype');font-weight:100 900;font-style:normal;font-display:swap;}\n",css)
map <- htmlwidgets::prependContent(map, htmltools::tags$style(htmltools::HTML(css)))
# Quarto bundles Pandoc, so exporting a single offline HTML does not require RStudio.
quarto <- Sys.which("quarto")
if (nzchar(quarto)) {
  candidate <- file.path(dirname(quarto), "tools")
  if (file.exists(file.path(candidate, "pandoc.exe")) || file.exists(file.path(candidate, "pandoc"))) {
    Sys.setenv(RSTUDIO_PANDOC = candidate)
    rmarkdown::find_pandoc(dir = candidate, cache = FALSE)
  }
}
htmlwidgets::saveWidget(map, file.path(out, "index.html"), selfcontained = TRUE, title = "Whimbrel \u00b7 52 / HIDEF MAPS", background = "#2DD2C0")

# Designed static poster and derived corridors use the same SQLite observations.
versions <- data.frame(package = required, version = vapply(required, function(p) as.character(utils::packageVersion(p)), character(1)))
write.csv(versions, "research/spoi/package-versions.csv", row.names = FALSE)
writeLines(sub("[[:blank:]]+$", "", capture.output(sessionInfo())), "research/spoi/session-info.txt")
cat("Built", file.path(out, "index.html"), if (!html_only) "and poster.png" else "(HTML only)", "from", nrow(positions), "source observations.\n")
