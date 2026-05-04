# censcast

Hospital **cens**us fore**cast**s from hubverse admission forecasts.

`censcast` convolves hubverse-format admission quantile forecasts with
a length-of-stay (LOS) distribution to produce hubverse-format census
quantile forecasts. Same schema in, same schema out.

```
census(t) = Σ_{s ≤ t} admissions(s) · P(LOS > t − s)
```

## Pipeline

```r
library(censcast)
library(hubData)
library(dplyr)

los <- los_spec("negbin", mu = 2, k = 1.7, max_stay = 15)

forecast <- connect_hub(s3_bucket("cdcepi-flusight-forecast-hub")) |>
  filter(target == "wk inc flu hosp",
         output_type == "quantile",
         model_id    == "FluSight-ensemble") |>
  collect_hub()

history <- connect_target_timeseries(s3_bucket("cdcepi-flusight-forecast-hub")) |>
  filter(target == "wk inc flu hosp") |>
  collect()

census_fc <- forecast |> fcast_census(los = los, history = history)

plot_fan(census_fc, location = "US")
```

## API

| Function         | Role |
|------------------|------|
| `los_spec()`     | Length-of-stay survival vector, parametric. |
| `fcast_census()` | Convolve hubverse admissions × LOS → hubverse census. |
| `plot_fan()`     | Quantile fan chart, returns a `ggplot`. |
| `score_census()` | Optional WIS via `scoringutils`. |

See the vignette for the full walk-through, including how to compare
multiple LOS specs and read the result.

## Out of scope

- LOS fitting (bring your own).
- Hub I/O wrappers (use `hubData`).
- Census truth (hubs ship admissions truth).

## License

MIT.
