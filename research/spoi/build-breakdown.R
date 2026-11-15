# A nine-panel design walkthrough. Panels 1-7 use a north-up Mercator view;
# panels 8-9 are the oblique poster exports written by poster-layout.R.
# Story 1 (panels 2-6): extract meaningful migration journeys from tracking data.
# Story 2 (panels 7-9): turn those journeys into a readable map.
render_spoi_breakdown <- function(con, paper, analysis, projection, colours=spoi_palette()) {
  view <- "EPSG:3857"
  ink <- "#262626"
  top <- unname(sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(c(-17,72)),crs=4326),view))[1,])
  height <- top[2];width <- height*210/297
  limits <- c(xmin=top[1]-width/2,xmax=top[1]+width/2,ymin=0,ymax=height)
  land <- sf::st_transform(paper$land,view)
  target <- terra::rast(ncols=600,nrows=849,xmin=limits["xmin"],xmax=limits["xmax"],ymin=0,ymax=height,crs=view)
  # The tilted poster cache does not cover every corner of a north-up view.
  # Cache this view independently from the original full-coverage source raster.
  cache_key<-"gray-earth-50m-northup-mercator-a4-grey-v2"
  matching<-FALSE
  if(DBI::dbExistsTable(con,"breakdown_relief")){
    cached<-DBI::dbReadTable(con,"breakdown_relief")
    metadata<-jsonlite::fromJSON(cached$metadata_json[1])
    matching<-cached$name[1]==cache_key && max(abs(unlist(metadata$bounds)-limits))<.001
  }
  if(!matching){
    path<-normalizePath("data/raw/spoi/GRAY_50M_SR_W.zip",winslash="/",mustWork=TRUE)
    source_raster<-terra::rast(paste0("/vsizip/",path,"/GRAY_50M_SR_W.tif"))
    source_raster<-terra::crop(source_raster,terra::ext(-70,40,-10,80))
    relief<-terra::project(source_raster,target,method="bilinear")
    relief<-terra::mask(relief,terra::vect(land))
    relief<-round(190+55*terra::clamp(relief,lower=0,upper=255)/255)
    raster_file<-tempfile(fileext=".tif")
    terra::writeRaster(relief,raster_file,datatype="INT1U",NAflag=0,gdal=c("COMPRESS=DEFLATE"),overwrite=TRUE)
    metadata_json<-jsonlite::toJSON(list(source="https://naciscdn.org/naturalearth/50m/raster/GRAY_50M_SR_W.zip",licence="Public domain",retrieved="2026-11-15",source_md5=unname(tools::md5sum(path)),projection=view,bounds=as.list(limits),width=600,height=849,method="Project full source coverage to north-up frame, mask to Natural Earth land, remap grey to 190–245"),auto_unbox=TRUE)
    DBI::dbWriteTable(con,"breakdown_relief",data.frame(name=cache_key,tif=I(list(readBin(raster_file,"raw",n=file.info(raster_file)$size))),metadata_json=metadata_json),overwrite=TRUE)
  }else{
    raster_file<-tempfile(fileext=".tif");writeBin(cached$tif[[1]],raster_file);relief<-terra::rast(raster_file)
  }
  graticule <- sf::st_transform(sf::st_graticule(lon=seq(-70,40,10),lat=seq(0,80,10)),view)
  base <- ggplot2::ggplot()+
    ggplot2::geom_sf(data=graticule,colour="white",linewidth=.15,alpha=.45)+
    ggplot2::geom_sf(data=land,fill="#F5F5F5",colour="white",linewidth=.25)+
    ggplot2::annotation_custom(grid::rasterGrob(as.raster(as.matrix(relief,wide=TRUE)/255),interpolate=TRUE),xmin=limits["xmin"],xmax=limits["xmax"],ymin=0,ymax=height)+
    ggplot2::scale_colour_identity()+ggplot2::scale_alpha_identity()+ggplot2::scale_linewidth_identity()+
    ggplot2::theme_void()+ggplot2::theme(plot.background=ggplot2::element_rect(fill=colours$ocean,colour=NA),panel.background=ggplot2::element_rect(fill=colours$ocean,colour=NA),plot.margin=ggplot2::margin(0,0,0,0))
  frame <- function(fig,xlim=limits[c("xmin","xmax")])
    fig+ggplot2::coord_sf(crs=view,xlim=xlim,ylim=limits[c("ymin","ymax")],expand=FALSE,datum=NA)
  publish_png <- function(name,draw){
    target_file<-file.path("previews/spoi",name);pending_file<-tempfile(tmpdir="previews/spoi",fileext=".png")
    ragg::agg_png(pending_file,width=210,height=297,units="mm",res=200,background=colours$ocean)
    draw();grDevices::dev.off();spoi_publish(pending_file,target_file)
  }
  save_stage <- function(fig,name) publish_png(name,function()print(frame(fig)))

  # 1. Geographic canvas only.
  save_stage(base,"build-01-map.png")

  # Shared observation table: quality mask, 36-hour gaps and bird/cycle changes break lines.
  d<-analysis$observations
  d<-d[order(d$bird_id,d$cycle,d$timestamp),]
  time<-as.numeric(as.POSIXct(d$timestamp,format="%Y-%m-%dT%H:%M:%S",tz="UTC"))
  valid<-d$display_ok==1 & is.finite(d$longitude) & is.finite(d$latitude)
  previous_valid<-c(FALSE,head(valid,-1))
  breaks<-!valid | !previous_valid | c(TRUE,diff(time)>36*3600 | diff(time)<=0) |
    c(TRUE,tail(d$bird_id,-1)!=head(d$bird_id,-1) | tail(d$cycle,-1)!=head(d$cycle,-1))
  # Build linestrings from runs of rows that share a key and are not broken.
  lines_by <- function(key,keep=valid){
    run_break<-breaks | c(TRUE,tail(key,-1)!=head(key,-1)) | !keep | !c(FALSE,head(keep,-1))
    groups<-split(which(keep),cumsum(run_break)[keep]);groups<-groups[lengths(groups)>=2]
    if(!length(groups))return(NULL)
    sf::st_transform(sf::st_sf(key=vapply(groups,function(i)key[i[1]],character(1)),
      geometry=sf::st_sfc(lapply(groups,function(i)sf::st_linestring(as.matrix(d[i,c("longitude","latitude")]))),crs=4326)),view)
  }
  tracks<-lines_by(rep("all",nrow(d)))
  track_layer<-function(alpha=.18)ggplot2::geom_sf(data=tracks,colour=ink,linewidth=.22,alpha=alpha)

  # 2. Every displayable estimate: migrations and local movements alike.
  save_stage(base+track_layer(),"build-02-trajectories.png")

  # 3. Where birds spend time: equal-bird-weight kernel concentration regions.
  density<-sf::st_transform(analysis$density,view)
  density_layer<-function(scale=1)ggplot2::geom_sf(data=density,ggplot2::aes(alpha=display_alpha*scale),fill=ink,colour=NA,show.legend=FALSE)
  save_stage(base+density_layer(),"build-03-regions.png")

  # 4. Regions over the original trajectories, with their land-constrained anchors.
  anchors<-sf::st_transform(sf::st_as_sf(analysis$anchors,coords=c("longitude","latitude"),crs=4326),view)
  anchor_layer<-ggplot2::geom_sf(data=anchors,shape=21,size=2.6,fill="white",colour=ink,stroke=.7)
  save_stage(base+track_layer(.14)+density_layer()+anchor_layer,"build-04-anchors.png")

  # 5. Seasonal migration events from timestamps and regions (still uncoloured).
  journeys<-analysis$journeys[analysis$journeys$complete==1,]
  departure<-as.numeric(as.POSIXct(journeys$departure,format="%Y-%m-%dT%H:%M:%S",tz="UTC"))
  arrival<-as.numeric(as.POSIXct(journeys$arrival,format="%Y-%m-%dT%H:%M:%S",tz="UTC"))
  journey_of<-rep(NA_character_,nrow(d));season_of<-rep(NA_character_,nrow(d))
  for(i in seq_len(nrow(journeys))){
    inside<-d$bird_id==journeys$bird_id[i] & time>=departure[i] & time<=arrival[i]
    journey_of[inside]<-journeys$journey_id[i];season_of[inside]<-journeys$season[i]
  }
  stops<-if(!is.null(analysis$stops))analysis$stops else DBI::dbReadTable(con,"journey_stops")
  at_stop<-rep(FALSE,nrow(d))
  for(i in seq_len(nrow(stops))){
    first<-as.numeric(as.POSIXct(stops$first[i],format="%Y-%m-%dT%H:%M:%S",tz="UTC"))
    last<-as.numeric(as.POSIXct(stops$last[i],format="%Y-%m-%dT%H:%M:%S",tz="UTC"))
    at_stop[d$bird_id==stops$bird_id[i] & time>=first & time<=last]<-TRUE
  }
  in_journey<-valid & !is.na(journey_of)
  migration<-lines_by(ifelse(is.na(journey_of),"",journey_of),in_journey)
  # Event markers: the first and last displayable estimate inside each journey interval.
  ends<-do.call(rbind,lapply(split(which(in_journey),journey_of[in_journey]),function(i)
    data.frame(event=c("Departure","Arrival"),longitude=d$longitude[i[c(1,length(i))]],latitude=d$latitude[i[c(1,length(i))]])))
  ends<-sf::st_transform(sf::st_as_sf(ends,coords=c("longitude","latitude"),crs=4326),view)
  stop_points<-sf::st_transform(sf::st_as_sf(stops,coords=c("longitude","latitude"),crs=4326),view)
  save_stage(base+track_layer(.07)+density_layer(.6)+
    ggplot2::geom_sf(data=migration,colour=ink,linewidth=.3,alpha=.55)+
    ggplot2::geom_sf(data=stop_points,shape=22,size=1.8,fill="white",colour=ink,stroke=.5)+
    ggplot2::geom_sf(data=ends[ends$event=="Departure",],shape=21,size=1.3,fill="white",colour=ink,stroke=.5)+
    ggplot2::geom_sf(data=ends[ends$event=="Arrival",],shape=21,size=1.3,fill=ink,colour="white",stroke=.3)+
    anchor_layer,"build-05-events.png")

  # 6. Keep only travelling estimates inside journeys; drop extended stays; colour by season.
  travelling<-in_journey & !at_stop
  extracted<-lines_by(ifelse(is.na(journey_of),"",paste(journey_of,season_of)),travelling)
  extracted$colour<-ifelse(grepl("Outbound$",extracted$key),colours$south,colours$north)
  journey_layer<-function(alpha=.85,width=.45)ggplot2::geom_sf(data=extracted,ggplot2::aes(colour=colour),linewidth=width,alpha=alpha)
  save_stage(base+density_layer(.6)+journey_layer()+anchor_layer,"build-06-journeys.png")

  # 7. Two smoothing approaches, side by side. A is carried into panels 8 and 9.
  lanes<-sf::st_transform(make_lane_geometry(analysis,projection),view)
  bezier<-list(
    ggplot2::geom_sf(data=lanes,ggplot2::aes(linewidth=width+.3),colour="white",show.legend=FALSE),
    ggplot2::geom_sf(data=lanes,ggplot2::aes(linewidth=width,colour=color),show.legend=FALSE))
  # B: smooth each extracted journey, then summarise the season with equal bird weight.
  p<-d[travelling,];p$t<-time[travelling]/86400;p$journey<-journey_of[travelling];p$season<-season_of[travelling]
  journey_smooth<-do.call(rbind,lapply(split(p,p$journey),function(q){
    q<-q[order(q$t),];if(nrow(q)<8)return(NULL)
    grid_t<-seq(min(q$t),max(q$t),length.out=60)
    lon<-stats::predict(stats::smooth.spline(q$t,q$longitude,spar=.8),grid_t)$y
    lat<-stats::predict(stats::smooth.spline(q$t,q$latitude,spar=.8),grid_t)$y
    data.frame(journey=q$journey[1],bird_id=q$bird_id[1],season=q$season[1],step=seq_along(grid_t),longitude=lon,latitude=lat)
  }))
  bins<-seq(0,72,by=2)
  p$bin<-bins[findInterval(p$latitude,bins)]+1
  per_journey<-stats::aggregate(longitude~journey+bird_id+season+bin,p,stats::median)
  per_bird<-stats::aggregate(longitude~bird_id+season+bin,per_journey,mean)
  per_season<-merge(stats::aggregate(longitude~season+bin,per_bird,mean),
    stats::aggregate(cbind(birds=bird_id)~season+bin,per_bird,function(x)length(unique(x))))
  per_season<-per_season[per_season$birds>=3,]
  season_smooth<-do.call(rbind,lapply(split(per_season,per_season$season),function(q){
    q<-q[order(q$bin),];grid_lat<-seq(min(q$bin),max(q$bin),by=.25)
    fit<-stats::smooth.spline(q$bin,q$longitude,w=q$birds,spar=.65)
    data.frame(season=q$season[1],latitude=grid_lat,longitude=stats::predict(fit,grid_lat)$y,
      birds=stats::approx(q$bin,q$birds,grid_lat)$y)
  }))
  to_lines<-function(x,id){
    pieces<-split(x,x[[id]])
    sf::st_transform(sf::st_sf(season=vapply(pieces,function(q)q$season[1],character(1)),
      geometry=sf::st_sfc(lapply(pieces,function(q)sf::st_linestring(as.matrix(q[,c("longitude","latitude")]))),crs=4326)),view)
  }
  smooth_journeys<-to_lines(journey_smooth,"journey")
  smooth_seasons<-to_lines(season_smooth,"season")
  for(z in c("smooth_journeys","smooth_seasons")){x<-get(z);x$colour<-ifelse(x$season=="Outbound",colours$south,colours$north);assign(z,x)}
  season_ends<-do.call(rbind,lapply(split(season_smooth,season_smooth$season),function(q)q[c(1,nrow(q)),]))
  season_ends<-sf::st_transform(sf::st_as_sf(season_ends,coords=c("longitude","latitude"),crs=4326),view)
  data_driven<-list(
    ggplot2::geom_sf(data=smooth_journeys,ggplot2::aes(colour=colour),linewidth=.3,alpha=.45),
    ggplot2::geom_sf(data=smooth_seasons,colour="white",linewidth=1.9),
    ggplot2::geom_sf(data=smooth_seasons,ggplot2::aes(colour=colour),linewidth=1.4),
    ggplot2::geom_sf(data=season_ends,shape=21,fill="white",colour=ink,size=1.8))
  half<-width/4;xlim<-c(top[1]-half,top[1]+half)
  pane<-function(layers)frame(base+density_layer()+layers+anchor_layer,xlim)
  label<-function(title,detail,x){
    grid::grid.rect(x=x,y=.965,width=.47,height=.05,gp=grid::gpar(fill="white",col=NA,alpha=.9))
    grid::grid.text(title,x=x-.225,y=.975,just="left",gp=grid::gpar(fontfamily="Jost Poster",fontface="bold",fontsize=12,col=ink))
    grid::grid.text(detail,x=x-.225,y=.952,just="left",gp=grid::gpar(fontfamily="Jost Poster",fontsize=7.5,col=ink))
  }
  publish_png("build-07-smoothing.png",function(){
    print(pane(bezier),vp=grid::viewport(x=.25,width=.5))
    print(pane(data_driven),vp=grid::viewport(x=.75,width=.5))
    grid::grid.lines(x=c(.5,.5),y=c(0,1),gp=grid::gpar(col="white",lwd=3))
    label("A  Bézier anchors (selected)","Fixed regional endpoints; carried into panels 8–9",.25)
    label("B  Data-driven smoothing","Smoothed journeys and seasonal means",.75)
  })
  utils::write.csv(season_smooth,"research/spoi/breakdown-smoothing.csv",row.names=FALSE)

  writeLines(jsonlite::toJSON(list(
    order=c("Start with the map","Plot all trajectories","Identify concentration regions","Add the geographic anchors",
      "Identify seasonal migration events","Extract and colour migration journeys","Smooth the migration routes",
      "Tilt the composition","Tell the story"),
    files=c("build-01-map.png","build-02-trajectories.png","build-03-regions.png","build-04-anchors.png",
      "build-05-events.png","build-06-journeys.png","build-07-smoothing.png","poster-lanes.png","poster.png"),
    groups=list(`Geographic foundation`=1,`Explore the tracking data`=2:4,`Isolate seasonal migration`=5:6,
      `Simplify the trajectories`=7,`Compose and communicate`=8:9),
    seasonal_colour="Introduced at panel 6 only. Orange: southbound autumn (Outbound); magenta: northbound spring (Inbound).",
    events="Complete candidate journeys from journey_journeys (departure-arrival); candidate stops from journey_stops. Departure/arrival markers are the first/last displayable estimate inside each interval.",
    extraction="Displayable estimates inside complete journey intervals, excluding estimates inside candidate stop intervals. Quality-mask, 36-hour, cycle and stop breaks are preserved.",
    smoothing=list(selected="A: cubic Bezier links between land-constrained regional anchors (make_lane_geometry)",
      A="Endpoints fixed at regional anchors; bends are design choices; widths scale with journey counts.",
      B=paste("Per journey: smooth.spline (spar 0.8) of longitude and latitude against time, 60 steps, journeys with at least 8 travelling estimates.",
        "Per season: median longitude per journey in 2-degree latitude bins, mean within bird, equal bird weight, at least 3 birds, weighted smooth.spline (spar 0.65); written to breakdown-smoothing.csv."),
      reason="B follows the data but its seasonal means stop where bin support ends and average divergent spring routes into one line; A keeps meaningful endpoints and separates the spring lanes."),
    exploratory_view="EPSG:3857; 0–72N, A4 frame centred on 17W. Panel 7 panes are half-width crops of the same frame. Full-coverage north-up relief is cached independently in breakdown_relief.",
    final_view=projection,
    meaning="Design-decision sequence, not literal render-call order."),auto_unbox=TRUE,pretty=TRUE),"research/spoi/breakdown-method.json")
}
