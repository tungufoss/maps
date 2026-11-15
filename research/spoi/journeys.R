# Exploratory, conservative region-crossing summaries, not the paper's event labels.
spoi_time <- function(x) as.numeric(as.POSIXct(x,format="%Y-%m-%dT%H:%M:%S",tz="UTC"))/86400

prepare_countries <- function(con,projection) {
  if(!DBI::dbExistsTable(con,"country_geography")) {
    path <- normalizePath("data/raw/spoi/ne_50m_admin_0_countries.zip",winslash="/",mustWork=TRUE)
    x <- sf::st_make_valid(sf::st_read(paste0("/vsizip/",path),quiet=TRUE))
    x <- suppressWarnings(sf::st_crop(x,c(xmin=-35,ymin=0,xmax=15,ymax=72)))
    x <- x[,c("ADMIN","ADM0_A3")]
    f <- tempfile(fileext=".geojson"); sf::st_write(x,f,quiet=TRUE)
    DBI::dbWriteTable(con,"country_geography",data.frame(geojson=paste(readLines(f,warn=FALSE),collapse="\n"),
      source="https://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_countries.zip",
      licence="Public domain",retrieved="2026-11-15",source_md5=unname(tools::md5sum(path))))
  }
  x <- DBI::dbReadTable(con,"country_geography")
  f <- tempfile(fileext=".geojson"); writeLines(x$geojson[1],f,useBytes=TRUE)
  sf::st_transform(sf::st_read(f,quiet=TRUE),projection)
}

align_sensors <- function(d,environment) {
  d$t <- spoi_time(d$timestamp); environment$t <- spoi_time(environment$timestamp)
  d$sensor_n <- 0L; d$land_signal <- NA_real_
  for(id in unique(d$bird_id)) {
    e <- environment[environment$bird_id==id,]
    for(i in which(d$bird_id==id)) {
      # Approximate 12 h light-location interval; never borrow another bird's data.
      q <- e[abs(e$t-d$t[i])<=.25,]
      d$sensor_n[i] <- nrow(q)
      if(nrow(q)) d$land_signal[i] <- mean(q$wet_contacts>0 | q$conductivity>15 |
        (!is.na(q$maximum_temperature-q$minimum_temperature) & q$maximum_temperature-q$minimum_temperature>=8))
    }
  }
  d
}

classify_stop_country <- function(lon,lat,countries) {
  p <- sf::st_transform(sf::st_sfc(sf::st_point(c(lon,lat)),crs=4326),sf::st_crs(countries))
  dist <- as.numeric(sf::st_distance(p,countries))/1000; o <- order(dist)
  # A country is a coarse candidate, not a precise assignment of each light fix.
  ambiguous <- dist[o[1]]>200 || (dist[o[1]]>0 && dist[o[2]]-dist[o[1]]<30)
  list(country=if(ambiguous) "Unresolved" else countries$ADMIN[o[1]],
    nearest_country=countries$ADMIN[o[1]],distance_km=dist[o[1]],margin_km=dist[o[2]]-dist[o[1]])
}

sensor_change <- function(environment,id,reference,kind,season) {
  # Local two-regime change point; bracketed by the coarse location crossing.
  offsets<-if(kind=="departure")c(-7,1,-4,.5) else if(season=="Outbound")c(-1,7,-.5,4) else c(-3,4,-1.5,2)
  e<-environment[environment$bird_id==id & environment$t>=reference+offsets[1] & environment$t<=reference+offsets[2],]
  e<-e[order(e$t),]
  if(nrow(e)<12)return(NA_real_)
  features<-cbind(e$minimum_temperature,e$maximum_temperature,log1p(e$wet_contacts),log1p(e$conductivity))
  usable<-apply(features,2,function(v)sum(is.finite(v))>=8 && sd(v,na.rm=TRUE)>.1)
  features<-features[,usable,drop=FALSE]
  if(!ncol(features))return(NA_real_)
  for(k in seq_len(ncol(features)))features[,k]<-(features[,k]-mean(features[,k],na.rm=TRUE))/sd(features[,k],na.rm=TRUE)
  candidates<-which(e$t>=reference+offsets[3] & e$t<=reference+offsets[4] & seq_len(nrow(e))>=5 & seq_len(nrow(e))<=nrow(e)-4)
  if(!length(candidates))return(NA_real_)
  loss<-function(z)sum(vapply(seq_len(ncol(z)),function(k){v<-z[,k];sum((v-mean(v,na.rm=TRUE))^2,na.rm=TRUE)},numeric(1)))
  cost<-vapply(candidates,function(i)loss(features[1:(i-1),,drop=FALSE])+loss(features[i:nrow(e),,drop=FALSE]),numeric(1))
  i<-candidates[which.min(cost)]
  # A boundary optimum indicates that the event may be outside the search window.
  if(i %in% range(candidates) || max(diff(e$t))>.5)return(NA_real_)
  mean(e$t[c(i-1,i)])
}

detect_journeys <- function(d,countries,min_stop_days=3,environment=NULL) {
  journeys <- list(); stops <- list()
  d$year <- as.integer(substr(d$timestamp,1,4))
  for(id in unique(d$bird_id)) for(year in sort(unique(d$year[d$bird_id==id]))) for(season in c("Outbound","Inbound")) {
    dates <- if(season=="Outbound") c("07-20","09-01") else c("04-10","05-25")
    q <- d[d$bird_id==id & d$timestamp>=paste0(year,"-",dates[1]) & d$timestamp<paste0(year,"-",dates[2],"T23:59:59"),]
    if(nrow(q)<6) next
    q <- q[order(q$t),]
    q$slat <- vapply(q$t,function(t)median(q$latitude[abs(q$t-t)<=.8]),numeric(1))
    q$slon <- vapply(q$t,function(t)median(q$longitude[abs(q$t-t)<=.8]),numeric(1))
    state <- ifelse(q$slat>=60 & q$slon>=-35 & q$slon<=-8,"Iceland",
      ifelse(q$slat<=32 & q$slon>=-30 & q$slon<=5,"Africa","Transit"))
    runs <- cumsum(c(TRUE,state[-1]!=state[-length(state)] | diff(q$t)>1.5))
    stable <- rep(FALSE,nrow(q))
    for(g in unique(runs)) { i<-which(runs==g); if(length(i)>=4 && diff(range(q$t[i]))>=1.5)stable[i]<-TRUE }
    origin <- if(season=="Outbound") "Iceland" else "Africa"
    destination <- if(season=="Outbound") "Africa" else "Iceland"
    o <- which(state==origin & stable); a <- which(state==destination & stable)
    # Do not count deployment-only summers or an incomplete winter as a journey.
    if(!length(o) && !length(a)) next
    if(length(o) && !length(a) && max(q$t)-max(q$t[o])<3)next
    if(length(a) && !length(o) && min(q$t[a])-min(q$t)<3)next
    a <- if(length(o)) a[a>min(o)] else a
    complete <- length(o)>0 && length(a)>0
    key <- paste(id,year,season,sep="/")
    row <- data.frame(journey_id=key,bird_id=id,year=year,season=season,complete=as.integer(complete),
      lane="Unresolved",departure=NA_character_,arrival=NA_character_,elapsed_days=NA_real_,
      stopover_days=NA_real_,max_gap_days=NA_real_,sensor_coverage=NA_real_,
      timing_method="Unavailable",crossing_elapsed_days=NA_real_,reason="Incomplete origin/destination coverage")
    if(complete) {
      ai <- min(a); oi <- max(o[o<ai])
      # Region-crossing times are bracket midpoints, not four-hour flight events.
      start <- mean(q$t[c(oi,oi+1)]); end <- mean(q$t[c(ai-1,ai)])
      row$crossing_elapsed_days<-end-start
      row$timing_method<-"Location crossing only"
      if(!is.null(environment)) {
        depart<-sensor_change(environment,id,start,"departure",season)
        arrive<-sensor_change(environment,id,end,"arrival",season)
        if(is.finite(depart) && is.finite(arrive) && arrive>depart) {
          start<-depart;end<-arrive;row$timing_method<-"Local sensor change points"
        }
      }
      row$departure <- format(as.POSIXct(start*86400,origin="1970-01-01",tz="UTC"),"%Y-%m-%dT%H:%M:%S")
      row$arrival <- format(as.POSIXct(end*86400,origin="1970-01-01",tz="UTC"),"%Y-%m-%dT%H:%M:%S")
      row$elapsed_days <- end-start
      path <- q[oi:ai,]; row$max_gap_days <- max(diff(path$t))
      row$sensor_coverage <- mean(path$sensor_n>0)
      mid <- path[path$slat>=35 & path$slat<60 & path$slon>=-15 & path$slon<=5,]
      groups <- if(nrow(mid))cumsum(c(TRUE,diff(mid$t)>1.5)) else integer()
      found <- list()
      for(g in unique(groups)) {
        z <- mid[groups==g,]
        duration <- diff(range(z$t))
        # Longitudinal/latitudinal stability rejects simply flying across Europe.
        if(nrow(z)<4 || duration<min_stop_days || IQR(z$longitude)>4 || IQR(z$latitude)>5)next
        signal <- mean(z$land_signal,na.rm=TRUE); coverage<-mean(z$sensor_n>0)
        if(!is.finite(signal) || signal<.5 || coverage<.5) next
        country <- classify_stop_country(median(z$longitude),median(z$latitude),countries)
        stop <- data.frame(journey_id=key,bird_id=id,year=year,season=season,
          country=country$country,nearest_country=country$nearest_country,distance_km=country$distance_km,
          margin_km=country$margin_km,first=min(z$timestamp),last=max(z$timestamp),
          duration_days=duration,longitude=mean(z$longitude),latitude=mean(z$latitude),
          land_signal=signal,sensor_coverage=coverage,observations=nrow(z))
        found[[length(found)+1]]<-stop
        stops[[length(stops)+1]]<-stop
      }
      row$stopover_days <- if(length(found))sum(vapply(found,function(x)x$duration_days,numeric(1))) else 0
      if(length(found)) {
        names <- unique(vapply(found,function(x)x$country,character(1)))
        row$lane <- if(length(names)==1)names else "Multiple / unresolved"
        row$reason <- "Sensor-supported, spatially stable candidate stopover"
      } else if(row$max_gap_days<=1.5 && row$sensor_coverage>=.5) {
        row$lane <- "Direct"; row$reason <- "No supported stop of at least three days; short stops may be missed"
      } else row$reason <- "Gaps or sensor coverage prevent a direct/stopover decision"
    }
    journeys[[length(journeys)+1]] <- row
  }
  list(journeys=if(length(journeys))do.call(rbind,journeys) else data.frame(),
    stops=if(length(stops))do.call(rbind,stops) else data.frame())
}

equal_bird_weights <- function(d) {
  # Each bird has equal mass; cycles within that bird also have equal mass.
  group <- interaction(d$bird_id,d$cycle,drop=TRUE)
  n <- table(group); pairs <- unique(d[,c("bird_id","cycle")]); cycles<-table(pairs$bird_id)
  1/as.numeric(n[as.character(group)])/as.numeric(cycles[d$bird_id])/length(unique(d$bird_id))
}

land_anchor <- function(points,weights,region) {
  m <- colSums(sf::st_coordinates(points)*weights)/sum(weights)
  p <- sf::st_sfc(sf::st_point(m),crs=sf::st_crs(points))
  if(lengths(sf::st_intersects(p,region))>0)shown<-p else {
    inset <- suppressWarnings(sf::st_buffer(sf::st_union(region),-1000))
    if(all(sf::st_is_empty(inset)))inset<-sf::st_union(region)
    link <- sf::st_coordinates(sf::st_nearest_points(p,inset))
    shown<-sf::st_sfc(sf::st_point(link[nrow(link),1:2]),crs=sf::st_crs(points))
  }
  list(raw=p,shown=shown,displacement_km=as.numeric(sf::st_distance(p,shown))/1000)
}

region_density <- function(points,weights,region,bandwidth_km,step_km=20) {
  xy <- sf::st_coordinates(points); b<-sf::st_bbox(region)
  # Limit the country mask to the data's vicinity; prevents remote territories.
  b[c("xmin","ymin")]<-pmax(b[c("xmin","ymin")],apply(xy,2,min)-bandwidth_km*3000)
  b[c("xmax","ymax")]<-pmin(b[c("xmax","ymax")],apply(xy,2,max)+bandwidth_km*3000)
  xs<-seq(b["xmin"],b["xmax"],by=step_km*1000); ys<-seq(b["ymin"],b["ymax"],by=step_km*1000)
  cells<-expand.grid(x=xs,y=ys); s<-sf::st_as_sf(cells,coords=c("x","y"),crs=sf::st_crs(points))
  inside<-lengths(sf::st_intersects(s,region))>0; value<-numeric(nrow(cells))
  for(i in which(inside))value[i]<-sum(weights*exp(-((xy[,1]-cells$x[i])^2+(xy[,2]-cells$y[i])^2)/(2*(bandwidth_km*1000)^2)))
  if(!sum(value))return(NULL)
  ranked<-sort(value[value>0],decreasing=TRUE); mass<-cumsum(ranked)/sum(ranked)
  out<-list()
  for(level in c(.95,.75,.50)) {
    threshold<-ranked[which(mass>=level)[1]]
    contour<-isoband::isobands(xs,ys,t(matrix(value,nrow=length(xs))),levels_low=threshold,levels_high=max(value)*1.01)
    shape<-sf::st_sfc(isoband::iso_to_sfg(contour)[[1]],crs=sf::st_crs(points))
    shape<-suppressWarnings(sf::st_intersection(shape,sf::st_union(region)))
    shape<-sf::st_make_valid(shape)
    out[[length(out)+1]]<-sf::st_sf(level=level,geometry=shape)
  }
  do.call(rbind,out)
}

analyse_journeys <- function(observations,environment,countries,projection) {
  d<-observations[observations$display_ok==1,]
  d<-align_sensors(d,environment)
  environment$t<-spoi_time(environment$timestamp)
  detected<-detect_journeys(d,countries,environment=environment)
  j<-detected$journeys; stops<-detected$stops
  summary<-list()
  for(season in unique(j$season)) {
    q<-j[j$season==season & j$complete==1,]
    for(lane in unique(q$lane)) {
      z<-q[q$lane==lane,]
      summary[[length(summary)+1]]<-data.frame(season=season,lane=lane,journeys=nrow(z),
        denominator=nrow(q),percent=100*nrow(z)/nrow(q),birds=length(unique(z$bird_id)),
        timed_journeys=sum(z$timing_method=="Local sensor change points"),
        mean_elapsed_days=if(any(z$timing_method=="Local sensor change points"))mean(z$elapsed_days[z$timing_method=="Local sensor change points"]) else NA_real_,
        mean_stopover_days=mean(z$stopover_days))
    }
  }
  summary<-do.call(rbind,summary)
  regions<-list(); densities<-list(); anchors<-list()
  add_region<-function(name,role,z,codes,bandwidth) {
    if(nrow(z)<3)return()
    region<-countries[countries$ADM0_A3 %in% codes,]
    p<-sf::st_transform(sf::st_as_sf(z,coords=c("longitude","latitude"),crs=4326),projection)
    w<-equal_bird_weights(z); anchor<-land_anchor(p,w,region)
    ll<-sf::st_coordinates(sf::st_transform(anchor$shown,4326)); raw<-sf::st_coordinates(sf::st_transform(anchor$raw,4326))
    anchors[[length(anchors)+1]]<<-data.frame(region=name,role=role,longitude=ll[1],latitude=ll[2],
      raw_longitude=raw[1],raw_latitude=raw[2],display_displacement_km=anchor$displacement_km,
      birds=length(unique(z$bird_id)),observations=nrow(z),bandwidth_km=bandwidth)
    den<-region_density(p,w,region,bandwidth)
    if(!is.null(den)){
      den$region<-name;den$role<-role;den$birds<-length(unique(z$bird_id))
      den$display_alpha<-ifelse(den$level==.95,.08,ifelse(den$level==.75,.20,.42))*den$birds/length(unique(d$bird_id))
      densities[[length(densities)+1]]<<-den
    }
    regions[[name]]<<-z
  }
  add_region("Iceland","Breeding",d[d$month %in% c(6,7) & d$latitude>=58 & d$latitude<=70 & d$longitude>=-30 & d$longitude<=-10,],"ISL",90)
  add_region("West Africa","Non-breeding",d[d$month %in% c(11,12,1,2) & d$latitude<=30 & d$longitude>=-25 & d$longitude<=5,],c("MAR","MRT","SEN","GMB","GNB","GIN","SLE"),160)
  if(nrow(stops))for(country in unique(stops$country[stops$country!="Unresolved"])) {
    s<-stops[stops$country==country,]; selected<-rep(FALSE,nrow(d))
    for(i in seq_len(nrow(s)))selected<-selected | (d$bird_id==s$bird_id[i] & d$timestamp>=s$first[i] & d$timestamp<=s$last[i])
    add_region(country,"Stopover",d[selected,],countries$ADM0_A3[countries$ADMIN==country],90)
  }
  list(journeys=j,stops=stops,summary=summary,anchors=do.call(rbind,anchors),density=do.call(rbind,densities),
    method=list(name="Exploratory sensor-supported region crossings",version="1.0",not_paper_event_reproduction=TRUE,
      location_smoothing="Median of fixes within +/-0.8 days; no interpolation",stable_endpoint="At least four fixes spanning 1.5 days",
      windows=list(outbound="20 July to 1 September",inbound="10 April to 25 May"),
      endpoints=list(Iceland="smoothed latitude >=60; longitude -35 to -8",Africa="smoothed latitude <=32; longitude -30 to 5"),
      stopover="Europe 35-60N/-15-5E, >=3 days, >=4 fixes; longitude IQR <=4deg, latitude IQR <=5deg; >=50% sensor coverage and land signal",
      sensor_alignment="Same bird, +/-6h around light-interval midpoint; land evidence = wet contacts>0 OR conductivity>15 OR temperature range>=8C. Heuristic, not calibrated flight classification.",
      country="Nearest Natural Earth country to stop median, using distances in the poster's oblique Mercator projection; unresolved if >200km offshore or offshore nearest/second-nearest margin<30km. Country assignments remain approximate and projection/threshold dependent.",
      timing="Broad location crossings bracket local two-regime sensor change points (standardized temperature min/max, log1p wet contacts/conductivity, minimum within-segment SSE). Departure search -4 to +0.5 days; arrival -0.5 to +4 days south or -1.5 to +2 days north. Boundary optimum/gaps >12h rejected. Only journeys with both sensor estimates contribute to mean elapsed days. Location-crossing duration retained separately; includes stopovers, excludes pre-departure fuelling. Heuristic, not validated four-hour event accuracy.",
      direct="No detected >=3-day stop, max location gap <=36h, sensor coverage >=50%; short/unobserved stops remain possible",
      denominator="Complete origin-destination candidate journeys per season, including unresolved; incomplete journeys retained separately. Repeated journeys count separately.",
      regional_mean="Projected arithmetic mean, equal weight to birds and then cycles; same breeding/winter anchors for both directions; raw means and land displacement retained",
      density="Weighted Gaussian kernel; fixed 90km breeding/stopover and 160km winter bandwidths; conditional on land. Nested 50/75/95% grid mass; not positional confidence bounds or species-wide range. Black fill without contour outlines; layer alpha .42/.20/.08 multiplied by contributing birds/19, so small-sample regions are fainter.",
      limitations="Raw geolocations are noisy and these analyst thresholds are not validated against the authors' events. Countries, journey classes and elapsed days are exploratory approximations. Data do not resolve exact flight paths; source timezone/datum unspecified.",
      paper="https://doi.org/10.1111/jav.01938",data="https://doi.org/10.5061/dryad.3kf35s5"))
}
