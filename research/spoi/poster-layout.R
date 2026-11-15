# Shared layout: only the strings differ between English and Icelandic exports.
poster_words <- function(language) {
  if(language=="is")list(title="SP\u00d3I",title_size=82,subtitle="SUMAR \u00c1 \u00cdSLANDI",vacation="\u2248 3 m\u00e1na\u00f0a sumarfr\u00ed",
    author="Kort skilgreind af Dr. Helgu Ingimundard\u00f3ttur",biology="Ungarnir klekjast \u00fat \u00e1 \u00cdslandi.\nFullor\u00f0nu fuglarnir dvelja sunnar \u00e1 veturna.",
    iceland="\u00cdSLAND",breeding="Varpsv\u00e6\u00f0i",spring="VOR",autumn="HAUST",africa="VESTUR-AFR\u00cdKA",winter="Vetrardv\u00f6l",
    study="19 fuglar \u00b7 56 fer\u00f0ir",adults="Fullor\u00f0nir fuglar \u00ed ranns\u00f3kninni.\n13 karlfuglar og 6 kvenfuglar.",
    south="Um 4\u20135 dagar su\u00f0ur",south_detail="Skynjaramat \u00b7 28 t\u00edmasettar fer\u00f0ir",lanes="VORFER\u00d0IR \u00b7 n = 26",lane_note="Breidd l\u00ednu s\u00fdnir hlutfall fer\u00f0a.",
    direct="Beint",Ireland="\u00cdrland",`United Kingdom`="Bretland",France="Frakkland",Portugal="Port\u00fagal",Unresolved="\u00d3v\u00eds sta\u00f0setning",
    day="d.",via="fer\u00f0",stop="vi\u00f0dv\u00f6l",untimed="T\u00edmalengd \u00f3viss",timed="t\u00edmasettar",unresolved="1/26 fer\u00f0: \u00f3v\u00eds vi\u00f0komusta\u00f0ur (4%).",
    breeding_key="Varp",stop_key="Vi\u00f0koma",winter_key="Vetrardv\u00f6l",density="Dekkri kjarnar: meiri \u00fe\u00e9ttleiki \u00e1\u00e6tla\u00f0ra sta\u00f0setninga.",
    caveat="K\u00f6nnunarmat \u00far hr\u00e1um lj\u00f3sm\u00e6lig\u00f6gnum; ekki sta\u00f0festir atbur\u00f0ir h\u00f6funda.\nLei\u00f0ir eru sk\u00fdringarmyndir milli sv\u00e6\u00f0a. T\u00edmi er me\u00f0 vi\u00f0dv\u00f6lum, \u00e1n fitus\u00f6fnunar fyrir brottf\u00f6r.",
    source="GREIN",data="G\u00d6GN",geography="Land og h\u00e6\u00f0askuggar: Natural Earth, almannaeign. Sk\u00e1sni\u00f0 Mercators.",
    credit="Fuglamynd: gervigreind eftir Nozeman & Sepp. Upprunaleg mynd \u00ed almannaeign; heimildir og fyrirm\u00e6li \u00ed grein.",
    method="Teikna\u00f0 \u00ed R. Sameiginlegir landbundnir me\u00f0alpunktar; 50/75/95% \u00fe\u00e9ttleikasv\u00e6\u00f0i \u00e1 landi, ekki \u00f6ryggism\u00f6rk.")
  else list(title="WHIMBREL",title_size=34,subtitle="SUMMERS IN ICELAND",vacation="\u2248 3 months of summer vacation",
    author="Maps defined by Dr Helga Ingimundard\u00f3ttir",biology="Chicks hatch in Iceland.\nAdults winter farther south.",
    iceland="ICELAND",breeding="Breeding grounds",spring="SPRING",autumn="AUTUMN",africa="WEST AFRICA",winter="Non-breeding season",
    study="19 birds \u00b7 56 migrations",adults="Tracked adults in the study.\n13 males and 6 females.",south="About 4\u20135 days south",south_detail="Sensor estimates \u00b7 28 timed journeys",
    lanes="SPRING JOURNEYS \u00b7 n = 26",lane_note="Spring band width shows journey share.",
    direct="Direct",Ireland="Ireland",`United Kingdom`="United Kingdom",France="France",Portugal="Portugal",Unresolved="Unresolved location",
    day="d",via="journey",stop="stopped",untimed="Timing unresolved",timed="timed",unresolved="1/26 journeys: unresolved stop country (4%).",
    breeding_key="Breeding",stop_key="Stopover",winter_key="Non-breeding",density="Darker cores: greater concentration of location estimates.",
    caveat="Exploratory estimates from raw geolocations; not the authors' confirmed events.\nLanes are schematic links between regions. Elapsed time includes stops, excludes pre-departure fuelling.",
    source="PAPER",data="DATA",geography="Geography & shaded relief: Natural Earth, public domain. Projection: oblique Mercator.",
    credit="Bird illustration: AI after Nozeman & Sepp, public-domain reference. Original, prompt and provenance in the write-up.",
    method="Drawn in R. Shared land-constrained mean markers; 50/75/95% on-land density regions, not confidence bounds.")
}

spoi_palette <- function() {
  ocean<-"#2DD2C0";hue<-rgb2hsv(col2rgb(ocean))[1]
  # The two neighbours of teal's RGB complement, +/-30 degrees from it.
  list(ocean=ocean,south=hsv((hue+210/360)%%1,.70,.82),north=hsv((hue+150/360)%%1,.55,.65),
    legend="Muted orange south; muted magenta north.",
    legend_is="Appels\u00ednugult su\u00f0ur; fj\u00f3lubleikt nor\u00f0ur.",
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

render_spoi_poster <- function(analysis,cartography,projection,bounds,language="en",colours=spoi_palette(),tag="",linkedin=TRUE) {
  w<-poster_words(language);land<-cartography$land;a<-analysis$anchors
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
  suffix<-if(language=="is")"-is" else ""
  file<-paste0("previews/spoi/poster",suffix,tag,".png")
  ragg::agg_png(file,width=1200,height=1800,res=150,background=colours$ocean);print(fig)
  txt<-function(label,x,y,size=12,face="plain",just="left")grid::grid.text(label,x=x,y=y,just=just,gp=grid::gpar(fontfamily="Jost Poster",fontsize=size,fontface=face,col="#262626"))
  leader<-function(x,y)grid::grid.lines(x=x,y=y,gp=grid::gpar(col="#262626",lwd=.8))
  npc<-function(point)c((point[1]-bounds["xmin"])/diff(bounds[c("xmin","xmax")]),(point[2]-bounds["ymin"])/diff(bounds[c("ymin","ymax")]))
  ap<-sf::st_coordinates(anchors); ice<-npc(ap[a$region=="Iceland",]);africa<-npc(ap[a$region=="West Africa",])
  txt("52 / HIDEF MAPS",.035,.977,12,"bold");txt(w$author,.035,.957,6.5)
  grid::grid.raster(png::readPNG("research/illustrations/spoi-flight-ai.png"),x=.25,y=if(language=="en").66 else .70,width=.46,interpolate=TRUE)
  txt(w$title,.04,if(language=="en").535 else .575,w$title_size,"bold");txt(w$subtitle,.045,.495,19,"bold")
  txt(w$vacation,.045,.464,10.5,"bold");txt("Numenius phaeopus islandicus",.045,.441,9,"italic");txt(w$biology,.045,.406,9.5)
  txt("1",.42,.943,38,"bold");txt(w$iceland,.49,.950,12,"bold");txt(w$breeding,.49,.929,9)
  leader(c(.41,.39,ice[1]+.012),c(.94,.94,ice[2]+.002))
  txt("4",.70,.895,38,"bold");txt(w$spring,.77,.904,12,"bold")
  txt(if(language=="is")"Fj\u00f6lbreytt lei\u00f0 heim" else "More than one way home",.70,.858,8.5)
  # Study card and autumn note follow the existing poster's composition.
  grid::grid.polygon(x=c(.035,.345,.345,.315,.035),y=c(.359,.359,.272,.258,.258),gp=grid::gpar(fill=grDevices::adjustcolor("white",alpha.f=.80),col=NA))
  txt(w$study,.05,.338,12,"bold");txt(w$adults,.05,.307,9)
  txt("2",.37,.346,38,"bold");txt(w$autumn,.44,.355,11,"bold");txt(w$south,.44,.326,8.5)
  # Duration includes the two unresolved route classifications; denominator explicit.
  timed<-sum(analysis$summary$timed_journeys[analysis$summary$season=="Outbound"])
  txt(sub("28",paste0("\n",timed),w$south_detail),.44,.302,6.5)
  txt("3",.40,.166,38,"bold");txt(w$africa,.47,.177,12,"bold");txt(w$winter,.47,.150,9)
  leader(c(.64,.67,africa[1]-.012),c(.135,.135,africa[2]+.004))
  # One short information box replaces the individual-country annotations.
  grid::grid.rect(x=.835,y=.73,width=.28,height=.19,gp=grid::gpar(fill=grDevices::adjustcolor("white",alpha.f=.75),col=NA))
  txt(if(language=="is")"HEIMFER\u00d0IN \u00b7 n=26" else "THE JOURNEY HOME \u00b7 n=26",.715,.805,9,"bold")
  summary<-if(language=="is")paste("Flestir stoppa \u00e1 lei\u00f0inni heim.","Um helmingur tekur 12 daga", "sm\u00e1fr\u00ed \u00e1 \u00cdrlandi a\u00f0 me\u00f0altali.","~16 dagar um \u00cdrland; ~5 beint.","Fer\u00f0at\u00edmi inniheldur vi\u00f0dv\u00f6l.",sep="\n") else paste("Most stop on the way home.","About half take a 12-day", "mini-break in Ireland, on average.","~16 days via Ireland; ~5 direct.","Elapsed time includes stops.",sep="\n")
  txt(summary,.715,.734,8.4)
  txt(if(language=="is")paste(colours$legend_is,"Breidd l\u00ednu s\u00fdnir fj\u00f6lda fer\u00f0a.","Dekkri sv\u00e6\u00f0i: fleiri fuglar.",sep="\n") else paste(colours$legend,"One width scale: number of journeys.","Darker regions: more contributing birds.",sep="\n"),.715,.657,6.1)
  # Geographic names remain deliberately brief, with no per-stop statistics.
  for(i in which(a$role=="Stopover")) {
    pos<-npc(ap[i,]);txt(toupper(w[[a$region[i]]]),pos[1]+.016,pos[2]+.006,6,"bold")
  }
  places<-data.frame(lon=c(-5,-7,-13,-13,-12.1,-9,-10.5),lat=c(31,21,15,13.7,12.4,9,7.8),
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
  invisible(file)
}
