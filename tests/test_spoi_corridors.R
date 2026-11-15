source("research/spoi/corridors.R")
fixture <- data.frame(bird_id=c("A","A","B","C","MASKED"),cycle=c("one","two","one","one","one"),
  longitude=c(0,10,15,25,-49),latitude=rep(11,5),month=rep(8,5),display_ok=c(1,1,1,1,0))
one <- estimate_corridors(fixture,repetitions=200,seed=27,min_birds=3)
two <- estimate_corridors(fixture,repetitions=200,seed=27,min_birds=3)
stopifnot(isTRUE(all.equal(one$estimates,two$estimates)),nrow(one$estimates)==1,
          one$estimates$birds==3,one$estimates$mean_longitude==15,
          !"MASKED" %in% one$bird_bins$bird_id,
          one$estimates$lower<=15,one$estimates$upper>=15)
cat("Corridor checks passed: equal bird weights, masked rows excluded, deterministic bootstrap.\n")
long <- do.call(rbind,lapply(c(11,13.5,16,18.5,26),function(lat){q<-fixture;q$latitude<-lat;q$longitude<-q$longitude+sin(lat);q}))
smooth <- estimate_corridors(long,repetitions=100,seed=27,min_birds=3)
stopifnot(nrow(smooth$curves)>nrow(smooth$estimates),all(smooth$curves$lower<=smooth$curves$upper),
          length(unique(smooth$curves$run))==2,!any(smooth$curves$latitude>18.75 & smooth$curves$latitude<26.25))
cat("Smoothed-bootstrap checks passed; unsupported latitude gaps remain open.\n")
