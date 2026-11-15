# A design walkthrough: north-up exploration, then the final oblique composition.
render_spoi_breakdown <- function(con, paper, analysis, projection, colours=spoi_palette()) {
  view <- "EPSG:3857"
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
    ggplot2::theme_void()+ggplot2::theme(plot.background=ggplot2::element_rect(fill=colours$ocean,colour=NA),panel.background=ggplot2::element_rect(fill=colours$ocean,colour=NA),plot.margin=ggplot2::margin(0,0,0,0))
  save_stage <- function(fig,name){
    fig<-fig+ggplot2::coord_sf(crs=view,xlim=limits[c("xmin","xmax")],ylim=limits[c("ymin","ymax")],expand=FALSE,datum=NA)
    target_file<-file.path("previews/spoi",name);pending_file<-tempfile(tmpdir="previews/spoi",fileext=".png")
    ragg::agg_png(pending_file,width=210,height=297,units="mm",res=200,background=colours$ocean)
    print(fig);grDevices::dev.off();spoi_publish(pending_file,target_file)
  }
  save_stage(base,"build-01-map.png")

  d<-analysis$observations
  d<-d[order(d$bird_id,d$cycle,d$timestamp),]
  time<-as.numeric(as.POSIXct(d$timestamp,format="%Y-%m-%dT%H:%M:%S",tz="UTC"))
  valid<-d$display_ok==1 & is.finite(d$longitude) & is.finite(d$latitude)
  previous_valid<-c(FALSE,head(valid,-1))
  breaks<-!valid | !previous_valid | c(TRUE,diff(time)>36*3600 | diff(time)<=0) |
    c(TRUE,tail(d$bird_id,-1)!=head(d$bird_id,-1) | tail(d$cycle,-1)!=head(d$cycle,-1))
  groups<-split(which(valid),cumsum(breaks)[valid])
  groups<-groups[lengths(groups)>=2]
  tracks<-sf::st_sf(geometry=sf::st_sfc(lapply(groups,function(i)sf::st_linestring(as.matrix(d[i,c("longitude","latitude")]))),crs=4326))
  tracks<-sf::st_transform(tracks,view)
  save_stage(base+ggplot2::geom_sf(data=tracks,colour="#262626",linewidth=.22,alpha=.18),"build-02-trajectories.png")

  # The paper motivates the season contrast; intervals are this project's
  # documented exploratory assignments, not supplied per-fix paper labels.
  direction<-rep("Other",nrow(d))
  journeys<-analysis$journeys[analysis$journeys$complete==1,]
  for(i in seq_len(nrow(journeys))){
    departure<-as.numeric(as.POSIXct(journeys$departure[i],format="%Y-%m-%dT%H:%M:%S",tz="UTC"))
    arrival<-as.numeric(as.POSIXct(journeys$arrival[i],format="%Y-%m-%dT%H:%M:%S",tz="UTC"))
    if(is.finite(departure)&&is.finite(arrival))direction[d$bird_id==journeys$bird_id[i] & time>=departure & time<=arrival]<-journeys$season[i]
  }
  colour_break<-breaks | c(TRUE,tail(direction,-1)!=head(direction,-1))
  colour_groups<-split(which(valid),cumsum(colour_break)[valid]);colour_groups<-colour_groups[lengths(colour_groups)>=2]
  coloured<-do.call(rbind,lapply(colour_groups,function(i){
    season<-direction[i[1]]
    sf::st_sf(colour=if(season=="Outbound")colours$south else if(season=="Inbound")colours$north else "#262626",
      opacity=if(season=="Other").08 else .65,
      geometry=sf::st_sfc(sf::st_linestring(as.matrix(d[i,c("longitude","latitude")])),crs=4326))
  }))
  coloured<-sf::st_transform(coloured,view)
  save_stage(base+ggplot2::geom_sf(data=coloured,ggplot2::aes(colour=colour,alpha=opacity),linewidth=.35,show.legend=FALSE)+
    ggplot2::scale_colour_identity()+ggplot2::scale_alpha_identity(),"build-03-direction.png")

  curves<-DBI::dbReadTable(con,"corridor_curves")
  pieces<-split(curves,interaction(curves$season,curves$run,drop=TRUE))
  smooth<-do.call(rbind,lapply(pieces,function(q){
    q<-q[order(q$latitude),]
    sf::st_sf(colour=if(q$season[1]=="Outbound")colours$south else colours$north,
      geometry=sf::st_sfc(sf::st_linestring(as.matrix(q[,c("mean_longitude","latitude")])),crs=4326))
  }))
  smooth<-sf::st_transform(smooth,view)
  endpoints<-sf::st_sf(geometry=sf::st_sfc(unlist(lapply(sf::st_geometry(smooth),function(x)list(sf::st_point(x[1,]),sf::st_point(x[nrow(x),]))),recursive=FALSE),crs=view))
  save_stage(base+ggplot2::geom_sf(data=smooth,ggplot2::aes(colour=colour),linewidth=1.1,show.legend=FALSE)+
    ggplot2::scale_colour_identity()+ggplot2::geom_sf(data=endpoints,shape=21,fill="white",colour="#262626",size=2),"build-03-smoothing.png")

  lanes<-sf::st_transform(make_lane_geometry(analysis,projection),view)
  anchors<-sf::st_transform(sf::st_as_sf(analysis$anchors,coords=c("longitude","latitude"),crs=4326),view)
  density<-sf::st_transform(analysis$density,view)
  lane_layers<-list(
    ggplot2::geom_sf(data=lanes,ggplot2::aes(linewidth=width+.3),colour="white",show.legend=FALSE),
    ggplot2::geom_sf(data=lanes,ggplot2::aes(linewidth=width,colour=color),show.legend=FALSE),
    ggplot2::scale_linewidth_identity(),ggplot2::scale_colour_identity(),
    ggplot2::geom_sf(data=anchors,shape=21,size=2.6,fill="white",colour="#262626",stroke=.7))
  save_stage(base+lane_layers,"build-04-anchors.png")
  save_stage(base+ggplot2::geom_sf(data=density,ggplot2::aes(alpha=display_alpha),fill="#262626",colour=NA,show.legend=FALSE)+
    ggplot2::scale_alpha_identity()+lane_layers,"build-05-density.png")
  writeLines(jsonlite::toJSON(list(order=c("Map","Observed trajectories","Season-coloured observed trajectories","Archived candidate smooths","Constrained regional anchors and schematic lanes","Concentration regions","Final oblique composition","Text and illustration"),
    direction_colours="Paper motivates seasonal distinction. Colour complete candidate journey intervals from journey_journeys; outside intervals stays grey. Preserve gaps and cycle breaks; split on colour changes.",
    exploratory_view="EPSG:3857; 0–72N, A4 frame centred on 17W. Full-coverage north-up relief is cached independently in breakdown_relief.",
    final_view=projection,meaning="Design-decision sequence, not literal render-call order. The archived smooth is superseded by anchor-based links. All observed trajectories retain quality-mask, 36-hour and cycle breaks."),auto_unbox=TRUE,pretty=TRUE),"research/spoi/breakdown-method.json")
}
