# Cache the real, public-domain 1:50m geography and relief in SQLite.
prepare_poster_cartography <- function(con, projection, bounds) {
  feature_key <- "natural-earth-50m-land"
  have_features <- DBI::dbExistsTable(con,"poster_geography")
  if (!have_features) {
    path <- normalizePath("data/raw/spoi/ne_50m_land.zip",winslash="/",mustWork=TRUE)
    land <- sf::st_make_valid(sf::st_read(paste0("/vsizip/",path),quiet=TRUE))
    land <- suppressWarnings(sf::st_crop(land,c(xmin=-70,ymin=-10,xmax=40,ymax=80)))
    f <- tempfile(fileext=".geojson"); sf::st_write(land,f,quiet=TRUE)
    DBI::dbWriteTable(con,"poster_geography",data.frame(name=feature_key,
      geojson=paste(readLines(f,warn=FALSE),collapse="\n"),
      source="https://naciscdn.org/naturalearth/50m/physical/ne_50m_land.zip",
      licence="Public domain",retrieved="2026-11-15",source_md5=unname(tools::md5sum(path))))
  }
  features <- DBI::dbReadTable(con,"poster_geography")
  f <- tempfile(fileext=".geojson"); writeLines(features$geojson[[1]],f,useBytes=TRUE)
  land <- sf::st_read(f,quiet=TRUE)
  relief_key <- "gray-earth-50m-omerc15-reference-v1"
  if (!DBI::dbExistsTable(con,"poster_relief")) {
    path <- normalizePath("data/raw/spoi/GRAY_50M_SR_W.zip",winslash="/",mustWork=TRUE)
    raster <- terra::rast(paste0("/vsizip/",path,"/GRAY_50M_SR_W.tif"))
    raster <- terra::crop(raster,terra::ext(-70,40,-10,80))
    target <- terra::rast(ncols=1000,nrows=1500,xmin=bounds["xmin"],xmax=bounds["xmax"],
      ymin=bounds["ymin"],ymax=bounds["ymax"],crs=projection)
    relief <- terra::project(raster,target,method="bilinear")
    relief <- terra::mask(relief,terra::vect(sf::st_transform(land,projection)))
    # Preserve terrain structure while keeping the land close to white paper.
    relief <- round(190 + 65 * terra::clamp(relief,lower=0,upper=255) / 255)
    cache <- tempfile(fileext=".tif")
    terra::writeRaster(relief,cache,datatype="INT1U",NAflag=0,gdal=c("COMPRESS=DEFLATE"),overwrite=TRUE)
    metadata <- jsonlite::toJSON(list(source="https://naciscdn.org/naturalearth/50m/raster/GRAY_50M_SR_W.zip",
      dataset="Natural Earth Gray Earth with Shaded Relief, Hypsography and Flat Water",version="3.2.0",
      licence="Public domain",retrieved="2026-11-15",source_md5=unname(tools::md5sum(path)),
      projection=projection,bounds=as.list(bounds),width=1000,height=1500,
      method="Bilinear projection, mask to real 1:50m land, gray tones remapped to 190–255"),auto_unbox=TRUE)
    DBI::dbWriteTable(con,"poster_relief",data.frame(name=relief_key,
      tif=I(list(readBin(cache,"raw",n=file.info(cache)$size))),metadata_json=metadata))
  }
  cached <- DBI::dbReadTable(con,"poster_relief")
  stopifnot(cached$name[[1]]==relief_key)
  f <- tempfile(fileext=".tif"); writeBin(cached$tif[[1]],f)
  relief <- terra::rast(f)
  list(land=sf::st_transform(land,projection),relief=relief,metadata=cached$metadata_json[[1]])
}
