# Exploratory latitude-binned seasonal location corridors, not inferred flights.
estimate_corridors <- function(positions, repetitions = 1000L, seed = 2027L, min_birds = 5L, smoothing = 0.65) {
  d <- positions[positions$display_ok == 1 & !is.na(positions$latitude), ]
  d$season <- ifelse(d$month %in% c(7,8,9), "Outbound", ifelse(d$month %in% c(4,5), "Inbound", NA_character_))
  d <- d[!is.na(d$season) & d$latitude >= 5 & d$latitude < 67.5, ]
  d$latitude_bin <- floor(d$latitude / 2.5) * 2.5 + 1.25
  # Each cycle contributes one robust longitude per bird and latitude bin.
  cycle_bins <- aggregate(longitude ~ bird_id + cycle + season + latitude_bin, d, median)
  # Repeated years do not give a bird more weight than a bird tracked once.
  bird_bins <- aggregate(longitude ~ bird_id + season + latitude_bin, cycle_bins, mean)
  set.seed(seed)
  estimates <- list(); curves <- list()
  for (season in c("Outbound", "Inbound")) {
    b <- bird_bins[bird_bins$season == season, ]
    if (!nrow(b)) next
    ids <- sort(unique(b$bird_id)); latitudes <- sort(unique(b$latitude_bin))
    boot_ids <- replicate(repetitions, sample(ids, length(ids), replace = TRUE), simplify = FALSE)
    season_bins <- list(); season_boot <- list()
    for (latitude in latitudes) {
      slice <- b[b$latitude_bin == latitude, ]
      if (nrow(slice) < min_birds) next
      values <- setNames(slice$longitude, slice$bird_id)
      boot <- vapply(boot_ids, function(sample_ids) {
        sampled <- values[sample_ids]
        if (all(is.na(sampled))) NA_real_ else mean(sampled, na.rm = TRUE)
      }, numeric(1))
      interval <- quantile(boot, c(.025,.975), na.rm = TRUE, names = FALSE)
      estimates[[length(estimates)+1L]] <- data.frame(season=season, latitude=latitude,
        mean_longitude=mean(slice$longitude), lower=interval[1], upper=interval[2],
        birds=nrow(slice), bootstrap_repetitions=repetitions)
      season_bins[[length(season_bins)+1L]] <- tail(estimates,1)[[1]]
      season_boot[[length(season_boot)+1L]] <- boot
    }
    if (!length(season_bins)) next
    bins <- do.call(rbind,season_bins); boot_matrix <- do.call(rbind,season_boot)
    runs <- cumsum(c(TRUE,diff(bins$latitude)>2.6))
    for (run in unique(runs)) {
      i <- which(runs==run); latitude <- bins$latitude[i]
      grid <- if(length(i)>1)seq(min(latitude),max(latitude),by=.25) else latitude
      fit <- function(values) {
        valid <- is.finite(values)
        if(sum(valid)>=4) return(predict(smooth.spline(latitude[valid],values[valid],spar=smoothing),grid)$y)
        if(sum(valid)>=2) return(approx(latitude[valid],values[valid],xout=grid,rule=1)$y)
        rep(if(sum(valid)==1)values[valid] else NA_real_,length(grid))
      }
      central <- fit(bins$mean_longitude[i])
      smoothed_boot <- vapply(seq_len(repetitions),function(j)fit(boot_matrix[i,j]),numeric(length(grid)))
      if (length(grid)==1) smoothed_boot <- matrix(smoothed_boot,nrow=1)
      limits <- t(apply(smoothed_boot,1,quantile,probs=c(.025,.975),na.rm=TRUE,names=FALSE))
      curves[[length(curves)+1L]] <- data.frame(season=season,run=run,latitude=grid,
        mean_longitude=central,lower=limits[,1],upper=limits[,2])
    }
  }
  estimates <- do.call(rbind, estimates)
  stopifnot(all(estimates$birds >= min_birds), all(estimates$lower <= estimates$upper),
            all(estimates$mean_longitude >= -50 & estimates$mean_longitude <= 20))
  curves <- do.call(rbind,curves)
  stopifnot(all(curves$lower<=curves$upper),all(is.finite(curves$mean_longitude)))
  list(estimates=estimates,curves=curves,bird_bins=bird_bins,cycle_bins=cycle_bins,
       method=list(name="Exploratory seasonal location corridor",latitude_bin_degrees=2.5,
         months=list(outbound=c(7,8,9),inbound=c(4,5)),within_bird_cycle="median longitude",
         within_bird_across_cycles="mean of cycle-bin summaries",between_birds="equal-weight mean",
         smoothing=list(method="cubic smoothing spline",spar=smoothing,applies_to="equal-bird means and every bootstrap curve",scope="separate supported latitude runs; no bridging unsupported bins"),
         uncertainty="95% percentile cluster bootstrap of bird IDs; not individual location error or a flight-path confidence band",
         seed=seed,repetitions=repetitions,min_birds=min_birds,
         limitations="Calendar windows do not identify migration events. Binning loses sequence and may mix stationary/migrating observations. Missingness may be informative. Do not infer stopovers, exact flight paths or distance from the mean corridor."))
}
