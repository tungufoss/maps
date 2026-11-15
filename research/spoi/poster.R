# Reproducible bilingual R posters, built only from the committed SQLite data.
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.UTF-8")
.libPaths(c(file.path(getwd(), ".R-library"), .libPaths()))
library(ggplot2); library(sf); sf_use_s2(FALSE)
source("research/spoi/corridors.R")
source("research/spoi/journeys.R")
source("research/spoi/cartography.R")
source("research/spoi/poster-layout.R")
con <- DBI::dbConnect(RSQLite::SQLite(), "data/spoi/spoi.sqlite")
observations <- DBI::dbGetQuery(con,"SELECT * FROM observations ORDER BY bird_id,cycle,timestamp")
result <- estimate_corridors(observations)
DBI::dbWriteTable(con,"corridor_estimates",result$estimates,overwrite=TRUE)
DBI::dbWriteTable(con,"corridor_curves",result$curves,overwrite=TRUE)
DBI::dbWriteTable(con,"corridor_bird_bins",result$bird_bins,overwrite=TRUE)
DBI::dbWriteTable(con,"corridor_cycle_bins",result$cycle_bins,overwrite=TRUE)
DBI::dbWriteTable(con,"analysis_methods",data.frame(name="seasonal_corridors",method_json=jsonlite::toJSON(result$method,auto_unbox=TRUE)),overwrite=TRUE)
projection <- "+proj=omerc +lat_0=35 +lonc=-20 +alpha=15 +gamma=0 +k=1 +datum=WGS84 +units=m +no_defs"
xy <- function(lon,lat) st_coordinates(st_transform(st_as_sf(data.frame(lon=lon,lat=lat),coords=c("lon","lat"),crs=4326),projection))
ends <- unname(xy(c(-20.2,-15),c(63.8,11)))
width <- (ends[2,1]-ends[1,1])/.42; height <- width*1.5
bounds <- c(xmin=ends[1,1]-.29*width,xmax=ends[1,1]+.71*width,ymin=ends[2,2]-.13*height,ymax=ends[2,2]+.87*height)
cartography <- prepare_poster_cartography(con,projection,bounds)
countries <- prepare_countries(con,projection)
analysis <- analyse_journeys(observations,DBI::dbReadTable(con,"environment"),countries,projection)
story_facts <- poster_story_facts(analysis)
DBI::dbWriteTable(con,"poster_residence",story_facts$residence,overwrite=TRUE)
write.csv(story_facts$residence,"research/spoi/poster-residence.csv",row.names=FALSE)
writeLines(jsonlite::toJSON(story_facts,auto_unbox=TRUE,pretty=TRUE),"research/spoi/poster-story-facts.json")
analysis$method$residence <- "Pair accepted sensor-refined arrival and next departure for the same bird. Iceland: spring/autumn within a calendar year, 20-180 days. West Africa: autumn/next spring, 90-330 days. Average stays within birds, then equally across birds. Convert days using 30.4375 days/month; round to whole months for public captions. Partial stays excluded; small summer sample does not represent every bird. Full values and sample sizes in poster_residence."
analysis$method$route_display <- list(geometry="Schematic cubic links between shared regional means; not estimated flight paths",
  width="One count scale for both directions: 0.13 mm per journey; white edge halos are not part of the count encoding",
  outbound="30 direct autumn migrations reported in the paper; automated classifications remain separately retained",
  inbound="Exploratory complete spring journey counts; unresolved country included in denominator but no invented route",
  colour=spoi_palette(),pattern="Both solid; arrows show direction")
for(name in c("journeys","stops","summary","anchors"))DBI::dbWriteTable(con,paste0("journey_",name),analysis[[name]],overwrite=TRUE)
DBI::dbWriteTable(con,"journey_methods",data.frame(method_json=jsonlite::toJSON(analysis$method,auto_unbox=TRUE,pretty=TRUE)),overwrite=TRUE)
save_geo <- function(x,table) {
  f<-tempfile(fileext=".geojson");st_write(st_transform(x,4326),f,quiet=TRUE)
  DBI::dbWriteTable(con,table,data.frame(geojson=paste(readLines(f,warn=FALSE),collapse="\n")),overwrite=TRUE)
}
save_geo(analysis$density,"journey_density");save_geo(make_lane_geometry(analysis,projection),"journey_lanes")
DBI::dbDisconnect(con)
systemfonts::register_font("Jost Poster",plain="styles/fonts/Jost-Regular.ttf",bold="styles/fonts/Jost-Black.ttf",italic="styles/fonts/Jost-Italic.ttf",bolditalic="styles/fonts/Jost-BlackItalic.ttf")
dir.create("previews/spoi",recursive=TRUE,showWarnings=FALSE)
for(language in c("en","is"))render_spoi_poster(analysis,cartography,projection,bounds,language)
for(name in c("journeys","stops","summary","anchors"))write.csv(analysis[[name]],paste0("research/spoi/journey-",name,".csv"),row.names=FALSE)
writeLines(jsonlite::toJSON(analysis$method,auto_unbox=TRUE,pretty=TRUE),"research/spoi/journey-method.json")
write.csv(result$estimates,"research/spoi/corridor-estimates.csv",row.names=FALSE)
write.csv(result$curves,"research/spoi/corridor-curves.csv",row.names=FALSE)
writeLines(jsonlite::toJSON(result$method,auto_unbox=TRUE,pretty=TRUE),"research/spoi/corridor-method.json")
cat("Built English and Icelandic R posters; exploratory journey summaries:\n")
print(analysis$summary)
