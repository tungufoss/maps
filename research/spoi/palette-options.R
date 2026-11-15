# Reproducible colour studies; leaves the canonical English/Icelandic exports intact.
if(.Platform$OS.type=="windows")Sys.setlocale("LC_CTYPE","English_United States.UTF-8")
.libPaths(c(".R-library",.libPaths()))
library(sf);sf_use_s2(FALSE);library(ggplot2)
source("research/spoi/cartography.R");source("research/spoi/poster-layout.R")
con<-DBI::dbConnect(RSQLite::SQLite(),"data/spoi/spoi.sqlite")
projection<-"+proj=omerc +lat_0=35 +lonc=-20 +alpha=15 +gamma=0 +k=1 +datum=WGS84 +units=m +no_defs"
metadata<-jsonlite::fromJSON(DBI::dbReadTable(con,"poster_relief")$metadata_json[1]);bounds<-unlist(metadata$bounds)
analysis<-list(anchors=DBI::dbReadTable(con,"journey_anchors"),summary=DBI::dbReadTable(con,"journey_summary"))
f<-tempfile(fileext=".geojson");writeLines(DBI::dbReadTable(con,"journey_density")$geojson[1],f);analysis$density<-st_transform(st_read(f,quiet=TRUE),projection)
cartography<-prepare_poster_cartography(con,projection,bounds);DBI::dbDisconnect(con)
systemfonts::register_font("Jost Poster",plain="styles/fonts/Jost-Regular.ttf",bold="styles/fonts/Jost-Black.ttf",italic="styles/fonts/Jost-Italic.ttf",bolditalic="styles/fonts/Jost-BlackItalic.ttf")
# Keep the chosen teal ocean; route colours now come from RGB hue-wheel relationships.
scss<-readLines("styles/hi-site.scss")
colour<-function(name){line<-grep(paste0("^\\$hi-",name,":"),scss,value=TRUE);stopifnot(length(line)==1);regmatches(line,regexpr("#[0-9A-Fa-f]{6}",line))}
tint<-function(col,amount=.30)rgb(t(col2rgb(col))*amount/255+1-amount)
teal_hue<-rgb2hsv(col2rgb(colour("teal")))[1]
wheel<-function(degrees,saturation=.65,value=.8)hsv((teal_hue+degrees/360)%%1,saturation,value)
options<-list(
  list(ocean=colour("teal"),south=wheel(210,.70,.85),north=wheel(235,.65,.82),legend="Orange south; gold north. Nearby warm hues."),
  list(ocean=colour("teal"),south=wheel(240,.65,.78),north=wheel(120,.45,.65),legend="Gold south; violet north. RGB triadic scheme."),
  list(ocean=colour("teal"),south=wheel(210,.70,.82),north=wheel(150,.55,.65),legend="Orange south; magenta north. RGB split-complementary."))
for(i in seq_along(options))render_spoi_poster(analysis,cartography,projection,bounds,"en",options[[i]],paste0("-palette-",i),linkedin=FALSE)
ragg::agg_png("previews/spoi/palette-wheel-comparison.png",width=1800,height=1000,res=150,background="#F5F5F5")
grid::grid.newpage()
titles<-c("1  Orange + gold","2  Triadic: gold + violet","3  Split-complementary: orange + magenta")
for(i in 1:3){x<-(i-.5)/3;grid::grid.text(titles[i],x=x,y=.972,gp=grid::gpar(fontfamily="Jost Poster",fontface="bold",fontsize=12,col="#262626"));grid::grid.raster(png::readPNG(paste0("previews/spoi/poster-palette-",i,".png")),x=x,y=.48,width=.31,height=.837,interpolate=TRUE)}
grDevices::dev.off();cat("Built colour-wheel comparisons; route colours are not restricted to the HI palette. Canonical posters unchanged.\n")
print(lapply(options,function(x)x[c("ocean","south","north")]))
