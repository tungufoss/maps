# Run from the repository root: Rscript research/spoi/build.R
# Uses committed SQLite; no database server, token or internet needed after setup.
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.UTF-8")
.libPaths(c(file.path(getwd(), ".R-library"), .libPaths()))
required <- c("leaflet", "htmlwidgets", "htmltools", "jsonlite", "sf", "DBI", "RSQLite", "png", "base64enc")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages first: ", paste(missing, collapse = ", "))
root <- normalizePath(getwd(), winslash = "/")
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
payload <- list(positions = positions, birds = birds, quality = quality, flags = flags,
  environmentMissing = environment_missing, manifest = manifest,
  land = jsonlite::fromJSON(land_geo, simplifyVector = FALSE),
  birdImage = base64enc::dataURI(file = file.path(root, "research/illustrations/spoi-flight-ai.png"), mime = "image/png"))

map <- leaflet::leaflet(width = "100%", height = "100%", options = leaflet::leafletOptions(
  zoomControl = FALSE, preferCanvas = TRUE, minZoom = 2, maxZoom = 9, attributionControl = TRUE))
map <- leaflet::addControl(map, html = 'Made with Natural Earth | Geolocator estimates, not GPS', position = "bottomright", className = "map-credit")
map <- leaflet::fitBounds(map, -38, 0, 10, 70)
render_code <- paste("function(el,x,data){", paste(readLines("research/spoi/poster-data.js", warn = FALSE, encoding = "UTF-8"), collapse = "\n"), paste(readLines("research/spoi/poster.js", warn = FALSE, encoding = "UTF-8"), collapse = "\n"), "}", sep = "\n")
map <- htmlwidgets::onRender(map, render_code, data = payload)
css <- paste(readLines("research/spoi/poster.css", warn = FALSE, encoding = "UTF-8"), collapse = "\n")
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
htmlwidgets::saveWidget(map, file.path(out, "index.html"), selfcontained = TRUE, title = "Sp\u00f3i \u00b7 52 / HIDEF MAPS", background = "#2DD2C0")

# A real R-drawn static companion; uses the exact same display mask and gap rule.
mercator <- function(lon, lat) cbind(lon * pi / 180 * 6378137, log(tan(pi / 4 + lat * pi / 360)) * 6378137)
land_m <- sf::st_transform(land, 3857)
corners <- mercator(c(-38, 10), c(0, 70))
grDevices::png(file.path(out, "poster.png"), width = 1200, height = 1500, res = 150, bg = "#2DD2C0")
par(mar = c(6, 1, 6, 1), family = "sans", bg = "#2DD2C0", xpd = FALSE)
plot(sf::st_geometry(land_m), xlim = corners[, 1], ylim = corners[, 2], col = "#F5F5F5", border = "#ffffff", axes = FALSE, asp = 1)
for (group in split(positions, interaction(positions$bird_id, positions$cycle, drop = TRUE))) {
  group <- group[order(group$timestamp), ]
  if (nrow(group) > 1) {
    times <- as.numeric(as.POSIXct(group$timestamp, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"))
    gap <- diff(times) / 3600
    eligible <- head(group$display_ok, -1) == 1 & tail(group$display_ok, -1) == 1 & gap > 0 & gap <= 36
    a <- which(eligible); b <- a + 1
    if (length(a)) {
      start <- mercator(group$longitude[a], group$latitude[a]); end <- mercator(group$longitude[b], group$latitude[b])
      segments(start[, 1], start[, 2], end[, 1], end[, 2], col = grDevices::adjustcolor("#262626", alpha.f = 0.16), lwd = 0.6)
    }
  }
}
for (place in list(c(-19,65,"ICELAND"), c(-8,54,"IRELAND"), c(-7,40,"IBERIA"), c(-10,11,"WEST AFRICA"))) {
  xy <- mercator(as.numeric(place[1]), as.numeric(place[2])); text(xy[1], xy[2], place[3], cex = 0.75, font = 2)
}
title(main = "SP\u00d3I: ESCAPING THE ICELANDIC WINTER", cex.main = 1.3, col.main = "#262626", line = 3)
mtext("52 / HIDEF MAPS \u00b7 Maps defined by Dr Helga Ingimundard\u00f3ttir", side = 3, line = 1, cex = 0.65)
mtext("19 birds \u00b7 observed estimates overlaid \u00b7 breaks retained \u00b7 2012\u20132016", side = 1, line = 1, cex = 0.7)
mtext("Paper: doi:10.1111/jav.01938 | Data: doi:10.5061/dryad.3kf35s5 (CC0)", side = 1, line = 2.5, cex = 0.6)
mtext("Raw geolocation estimates with conservative display flags; not a reproduction of the paper's filtered tracks.", side = 1, line = 4, cex = 0.55)
dev.off()
versions <- data.frame(package = required, version = vapply(required, function(p) as.character(utils::packageVersion(p)), character(1)))
write.csv(versions, "research/spoi/package-versions.csv", row.names = FALSE)
writeLines(capture.output(sessionInfo()), "research/spoi/session-info.txt")
cat("Built", file.path(out, "index.html"), "and poster.png from", nrow(positions), "source observations.\n")
