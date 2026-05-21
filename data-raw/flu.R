# Build the toy datasets shipped with the package.
# Re-run after edits with: source("data-raw/flu.R")

library(dplyr)
library(tibble)
devtools::load_all()  # for spec_los()

set.seed(1)
ref      <- as.Date("2024-12-21")
horizons <- 1:4
qs       <- c(0.025, 0.25, 0.5, 0.75, 0.975)

# Admission history: 53 weeks before + 4 weeks overlapping the forecast
# horizons (so it can also serve as truth in score_census()).
dates <- seq(ref - 52 * 7, ref + max(horizons) * 7, by = 7)
admission_history <- tibble(
  target_end_date = dates,
  target          = "wk inc flu hosp",
  location        = "US",
  observation     = rpois(length(dates),
                          100 + 80 * sin(2 * pi * seq_along(dates) / 52))
)

# Census truth: convolve admissions with a "true" LOS. Pair with
# admission_history as input to fit_los() or as truth in score_census().
true_los       <- spec_los("negbin", mu = 2, k = 1.7, max_stay = 8)
census_history <- admission_history |>
  mutate(observation = round(stats::convolve(
    observation, rev(true_los), type = "open"
  )[seq_along(observation)]))

grid <- expand.grid(h = horizons, q = qs)
last <- admission_history |>
  filter(target_end_date < ref) |>
  pull(observation) |> tail(1)
med  <- last * c(1, 0.95, 0.9, 0.85)

admission_forecast <- tibble(
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

usethis::use_data(
  admission_history, admission_forecast, census_history,
  overwrite = TRUE
)
