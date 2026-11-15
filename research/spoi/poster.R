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
projection <- "+proj=omerc +lat_0=35 +lonc=-20 +alpha=15 +gamma=0 +k=1 +datum=WGS84 +units=m +no_defs"
xy <- function(lon,lat) st_coordinates(st_transform(st_as_sf(data.frame(lon=lon,lat=lat),coords=c("lon","lat"),crs=4326),projection))
ends <- unname(xy(c(-20.2,-15),c(63.8,11)))
width <- (ends[2,1]-ends[1,1])/.42
height <- width*1.5
bounds <- c(xmin=ends[1,1]-.29*width,xmax=ends[1,1]+.71*width,ymin=ends[2,2]-.13*height,ymax=ends[2,2]+.87*height)
source("research/spoi/cartography.R")
cartography <- prepare_poster_cartography(con,projection,bounds)
land <- cartography$land
DBI::dbDisconnect(con)
systemfonts::register_font("Jost Poster",plain="styles/fonts/Jost-Regular.ttf",bold="styles/fonts/Jost-Black.ttf",italic="styles/fonts/Jost-Italic.ttf",bolditalic="styles/fonts/Jost-BlackItalic.ttf")
relief_matrix <- as.matrix(cartography$relief,wide=TRUE)/255
relief_image <- as.raster(relief_matrix)
graticule <- st_transform(st_graticule(lon=seq(-70,40,10),lat=seq(0,80,10)),projection)
lines <- list(); ribbons <- list()
for (season in c("Outbound","Inbound")) {
  d <- result$curves[result$curves$season==season,]
  # Display the estimated corridor between the broad winter/breeding latitudes;
  # retain the complete estimate in SQLite and CSV for inspection.
  d <- d[d$latitude>=11 & d$latitude<=63.8,]
  d <- d[order(d$latitude),]
  # Do not span bins that failed the minimum-bird coverage threshold.
  groups <- d$run
  for (group in unique(groups)) {
    q <- d[groups==group,]
    if(nrow(q)<2)next
    centre <- cbind(q$mean_longitude,q$latitude)
    if (season=="Outbound") centre <- centre[nrow(centre):1,,drop=FALSE]
    ring <- rbind(cbind(q$lower,q$latitude),cbind(rev(q$upper),rev(q$latitude)),c(q$lower[1],q$latitude[1]))
    lines[[length(lines)+1]] <- st_sf(season=season,geometry=st_sfc(st_linestring(centre),crs=4326))
    ribbons[[length(ribbons)+1]] <- st_sf(season=season,geometry=st_sfc(st_polygon(list(ring)),crs=4326))
  }
}
route <- st_transform(do.call(rbind,lines),projection)
band <- st_transform(do.call(rbind,ribbons),projection)
st_geometry_shadow <- st_geometry(land) + c(16000,-16000)
shadow <- st_sf(geometry=st_geometry_shadow); st_crs(shadow)<-st_crs(land)
place <- data.frame(name=c("IRELAND","BRITAIN","FRANCE","IBERIA","MOROCCO","MAURITANIA","SENEGAL","GUINEA-BISSAU","GUINEA"),lon=c(-8,-1,2,-4,-5,-7,-13,-13,-9),lat=c(55,55,47,40,31,21,15,11.8,9))
place_xy <- xy(place$lon,place$lat);place$x<-place_xy[,1];place$y<-place_xy[,2]
anchor <- xy(c(-20.2,-8,-15),c(63.8,53.5,11))
fig <- ggplot()+
  geom_sf(data=graticule,colour="white",linewidth=.15,alpha=.45)+
  geom_sf(data=shadow,fill="#262626",colour=NA,alpha=.12)+
  geom_sf(data=land,fill="#F5F5F5",colour="white",linewidth=.25)+
  annotation_custom(grid::rasterGrob(relief_image,interpolate=TRUE),xmin=bounds["xmin"],xmax=bounds["xmax"],ymin=bounds["ymin"],ymax=bounds["ymax"])+
  geom_sf(data=band,aes(fill=season),colour=NA,alpha=.10,show.legend=FALSE)+
  scale_fill_manual(values=c(Outbound="#262626",Inbound="#ffffff"))+
  geom_sf(data=route,colour="white",linewidth=1.8,show.legend=FALSE)+
  geom_sf(data=route,aes(linetype=season),colour="#262626",linewidth=.85,arrow=grid::arrow(length=grid::unit(2,"mm"),type="closed"),show.legend=FALSE)+
  scale_linetype_manual(values=c(Outbound="solid",Inbound="22"))+
  geom_text(data=place,aes(x=x,y=y,label=name),family="Jost Poster",fontface="bold",size=2.5,colour="#262626")+
  annotate("point",x=anchor[,1],y=anchor[,2],shape=21,size=3,fill="white",colour="#262626",stroke=.7)+
  coord_sf(crs=projection,xlim=bounds[c("xmin","xmax")],ylim=bounds[c("ymin","ymax")],expand=FALSE,datum=NA)+
  theme_void()+theme(plot.background=element_rect(fill="#2DD2C0",colour=NA),panel.background=element_rect(fill="#2DD2C0",colour=NA),plot.margin=margin(0,0,0,0))
dir.create("previews/spoi",recursive=TRUE,showWarnings=FALSE)
ragg::agg_png("previews/spoi/poster.png",width=1200,height=1800,res=150,background="#2DD2C0")
print(fig)
library(grid)
txt <- function(label,x,y,size=12,face="plain",family="Jost Poster",colour="#262626",just="left") grid.text(label,x=x,y=y,just=just,gp=gpar(fontfamily=family,fontsize=size,fontface=face,col=colour))
leader <- function(x,y) grid.lines(x=x,y=y,gp=gpar(col="#262626",lwd=.8))
npc <- function(point) c((point[1]-bounds["xmin"])/diff(bounds[c("xmin","xmax")]),(point[2]-bounds["ymin"])/diff(bounds[c("ymin","ymax")]))
ice <- npc(anchor[1,]); ireland <- npc(anchor[2,]); africa <- npc(anchor[3,])
txt("52 / HIDEF MAPS",.035,.977,12,"bold")
txt("Maps defined by Dr Helga Ingimundard\u00f3ttir",.035,.957,6.5)
image <- png::readPNG("research/illustrations/spoi-flight-ai.png")
grid.raster(image,x=.30,y=.77,width=.57,interpolate=TRUE)
txt("SP\u00d3I",.04,.575,98,"bold")
txt("SUMMERS IN ICELAND",.045,.495,19,"bold")
txt("\u2248 3 months of summer vacation",.045,.464,10.5,"bold")
txt("Numenius phaeopus islandicus",.045,.441,9,"italic")
txt("Chicks hatch in Iceland.\nAdults winter farther south.",.045,.406,10)
txt("1",.42,.943,38,"bold")
txt("ICELAND",.49,.950,12,"bold")
txt("The breeding grounds",.49,.929,9)
leader(c(.41,.39,ice[1]+.04,ice[1]+.012),c(.94,.94,ice[2]+.012,ice[2]+.002))
txt("4",.70,.895,38,"bold")
txt("SPRING",.77,.904,12,"bold")
txt("Most journeys\ninclude a stopover",.77,.873,9)
leader(c(.72,.70,ireland[1]+.012),c(.857,.84,ireland[2]+.01))
# Pale study card, with the clipped corner of the reference design.
grid.polygon(x=c(.035,.345,.345,.315,.035),y=c(.359,.359,.272,.258,.258),gp=gpar(fill=grDevices::adjustcolor("white",alpha.f=.80),col=NA))
txt("19 birds \u00b7 56 migrations",.05,.338,12,"bold")
txt("Tracked adults in the study.\n13 males and 6 females.",.05,.307,9)
txt("2",.37,.346,38,"bold")
txt("AUTUMN",.44,.355,11,"bold")
txt("Direct journeys\nto West Africa",.44,.323,8.5)
txt("3",.40,.166,38,"bold")
txt("WEST AFRICA",.47,.177,12,"bold")
txt("The non-breeding\nseason",.47,.145,9)
leader(c(.64,.67,africa[1]-.012),c(.15,.15,africa[2]+.004))
leader(c(.04,.35),c(.222,.222))
grid.lines(x=c(.04,.12),y=c(.202,.202),gp=gpar(col="#262626",lwd=2))
txt("Outbound seasonal mean",.15,.202,8.5)
grid.lines(x=c(.04,.12),y=c(.180,.180),gp=gpar(col="#262626",lwd=2,lty=2))
txt("Inbound seasonal mean",.15,.180,8.5)
txt("Smoothed candidate corridors. Shading: 95% bird-bootstrap bands.\nNot individual flight paths or positional-error bounds.",.04,.113,6.6,"italic")
leader(c(.035,.95),c(.088,.088))
txt("PAPER  Carneiro, Gunnarsson & Alves (2019)  |  doi:10.1111/jav.01938",.035,.072,6.5)
txt("DATA  Dryad, CC0  |  doi:10.5061/dryad.3kf35s5",.035,.057,6.5)
txt("Geography & shaded relief: Natural Earth, public domain. Projection: oblique Mercator.",.035,.043,6)
txt("Design inspiration: Warren Davison, Drawn by Flight. Bird: AI-generated after Nozeman & Sepp (KB, public-domain reference).",.035,.029,5.5)
txt("R-drawn geography, layout and estimates. 1,000 bird-level bootstrap resamples; source, fonts and methods supplied.",.035,.016,5.5)
dev.off()
# A LinkedIn-sized companion preserves the reference poster's proportions.
ragg::agg_png("previews/spoi/poster-linkedin.png",width=1200,height=1500,res=150,background="#2DD2C0")
grid.newpage()
grid.raster(png::readPNG("previews/spoi/poster.png"),x=.5,y=.5,width=5/6,height=1,interpolate=TRUE)
dev.off()
write.csv(result$estimates,"research/spoi/corridor-estimates.csv",row.names=FALSE)
write.csv(result$curves,"research/spoi/corridor-curves.csv",row.names=FALSE)
writeLines(jsonlite::toJSON(result$method,auto_unbox=TRUE,pretty=TRUE),"research/spoi/corridor-method.json")
cat("Designed R poster built;",nrow(result$estimates),"supported seasonal latitude bands.\n")
print(aggregate(birds~season,result$estimates,range))
