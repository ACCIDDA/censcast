# Forecast census from a hubverse admission forecast

Convolves a hubverse admission quantile forecast with a length of stay
survival vector to produce a hubverse census quantile forecast.

## Usage

``` r
fcast_census(admission_fcast, los, admission_history)
```

## Arguments

- admission_fcast:

  Hubverse model output tibble of admission quantile forecasts (output
  of
  [`hubData::collect_hub()`](https://hubverse-org.github.io/hubData/reference/collect_hub.html)).
  One row per (model, location, reference_date, horizon, quantile).

- los:

  Numeric survival vector `P(LOS > d)` of length `max_stay + 1`. Use
  [`spec_los()`](https://accidda.github.io/censcast/reference/spec_los.md)
  for literature priors or
  [`fit_los()`](https://accidda.github.io/censcast/reference/fit_los.md)
  for a data driven fit.

- admission_history:

  Hubverse target time series tibble of observed admissions (output of
  [`hubData::connect_target_timeseries()`](https://hubverse-org.github.io/hubData/reference/connect_target_timeseries.html)
  then collected). Must cover at least `max_stay` time steps immediately
  before each `reference_date` in `admission_fcast`.

## Value

A tibble with the same hubverse columns as `admission_fcast`, with
`value` now representing census instead of admissions.

## Details

Census on the first forecast day depends on admissions before the
forecast starts, because patients already in hospital are still
occupying beds. `admission_history` supplies those pre forecast
admissions so the convolution can see the full `max_stay` window. Groups
with fewer than `max_stay` historical observations before their
`reference_date` are dropped silently.
