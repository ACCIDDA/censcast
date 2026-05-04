library(hubData)
library(dplyr)
library(purrr)
library(ggplot2)
devtools::load_all()

# --- Window: last 100 days --------------------------------------------
end_date <- Sys.Date()
start_date <- end_date - 100

# --- LOS specs to compare. List names become facet labels. ------------
los_specs <- list(
  "short (mu=0.5w)" = los_spec("negbin", mu = 0.5, k = 1.7, max_stay = 8),
  "med (mu=2w)" = los_spec("negbin", mu = 2, k = 1.7, max_stay = 15),
  "long (mu=5w)" = los_spec("negbin", mu = 5, k = 1.7, max_stay = 40)
)

# 1. Hub admission forecast — last 100 days.
forecast <- connect_hub(s3_bucket("cdcepi-flusight-forecast-hub")) |>
  filter(
    target == "wk inc flu hosp",
    output_type == "quantile",
    model_id == "FluSight-ensemble",
    reference_date >= start_date
  ) |>
  collect_hub()

# 2. Matching truth — back enough for the LONGEST max_stay.
max_stay_max <- max(vapply(los_specs, \(l) length(l) - 1L, integer(1)))
history_start <- start_date - (max_stay_max + 4) * 7

history <- connect_target_timeseries(
  s3_bucket("cdcepi-flusight-forecast-hub")
) |>
  filter(target == "wk inc flu hosp", target_end_date >= history_start) |>
  collect()

# 3. Convolve once per LOS spec; tag each run with the list name.
census_runs <- imap(los_specs, \(los, name) {
  forecast |>
    fcast_census(los = los, history = history) |>
    mutate(los = name)
}) |>
  bind_rows()

# --- 4. Plot: census panels (per LOS) + admissions panel --------------

all_pi <- bind_rows(
  census_runs |> mutate(id = paste("Census:", los)) |> select(-los),
  forecast |> mutate(id = "Admissions (hub forecast)")
) |>
  mutate(
    panel = factor(
      id,
      levels = c(
        paste("Census:", names(los_specs)),
        "Admissions (hub forecast)"
      )
    )
  )

# Truth on the admissions panel only.
obs_adm <- history |>
  filter(location == "US", target_end_date >= start_date - 56)

plot_fan(all_pi, location = "01", truth = obs_adm) +
  facet_wrap(~panel, ncol = 1, scales = "free_y")
