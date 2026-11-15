# Rebuild only the nine-panel gallery assets (panels 1-7) from the committed
# analysis. Panels 8-9 (poster-lanes.png, poster.png) come from render-prepared.R.
# Run from the repository root: Rscript research/spoi/render-breakdown.R [database]
if(.Platform$OS.type=="windows")Sys.setlocale("LC_CTYPE","English_United States.UTF-8")
.libPaths(c(".R-library",.libPaths()))
sf::sf_use_s2(FALSE)
source("research/spoi/cartography.R");source("research/spoi/journeys.R");source("research/spoi/poster-layout.R");source("research/spoi/build-breakdown.R")
args<-commandArgs(trailingOnly=TRUE)
con<-DBI::dbConnect(RSQLite::SQLite(),if(length(args))args[1] else "data/spoi/spoi.sqlite")
analysis<-list(anchors=DBI::dbReadTable(con,"journey_anchors"),summary=DBI::dbReadTable(con,"journey_summary"),
  journeys=DBI::dbReadTable(con,"journey_journeys"),stops=DBI::dbReadTable(con,"journey_stops"))
analysis$observations<-DBI::dbGetQuery(con,"SELECT * FROM observations ORDER BY bird_id,cycle,timestamp")
metadata<-jsonlite::fromJSON(DBI::dbReadTable(con,"poster_relief")$metadata_json[1])
bounds<-spoi_page_bounds(unlist(metadata$bounds));projection<-metadata$projection
f<-tempfile(fileext=".geojson");writeLines(DBI::dbReadTable(con,"journey_density")$geojson[1],f)
analysis$density<-sf::st_transform(sf::st_read(f,quiet=TRUE),projection)
cartography<-prepare_poster_cartography(con,projection,bounds)
systemfonts::register_font("Jost Poster",plain="styles/fonts/Jost-Regular.ttf",bold="styles/fonts/Jost-Black.ttf",italic="styles/fonts/Jost-Italic.ttf",bolditalic="styles/fonts/Jost-BlackItalic.ttf")
render_spoi_breakdown(con,cartography,analysis,projection)
DBI::dbDisconnect(con)
cat("Rendered gallery panels 1-7 in previews/spoi/.\n")
