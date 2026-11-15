# Shared layout: only the strings differ between English and Icelandic exports.
poster_words <- function(language) {
  if(language=="is")list(title="SP\u00d3I",title_size=82,subtitle="SUMAR \u00c1 \u00cdSLANDI",
    author="Kort skilgreind af Dr. Helgu Ingimundard\u00f3ttur",biology="Ungarnir klekjast \u00fat \u00e1 \u00cdslandi.\nFullor\u00f0nu fuglarnir dvelja sunnar \u00e1 veturna.",
    iceland="\u00cdSLAND",breeding="Varpsv\u00e6\u00f0i",spring="VOR",autumn="HAUST",africa="VESTUR-AFR\u00cdKA",winter="Vetrardv\u00f6l",
    study="19 fuglar \u00b7 56 fer\u00f0ir",adults="Litlir m\u00e6lar \u00e1 f\u00f3tum fuglanna\nhj\u00e1lpu\u00f0u a\u00f0 rekja fer\u00f0ir \u00feeirra.",
    south="Um 4\u20135 dagar su\u00f0ur",south_detail="Skynjaramat \u00b7 28 t\u00edmasettar fer\u00f0ir",lanes="VORFER\u00d0IR \u00b7 n = 26",lane_note="Breidd l\u00ednu s\u00fdnir hlutfall fer\u00f0a.",
    direct="Beint",Ireland="\u00cdrland",`United Kingdom`="Bretland",France="Frakkland",Portugal="Port\u00fagal",Unresolved="\u00d3v\u00eds sta\u00f0setning",
    day="d.",via="fer\u00f0",stop="vi\u00f0dv\u00f6l",untimed="T\u00edmalengd \u00f3viss",timed="t\u00edmasettar",unresolved="1/26 fer\u00f0: \u00f3v\u00eds vi\u00f0komusta\u00f0ur (4%).",
    breeding_key="Varp",stop_key="Vi\u00f0koma",winter_key="Vetrardv\u00f6l",density="Dekkri kjarnar: meiri \u00fe\u00e9ttleiki \u00e1\u00e6tla\u00f0ra sta\u00f0setninga.",
    caveat="T\u00edmar eru n\u00e1munda\u00f0ar \u00e1\u00e6tlanir \u00far g\u00f6gnunum; fer\u00f0at\u00edmi er me\u00f0 vi\u00f0komum.\nL\u00ednurnar tengja sv\u00e6\u00f0i og s\u00fdna ekki n\u00e1kv\u00e6ma flugsl\u00f3\u00f0a. N\u00e1nari fyrirvarar \u00ed grein.",
    source="GREIN",data="G\u00d6GN",geography="Land og h\u00e6\u00f0askuggar: Natural Earth, almannaeign. Sk\u00e1sni\u00f0 Mercators.",
    credit="Fuglamynd: gervigreind eftir Nozeman & Sepp. Upprunaleg mynd \u00ed almannaeign; heimildir og fyrirm\u00e6li \u00ed grein.",
    method="Gert \u00ed R \u00far opnum g\u00f6gnum. A\u00f0fer\u00f0, \u00f3vissa og lei\u00f0beiningar um endurger\u00f0 \u00ed grein.")
  else list(title="WHIMBREL",title_size=34,subtitle="SUMMERS IN ICELAND",
    author="Maps defined by Dr Helga Ingimundard\u00f3ttir",biology="Chicks hatch in Iceland.\nAdults winter farther south.",
    iceland="ICELAND",breeding="Breeding grounds",spring="SPRING",autumn="AUTUMN",africa="WEST AFRICA",winter="Non-breeding season",
    study="19 birds \u00b7 56 migrations",adults="Tiny leg-mounted loggers helped\nresearchers follow their journeys.",south="About 4\u20135 days south",south_detail="Sensor estimates \u00b7 28 timed journeys",
    lanes="SPRING JOURNEYS \u00b7 n = 26",lane_note="Spring band width shows journey share.",
    direct="Direct",Ireland="Ireland",`United Kingdom`="United Kingdom",France="France",Portugal="Portugal",Unresolved="Unresolved location",
    day="d",via="journey",stop="stopped",untimed="Timing unresolved",timed="timed",unresolved="1/26 journeys: unresolved stop country (4%).",
    breeding_key="Breeding",stop_key="Stopover",winter_key="Non-breeding",density="Darker cores: greater concentration of location estimates.",
    caveat="Rounded estimates from tracking data; journey time includes stops.\nLines link regions, not exact flight paths. Further limitations in the write-up.",
    source="PAPER",data="DATA",geography="Geography & shaded relief: Natural Earth, public domain. Projection: oblique Mercator.",
    credit="Bird illustration: AI after Nozeman & Sepp, public-domain reference. Original, prompt and provenance in the write-up.",
    method="Made in R from open data. Methods, uncertainty and reproduction in the write-up.")
}

poster_story_facts <- function(analysis) {
  j<-analysis$journeys
  j<-j[j$complete==1 & j$timing_method=="Local sensor change points",]
  day<-function(x)as.numeric(as.POSIXct(x,format="%Y-%m-%dT%H:%M:%S",tz="UTC"))/86400
  stays<-function(winter=FALSE){
    start<-j[j$season==if(winter)"Outbound" else "Inbound",]
    end<-j[j$season==if(winter)"Inbound" else "Outbound",]
    start$pair_year<-start$year+as.integer(winter);end$pair_year<-end$year
    pairs<-merge(start,end,by=c("bird_id","pair_year"),suffixes=c("_start","_end"))
    pairs$days<-day(pairs$departure_end)-day(pairs$arrival_start)
    pairs<-pairs[pairs$days>(if(winter)90 else 20) & pairs$days<(if(winter)330 else 180),]
    per_bird<-aggregate(days~bird_id,pairs,mean)
    data.frame(region=if(winter)"West Africa" else "Iceland",mean_days=mean(per_bird$days),
      mean_months=mean(per_bird$days)/30.4375,birds=nrow(per_bird),paired_stays=nrow(pairs))
  }
  residence<-rbind(stays(),stays(TRUE))
  q<-analysis$summary
  ireland<-q[q$season=="Inbound" & q$lane=="Ireland",]
  direct<-q[q$season=="Inbound" & q$lane=="Direct",]
  south<-q[q$season=="Outbound",]
  list(residence=residence,summer_months=round(residence$mean_months[residence$region=="Iceland"]),
    winter_months=round(residence$mean_months[residence$region=="West Africa"]),
    south_days=weighted.mean(south$mean_elapsed_days,south$timed_journeys,na.rm=TRUE),
    ireland_stop_days=round(ireland$mean_stopover_days),ireland_journey_days=round(ireland$mean_elapsed_days),
    direct_home_days=round(direct$mean_elapsed_days),ireland_share=ireland$percent)
}

spoi_palette <- function() {
  ocean<-"#2DD2C0";hue<-rgb2hsv(col2rgb(ocean))[1]
  # The two neighbours of teal's RGB complement, +/-30 degrees from it.
  list(ocean=ocean,south=hsv((hue+210/360)%%1,.70,.82),north=hsv((hue+150/360)%%1,.55,.65),
    legend="Orange southbound; magenta northbound.",
    legend_is="Appels\u00ednugult su\u00f0urflug; fj\u00f3lubleikt nor\u00f0urflug.",
    relationship="RGB split-complementary: route hues at teal +210 and +150 degrees; adjusted saturation/value. Not restricted to the HI route palette.")
}

make_lane_geometry <- function(analysis,projection,colours=spoi_palette()) {
  a<-analysis$anchors
  point<-function(name){z<-a[a$region==name,];sf::st_coordinates(sf::st_transform(sf::st_as_sf(z,coords=c("longitude","latitude"),crs=4326),projection))[1,]}
  ice<-point("Iceland");africa<-point("West Africa")
  # Cubic interpolation is design geometry, never presented as measured tracks.
  segment<-function(start,end,bend=0) {
    t<-seq(0,1,length.out=80);delta<-end-start;perp<-c(-delta[2],delta[1]);perp<-perp/sqrt(sum(perp^2))*bend
    c1<-start+delta/3+perp;c2<-start+delta*2/3+perp
    outer((1-t)^3,start)+outer(3*(1-t)^2*t,c1)+outer(3*(1-t)*t^2,c2)+outer(t^3,end)
  }
  out<-list(sf::st_sf(season="Outbound",lane="Southbound",journeys=30,percent=100,width=30*.13,color=colours$south,count_source="Published paper: 30 direct autumn migrations",
    geometry=sf::st_sfc(sf::st_linestring(segment(ice,africa,-270000)),crs=projection)))
  q<-analysis$summary[analysis$summary$season=="Inbound",]
  for(i in seq_len(nrow(q))) {
    if(q$lane[i]=="Direct")path<-segment(africa,ice,70000)
    else if(q$lane[i] %in% a$region) {
      stop<-point(q$lane[i]);path<-rbind(segment(africa,stop,-85000),segment(stop,ice,-65000)[-1,])
    } else next
    out[[length(out)+1]]<-sf::st_sf(season="Inbound",lane=q$lane[i],journeys=q$journeys[i],percent=q$percent[i],width=q$journeys[i]*.13,color=colours$north,count_source="Exploratory classification of 26 complete spring journeys",
      geometry=sf::st_sfc(sf::st_linestring(path),crs=projection))
  }
  do.call(rbind,out)
}

render_spoi_poster <- function(analysis,cartography,projection,bounds,language="en",colours=spoi_palette(),tag="",linkedin=TRUE,mode="poster") {
  w<-poster_words(language);land<-cartography$land;a<-analysis$anchors;facts<-poster_story_facts(analysis)
  xy<-function(lon,lat)sf::st_coordinates(sf::st_transform(sf::st_as_sf(data.frame(lon,lat),coords=c("lon","lat"),crs=4326),projection))
  anchors<-sf::st_transform(sf::st_as_sf(a,coords=c("longitude","latitude"),crs=4326),projection)
  lanes<-make_lane_geometry(analysis,projection,colours)
  lanes$halo<-ifelse(tolower(lanes$color)=="#ffffff","#515151","#ffffff")
  graticule<-sf::st_transform(sf::st_graticule(lon=seq(-70,40,10),lat=seq(0,80,10)),projection)
  shadow<-sf::st_sf(geometry=sf::st_geometry(land)+c(16000,-16000));sf::st_crs(shadow)<-sf::st_crs(land)
  den<-analysis$density
  # Quiet monochrome regions: concentration and contributing bird count control alpha.
  den$shade<-den$display_alpha;den$fill<-"#262626"
  fig<-ggplot2::ggplot()+
    ggplot2::geom_sf(data=graticule,colour="white",linewidth=.15,alpha=.45)+
    ggplot2::geom_sf(data=shadow,fill="#262626",colour=NA,alpha=.12)+
    ggplot2::geom_sf(data=land,fill="#F5F5F5",colour="white",linewidth=.25)+
    ggplot2::annotation_custom(grid::rasterGrob(as.raster(as.matrix(cartography$relief,wide=TRUE)/255),interpolate=TRUE),xmin=bounds["xmin"],xmax=bounds["xmax"],ymin=bounds["ymin"],ymax=bounds["ymax"])+
    ggplot2::geom_sf(data=den,ggplot2::aes(fill=fill,alpha=shade),colour=NA,show.legend=FALSE)+
    ggplot2::scale_fill_identity()+ggplot2::scale_alpha_identity()+
    ggplot2::geom_sf(data=lanes,ggplot2::aes(linewidth=width+.3,colour=halo),show.legend=FALSE)+
    ggplot2::geom_sf(data=lanes,ggplot2::aes(linewidth=width,colour=color),alpha=1,arrow=grid::arrow(length=grid::unit(1.8,"mm"),type="closed"),show.legend=FALSE)+
    ggplot2::scale_linewidth_identity()+ggplot2::scale_colour_identity()+
    ggplot2::geom_sf(data=anchors,shape=21,size=2.6,fill="white",colour="#262626",stroke=.7)+
    ggplot2::coord_sf(crs=projection,xlim=bounds[c("xmin","xmax")],ylim=bounds[c("ymin","ymax")],expand=FALSE,datum=NA)+
    ggplot2::theme_void()+ggplot2::theme(plot.background=ggplot2::element_rect(fill=colours$ocean,colour=NA),panel.background=ggplot2::element_rect(fill=colours$ocean,colour=NA),plot.margin=ggplot2::margin(0,0,0,0))
  if(mode %in% c("background","overview","observed"))fig$layers<-fig$layers[seq_len(4)]
  if(mode=="regions")fig$layers<-fig$layers[seq_len(5)]
  if(mode=="observed"){
    observed<-analysis$observations[analysis$observations$display_ok==1,]
    observed<-sf::st_transform(sf::st_as_sf(observed,coords=c("longitude","latitude"),crs=4326),projection)
    fig<-fig+ggplot2::geom_sf(data=observed,size=.22,alpha=.14,colour="#262626")+
      ggplot2::coord_sf(crs=projection,xlim=bounds[c("xmin","xmax")],ylim=bounds[c("ymin","ymax")],expand=FALSE,datum=NA)
  }
  suffix<-if(language=="is")"-is" else ""
  file<-paste0("previews/spoi/poster",suffix,tag,".png")
  ragg::agg_png(file,width=1200,height=1800,res=150,background=colours$ocean);print(fig)
  if(mode %in% c("background","observed","regions","lanes")) {grDevices::dev.off();return(invisible(file))}
  txt<-function(label,x,y,size=12,face="plain",just="left")grid::grid.text(label,x=x,y=y,just=just,gp=grid::gpar(fontfamily="Jost Poster",fontsize=size,fontface=face,col="#262626"))
  leader<-function(x,y)grid::grid.lines(x=x,y=y,gp=grid::gpar(col="#262626",lwd=.8))
  npc<-function(point)c((point[1]-bounds["xmin"])/diff(bounds[c("xmin","xmax")]),(point[2]-bounds["ymin"])/diff(bounds[c("ymin","ymax")]))
  ap<-sf::st_coordinates(anchors); ice<-npc(ap[a$region=="Iceland",]);africa<-npc(ap[a$region=="West Africa",])
  txt("52 / HIDEF MAPS",.035,.977,12,"bold");txt(w$author,.035,.957,6.5)
  grid::grid.raster(png::readPNG("research/illustrations/images/spoi-flight-ai.png"),x=.25,y=if(language=="en").60 else .64,width=.46,interpolate=TRUE)
  text_width<-function(label,size)grid::convertWidth(grid::grobWidth(grid::textGrob(label,gp=grid::gpar(fontfamily="Jost Poster",fontface="bold",fontsize=size))),"inches",valueOnly=TRUE)
  subtitle_width<-text_width(w$subtitle,19)
  title_size<-w$title_size*subtitle_width/text_width(w$title,w$title_size)
  title_width<-text_width(w$title,title_size)
  name_y<-if(language=="en").475 else .515
  title_height<-grid::convertHeight(grid::grobHeight(grid::textGrob(w$title,gp=grid::gpar(fontfamily="Jost Poster",fontface="bold",fontsize=title_size))),"npc",valueOnly=TRUE)
  latin_y<-name_y-title_height/2-.018
  subtitle_y<-latin_y-.037
  txt(w$title,.045,name_y,title_size,"bold")
  txt("Numenius phaeopus islandicus",.045,latin_y,9,"italic")
  txt(w$subtitle,.045,subtitle_y,19,"bold")
  txt(w$biology,.045,min(.365,subtitle_y-.055),9.5)
  txt("1",.42,.943,38,"bold");txt(w$iceland,.49,.950,12,"bold")
  txt(if(language=="is")sprintf("Um %d m\u00e1nu\u00f0ir \u00e1 varpsl\u00f3\u00f0um.\nH\u00e9r verpa fuglarnir\nog ala upp unga.",facts$summer_months) else sprintf("About %d months on the\nbreeding grounds, to nest\nand raise their chicks.",facts$summer_months),.49,.915,9)
  leader(c(.41,.39,ice[1]+.012),c(.94,.94,ice[2]+.002))
  txt("4",.70,.432,38,"bold");txt(if(language=="is")"VORFER\u00d0IN" else "SPRING JOURNEY",.77,.441,12,"bold")
  txt(if(language=="is")"Til \u00cdslands" else "To Iceland",.77,.419,8.5)
  # Study card and autumn note follow the existing poster's composition.
  grid::grid.polygon(x=c(.035,.345,.345,.315,.035),y=c(.285,.285,.198,.184,.184),gp=grid::gpar(fill=grDevices::adjustcolor("white",alpha.f=.80),col=NA))
  txt(w$study,.05,.264,12,"bold");txt(w$adults,.05,.233,9)
  autumn_heading<-if(language=="is")"HAUSTFER\u00d0IN" else "AUTUMN JOURNEY"
  autumn_destination<-if(language=="is")"Til Vestur-Afr\u00edku" else "To West Africa"
  autumn_duration<-if(language=="is")sprintf("Beint \u00e1 um %d\u2013%d d\u00f6gum.",floor(facts$south_days),ceiling(facts$south_days)) else sprintf("Non-stop in about %d\u2013%d days.",floor(facts$south_days),ceiling(facts$south_days))
  page_width<-grid::convertWidth(grid::unit(1,"npc"),"inches",valueOnly=TRUE)
  autumn_left<-.310-max(text_width(autumn_heading,12),text_width(autumn_destination,8.5),text_width(autumn_duration,9))/page_width
  two_left<-autumn_left-text_width("2",38)/page_width-.015
  txt("2",two_left,.800,38,"bold")
  txt(autumn_heading,autumn_left,.816,12,"bold")
  txt(autumn_destination,autumn_left,.794,8.5)
  txt(autumn_duration,autumn_left,.770,9)
  # Local geographic scale, independent of the schematic journey geometry.
  # Solve for a horizontal projected bar spanning 1,000 km on a mean-radius sphere.
  scale_start<-c(bounds["xmin"]+.05*diff(bounds[c("xmin","xmax")]),bounds["ymin"]+.715*diff(bounds[c("ymin","ymax")]))
  scale_distance<-function(dx){
    ll<-sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(unname(scale_start)),sf::st_point(unname(scale_start+c(dx,0))),crs=projection),4326))*pi/180
    h<-sin((ll[2,2]-ll[1,2])/2)^2+cos(ll[1,2])*cos(ll[2,2])*sin((ll[2,1]-ll[1,1])/2)^2
    2*6371008.8*asin(sqrt(min(1,h)))
  }
  scale_metres<-uniroot(function(dx)scale_distance(dx)-1e6,c(5e5,2e6))$root
  scale_end<-.05+scale_metres/diff(bounds[c("xmin","xmax")])
  leader(c(.05,scale_end),c(.715,.715));leader(c(.05,.05),c(.711,.719));leader(c(scale_end,scale_end),c(.711,.719))
  txt(if(language=="is")"Sk\u00e1sni\u00f0 Mercators" else "Oblique Mercator",.05,.739,7)
  txt(if(language=="is")"Um 1.000 km \u00b7 kvar\u00f0i h\u00e9r" else "Approx. 1,000 km \u00b7 scale here",.05,.697,6.5)
  stopifnot(abs(scale_distance(scale_metres)-1e6)<1)
  txt("3",.40,.166,38,"bold");txt(w$africa,.47,.177,12,"bold")
  txt(if(language=="is")sprintf("Um %d m\u00e1na\u00f0a vetrardv\u00f6l\nvi\u00f0 strendur Vestur-Afr\u00edku.",facts$winter_months) else sprintf("About %d months on\nWest Africa's Atlantic coast.",facts$winter_months),.47,.145,9)
  leader(c(.68,.69,africa[1]-.012),c(.135,.135,africa[2]+.004))
  # Public-facing story, directly on the map: no return-journey panel.
  summary<-if(language=="is")sprintf("Um helmingur fer um \u00cdrland.\nA\u00f0 jafna\u00f0i %d daga vi\u00f0koma.\n\u00dear g\u00e6tu fuglarnir safna\u00f0 kr\u00f6ftum\nog be\u00f0i\u00f0 hagst\u00e6\u00f0ra skilyr\u00f0a\nfyrir flugi\u00f0 til \u00cdslands.\nTil \u00cdslands um \u00cdrland: um %d dagar.\nBeint til \u00cdslands: um %d dagar.",facts$ireland_stop_days,facts$ireland_journey_days,facts$direct_home_days) else sprintf("About half stop in Ireland:\n%d days there, on average.\nThey may build reserves and wait\nfor favourable conditions\nto continue to Iceland.\nTo Iceland via Ireland: about %d days.\nDirect to Iceland: about %d days.",facts$ireland_stop_days,facts$ireland_journey_days,facts$direct_home_days)
  txt(summary,.70,.355,9)
  # Width explanation belongs in the clear ocean text area.
  txt(if(language=="is")paste("Bre\u00ed\u00f0ari l\u00ednur s\u00fdna fleiri fer\u00f0ir.",colours$legend_is,"Dekkri sv\u00e6\u00f0i s\u00fdna fleiri fugla.",sep="\n") else paste("Wider lines show more journeys.",colours$legend,"Darker regions show more birds.",sep="\n"),.04,.153,7.5)
  # Geographic names remain deliberately brief, with no per-stop statistics.
  for(i in which(a$role=="Stopover")) {
    pos<-npc(ap[i,]);txt(toupper(w[[a$region[i]]]),pos[1]+.016,pos[2]+.006,6,"bold")
  }
  places<-data.frame(lon=c(-5,-12,-13,-13,-12.1,-9,-10.5),lat=c(31,20.5,15,13.7,12.4,9,7.8),
    en=c("MOROCCO","MAURITANIA","SENEGAL","THE GAMBIA","GUINEA-BISSAU","GUINEA","SIERRA LEONE"),
    is=c("MAROKK\u00d3","M\u00c1RITAN\u00cdA","SENEGAL","GAMB\u00cdA","G\u00cdNEA-BISSAU","G\u00cdNEA","S\u00cdERRA LE\u00d3NE"))
  for(i in seq_len(nrow(places))){pos<-npc(xy(places$lon[i],places$lat[i]));txt(if(language=="is")places$is[i] else places$en[i],pos[1],pos[2],6,"bold")}
  txt(w$caveat,.04,.112,6.1,"italic")
  leader(c(.035,.95),c(.088,.088))
  txt(paste(w$source," Carneiro, Gunnarsson & Alves (2019)  |  doi:10.1111/jav.01938"),.035,.072,6.5)
  txt(paste(w$data," Dryad, CC0  |  doi:10.5061/dryad.3kf35s5"),.035,.057,6.5)
  txt(w$geography,.035,.043,6);txt(w$credit,.035,.029,5.3);txt(w$method,.035,.016,5.3)
  grDevices::dev.off()
  if(linkedin){
  ragg::agg_png(paste0("previews/spoi/poster",suffix,tag,"-linkedin.png"),width=1200,height=1500,res=150,background=colours$ocean)
  grid::grid.newpage();grid::grid.raster(png::readPNG(file),x=.5,y=.5,width=5/6,height=1,interpolate=TRUE);grDevices::dev.off()
  }
  invisible(structure(file,title_width_inches=title_width,subtitle_width_inches=subtitle_width))
}
