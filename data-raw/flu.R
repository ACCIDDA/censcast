# Build the toy datasets shipped with the package.
# Re-run after edits with: source("data-raw/flu.R")

library(dplyr)
library(tibble)

set.seed(1)
ref      <- as.Date("2024-12-21")
horizons <- 1:4
qs       <- c(0.025, 0.25, 0.5, 0.75, 0.975)

# Admission history: 53 weeks before + 4 weeks overlapping the forecast
# horizons (so it can also serve as truth in score_census()).
dates <- seq(ref - 52 * 7, ref + max(horizons) * 7, by = 7)
flu_history <- tibble(
  target_end_date = dates,
  target          = "wk inc flu hosp",
  location        = "US",
  observation     = rpois(length(dates),
                          100 + 80 * sin(2 * pi * seq_along(dates) / 52))
)

grid <- expand.grid(h = horizons, q = qs)
last <- flu_history |>
  filter(target_end_date < ref) |>
  pull(observation) |> tail(1)
med  <- last * c(1, 0.95, 0.9, 0.85)

flu_forecast <- tibble(
  model_id        = "demo",
  location        = "US",
  reference_date  = ref,
  horizon         = grid$h,
  target_end_date = ref + grid$h * 7L,
  target          = "wk inc flu hosp",
  output_type     = "quantile",
  output_type_id  = as.character(grid$q),
  value           = pmax(med[grid$h] + qnorm(grid$q) * 15 * sqrt(grid$h), 0)
)

usethis::use_data(flu_history, flu_forecast, overwrite = TRUE)
