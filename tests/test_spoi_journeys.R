if(.Platform$OS.type=="windows")Sys.setlocale("LC_CTYPE","English_United States.UTF-8")
.libPaths(c(file.path(getwd(),".R-library"),.libPaths()))
library(sf); sf_use_s2(FALSE)
source("research/spoi/journeys.R")
box<-function(x,y)st_polygon(list(rbind(c(x-1,y-1),c(x+1,y-1),c(x+1,y+1),c(x-1,y+1),c(x-1,y-1))))
countries<-st_sf(ADMIN=c("Ireland","France","Iceland"),ADM0_A3=c("IRL","FRA","ISL"),
  geometry=st_sfc(box(-8,53),box(2,46),box(-20,64),crs=4326))
countries<-st_transform(countries,3857)
make<-function(id,stop=TRUE){
  t<-seq(as.POSIXct("2015-04-10",tz="UTC"),as.POSIXct("2015-05-18",tz="UTC"),by="12 hours")
  days<-as.numeric(difftime(t,t[1],units="days"))
  if(stop){lat<-approx(c(0,10,14,24,27,38),c(12,12,53,53,64,64),days)$y;lon<-approx(c(0,10,14,24,27,38),c(-15,-15,-8,-8,-20,-20),days)$y}
  else{lat<-approx(c(0,10,15,38),c(12,12,64,64),days)$y;lon<-rep(-20,length(t))}
  data.frame(bird_id=id,timestamp=format(t,"%Y-%m-%dT%H:%M:%S"),longitude=lon,latitude=lat,
    month=as.integer(format(t,"%m")),cycle="2014-2015",display_ok=1,sensor_n=3,land_signal=1,t=as.numeric(t)/86400)
}
fixture<-rbind(make("STOP"),make("DIRECT",FALSE))
x<-detect_journeys(fixture,countries)
stopifnot(nrow(x$journeys)==2,x$journeys$lane[x$journeys$bird_id=="STOP"]=="Ireland",
  x$journeys$lane[x$journeys$bird_id=="DIRECT"]=="Direct",
  x$journeys$elapsed_days[x$journeys$bird_id=="STOP"]>x$journeys$elapsed_days[x$journeys$bird_id=="DIRECT"],
  x$stops$duration_days>=9)
missing<-fixture[fixture$bird_id=="DIRECT" & !(fixture$t>spoi_time("2015-04-20T00:00:00") & fixture$t<spoi_time("2015-04-24T00:00:00")),]
stopifnot(detect_journeys(missing,countries)$journeys$lane=="Unresolved")
partial<-fixture[fixture$bird_id=="STOP" & fixture$latitude<60,]
stopifnot(all(detect_journeys(partial,countries)$journeys$complete==0))
z<-data.frame(bird_id=c(rep("A",100),"B"),cycle="one")
w<-equal_bird_weights(z)
stopifnot(abs(sum(w[1:100])-.5)<1e-12,abs(w[101]-.5)<1e-12)
p<-st_as_sf(data.frame(x=c(-6,-5),y=c(53,53)),coords=c("x","y"),crs=4326)|>st_transform(3857)
a<-land_anchor(p,c(.5,.5),countries[countries$ADMIN=="Ireland",])
stopifnot(a$displacement_km>0,lengths(st_intersects(a$shown,countries[countries$ADMIN=="Ireland",]))==1,
  lengths(st_intersects(a$raw,countries[countries$ADMIN=="Ireland",]))==0)
env<-data.frame(bird_id=c("A","B"),timestamp="2015-04-20T00:00:00",wet_contacts=c(1,0),conductivity=0,minimum_temperature=5,maximum_temperature=5)
obs<-fixture[1:2,];obs$bird_id<-c("A","B");obs$timestamp<-"2015-04-20T00:00:00"
aligned<-align_sensors(obs,env)
stopifnot(identical(aligned$land_signal,c(1,0)))
cat("Journey checks passed: direct vs stopover, missing coverage, incomplete journeys, equal bird weights, country-constrained marker, bird-specific sensors.\n")
# A known sensor-regime transition should be recovered; another bird must not affect it.
t<-seq(spoi_time("2015-04-10T00:00:00"),spoi_time("2015-04-20T00:00:00"),by=1/6)
regime<-t>=spoi_time("2015-04-16T00:00:00")
e<-data.frame(bird_id="A",t=t,minimum_temperature=ifelse(regime,10,25),maximum_temperature=ifelse(regime,18,32),wet_contacts=ifelse(regime,0,300),conductivity=ifelse(regime,0,118))
event<-sensor_change(e,"A",spoi_time("2015-04-18T00:00:00"),"departure","Inbound")
stopifnot(abs(event-spoi_time("2015-04-16T00:00:00"))<.17,is.na(sensor_change(e,"B",spoi_time("2015-04-18T00:00:00"),"departure","Inbound")))
cat("Sensor timing checks passed: known change recovered; wrong bird rejected.\n")
source("research/spoi/poster-layout.R")
demo<-list(anchors=data.frame(region=c("Iceland","West Africa","Ireland","France"),longitude=c(-20,-15,-8,-4),latitude=c(64,12,53,48)),
  summary=data.frame(season="Inbound",lane=c("Ireland","Direct","France"),journeys=c(13,5,1),percent=100*c(13,5,1)/26))
lanes<-make_lane_geometry(demo,st_crs(countries))
stopifnot(lanes$width[lanes$season=="Outbound"]>max(lanes$width[lanes$season=="Inbound"]),
  abs(lanes$width[lanes$lane=="Southbound"]/lanes$width[lanes$lane=="Ireland"]-30/13)<1e-10,
  all(lanes$color[lanes$season=="Outbound"]==spoi_palette()$south),all(lanes$color[lanes$season=="Inbound"]==spoi_palette()$north))
pal<-spoi_palette();hue<-function(col)rgb2hsv(col2rgb(col))[1]*360
stopifnot(abs((hue(pal$south)-hue(pal$ocean))%%360-210)<1,
          abs((hue(pal$north)-hue(pal$ocean))%%360-150)<1)
cat("Lane-scale checks passed: 30 southbound journeys are wider than 13 via Ireland, on one proportional count scale; route hues are split-complementary to teal.\n")
