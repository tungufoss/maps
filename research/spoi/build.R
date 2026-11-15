# Static poster/article build by default. Interactive prototype is parked on
# feature/whimbrel-interactive-poster; --html-only is an explicit prototype rebuild.
# Run from the repository root: Rscript research/spoi/build.R
# Uses committed SQLite and embeds the same Natural Earth paper map as the poster.
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
source("research/spoi/cartography.R");source("research/spoi/journeys.R");source("research/spoi/poster-layout.R")
poster_metadata<-jsonlite::fromJSON(DBI::dbReadTable(con,"poster_relief")$metadata_json[1])
poster_bounds<-unlist(poster_metadata$bounds);poster_projection<-poster_metadata$projection
paper<-prepare_poster_cartography(con,poster_projection,poster_bounds)
prepared<-list(anchors=DBI::dbReadTable(con,"journey_anchors"),summary=DBI::dbReadTable(con,"journey_summary"),journeys=DBI::dbReadTable(con,"journey_journeys"))
prepared$observations<-positions
density_file<-tempfile(fileext=".geojson");writeLines(journey_payload$density,density_file)
prepared$density<-sf::st_transform(sf::st_read(density_file,quiet=TRUE),poster_projection)
systemfonts::register_font("Jost Poster",plain="styles/fonts/Jost-Regular.ttf",bold="styles/fonts/Jost-Black.ttf",italic="styles/fonts/Jost-Italic.ttf",bolditalic="styles/fonts/Jost-BlackItalic.ttf")
for(mode in if(html_only)c("background","overview","lanes") else "lanes")render_spoi_poster(prepared,paper,poster_projection,poster_bounds,tag=paste0("-",mode),mode=mode)
source("research/spoi/build-breakdown.R")
render_spoi_breakdown(con,paper,prepared,poster_projection)
if(!html_only){
  landing<-tempfile(tmpdir="previews/spoi",fileext=".html")
  stopifnot(file.copy("research/spoi/static-index.html",landing))
  spoi_publish(landing,"previews/spoi/index.html")
  DBI::dbDisconnect(con)
  cat("Built A4 English/Icelandic posters and nine-panel article assets. Interactive work is parked.\n")
  quit(save="no",status=0)
}
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
  birdImage = base64enc::dataURI(file = file.path(root, "research/illustrations/images/spoi-flight-ai.png"), mime = "image/png"))
payload$paper<-list(projection=poster_projection,bounds=as.list(poster_bounds),
  background=base64enc::dataURI(file="previews/spoi/poster-background.png",mime="image/png"),
  overview=base64enc::dataURI(file="previews/spoi/poster-overview.png",mime="image/png"))
check_locations<-data.frame(longitude=c(-19.24562,-14.918776,-8.677507),latitude=c(63.450715,11.694855,51.871933))
check_xy<-sf::st_coordinates(sf::st_transform(sf::st_as_sf(check_locations,coords=c("longitude","latitude"),crs=4326),poster_projection))
payload$paper$checks<-cbind(check_locations,x=check_xy[,1],y=check_xy[,2])

map <- leaflet::leaflet(width = "100%", height = 700, options = leaflet::leafletOptions(
  zoomControl = FALSE, preferCanvas = TRUE, minZoom = 0, maxZoom = 9, zoomSnap=0,zoomAnimation=FALSE,
  crs=leaflet::leafletCRS(crsClass="L.Proj.CRS",code="SPOI:OMERC",proj4def=paste(poster_projection,"+x_0=0 +y_0=0"),resolutions=32768/2^(0:9)),attributionControl = TRUE))
# Avoid Leaflet's automatic world-bounds fit: this regional CRS has a singularity
# outside the poster extent. onRender fits the exact projected paper rectangle.
map_centre<-sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(c(mean(poster_bounds[c("xmin","xmax")]),mean(poster_bounds[c("ymin","ymax")]))),crs=poster_projection),4326))[1,]
map<-leaflet::setView(map,lng=unname(map_centre[1]),lat=unname(map_centre[2]),zoom=2)
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
widget_file<-tempfile(tmpdir=out,fileext=".html")
htmlwidgets::saveWidget(map, widget_file, selfcontained = TRUE, title = "Whimbrel \u00b7 52 / HIDEF MAPS", background = "#2DD2C0")
# R's truncate-and-copy intermittently fails against an open served HTML on
# Windows. A same-volume atomic replacement keeps the previous export intact.
python_launcher<-Sys.which(if(.Platform$OS.type=="windows")"py" else "python3")
if(!nzchar(python_launcher))stop("Python 3 is required to atomically publish the prepared HTML.")
publish_args<-c(if(.Platform$OS.type=="windows")"-3",shQuote("research/spoi/publish-html.py"),shQuote(widget_file),shQuote(file.path(out,"index.html")))
stopifnot(system2(python_launcher,publish_args)==0)

# Designed static poster and derived corridors use the same SQLite observations.
versions <- data.frame(package = required, version = vapply(required, function(p) as.character(utils::packageVersion(p)), character(1)))
write.csv(versions, "research/spoi/package-versions.csv", row.names = FALSE)
writeLines(sub("[[:blank:]]+$", "", capture.output(sessionInfo())), "research/spoi/session-info.txt")
cat("Built", file.path(out, "index.html"), if (!html_only) "and poster.png" else "(HTML only)", "from", nrow(positions), "source observations.\n")
