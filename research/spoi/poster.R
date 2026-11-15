# Rscript research/spoi/poster.R -- creates the designed static poster from SQLite.
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.UTF-8")
.libPaths(c(file.path(getwd(), ".R-library"), .libPaths()))
library(ggplot2)
library(sf)
sf_use_s2(FALSE)
source("research/spoi/corridors.R")
con <- DBI::dbConnect(RSQLite::SQLite(), "data/spoi/spoi.sqlite")
observations <- DBI::dbGetQuery(con,"SELECT * FROM observations ORDER BY bird_id,cycle,timestamp")
result <- estimate_corridors(observations)
DBI::dbWriteTable(con,"corridor_estimates",result$estimates,overwrite=TRUE)
DBI::dbWriteTable(con,"corridor_curves",result$curves,overwrite=TRUE)
DBI::dbWriteTable(con,"corridor_bird_bins",result$bird_bins,overwrite=TRUE)
DBI::dbWriteTable(con,"corridor_cycle_bins",result$cycle_bins,overwrite=TRUE)
DBI::dbWriteTable(con,"analysis_methods",data.frame(name="seasonal_corridors",method_json=jsonlite::toJSON(result$method,auto_unbox=TRUE)),overwrite=TRUE)
basemap <- DBI::dbReadTable(con,"basemaps")
DBI::dbDisconnect(con)
land_file <- tempfile(fileext=".geojson")
writeLines(basemap$geojson[[1]],land_file,useBytes=TRUE)
land <- st_make_valid(st_read(land_file,quiet=TRUE))
land <- suppressWarnings(st_crop(land,c(xmin=-70,ymin=-10,xmax=40,ymax=80)))
projection <- "+proj=eqdc +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-20 +datum=WGS84 +units=m +no_defs"
land <- st_transform(land,projection)
xy <- function(lon,lat) st_coordinates(st_transform(st_as_sf(data.frame(lon=lon,lat=lat),coords=c("lon","lat"),crs=4326),projection))
corners <- xy(c(-40,15,-40,15),c(0,0,73,73))
bounds <- c(xmin=min(corners[,1]),xmax=max(corners[,1]),ymin=min(corners[,2]),ymax=max(corners[,2]))
graticule <- st_transform(st_graticule(lon=seq(-70,40,10),lat=seq(0,80,10)),projection)
lines <- list(); ribbons <- list()
for (season in c("Outbound","Inbound")) {
  d <- result$curves[result$curves$season==season,]
  d <- d[order(d$latitude),]
  # Do not span bins that failed the minimum-bird coverage threshold.
  groups <- d$run
  for (group in unique(groups)) {
    q <- d[groups==group,]
    if(nrow(q)<2)next
    centre <- cbind(q$mean_longitude,q$latitude)
    ring <- rbind(cbind(q$lower,q$latitude),cbind(rev(q$upper),rev(q$latitude)),c(q$lower[1],q$latitude[1]))
    lines[[length(lines)+1]] <- st_sf(season=season,geometry=st_sfc(st_linestring(centre),crs=4326))
    ribbons[[length(ribbons)+1]] <- st_sf(season=season,geometry=st_sfc(st_polygon(list(ring)),crs=4326))
  }
}
route <- st_transform(do.call(rbind,lines),projection)
band <- st_transform(do.call(rbind,ribbons),projection)
st_geometry_shadow <- st_geometry(land) + c(16000,-16000)
shadow <- st_sf(geometry=st_geometry_shadow); st_crs(shadow)<-st_crs(land)
place <- data.frame(name=c("ICELAND","IRELAND","BRITAIN","IBERIA","MOROCCO"),lon=c(-19,-9,0,-4,-6),lat=c(67,55,57,42,32))
place_xy <- xy(place$lon,place$lat);place$x<-place_xy[,1];place$y<-place_xy[,2]
anchor <- xy(c(-20.2,-8,-15),c(63.8,53.5,11))
fig <- ggplot()+
  geom_sf(data=graticule,colour="white",linewidth=.15,alpha=.45)+
  geom_sf(data=shadow,fill="#262626",colour=NA,alpha=.12)+
  geom_sf(data=land,fill="#F5F5F5",colour="white",linewidth=.25)+
  geom_sf(data=band,aes(fill=season),colour=NA,alpha=.20,show.legend=FALSE)+
  scale_fill_manual(values=c(Outbound="#262626",Inbound="#ffffff"))+
  geom_sf(data=route,colour="white",linewidth=1.8,show.legend=FALSE)+
  geom_sf(data=route,aes(linetype=season),colour="#262626",linewidth=.75,show.legend=FALSE)+
  scale_linetype_manual(values=c(Outbound="solid",Inbound="22"))+
  geom_text(data=place,aes(x=x,y=y,label=name),family="sans",fontface="bold",size=2.8,colour="#262626")+
  annotate("point",x=anchor[,1],y=anchor[,2],shape=21,size=3,fill="white",colour="#262626",stroke=.7)+
  coord_sf(crs=projection,xlim=bounds[c("xmin","xmax")],ylim=bounds[c("ymin","ymax")],expand=FALSE,datum=NA)+
  theme_void()+theme(plot.background=element_rect(fill="#2DD2C0",colour=NA),panel.background=element_rect(fill="#2DD2C0",colour=NA),plot.margin=margin(0,0,0,0))
dir.create("previews/spoi",recursive=TRUE,showWarnings=FALSE)
ragg::agg_png("previews/spoi/poster.png",width=1200,height=1500,res=150,background="#2DD2C0")
print(fig)
library(grid)
txt <- function(label,x,y,size=12,face="plain",family="Arial",colour="#262626",just="left") grid.text(label,x=x,y=y,just=just,gp=gpar(fontfamily=family,fontsize=size,fontface=face,col=colour))
txt("52 / HIDEF MAPS",.045,.975,12,"bold")
txt("Maps defined by Dr Helga Ingimundard\u00f3ttir",.045,.953,7)
image <- png::readPNG("research/illustrations/spoi-flight-ai.png")
grid.raster(image,x=.22,y=.85,width=.40,interpolate=TRUE)
txt("SP\u00d3I",.045,.56,91,family="Impact")
txt("SUMMERS IN ICELAND",.05,.49,23,family="Impact")
txt("\u2248 3 months of summer vacation",.05,.458,11,"bold")
txt("Numenius phaeopus islandicus",.05,.435,9,"italic")
txt("A short summer to breed.\nMost of the year away.",.05,.397,11)
txt("1",.55,.915,37,family="Impact")
txt("ICELAND",.60,.925,11,"bold")
txt("The breeding grounds",.60,.907,9)
txt("2",.43,.30,37,family="Impact")
txt("SOUTHBOUND",.48,.31,10,"bold")
txt("Direct autumn journeys\nin the published study",.48,.286,8)
txt("3",.56,.155,37,family="Impact")
txt("WEST AFRICA",.61,.166,10,"bold")
txt("The non-breeding season",.61,.147,8)
txt("4",.71,.69,37,family="Impact")
txt("NORTHBOUND",.77,.70,10,"bold")
txt("Most spring journeys\ninclude a stopover",.77,.676,8)
grid.lines(x=c(.05,.17),y=c(.325,.325),gp=gpar(col="#262626",lwd=2))
txt("Outbound: July\u2013September",.19,.325,8)
grid.lines(x=c(.05,.17),y=c(.304,.304),gp=gpar(col="#262626",lwd=2,lty=2))
txt("Inbound: April\u2013May",.19,.304,8)
txt("ESTIMATED SEASONAL CORRIDORS",.05,.263,8,"bold")
txt("Lines: smoothed, equal-bird seasonal mean corridor.\nShading: 95% bird-bootstrap band (1,000 resamples).\nNot individual flight paths or positional-error bounds.",.05,.229,7)
txt("19 ADULTS  /  56 MIGRATIONS",.05,.165,13,family="Impact")
txt("Study totals: 30 autumn and 26 spring migrations.\nCalendar windows here do not identify individual migration events.",.05,.13,7)
grid.lines(x=c(.045,.95),y=c(.082,.082),gp=gpar(col="#262626",lwd=.6))
txt("PAPER  Carneiro, Gunnarsson & Alves (2019)  \u00b7  doi:10.1111/jav.01938",.045,.065,6.5)
txt("DATA  Dryad, CC0  \u00b7  doi:10.5061/dryad.3kf35s5  |  Geography: Natural Earth, public domain",.045,.050,6.5)
txt("Design inspiration: Warren Davison, Drawn by Flight. Bird: AI-generated after Nozeman & Sepp (public-domain reference).",.045,.035,5.8)
txt("R-drawn map and statistical estimates. Equidistant conic projection. Raw geolocator estimates; limitations and methods accompany the data.",.045,.021,5.8)
dev.off()
write.csv(result$estimates,"research/spoi/corridor-estimates.csv",row.names=FALSE)
write.csv(result$curves,"research/spoi/corridor-curves.csv",row.names=FALSE)
writeLines(jsonlite::toJSON(result$method,auto_unbox=TRUE,pretty=TRUE),"research/spoi/corridor-method.json")
cat("Designed R poster built;",nrow(result$estimates),"supported seasonal latitude bands.\n")
print(aggregate(birds~season,result$estimates,range))
